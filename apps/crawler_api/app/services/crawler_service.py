from datetime import datetime, timedelta
import asyncio
from typing import Dict, List, Optional, Set

from loguru import logger
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.jobstores.memory import MemoryJobStore
from apscheduler.triggers.interval import IntervalTrigger

from app.config import settings
from app.models.artist import ArtistInDB
from app.services.supabase_service import SupabaseService
from app.services.youtube_service import YouTubeAPIService


class CrawlerService:
    """K-POP 팬캠 크롤러 서비스"""

    def __init__(self):
        """초기화"""
        self.youtube_service = YouTubeAPIService()
        self.supabase_service = SupabaseService()
        self.scheduler = None
        self.running_jobs = set()
        self.is_initialized = False

    async def initialize(self):
        """크롤러 서비스 초기화"""
        if self.is_initialized:
            return
        
        # 스케줄러 설정
        self.scheduler = AsyncIOScheduler(
            jobstores={"default": MemoryJobStore()},
        )
        
        # 주기적 크롤링 일정 추가
        self.scheduler.add_job(
            self.crawl_all_artists,
            trigger=IntervalTrigger(minutes=settings.CRAWL_INTERVAL_MINUTES),
            id="crawl_all_artists",
            replace_existing=True,
            next_run_time=datetime.now() + timedelta(minutes=1),  # 1분 후 첫 실행
        )
        
        # 스케줄러 시작
        self.scheduler.start()
        logger.info("크롤러 스케줄러 시작됨")
        
        self.is_initialized = True

    async def shutdown(self):
        """크롤러 서비스 종료"""
        if self.scheduler and self.scheduler.running:
            self.scheduler.shutdown()
            logger.info("크롤러 스케줄러 종료됨")

    async def crawl_all_artists(self):
        """모든 활성 아티스트의 팬캠 크롤링"""
        if "crawl_all_artists" in self.running_jobs:
            logger.warning("이미 아티스트 크롤링이 실행 중입니다.")
            return
        
        self.running_jobs.add("crawl_all_artists")
        
        try:
            # 활성 아티스트 조회
            artists = await self.supabase_service.get_artists(
                limit=1000,  # 모든 아티스트 조회
                active=True,
            )
            
            if not artists:
                logger.warning("크롤링할 아티스트가 없습니다.")
                return
            
            logger.info(f"{len(artists)}명의 아티스트에 대해 크롤링 시작")
            
            # 잠재적인 쿼터 사용량 계산
            # 아티스트당 1번의 검색(100) + 평균 10개 비디오 상세 정보(10)
            estimated_quota = len(artists) * 110
            
            if estimated_quota > settings.YOUTUBE_API_QUOTA_LIMIT:
                logger.warning(f"예상 쿼터 사용량({estimated_quota})이 한도({settings.YOUTUBE_API_QUOTA_LIMIT})를 초과합니다.")
                logger.warning("일부 아티스트만 크롤링합니다.")
                
                # 쿼터를 초과하지 않을 만큼만 아티스트 선택
                max_artists = settings.YOUTUBE_API_QUOTA_LIMIT // 110
                artists = artists[:max_artists]
            
            # 각 아티스트 크롤링
            tasks = []
            for artist in artists:
                task = asyncio.create_task(self._crawl_artist_fancams(artist))
                tasks.append(task)
            
            # 최대 5개 작업 동시 실행 (API 속도 제한 고려)
            for i in range(0, len(tasks), 5):
                batch = tasks[i:i+5]
                await asyncio.gather(*batch)
                await asyncio.sleep(1)  # API 속도 제한 방지를 위한 대기
            
            # 비디오 수 업데이트
            await self.supabase_service.update_video_counts()
            
            logger.info(f"모든 아티스트 크롤링 완료. 사용된 쿼터: {self.youtube_service.quota_used}")
            
        except Exception as e:
            logger.error(f"크롤링 중 오류 발생: {e}")
        
        finally:
            self.running_jobs.remove("crawl_all_artists")
            # 쿼터 사용량 초기화
            self.youtube_service.reset_quota()

    async def _crawl_artist_fancams(self, artist: ArtistInDB) -> int:
        """
        특정 아티스트의 팬캠 크롤링
        
        Args:
            artist: 아티스트 정보
            
        Returns:
            저장된 비디오 수
        """
        try:
            # 아티스트 검색어 구성
            search_keywords = []
            
            # 기본 검색어
            search_keywords.append(f"{artist.name} 직캠")
            search_keywords.append(f"{artist.name} fancam")
            
            # 추가 검색어가 있으면 추가
            if artist.search_keywords:
                search_keywords.extend(artist.search_keywords)
            
            # 대체 이름이 있으면 추가
            if artist.alternate_names:
                for alt_name in artist.alternate_names:
                    search_keywords.append(f"{alt_name} 직캠")
                    search_keywords.append(f"{alt_name} fancam")
            
            # 저장된 비디오 수
            saved_count = 0
            
            # 각 검색어로 크롤링
            for keyword in search_keywords:
                # 쿼터 한도 확인
                if self.youtube_service.quota_used >= settings.YOUTUBE_API_QUOTA_LIMIT:
                    logger.warning(f"쿼터 한도({settings.YOUTUBE_API_QUOTA_LIMIT})에 도달했습니다.")
                    break
                
                # 최근 1년 내 영상으로 제한
                published_after = datetime.now() - timedelta(days=365)
                
                # 비디오 검색
                videos, _ = await self.youtube_service.search_videos(
                    query=keyword,
                    max_results=settings.YOUTUBE_API_MAX_RESULTS,
                    published_after=published_after,
                    order="date",  # 최신순으로 정렬
                )
                
                logger.info(f"아티스트 '{artist.name}', 키워드 '{keyword}'로 {len(videos)}개 비디오 검색됨")
                
                # 검색 결과가 없으면 다음 키워드로
                if not videos:
                    continue
                
                # VideoCreate 모델로 변환 및 저장
                for video_data in videos:
                    # 최대 비디오 수 체크
                    if saved_count >= settings.MAX_VIDEOS_PER_ARTIST:
                        logger.info(f"아티스트 '{artist.name}'의 최대 비디오 수({settings.MAX_VIDEOS_PER_ARTIST})에 도달했습니다.")
                        break
                    
                    # 팬캠 여부 확인
                    if not video_data.get("is_fancam", False):
                        continue
                    
                    # 비디오 모델 생성
                    video_model = self.youtube_service.create_video_model(video_data)
                    
                    # 아티스트 ID 설정
                    video_model.artist_id = artist.id
                    logger.info(f"비디오에 아티스트 ID 할당: {artist.name}({artist.id}) -> {video_model.title}")
                    
                    # Supabase에 저장
                    saved_video = await self.supabase_service.create_video(video_model)
                    
                    if saved_video:
                        saved_count += 1
                
                # API 호출 간 간격 두기
                await asyncio.sleep(0.5)
            
            logger.info(f"아티스트 '{artist.name}'에 대해 {saved_count}개 비디오 저장됨")
            return saved_count
            
        except Exception as e:
            logger.error(f"아티스트 '{artist.name}' 크롤링 중 오류 발생: {e}")
            return 0

    async def crawl_artist(self, artist_id: str) -> Dict:
        """
        특정 아티스트의 팬캠 수동 크롤링
        
        Args:
            artist_id: 아티스트 ID
            
        Returns:
            크롤링 결과 정보
        """
        if f"crawl_artist_{artist_id}" in self.running_jobs:
            return {
                "success": False,
                "message": f"이미 아티스트 ID {artist_id}의 크롤링이 실행 중입니다.",
            }
        
        self.running_jobs.add(f"crawl_artist_{artist_id}")
        
        try:
            # 아티스트 정보 조회
            artists = await self.supabase_service.get_artists(limit=1)  # 임시 구현
            
            if not artists:
                return {
                    "success": False,
                    "message": f"아티스트 ID {artist_id}를 찾을 수 없습니다.",
                }
            
            artist = artists[0]  # 임시 구현
            
            # 크롤링 실행
            saved_count = await self._crawl_artist_fancams(artist)
            
            # 비디오 수 업데이트
            await self.supabase_service.update_video_counts()
            
            return {
                "success": True,
                "message": f"아티스트 '{artist.name}'에 대해 {saved_count}개 비디오 저장됨",
                "artist": artist.model_dump(),
                "saved_videos_count": saved_count,
                "quota_used": self.youtube_service.quota_used,
            }
            
        except Exception as e:
            logger.error(f"아티스트 ID {artist_id} 크롤링 중 오류 발생: {e}")
            return {
                "success": False,
                "message": f"크롤링 중 오류 발생: {str(e)}",
            }
        
        finally:
            self.running_jobs.remove(f"crawl_artist_{artist_id}")
            # 쿼터 사용량 초기화하지 않음 (누적 사용량 모니터링 위해)


# 싱글톤 인스턴스
crawler_service = CrawlerService()


async def get_crawler_service() -> CrawlerService:
    """크롤러 서비스 인스턴스 반환"""
    if not crawler_service.is_initialized:
        await crawler_service.initialize()
    return crawler_service 