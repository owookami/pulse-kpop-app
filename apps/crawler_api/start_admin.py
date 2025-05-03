#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Pulse 크롤러 웹 어드민 시작 스크립트
관리자 웹 인터페이스와 API 서버를 실행합니다.
"""

import os
import sys
import logging
import argparse
import webbrowser
import threading
import time
import uvicorn
from dotenv import load_dotenv

# 로깅 설정
os.makedirs('logs', exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/admin.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("admin-starter")

# 환경 변수 로드
load_dotenv()

def open_browser(port):
    """지정된 포트로 브라우저 열기"""
    url = f"http://localhost:{port}"
    # 서버가 시작될 시간 주기
    time.sleep(2)
    webbrowser.open(url)
    logger.info(f"브라우저에서 {url} 열기")

def main():
    # 명령줄 인수 파싱
    parser = argparse.ArgumentParser(description="Pulse 크롤러 웹 어드민 시작")
    parser.add_argument("--port", type=int, default=8000, help="웹 서버 포트 (기본값: 8000)")
    parser.add_argument("--host", type=str, default="0.0.0.0", help="웹 서버 호스트 (기본값: 0.0.0.0)")
    parser.add_argument("--no-browser", action="store_true", help="브라우저 자동 실행 안 함")
    args = parser.parse_args()

    # 필요한 디렉토리 확인
    os.makedirs('jobs', exist_ok=True)
    os.makedirs('output', exist_ok=True)

    # 브라우저 열기
    if not args.no_browser:
        threading.Thread(target=open_browser, args=(args.port,), daemon=True).start()

    # FastAPI 서버 실행
    logger.info(f"Pulse 크롤러 웹 어드민 서버를 http://{args.host}:{args.port}에서 시작합니다...")
    uvicorn.run(
        "admin_api:app",
        host=args.host,
        port=args.port,
        reload=True
    )

if __name__ == "__main__":
    main() 