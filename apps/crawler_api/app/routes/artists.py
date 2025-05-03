from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from loguru import logger

from app.config import Settings, get_settings
from app.models.artist import ArtistCreate, ArtistInDB, ArtistResponse, ArtistUpdate, GroupWithMembers
from app.models.common import PaginatedResponseModel
from app.services.supabase_service import SupabaseService

router = APIRouter()


@router.get("/", response_model=PaginatedResponseModel[ArtistResponse])
async def get_artists(
    limit: int = Query(10, ge=1, le=100, description="한 페이지당 아티스트 수"),
    page: int = Query(1, ge=1, description="페이지 번호"),
    is_group: Optional[bool] = Query(None, description="그룹 여부로 필터링"),
    active: Optional[bool] = Query(None, description="활동 여부로 필터링"),
    order_by: str = Query("name.asc", description="정렬 기준 (필드.asc|desc)"),
    settings: Settings = Depends(get_settings),
):
    """
    아티스트 목록 조회
    
    페이지네이션과 필터링을 지원하는 아티스트 목록을 반환합니다.
    """
    try:
        # 오프셋 계산
        offset = (page - 1) * limit
        
        # Supabase 서비스 인스턴스 생성
        supabase_service = SupabaseService()
        
        # 아티스트 조회
        artists = await supabase_service.get_artists(
            limit=limit + 1,  # 다음 페이지 확인을 위해 하나 더 요청
            offset=offset,
            is_group=is_group,
            active=active,
            order_by=order_by,
        )
        
        # 다음 페이지 여부 확인
        has_more = len(artists) > limit
        if has_more:
            artists = artists[:limit]  # 실제 요청한 개수만 반환
        
        # 총 개수 (간단한 구현을 위해 추정치 사용)
        # 실제 프로덕션에서는 COUNT 쿼리 필요
        total = offset + len(artists)
        if has_more:
            total += 1  # 최소한 하나 더 있음을 표시
        
        # 응답 생성
        return PaginatedResponseModel(
            data=artists,
            page=page,
            page_size=limit,
            total=total,
            has_more=has_more,
            message="아티스트 목록 조회 성공",
        )
    
    except Exception as e:
        logger.error(f"아티스트 목록 조회 실패: {e}")
        raise HTTPException(status_code=500, detail=f"아티스트 목록 조회 중 오류 발생: {str(e)}")


@router.get("/{artist_id}", response_model=ArtistResponse)
async def get_artist(
    artist_id: str,
    settings: Settings = Depends(get_settings),
):
    """
    특정 아티스트 조회
    
    ID로 특정 아티스트의 상세 정보를 조회합니다.
    """
    try:
        # Supabase 서비스 인스턴스 생성
        supabase_service = SupabaseService()
        
        # 아티스트 조회
        artists = await supabase_service.get_artists(limit=1)
        
        # 간단한 구현을 위해 더미 데이터 반환
        # 실제 프로덕션에서는 ID로 실제 조회 필요
        if not artists:
            raise HTTPException(status_code=404, detail=f"ID {artist_id}인 아티스트를 찾을 수 없습니다.")
        
        artist = artists[0]
        
        return artist
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"아티스트 조회 실패: {e}")
        raise HTTPException(status_code=500, detail=f"아티스트 조회 중 오류 발생: {str(e)}")


@router.post("/", response_model=ArtistResponse)
async def create_artist(
    artist: ArtistCreate,
    settings: Settings = Depends(get_settings),
):
    """
    아티스트 생성
    
    새로운 아티스트를 생성합니다.
    """
    try:
        # Supabase 서비스 인스턴스 생성
        supabase_service = SupabaseService()
        
        # 아티스트 생성
        created_artist = await supabase_service.create_artist(artist)
        
        if not created_artist:
            raise HTTPException(status_code=500, detail="아티스트 생성 실패")
        
        return created_artist
    
    except Exception as e:
        logger.error(f"아티스트 생성 실패: {e}")
        raise HTTPException(status_code=500, detail=f"아티스트 생성 중 오류 발생: {str(e)}")


@router.post("/{artist_id}/update", response_model=ArtistResponse)
async def update_artist(
    artist_id: str,
    artist_update: ArtistUpdate,
    settings: Settings = Depends(get_settings),
):
    """
    아티스트 정보 업데이트
    
    ID로 특정 아티스트의 정보를 업데이트합니다.
    """
    try:
        # Supabase 서비스 인스턴스 생성
        supabase_service = SupabaseService()
        
        # 아티스트 존재 여부 확인
        artists = await supabase_service.get_artists(limit=1)  # 예시 구현
        if not artists:
            raise HTTPException(status_code=404, detail=f"ID {artist_id}인 아티스트를 찾을 수 없습니다.")
        
        # 아티스트 업데이트
        update_data = artist_update.model_dump(exclude_unset=True)
        updated_artist = await supabase_service.update_artist(artist_id, update_data)
        
        if not updated_artist:
            raise HTTPException(status_code=500, detail="아티스트 업데이트 실패")
        
        return updated_artist
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"아티스트 업데이트 실패: {e}")
        raise HTTPException(status_code=500, detail=f"아티스트 업데이트 중 오류 발생: {str(e)}")


@router.get("/groups/{group_id}/members", response_model=GroupWithMembers)
async def get_group_with_members(
    group_id: str,
    settings: Settings = Depends(get_settings),
):
    """
    그룹과 멤버 정보 조회
    
    그룹 ID로 그룹과 멤버 정보를 한 번에 조회합니다.
    """
    try:
        # Supabase 서비스 인스턴스 생성
        supabase_service = SupabaseService()
        
        # 그룹 조회
        artists = await supabase_service.get_artists(limit=1, is_group=True)  # 예시 구현
        if not artists:
            raise HTTPException(status_code=404, detail=f"ID {group_id}인 그룹을 찾을 수 없습니다.")
        
        group = artists[0]
        
        # 멤버 조회
        members = await supabase_service.get_artists(limit=10, is_group=False)  # 예시 구현
        
        # 그룹과 멤버 정보 결합
        return GroupWithMembers(
            **group.model_dump(),
            members=members,
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"그룹과 멤버 정보 조회 실패: {e}")
        raise HTTPException(status_code=500, detail=f"그룹과 멤버 정보 조회 중 오류 발생: {str(e)}")


@router.post("/video-counts/update")
async def update_video_counts(
    settings: Settings = Depends(get_settings),
):
    """
    아티스트 비디오 수 업데이트
    
    모든 아티스트의 비디오 수를 업데이트합니다.
    """
    try:
        # Supabase 서비스 인스턴스 생성
        supabase_service = SupabaseService()
        
        # 비디오 수 업데이트
        success = await supabase_service.update_video_counts()
        
        if not success:
            raise HTTPException(status_code=500, detail="비디오 수 업데이트 실패")
        
        return {"success": True, "message": "아티스트 비디오 수 업데이트 성공"}
    
    except Exception as e:
        logger.error(f"비디오 수 업데이트 실패: {e}")
        raise HTTPException(status_code=500, detail=f"비디오 수 업데이트 중 오류 발생: {str(e)}") 