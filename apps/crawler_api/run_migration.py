#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Pulse 데이터베이스 마이그레이션 스크립트
videos 테이블에 유니크 제약 조건을 추가하여 중복 비디오를 방지합니다.
"""

import os
import sys
import logging
import requests
from dotenv import load_dotenv

# 로깅 설정
os.makedirs('logs', exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/run_migration.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("pulse-migration")

# 환경 변수 로드
load_dotenv()

def run_migration():
    """
    데이터베이스 마이그레이션 실행
    """
    # Supabase URL과 서비스 키 가져오기
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY")  # service_role 키 사용
    
    if not supabase_url or not supabase_key:
        logger.error("SUPABASE_URL 또는 SUPABASE_SERVICE_KEY가 설정되지 않았습니다.")
        sys.exit(1)
    
    logger.info(f"Supabase URL: {supabase_url}")
    
    # Supabase SQL API 엔드포인트
    sql_endpoint = f"{supabase_url}/rest/v1/rpc/execute"
    
    # API 요청 헤더
    headers = {
        "apikey": supabase_key,
        "Authorization": f"Bearer {supabase_key}",
        "Content-Type": "application/json",
        "Prefer": "return=minimal"
    }
    
    # 마이그레이션 쿼리 - platform과 platform_id 조합에 유니크 제약 조건 추가
    queries = [
        # 중복 데이터 확인 및 카운트
        """
        SELECT platform, platform_id, COUNT(*) 
        FROM videos 
        GROUP BY platform, platform_id 
        HAVING COUNT(*) > 1
        """,
        
        # 중복 제거 (동일한 platform_id를 가진 레코드 중 첫 번째를 제외한 나머지 삭제)
        """
        DELETE FROM videos
        WHERE id IN (
            SELECT id FROM (
                SELECT id, platform, platform_id,
                ROW_NUMBER() OVER(PARTITION BY platform, platform_id ORDER BY created_at ASC) AS row_num
                FROM videos
            ) t
            WHERE t.row_num > 1
        )
        """,
        
        # 유니크 제약 조건 추가
        """
        ALTER TABLE videos
        ADD CONSTRAINT videos_platform_platform_id_unique UNIQUE (platform, platform_id)
        """
    ]
    
    # 각 쿼리 실행
    for i, query in enumerate(queries):
        logger.info(f"마이그레이션 쿼리 {i+1}/{len(queries)} 실행 중...")
        
        try:
            # 쿼리 실행 요청
            response = requests.post(
                sql_endpoint,
                headers=headers,
                json={"query": query}
            )
            
            # 응답 확인
            if response.status_code in [200, 201, 204]:
                logger.info(f"마이그레이션 쿼리 {i+1} 성공!")
                
                # 중복 데이터 확인 쿼리인 경우 결과 로깅
                if i == 0 and response.text:
                    duplicates = response.json()
                    logger.info(f"중복 비디오 발견: {len(duplicates)}개")
                    for dup in duplicates[:10]:  # 처음 10개만 로깅
                        logger.info(f"  - {dup}")
                    if len(duplicates) > 10:
                        logger.info(f"  ... 그 외 {len(duplicates)-10}개 더 있음")
            else:
                logger.error(f"마이그레이션 쿼리 {i+1} 실패: {response.status_code} - {response.text}")
        except Exception as e:
            logger.error(f"마이그레이션 쿼리 {i+1} 실행 중 오류 발생: {str(e)}")
    
    logger.info("마이그레이션이 완료되었습니다.")

if __name__ == "__main__":
    logger.info("데이터베이스 마이그레이션 시작")
    run_migration()
    logger.info("데이터베이스 마이그레이션 완료") 