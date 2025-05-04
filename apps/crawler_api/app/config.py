import os
from functools import lru_cache
from typing import Optional

from pydantic import field_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """애플리케이션 설정"""

    # 앱 설정
    APP_NAME: str = "pulse-crawler-api"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "production"
    LOG_LEVEL: str = "INFO"

    # YouTube API 설정
    YOUTUBE_API_KEY: str
    YOUTUBE_API_QUOTA_LIMIT: int = 10000
    YOUTUBE_API_MAX_RESULTS: int = 50

    # Supabase 설정
    SUPABASE_URL: str
    SUPABASE_KEY: str
    SUPABASE_SERVICE_KEY: str

    # 크롤링 설정
    CRAWL_INTERVAL_MINUTES: int = 60
    CRAWL_BATCH_SIZE: int = 100
    MAX_VIDEOS_PER_ARTIST: int = 50

    @field_validator("ENVIRONMENT")
    def validate_environment(cls, v: str) -> str:
        """환경 타입 검증"""
        allowed_environments = {"development", "staging", "production"}
        if v.lower() not in allowed_environments:
            raise ValueError(f"ENVIRONMENT must be one of {allowed_environments}")
        return v.lower()
    
    class Config:
        """환경 변수 설정"""
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """설정 싱글톤 인스턴스 반환"""
    return Settings()


# 글로벌 설정 인스턴스
settings = get_settings() 