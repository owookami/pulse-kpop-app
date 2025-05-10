from datetime import datetime
import json
import re
from typing import Any, Dict, List, Optional, Tuple

import httpx
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from loguru import logger
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

from app.config import settings
from app.models.video import VideoCreate


class YouTubeAPIService:
    """YouTube API 서비스"""

    def __init__(self, api_key: Optional[str] = None):
        """초기화"""
        self.api_key = api_key or settings.YOUTUBE_API_KEY
        self._service = None
        self._quota_used = 0

    @property
    def service(self):
        """YouTube API 서비스 인스턴스 생성/반환"""
        if self._service is None:
            self._service = build("youtube", "v3", developerKey=self.api_key)
        return self._service

    @property
    def quota_used(self) -> int:
        """사용된 쿼터 반환"""
        return self._quota_used

    def reset_quota(self):
        """쿼터 사용량 초기화"""
        self._quota_used = 0

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type(HttpError)
    )
    async def search_videos(
        self,
        query: str,
        max_results: int = 10,
        published_after: Optional[datetime] = None,
        order: str = "relevance",
        page_token: Optional[str] = None,
    ) -> Tuple[List[Dict[str, Any]], Optional[str]]:
        """
        YouTube 비디오 검색
        
        Args:
            query: 검색 쿼리
            max_results: 최대 결과 수 (최대 50)
            published_after: 특정 날짜 이후 게시된 비디오만 검색
            order: 정렬 방식 ('date', 'rating', 'relevance', 'title', 'videoCount', 'viewCount')
            page_token: 다음 페이지 토큰
            
        Returns:
            검색 결과 리스트와 다음 페이지 토큰
        """
        # 쿼터 사용량 100
        self._quota_used += 100

        # 검색 매개변수
        search_params = {
            "q": query,
            "part": "snippet",
            "maxResults": min(max_results, 50),  # YouTube API 제한
            "type": "video",
            "order": order,
            "pageToken": page_token,
        }

        # 특정 날짜 이후 필터링
        if published_after:
            search_params["publishedAfter"] = published_after.isoformat() + "Z"

        try:
            # 검색 실행
            search_response = self.service.search().list(**search_params).execute()
            
            # 비디오 ID 목록 추출
            video_ids = [item["id"]["videoId"] for item in search_response.get("items", [])]
            
            if not video_ids:
                return [], search_response.get("nextPageToken")
            
            # 비디오 상세 정보 가져오기
            videos = await self.get_videos_details(video_ids)
            
            return videos, search_response.get("nextPageToken")
            
        except HttpError as e:
            logger.error(f"YouTube API 검색 에러: {e}")
            raise

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type(HttpError)
    )
    async def get_videos_details(self, video_ids: List[str]) -> List[Dict[str, Any]]:
        """
        비디오 ID 목록으로 상세 정보 조회
        
        Args:
            video_ids: 비디오 ID 목록
            
        Returns:
            비디오 상세 정보 목록
        """
        # 쿼터 사용량: 1 코스트 * 영상 수
        self._quota_used += len(video_ids)
        
        # 비어있는 목록 체크
        if not video_ids:
            return []

        try:
            # 컴마로 구분된 ID 문자열
            video_ids_str = ",".join(video_ids)
            
            # 비디오 상세 정보 요청
            videos_response = self.service.videos().list(
                part="snippet,contentDetails,statistics",
                id=video_ids_str
            ).execute()
            
            # 응답 처리
            videos = []
            for item in videos_response.get("items", []):
                # 비디오 데이터 매핑
                video_data = self._map_video_data(item)
                if video_data:
                    videos.append(video_data)
            
            return videos
            
        except HttpError as e:
            logger.error(f"YouTube 비디오 상세 정보 조회 에러: {e}")
            raise

    def _map_video_data(self, item: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        YouTube API 응답을 비디오 데이터로 매핑
        
        Args:
            item: YouTube API 응답 아이템
            
        Returns:
            매핑된 비디오 데이터
        """
        try:
            snippet = item.get("snippet", {})
            statistics = item.get("statistics", {})
            content_details = item.get("contentDetails", {})
            
            # 기본 메타데이터 추출
            published_at = snippet.get("publishedAt")
            if published_at:
                published_at = datetime.fromisoformat(published_at.replace("Z", "+00:00"))
            
            # 비디오 데이터 생성
            video_data = {
                "youtube_id": item.get("id", ""),
                "title": snippet.get("title", ""),
                "description": snippet.get("description", ""),
                "published_at": published_at or datetime.now(),
                "channel_id": snippet.get("channelId", ""),
                "channel_title": snippet.get("channelTitle", ""),
                "thumbnail_url": self._get_highest_res_thumbnail(snippet.get("thumbnails", {})),
                "tags": snippet.get("tags", []),
                "view_count": int(statistics.get("viewCount", 0)),
                "like_count": int(statistics.get("likeCount", 0)),
                "comment_count": int(statistics.get("commentCount", 0)),
                "duration": content_details.get("duration", ""),
            }
            
            # 팬캠 여부 분석
            video_data["is_fancam"] = self._is_fancam(video_data)
            
            # 아티스트 정보 추출
            artist_name, event_name = self._extract_artist_and_event(video_data)
            video_data["artist_name"] = artist_name
            video_data["event_name"] = event_name
            
            # 품질 점수 계산
            video_data["quality_score"] = self._calculate_quality_score(video_data)
            
            return video_data
            
        except Exception as e:
            logger.error(f"비디오 데이터 매핑 에러: {e}")
            return None

    def _get_highest_res_thumbnail(self, thumbnails: Dict[str, Any]) -> Optional[str]:
        """가장 높은 해상도의 썸네일 URL 반환"""
        # 해상도 우선순위: maxres > standard > high > medium > default
        for quality in ["maxres", "standard", "high", "medium", "default"]:
            if quality in thumbnails:
                return thumbnails[quality].get("url")
        return None

    def _is_fancam(self, video_data: Dict[str, Any]) -> bool:
        """
        비디오가 팬캠인지 분석
        
        다음 조건을 충족해야 함:
        1. 제목에 '직캠', 'fancam', 'focus', '포커스' 등의 키워드 포함
        2. 제목이나 설명에 부적절한 키워드가 없어야 함
        3. 일정 품질 이상의 영상이어야 함
        """
        title = video_data.get("title", "").lower()
        description = video_data.get("description", "").lower()
        tags = [tag.lower() for tag in video_data.get("tags", [])]
        channel_title = video_data.get("channel_title", "").lower()
        
        # 팬캠 관련 키워드
        fancam_keywords = [
            "fancam", "fan cam", "직캠", "focus", "포커스", "cam", "full cam", 
            "fullcam", "stage cam", "concert cam", "zoom", "무대", "stage", "performance"
        ]
        
        # 주요 방송사/채널 (신뢰할 수 있는 출처)
        trusted_channels = [
            "mbc", "kbs", "sbs", "m countdown", "mnet", "music bank", "inkigayo",
            "쇼! 음악중심", "뮤직뱅크", "엠카운트다운", "인기가요", "show champion"
        ]
        
        # 부적절한 키워드 (필터링해야 할 단어)
        inappropriate_keywords = [
            "fake", "deepfake", "ai", "edit", "reaction", "reacting", "lyrics", "audio",
            "compilation", "mashup", "mash up", "remix", "교차편집", "가사", "자막", "반응",
            "shorts", "tiktok", "instagram", "릴스", "reels", "1인 리액션", 
            "dance cover", "choreography", "안무", "cover", "커버"
        ]
        
        # 1. 팬캠 키워드가 있는지 확인
        has_fancam_keyword = False
        for keyword in fancam_keywords:
            if keyword in title:
                has_fancam_keyword = True
                break
        
        # 2. 신뢰할 수 있는 채널인지 확인
        is_trusted_channel = False
        for channel in trusted_channels:
            if channel in channel_title:
                is_trusted_channel = True
                break
                
        # 3. 부적절한 키워드가 있는지 확인
        has_inappropriate_keyword = False
        for keyword in inappropriate_keywords:
            if keyword in title or keyword in description:
                has_inappropriate_keyword = True
                break
        
        # 4. 최소 조회수 및 비디오 길이 확인
        view_count = video_data.get("view_count", 0)
        duration = video_data.get("duration", "")
        
        # ISO 8601 기간 형식 파싱 (PT1M30S = 1분 30초)
        minutes = 0
        seconds = 0
        
        if duration:
            minutes_match = re.search(r'(\d+)M', duration)
            if minutes_match:
                minutes = int(minutes_match.group(1))
                
            seconds_match = re.search(r'(\d+)S', duration)
            if seconds_match:
                seconds = int(seconds_match.group(1))
        
        total_seconds = minutes * 60 + seconds
        
        # 팬캠 조건:
        # - 팬캠 키워드가 있거나 신뢰할 수 있는 채널이어야 함
        # - 부적절한 키워드가 없어야 함
        # - 최소 30초 이상 길이 (너무 짧은 영상은 제외)
        # - 최소 1,000회 이상 조회수 (인기 있는 영상만)
        is_fancam = (has_fancam_keyword or is_trusted_channel) and \
                    not has_inappropriate_keyword and \
                    total_seconds >= 30 and \
                    view_count >= 1000
        
        return is_fancam

    def _extract_artist_and_event(self, video_data: Dict[str, Any]) -> Tuple[Optional[str], Optional[str]]:
        """
        제목에서 아티스트와 이벤트 정보 추출
        
        제목 패턴 예시:
        - [4K] 아이브 장원영 직캠 'Kitsch' (IVE WONGYOUNG Fancam) @음악중심 230325
        - [직캠] 르세라핌 카즈하 'UNFORGIVEN' (LE SSERAFIM KAZUHA Fancam) @뮤직뱅크
        - [4K] 에스파 윈터 'Spicy' 직캠 (aespa WINTER Fancam) @인기가요 230528
        """
        title = video_data.get("title", "")
        
        # 영어, 한글 이름 패턴 매치
        artist_pattern = r'(?:\[.*?\])?\s*([가-힣a-zA-Z\s]+)\s+([가-힣a-zA-Z\s]+)\s+(?:직캠|fancam|focus|cam)'
        event_pattern = r'@([가-힣a-zA-Z\s]+)\s*(\d{6})?'
        
        # 아티스트 매칭 시도
        artist_match = re.search(artist_pattern, title, re.IGNORECASE)
        artist_name = None
        
        if artist_match:
            # 그룹명과 멤버명 추출
            group_name = artist_match.group(1).strip()
            member_name = artist_match.group(2).strip()
            
            # 영어 그룹명이 괄호 안에 있는 경우 처리
            english_group_match = re.search(r'\(([A-Za-z\s]+)\s+[A-Za-z\s]+\)', title)
            if english_group_match:
                group_name = english_group_match.group(1).strip()
            
            artist_name = f"{member_name} ({group_name})"
        
        # 이벤트 매칭 시도
        event_match = re.search(event_pattern, title)
        event_name = None
        
        if event_match:
            event_name = event_match.group(1).strip()
            
            # 날짜가 있으면 추가
            if event_match.group(2):
                date_str = event_match.group(2)
                formatted_date = f"20{date_str[:2]}-{date_str[2:4]}-{date_str[4:6]}"
                event_name = f"{event_name} {formatted_date}"
        
        return artist_name, event_name

    def _calculate_quality_score(self, video_data: Dict[str, Any]) -> float:
        """
        비디오 품질 점수 계산
        
        다음 요소를 고려하여 0-100 점수 계산:
        - 조회수 (40%)
        - 좋아요 수 (20%)
        - 댓글 수 (10%)
        - 신뢰할 수 있는 채널 여부 (15%)
        - 영상 해상도/길이 (15%)
        """
        try:
            view_count = int(video_data.get("view_count", 0))
            like_count = int(video_data.get("like_count", 0))
            comment_count = int(video_data.get("comment_count", 0))
            channel_title = video_data.get("channel_title", "").lower()
            duration = video_data.get("duration", "")
            
            # 1. 조회수 점수 (0-40)
            view_score = min(40, (view_count / 10000) * 40) if view_count > 0 else 0
            
            # 2. 좋아요 점수 (0-20)
            like_score = min(20, (like_count / 1000) * 20) if like_count > 0 else 0
            
            # 3. 댓글 점수 (0-10)
            comment_score = min(10, (comment_count / 100) * 10) if comment_count > 0 else 0
            
            # 4. 채널 신뢰도 점수 (0-15)
            channel_score = 0
            trusted_channels = [
                "mbc", "kbs", "sbs", "m countdown", "mnet", "music bank", "inkigayo",
                "쇼! 음악중심", "뮤직뱅크", "엠카운트다운", "인기가요", "show champion",
                "official", "공식", "조회수", "조회", "직캠", "직캠티비"
            ]
            
            for trusted_channel in trusted_channels:
                if trusted_channel in channel_title:
                    channel_score = 15
                    break
            
            # 영상 길이가 적절한지 확인 (2분~5분 사이의 영상이 가장 이상적)
            # ISO 8601 기간 형식 파싱 (PT1M30S = 1분 30초)
            minutes = 0
            seconds = 0
            
            if duration:
                minutes_match = re.search(r'(\d+)M', duration)
                if minutes_match:
                    minutes = int(minutes_match.group(1))
                    
                seconds_match = re.search(r'(\d+)S', duration)
                if seconds_match:
                    seconds = int(seconds_match.group(1))
            
            total_seconds = minutes * 60 + seconds
            
            # 5. 길이 점수 (0-15)
            # 2분~5분 사이가 이상적인 팬캠 길이
            duration_score = 0
            if total_seconds >= 120 and total_seconds <= 300:
                duration_score = 15
            elif total_seconds > 300:
                duration_score = 10
            elif total_seconds >= 60:
                duration_score = 8
            elif total_seconds >= 30:
                duration_score = 5
            
            # 6. 영상 해상도 점수 (특별 보너스 최대 10점)
            resolution_bonus = 0
            thumbnail_url = video_data.get("thumbnail_url", "")
            if "maxres" in thumbnail_url:
                resolution_bonus = 10
            elif "hq" in thumbnail_url:
                resolution_bonus = 5
            
            # 7. 제목에 HD, 4K 등의 키워드가 포함된 경우 추가 보너스
            title = video_data.get("title", "").upper()
            resolution_keywords = ["4K", "HD", "FHD", "UHD", "1080P", "60FPS"]
            for keyword in resolution_keywords:
                if keyword in title:
                    resolution_bonus = max(resolution_bonus, 8)
                    break
            
            # 최종 점수 계산
            total_score = view_score + like_score + comment_score + channel_score + duration_score + resolution_bonus
            
            # 0-100 사이로 정규화
            return round(min(100, total_score), 2)
            
        except Exception as e:
            logger.error(f"품질 점수 계산 에러: {e}")
            return 0.0

    def create_video_model(self, video_data: Dict[str, Any]) -> VideoCreate:
        """
        비디오 데이터를 VideoCreate 모델로 변환
        
        Args:
            video_data: 매핑된 비디오 데이터
            
        Returns:
            VideoCreate 모델 인스턴스
        """
        # artist_id가 video_data에 없을 경우 명시적으로 None 설정
        artist_id = video_data.get("artist_id", None)
        
        # 썸네일 URL 확인 및 로깅
        thumbnail_url = video_data.get("thumbnail_url")
        if thumbnail_url is None:
            logger.warning(f"thumbnail_url이 None입니다: {video_data.get('youtube_id', 'unknown')} - {video_data.get('title', 'unknown')}")
        elif not thumbnail_url:
            logger.warning(f"thumbnail_url이 빈 문자열입니다: {video_data.get('youtube_id', 'unknown')} - {video_data.get('title', 'unknown')}")
        
        # 썸네일이 없는 경우 기본 썸네일 URL 설정
        if not thumbnail_url:
            youtube_id = video_data.get("youtube_id")
            if youtube_id:
                # YouTube 기본 썸네일 URL 생성
                thumbnail_url = f"https://i.ytimg.com/vi/{youtube_id}/hqdefault.jpg"
                logger.info(f"기본 썸네일 URL 생성: {thumbnail_url}")
        
        # VideoCreate 모델 생성 시 artist_id와 thumbnail_url 명시적으로 포함
        return VideoCreate(
            title=video_data.get("title", ""),
            youtube_id=video_data.get("youtube_id", ""),
            channel_id=video_data.get("channel_id", ""),
            channel_title=video_data.get("channel_title", ""),
            published_at=video_data.get("published_at"),
            description=video_data.get("description"),
            thumbnail_url=thumbnail_url,
            view_count=video_data.get("view_count", 0),
            like_count=video_data.get("like_count", 0),
            comment_count=video_data.get("comment_count", 0),
            duration=video_data.get("duration"),
            tags=video_data.get("tags", []),
            artist_id=artist_id,  # 명시적으로 artist_id 설정
            artist_name=video_data.get("artist_name"),
            event_name=video_data.get("event_name"),
            quality_score=video_data.get("quality_score", 0.0),
            is_fancam=video_data.get("is_fancam", True),
        ) 