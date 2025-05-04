import sys
import logging
from pprint import pformat

from loguru import logger

from app.config import settings


class InterceptHandler(logging.Handler):
    """표준 로깅을 Loguru로 연결하는 핸들러"""

    def emit(self, record):
        # Loguru로 로그 전달
        try:
            level = logger.level(record.levelname).name
        except ValueError:
            level = record.levelno

        # 호출자 찾기
        frame, depth = logging.currentframe(), 2
        while frame.f_code.co_filename == logging.__file__:
            frame = frame.f_back
            depth += 1

        logger.opt(depth=depth, exception=record.exc_info).log(level, record.getMessage())


def setup_logging():
    """로깅 설정"""
    # 로그 레벨 설정
    log_level = settings.LOG_LEVEL.upper()
    
    # 모든 로그 핸들러 제거
    logger.remove()
    
    # 새 로그 핸들러 추가
    log_format = (
        "<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | "
        "<level>{level: <8}</level> | "
        "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - "
        "<level>{message}</level>"
    )
    
    # 콘솔 로그 설정
    logger.configure(
        handlers=[
            {"sink": sys.stdout, "format": log_format, "level": log_level},
        ]
    )
    
    # 표준 로깅을 Loguru로 라우팅
    logging.basicConfig(handlers=[InterceptHandler()], level=0)
    
    # 써드파티 라이브러리 로그 레벨 조정
    for logger_name in ["uvicorn", "uvicorn.error", "fastapi"]:
        logging.getLogger(logger_name).setLevel(logging.INFO)
    
    # 디버그 모드일 때 추가 로깅
    if settings.DEBUG:
        logger.debug(f"Settings loaded: \n{pformat(dict(settings))}")
    
    logger.info("Logging system initialized") 