from contextlib import asynccontextmanager
from typing import Callable

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from app.config import settings
from app.routes import api_router
from app.utils.logging import setup_logging


@asynccontextmanager
async def lifespan(app: FastAPI):
    """애플리케이션 라이프사이클 관리"""
    # 시작 시 실행
    setup_logging()
    logger.info(f"Starting {settings.APP_NAME} v{settings.APP_VERSION} in {settings.ENVIRONMENT} mode")
    
    # ✨ 여기에 추가 시작 로직 추가 (DB 연결, 스케줄러 등)
    
    yield  # 애플리케이션 실행
    
    # 종료 시 실행
    logger.info(f"Shutting down {settings.APP_NAME}")
    
    # ✨ 여기에 정리 로직 추가 (연결 종료 등)


def create_app() -> FastAPI:
    """애플리케이션 인스턴스 생성"""
    app = FastAPI(
        title=settings.APP_NAME,
        description="K-POP 팬캠 크롤러 API",
        version=settings.APP_VERSION,
        lifespan=lifespan,
        docs_url="/docs" if settings.DEBUG else None,
        redoc_url="/redoc" if settings.DEBUG else None,
    )
    
    # CORS 미들웨어 설정
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # 프로덕션에서는 특정 도메인으로 제한
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # 요청/응답 로깅 미들웨어
    @app.middleware("http")
    async def log_requests(request: Request, call_next: Callable) -> Response:
        """요청 및 응답 로깅"""
        logger.info(f"{request.method} {request.url.path}")
        response = await call_next(request)
        logger.info(f"Status: {response.status_code}")
        return response
    
    # 라우터 등록
    app.include_router(api_router, prefix="/api/v1")
    
    return app


app = create_app() 