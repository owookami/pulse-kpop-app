from fastapi import APIRouter

from app.routes import health, videos, artists, crawler

# 메인 API 라우터
api_router = APIRouter()

# 헬스 체크 라우터 포함
api_router.include_router(health.router, tags=["health"])

# 비디오 라우터 포함
api_router.include_router(
    videos.router,
    prefix="/videos",
    tags=["videos"],
)

# 아티스트 라우터 포함
api_router.include_router(
    artists.router,
    prefix="/artists",
    tags=["artists"],
)

# 크롤러 라우터 포함
api_router.include_router(
    crawler.router,
    prefix="/crawler",
    tags=["crawler"],
) 