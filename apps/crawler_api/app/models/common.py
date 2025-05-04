from datetime import datetime
from typing import Any, Dict, Generic, List, Optional, TypeVar, Union

from pydantic import BaseModel, Field


T = TypeVar('T')


class BaseResponseModel(BaseModel):
    """API 응답 기본 모델"""
    success: bool = True
    message: Optional[str] = None


class PaginatedResponseModel(BaseResponseModel, Generic[T]):
    """페이지네이션 응답 모델"""
    data: List[T]
    page: int
    page_size: int
    total: int
    has_more: bool


class ErrorResponse(BaseResponseModel):
    """에러 응답 모델"""
    success: bool = False
    error_code: str
    message: str
    details: Optional[Dict[str, Any]] = None


class TimeStampedModel(BaseModel):
    """타임스탬프 모델 믹스인"""
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None 