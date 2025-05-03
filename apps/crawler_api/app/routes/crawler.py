from typing import Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from loguru import logger

from app.config import Settings, get_settings
from app.services.crawler_service import CrawlerService, get_crawler_service

router = APIRouter()


@router.post("/start")
async def start_crawler(
    settings: Settings = Depends(get_settings),
    crawler_service: CrawlerService = Depends(get_crawler_service),
):
    """
    크롤러 작업 시작
    
    모든 활성 아티스트에 대한 팬캠 크롤링 작업을 시작합니다.
    """
    try:
        # 이미 실행 중인지 확인
        if "crawl_all_artists" in crawler_service.running_jobs:
            return {
                "success": False,
                "message": "이미 크롤링이 실행 중입니다.",
            }
        
        # 비동기 작업 실행
        crawler_service.scheduler.add_job(
            crawler_service.crawl_all_artists,
            id="manual_crawl_all_artists",
            replace_existing=True,
            next_run_time=None,  # 즉시 실행
        )
        
        return {
            "success": True,
            "message": "크롤링 작업이 시작되었습니다.",
        }
    
    except Exception as e:
        logger.error(f"크롤링 시작 실패: {e}")
        raise HTTPException(status_code=500, detail=f"크롤링 시작 중 오류 발생: {str(e)}")


@router.post("/artists/{artist_id}")
async def crawl_artist(
    artist_id: str,
    settings: Settings = Depends(get_settings),
    crawler_service: CrawlerService = Depends(get_crawler_service),
):
    """
    특정 아티스트 크롤링
    
    특정 아티스트의 팬캠 크롤링 작업을 실행합니다.
    """
    try:
        # 비동기 크롤링 작업 실행
        result = await crawler_service.crawl_artist(artist_id)
        return result
    
    except Exception as e:
        logger.error(f"아티스트 크롤링 실패: {e}")
        raise HTTPException(status_code=500, detail=f"아티스트 크롤링 중 오류 발생: {str(e)}")


@router.get("/status")
async def get_crawler_status(
    settings: Settings = Depends(get_settings),
    crawler_service: CrawlerService = Depends(get_crawler_service),
):
    """
    크롤러 상태 조회
    
    현재 크롤러 서비스의 상태를 반환합니다.
    """
    try:
        # 스케줄러 상태 및 실행 중인 작업 목록
        scheduled_jobs = []
        if crawler_service.scheduler:
            for job in crawler_service.scheduler.get_jobs():
                scheduled_jobs.append({
                    "id": job.id,
                    "next_run_time": job.next_run_time.isoformat() if job.next_run_time else None,
                    "trigger": str(job.trigger),
                })
        
        return {
            "success": True,
            "is_initialized": crawler_service.is_initialized,
            "scheduler_running": crawler_service.scheduler.running if crawler_service.scheduler else False,
            "running_jobs": list(crawler_service.running_jobs),
            "scheduled_jobs": scheduled_jobs,
            "quota_used": crawler_service.youtube_service.quota_used,
            "quota_limit": settings.YOUTUBE_API_QUOTA_LIMIT,
            "crawl_interval_minutes": settings.CRAWL_INTERVAL_MINUTES,
        }
    
    except Exception as e:
        logger.error(f"크롤러 상태 조회 실패: {e}")
        raise HTTPException(status_code=500, detail=f"크롤러 상태 조회 중 오류 발생: {str(e)}")


@router.post("/stop")
async def stop_crawler(
    settings: Settings = Depends(get_settings),
    crawler_service: CrawlerService = Depends(get_crawler_service),
):
    """
    크롤러 작업 중지
    
    현재 실행 중인 크롤링 작업을 중지하고 스케줄러를 일시 중지합니다.
    """
    try:
        # 스케줄러 일시 중지
        if crawler_service.scheduler and crawler_service.scheduler.running:
            crawler_service.scheduler.pause()
        
        # 실행 중인 작업 목록 초기화
        # (실제로는 실행 중인 작업을 중지할 방법은 없지만, 새 작업이 시작되는 것을 막을 수 있음)
        crawler_service.running_jobs.clear()
        
        return {
            "success": True,
            "message": "크롤러가 일시 중지되었습니다. 현재 실행 중인 작업은 완료될 때까지 계속됩니다.",
        }
    
    except Exception as e:
        logger.error(f"크롤러 중지 실패: {e}")
        raise HTTPException(status_code=500, detail=f"크롤러 중지 중 오류 발생: {str(e)}")


@router.post("/resume")
async def resume_crawler(
    settings: Settings = Depends(get_settings),
    crawler_service: CrawlerService = Depends(get_crawler_service),
):
    """
    크롤러 작업 재개
    
    일시 중지된 스케줄러를 재개합니다.
    """
    try:
        # 스케줄러 재개
        if crawler_service.scheduler and not crawler_service.scheduler.running:
            crawler_service.scheduler.resume()
        
        return {
            "success": True,
            "message": "크롤러가 재개되었습니다.",
        }
    
    except Exception as e:
        logger.error(f"크롤러 재개 실패: {e}")
        raise HTTPException(status_code=500, detail=f"크롤러 재개 중 오류 발생: {str(e)}") 