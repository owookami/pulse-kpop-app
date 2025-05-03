from typing import List, Optional, Set

from pydantic import BaseModel, Field, HttpUrl

from app.models.common import TimeStampedModel


class ArtistBase(BaseModel):
    """아티스트 기본 모델"""
    name: str
    alternate_names: Optional[List[str]] = Field(default_factory=list)
    group_name: Optional[str] = None
    is_group: bool = False
    active: bool = True
    search_keywords: Optional[List[str]] = Field(default_factory=list)


class ArtistCreate(ArtistBase):
    """아티스트 생성 모델"""
    youtube_channels: Optional[List[str]] = Field(default_factory=list)
    thumbnail_url: Optional[HttpUrl] = None


class ArtistUpdate(BaseModel):
    """아티스트 업데이트 모델"""
    name: Optional[str] = None
    alternate_names: Optional[List[str]] = None
    group_name: Optional[str] = None
    is_group: Optional[bool] = None
    active: Optional[bool] = None
    search_keywords: Optional[List[str]] = None
    youtube_channels: Optional[List[str]] = None
    thumbnail_url: Optional[HttpUrl] = None


class ArtistInDB(ArtistBase, TimeStampedModel):
    """데이터베이스 아티스트 모델"""
    id: str
    youtube_channels: List[str] = Field(default_factory=list)
    thumbnail_url: Optional[HttpUrl] = None
    video_count: int = 0


class ArtistResponse(ArtistInDB):
    """아티스트 응답 모델"""
    pass


class GroupWithMembers(ArtistResponse):
    """그룹과 멤버 정보를 포함한 응답 모델"""
    members: List[ArtistResponse] = Field(default_factory=list) 