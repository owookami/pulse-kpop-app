from datetime import datetime
from typing import Optional, List

from pydantic import BaseModel, Field, HttpUrl

from app.models.common import TimeStampedModel


class VideoBase(BaseModel):
    """비디오 기본 모델"""
    title: str
    youtube_id: str
    channel_id: str
    channel_title: str
    published_at: datetime
    description: Optional[str] = None
    thumbnail_url: Optional[HttpUrl] = None
    view_count: Optional[int] = 0
    like_count: Optional[int] = 0
    comment_count: Optional[int] = 0
    duration: Optional[str] = None
    tags: Optional[List[str]] = Field(default_factory=list)


class VideoCreate(VideoBase):
    """비디오 생성 모델"""
    artist_id: Optional[str] = None
    artist_name: Optional[str] = None
    event_name: Optional[str] = None
    quality_score: Optional[float] = 0.0
    is_fancam: bool = True


class VideoUpdate(BaseModel):
    """비디오 업데이트 모델"""
    title: Optional[str] = None
    description: Optional[str] = None
    thumbnail_url: Optional[HttpUrl] = None
    view_count: Optional[int] = None
    like_count: Optional[int] = None
    comment_count: Optional[int] = None
    artist_id: Optional[str] = None
    artist_name: Optional[str] = None
    event_name: Optional[str] = None
    quality_score: Optional[float] = None
    is_fancam: Optional[bool] = None
    tags: Optional[List[str]] = None


class VideoInDB(VideoBase, TimeStampedModel):
    """데이터베이스 비디오 모델"""
    id: str
    artist_id: Optional[str] = None
    artist_name: Optional[str] = None
    event_name: Optional[str] = None
    quality_score: float = 0.0
    is_fancam: bool = True


class VideoResponse(VideoInDB):
    """비디오 응답 모델"""
    pass 