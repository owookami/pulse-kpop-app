from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from loguru import logger

from app.config import Settings, get_settings
from app.models.common import PaginatedResponseModel
from app.models.video import VideoCreate, VideoInDB, VideoResponse, VideoUpdate
from app.services.supabase_service import SupabaseService
from app.services.youtube_service import YouTubeAPIService

router = APIRouter()


@router.get("/", response_model=PaginatedResponseModel[VideoResponse])
async def get_videos(
    limit: int = Query(10, ge=1, le=100, description="한 페이지당 비디오 수"),
    page: int = Query(1, ge=1, description="페이지 번호"),
    artist_id: Optional[str] = Query(None, description="아티스트 ID로 필터링"),
    is_fancam: Optional[bool] = Query(None, description="팬캠 여부로 필터링"),
    order_by: str = Query("created_at.desc", description="정렬 기준 (필드.asc|desc)"),
    settings: Settings = Depends(get_settings),
):
    """
    비디오 목록 조회
    
    페이지네이션과 필터링을 지원하는 비디오 목록을 반환합니다.
    """
    try:
        # 오프셋 계산
        offset = (page - 1) * limit
        
        # Supabase 서비스 인스턴스 생성
        supabase_service = SupabaseService()
        
        # 비디오 조회
        videos = await supabase_service.get_videos(
            limit=limit + 1,  # 다음 페이지 확인을 위해 하나 더 요청
            offset=offset,
            artist_id=artist_id,
            is_fancam=is_fancam,
            order_by=order_by,
        )
        
        # 다음 페이지 여부 확인
        has_more = len(videos) > limit
        if has_more:
            videos = videos[:limit]  # 실제 요청한 개수만 반환
        
        # 총 개수 (간단한 구현을 위해 추정치 사용)
        # 실제 프로덕션에서는 COUNT 쿼리 필요
        total = offset + len(videos)
        if has_more:
            total += 1  # 최소한 하나 더 있음을 표시
        
        # 응답 생성
        return PaginatedResponseModel(
            data=videos,
            page=page,
            page_size=limit,
            total=total,
            has_more=has_more,
            message="비디오 목록 조회 성공",
        )
    
    except Exception as e:
        logger.error(f"비디오 목록 조회 실패: {e}")
        raise HTTPException(status_code=500, detail=f"비디오 목록 조회 중 오류 발생: {str(e)}")


@router.get("/{youtube_id}", response_model=VideoResponse)
async def get_video(
    youtube_id: str,
    settings: Settings = Depends(get_settings),
):
    """
    특정 비디오 조회
    
    YouTube ID로 특정 비디오의 상세 정보를 조회합니다.
    """
    try:
        # Supabase 서비스 인스턴스 생성
        supabase_service = SupabaseService()
        
        # 비디오 조회
        video = await supabase_service.get_video_by_youtube_id(youtube_id)
        
        if not video:
            raise HTTPException(status_code=404, detail=f"ID {youtube_id}인 비디오를 찾을 수 없습니다.")
        
        return video
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"비디오 조회 실패: {e}")
        raise HTTPException(status_code=500, detail=f"비디오 조회 중 오류 발생: {str(e)}")


@router.post("/search", response_model=PaginatedResponseModel[VideoResponse])
async def search_videos(
    query: str = Query(..., description="검색 쿼리"),
    max_results: int = Query(10, ge=1, le=50, description="최대 결과 수"),
    published_after: Optional[datetime] = Query(None, description="특정 날짜 이후 게시된 비디오만 검색"),
    page_token: Optional[str] = Query(None, description="다음 페이지 토큰"),
    settings: Settings = Depends(get_settings),
):
    """
    YouTube 비디오 검색
    
    YouTube API를 사용하여 비디오를 검색하고 결과를 반환합니다.
    """
    try:
        # YouTube API 서비스 인스턴스 생성
        youtube_service = YouTubeAPIService()
        
        # 비디오 검색
        videos, next_page_token = await youtube_service.search_videos(
            query=query,
            max_results=max_results,
            published_after=published_after,
            page_token=page_token,
        )
        
        # VideoResponse 모델로 변환
        video_responses = []
        for video_data in videos:
            video_model = youtube_service.create_video_model(video_data)
            
            # Supabase에 저장 (중복 체크 포함)
            supabase_service = SupabaseService()
            saved_video = await supabase_service.create_video(video_model)
            
            if saved_video:
                video_responses.append(saved_video)
        
        # 응답 생성
        return PaginatedResponseModel(
            data=video_responses,
            page=1,  # YouTube API는 토큰 기반 페이지네이션 사용
            page_size=max_results,
            total=len(video_responses),
            has_more=bool(next_page_token),
            message="비디오 검색 성공",
        )
    
    except Exception as e:
        logger.error(f"비디오 검색 실패: {e}")
        raise HTTPException(status_code=500, detail=f"비디오 검색 중 오류 발생: {str(e)}")


@router.post("/{youtube_id}/update", response_model=VideoResponse)
async def update_video_info(
    youtube_id: str,
    video_update: VideoUpdate,
    settings: Settings = Depends(get_settings),
):
    """
    비디오 정보 업데이트
    
    YouTube ID로 특정 비디오의 정보를 업데이트합니다.
    """
    try:
        # Supabase 서비스 인스턴스 생성
        supabase_service = SupabaseService()
        
        # 비디오 존재 여부 확인
        existing_video = await supabase_service.get_video_by_youtube_id(youtube_id)
        if not existing_video:
            raise HTTPException(status_code=404, detail=f"ID {youtube_id}인 비디오를 찾을 수 없습니다.")
        
        # 비디오 업데이트
        update_data = video_update.model_dump(exclude_unset=True)
        updated_video = await supabase_service.update_video(youtube_id, update_data)
        
        if not updated_video:
            raise HTTPException(status_code=500, detail="비디오 업데이트 실패")
        
        return updated_video
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"비디오 업데이트 실패: {e}")
        raise HTTPException(status_code=500, detail=f"비디오 업데이트 중 오류 발생: {str(e)}")


@router.delete("/{youtube_id}")
async def delete_video(
    youtube_id: str,
    settings: Settings = Depends(get_settings),
):
    """
    비디오 삭제
    
    YouTube ID로 특정 비디오를 삭제합니다.
    """
    try:
        # Supabase 서비스 인스턴스 생성
        supabase_service = SupabaseService()
        
        # 비디오 존재 여부 확인
        existing_video = await supabase_service.get_video_by_youtube_id(youtube_id)
        if not existing_video:
            raise HTTPException(status_code=404, detail=f"ID {youtube_id}인 비디오를 찾을 수 없습니다.")
        
        # 비디오 삭제
        success = await supabase_service.delete_video(youtube_id)
        
        if not success:
            raise HTTPException(status_code=500, detail="비디오 삭제 실패")
        
        return {"success": True, "message": f"ID {youtube_id}인 비디오가 삭제되었습니다."}
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"비디오 삭제 실패: {e}")
        raise HTTPException(status_code=500, detail=f"비디오 삭제 중 오류 발생: {str(e)}") 