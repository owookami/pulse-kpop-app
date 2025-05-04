from typing import Any, Dict, List, Optional, Union
from uuid import uuid4

import httpx
from loguru import logger
from supabase import Client, create_client
from tenacity import retry, stop_after_attempt, wait_exponential

from app.config import settings
from app.models.artist import ArtistCreate, ArtistInDB
from app.models.video import VideoCreate, VideoInDB


class SupabaseService:
    """Supabase 데이터베이스 서비스"""

    def __init__(self, url: Optional[str] = None, key: Optional[str] = None):
        """
        초기화
        
        Args:
            url: Supabase URL (기본값: 환경 변수)
            key: Supabase 키 (기본값: 환경 변수)
        """
        self.url = url or settings.SUPABASE_URL
        self.key = key or settings.SUPABASE_SERVICE_KEY
        self._client = None
        logger.info(f"Supabase 서비스 초기화: URL={self.url}")
        # 보안상 키의 처음과 끝 몇 자만 로그에 표시
        if self.key:
            key_preview = f"{self.key[:5]}...{self.key[-5:]}" if len(self.key) > 10 else "[설정되지 않음]"
            logger.info(f"Supabase 키 미리보기: {key_preview}")

    @property
    def client(self) -> Client:
        """Supabase 클라이언트 인스턴스 생성/반환"""
        if self._client is None:
            logger.info("Supabase 클라이언트 생성 중...")
            try:
                # JWT 토큰 디코딩 시도 (service_role 여부 확인)
                try:
                    import jwt
                    # JWT 토큰 헤더만 디코딩하여 역할 확인
                    token_parts = self.key.split('.')
                    if len(token_parts) == 3:  # 유효한 JWT 형식인 경우
                        payload = jwt.decode(self.key, options={"verify_signature": False})
                        role = payload.get('role', 'unknown')
                        logger.info(f"JWT 토큰 역할: {role}")
                    else:
                        logger.warning("API 키가 JWT 형식이 아닙니다.")
                except ImportError:
                    logger.warning("PyJWT 라이브러리가 설치되지 않았습니다. JWT 분석을 건너뜁니다.")
                except Exception as jwt_error:
                    logger.warning(f"JWT 분석 오류: {jwt_error}")
                
                # 클라이언트 생성 시도
                self._client = create_client(self.url, self.key)
                logger.info("Supabase 클라이언트가 성공적으로 생성되었습니다.")
                
                # 클라이언트 연결 테스트 
                try:
                    # 간단한 쿼리 테스트
                    test_response = self._client.table("videos").select("count", count="exact").limit(1).execute()
                    logger.info(f"Supabase 연결 테스트 성공: {test_response.count if hasattr(test_response, 'count') else '응답 받음'}")
                except Exception as test_error:
                    logger.error(f"Supabase 연결 테스트 실패: {test_error}")
                    
            except Exception as e:
                logger.error(f"Supabase 클라이언트 생성 중 오류 발생: {e}")
                # 추가 오류 정보 기록
                import traceback
                logger.error(f"오류 추적: {traceback.format_exc()}")
                raise
        return self._client

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def get_videos(
        self, 
        limit: int = 10, 
        offset: int = 0, 
        artist_id: Optional[str] = None,
        is_fancam: Optional[bool] = None,
        order_by: str = "created_at.desc"
    ) -> List[VideoInDB]:
        """
        비디오 목록 조회
        
        Args:
            limit: 조회할 비디오 수
            offset: 오프셋 (페이지네이션)
            artist_id: 아티스트 ID 필터
            is_fancam: 팬캠 여부 필터
            order_by: 정렬 기준
        
        Returns:
            비디오 목록
        """
        try:
            query = self.client.table("videos").select("*")
            
            # 필터 적용
            if artist_id:
                query = query.eq("artist_id", artist_id)
            if is_fancam is not None:
                query = query.eq("is_fancam", is_fancam)
            
            # 정렬 및 페이지네이션
            order_field, order_direction = order_by.split(".")
            query = query.order(order_field, ascending=(order_direction == "asc"))
            query = query.range(offset, offset + limit - 1)
            
            response = await query.execute()
            
            if not response.data:
                return []
            
            # VideoInDB 모델로 변환
            videos = [VideoInDB(**item) for item in response.data]
            return videos
            
        except Exception as e:
            logger.error(f"비디오 목록 조회 에러: {e}")
            return []

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def get_video_by_youtube_id(self, youtube_id: str) -> Optional[VideoInDB]:
        """
        YouTube ID로 비디오 조회
        
        Args:
            youtube_id: YouTube 비디오 ID
        
        Returns:
            비디오 정보 또는 None
        """
        try:
            response = await self.client.table("videos").select("*").eq("youtube_id", youtube_id).limit(1).execute()
            
            if not response.data:
                return None
            
            return VideoInDB(**response.data[0])
            
        except Exception as e:
            logger.error(f"YouTube ID로 비디오 조회 에러: {e}")
            return None

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def create_video(self, video: VideoCreate) -> Optional[VideoInDB]:
        """
        비디오 생성
        
        Args:
            video: 비디오 생성 모델
        
        Returns:
            생성된 비디오 정보 또는 None
        """
        try:
            # 중복 검사
            existing_video = await self.get_video_by_youtube_id(video.youtube_id)
            if existing_video:
                logger.info(f"이미 존재하는 비디오: {video.youtube_id}")
                return existing_video
            
            # artist_id 처리
            artist_id = None
            
            # 1. 우선순위 1: 이미 설정된 artist_id가 있는 경우
            if video.artist_id:
                artist_id = video.artist_id
                logger.info(f"비디오 모델에 이미 artist_id가 설정됨: {artist_id}")
            # 2. 우선순위 2: artist_name으로 검색
            elif video.artist_name:
                artist = await self.get_artist_by_name(video.artist_name)
                if artist:
                    artist_id = artist.id
                    logger.info(f"아티스트 이름으로 매칭: {video.artist_name} -> {artist_id}")
                else:
                    logger.warning(f"아티스트를 찾을 수 없음: {video.artist_name} (비디오: {video.title})")
            else:
                logger.warning(f"비디오에 artist_name이 없음: {video.youtube_id} - {video.title}")
            
            # 비디오 데이터 준비
            video_dict = video.model_dump(exclude_unset=True)
            video_dict["id"] = str(uuid4())
            
            # artist_id가 확인되면 명시적으로 설정
            if artist_id:
                video_dict["artist_id"] = artist_id
            else:
                # artist_id가 없는 경우, 모델에서도 삭제하여 DB 기본값 사용
                if "artist_id" in video_dict:
                    # None으로 설정된 경우 키 자체를 제거
                    video_dict.pop("artist_id")
                logger.warning(f"artist_id를 설정할 수 없음: {video.youtube_id} - {video.title}")
            
            # 비디오 삽입
            response = await self.client.table("videos").insert(video_dict).execute()
            
            if not response.data:
                logger.error("비디오 생성 실패")
                return None
            
            # 최종 설정된 artist_id 로깅
            created_video = VideoInDB(**response.data[0])
            if created_video.artist_id:
                logger.info(f"비디오가 artist_id [{created_video.artist_id}]로 생성됨: {created_video.title}")
            else:
                logger.warning(f"비디오가 artist_id 없이 생성됨: {created_video.title}")
            
            # 생성된 비디오 반환
            return created_video
            
        except Exception as e:
            logger.error(f"비디오 생성 에러: {e}")
            return None

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def update_video(self, youtube_id: str, video_data: Dict[str, Any]) -> Optional[VideoInDB]:
        """
        비디오 업데이트
        
        Args:
            youtube_id: YouTube 비디오 ID
            video_data: 업데이트할 비디오 데이터
        
        Returns:
            업데이트된 비디오 정보 또는 None
        """
        try:
            response = await self.client.table("videos").update(video_data).eq("youtube_id", youtube_id).execute()
            
            if not response.data:
                logger.error(f"비디오 업데이트 실패: {youtube_id}")
                return None
            
            return VideoInDB(**response.data[0])
            
        except Exception as e:
            logger.error(f"비디오 업데이트 에러: {e}")
            return None

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def delete_video(self, youtube_id: str) -> bool:
        """
        비디오 삭제
        
        Args:
            youtube_id: YouTube 비디오 ID
        
        Returns:
            삭제 성공 여부
        """
        try:
            response = await self.client.table("videos").delete().eq("youtube_id", youtube_id).execute()
            
            return bool(response.data)
            
        except Exception as e:
            logger.error(f"비디오 삭제 에러: {e}")
            return False

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def get_artists(
        self, 
        limit: int = 10, 
        offset: int = 0,
        is_group: Optional[bool] = None,
        active: Optional[bool] = None,
        order_by: str = "name.asc"
    ) -> List[ArtistInDB]:
        """
        아티스트 목록 조회
        
        Args:
            limit: 조회할 아티스트 수
            offset: 오프셋 (페이지네이션)
            is_group: 그룹 여부 필터
            active: 활동 여부 필터
            order_by: 정렬 기준
        
        Returns:
            아티스트 목록
        """
        try:
            query = self.client.table("artists").select("*")
            
            # 필터 적용
            if is_group is not None:
                query = query.eq("is_group", is_group)
            if active is not None:
                query = query.eq("active", active)
            
            # 정렬 및 페이지네이션
            order_field, order_direction = order_by.split(".")
            query = query.order(order_field, ascending=(order_direction == "asc"))
            query = query.range(offset, offset + limit - 1)
            
            response = await query.execute()
            
            if not response.data:
                return []
            
            # ArtistInDB 모델로 변환
            artists = [ArtistInDB(**item) for item in response.data]
            return artists
            
        except Exception as e:
            logger.error(f"아티스트 목록 조회 에러: {e}")
            return []

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def get_artist_by_name(self, name: str) -> Optional[ArtistInDB]:
        """
        이름으로 아티스트 조회 (대소문자 구분 없음)
        
        Args:
            name: 아티스트 이름
        
        Returns:
            아티스트 정보 또는 None
        """
        try:
            name = name.lower().strip()
            
            # 기본 이름으로 먼저 조회
            response = await self.client.table("artists").select("*").ilike("name", name).limit(1).execute()
            
            if response.data:
                return ArtistInDB(**response.data[0])
            
            # 대체 이름 배열에서 검색
            query = f"""
            SELECT *
            FROM artists
            WHERE EXISTS (
                SELECT 1
                FROM unnest(alternate_names) alt_name
                WHERE LOWER(alt_name) = '{name}'
            )
            LIMIT 1
            """
            
            response = await self.client.rpc("search_artist_by_alternate_name", {"search_name": name}).execute()
            
            if not response.data:
                return None
            
            return ArtistInDB(**response.data[0])
            
        except Exception as e:
            logger.error(f"이름으로 아티스트 조회 에러: {e}")
            return None

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def create_artist(self, artist: ArtistCreate) -> Optional[ArtistInDB]:
        """
        아티스트 생성
        
        Args:
            artist: 아티스트 생성 모델
        
        Returns:
            생성된 아티스트 정보 또는 None
        """
        try:
            # 중복 검사
            existing_artist = await self.get_artist_by_name(artist.name)
            if existing_artist:
                logger.info(f"이미 존재하는 아티스트: {artist.name}")
                return existing_artist
            
            # 아티스트 데이터 준비
            artist_dict = artist.model_dump(exclude_unset=True)
            artist_dict["id"] = str(uuid4())
            
            # 아티스트 삽입
            response = await self.client.table("artists").insert(artist_dict).execute()
            
            if not response.data:
                logger.error("아티스트 생성 실패")
                return None
            
            # 생성된 아티스트 반환
            return ArtistInDB(**response.data[0])
            
        except Exception as e:
            logger.error(f"아티스트 생성 에러: {e}")
            return None

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def update_artist(self, artist_id: str, artist_data: Dict[str, Any]) -> Optional[ArtistInDB]:
        """
        아티스트 업데이트
        
        Args:
            artist_id: 아티스트 ID
            artist_data: 업데이트할 아티스트 데이터
        
        Returns:
            업데이트된 아티스트 정보 또는 None
        """
        try:
            response = await self.client.table("artists").update(artist_data).eq("id", artist_id).execute()
            
            if not response.data:
                logger.error(f"아티스트 업데이트 실패: {artist_id}")
                return None
            
            return ArtistInDB(**response.data[0])
            
        except Exception as e:
            logger.error(f"아티스트 업데이트 에러: {e}")
            return None

    async def reset_video_counts(self) -> bool:
        """
        모든 아티스트의 비디오 수 초기화
        
        Returns:
            성공 여부
        """
        try:
            # 모든 아티스트의 video_count를 0으로 초기화
            await self.client.table("artists").update({"video_count": 0}).execute()
            return True
        except Exception as e:
            logger.error(f"비디오 수 초기화 에러: {e}")
            return False

    async def update_video_counts(self) -> bool:
        """
        아티스트 비디오 카운트 업데이트
        아티스트와 연결된 모든 비디오를 카운트하여 video_count 필드 업데이트
        
        Returns:
            성공 여부
        """
        try:
            # 먼저 모든 카운트 초기화
            await self.reset_video_counts()
            
            # 아티스트별 비디오 수 조회 및 업데이트
            artists = await self.get_artists(limit=1000)  # 모든 아티스트 조회
            
            for artist in artists:
                # 아티스트의 비디오 수 조회
                query = f"""
                SELECT COUNT(*) as count
                FROM videos
                WHERE artist_id = '{artist.id}'
                """
                
                response = await self.client.rpc("count_artist_videos", {"artist_id": artist.id}).execute()
                
                if response.data:
                    video_count = response.data[0].get("count", 0)
                    
                    # 업데이트
                    await self.client.table("artists").update({"video_count": video_count}).eq("id", artist.id).execute()
                    
                    logger.info(f"아티스트 비디오 수 업데이트: {artist.name} - {video_count}개")
            
            return True
            
        except Exception as e:
            logger.error(f"비디오 카운트 업데이트 에러: {e}")
            return False 