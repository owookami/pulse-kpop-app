#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Pulse 크롤러 실행 스크립트
K-POP 팬캠 데이터를 수집하고 데이터베이스에 저장합니다.
"""

import os
import sys
import logging
import argparse
import datetime
import json
import uuid
import time
import concurrent.futures
from pathlib import Path
from typing import Dict, Any, List, Optional, Union, Tuple

# 필요한 모듈 임포트
from dotenv import load_dotenv
from basic_crawler import YouTubeCrawler
from postgrest.exceptions import APIError as PostgrestAPIError

# 로깅 설정
os.makedirs('logs', exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/run_crawler.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("pulse-crawler")

# 환경 변수 로드
load_dotenv()

# 기본 설정
DEFAULT_OUTPUT_DIR = Path("output")
MAX_RETRIES = 3
RETRY_DELAY = 2  # 초

# 아티스트 목록 (실제 애플리케이션에서는 데이터베이스에서 가져옴)
DEFAULT_ARTISTS = [
    {"id": "1", "name": "지수", "groupName": "블랙핑크"},
    {"id": "2", "name": "제니", "groupName": "블랙핑크"},
    {"id": "3", "name": "로제", "groupName": "블랙핑크"},
    {"id": "4", "name": "리사", "groupName": "블랙핑크"},
    {"id": "5", "name": "RM", "groupName": "방탄소년단"},
    {"id": "6", "name": "진", "groupName": "방탄소년단"},
    {"id": "7", "name": "슈가", "groupName": "방탄소년단"},
    {"id": "8", "name": "제이홉", "groupName": "방탄소년단"},
    {"id": "9", "name": "지민", "groupName": "방탄소년단"},
    {"id": "10", "name": "뷔", "groupName": "방탄소년단"},
    {"id": "11", "name": "정국", "groupName": "방탄소년단"},
]

# 그룹 목록 (실제 애플리케이션에서는 데이터베이스에서 가져옴)
DEFAULT_GROUPS = [
    {"id": "1", "name": "블랙핑크"},
    {"id": "2", "name": "방탄소년단"},
    {"id": "3", "name": "아이브"},
    {"id": "4", "name": "뉴진스"},
    {"id": "5", "name": "에스파"},
]

def get_youtube_api_key() -> str:
    """
    YouTube API 키 가져오기
    
    Returns:
        API 키
    """
    api_key = os.getenv("YOUTUBE_API_KEY")
    logger.info(f"[크롤링 프로세스] YouTube API 키 확인 중...")
    
    if not api_key:
        logger.error("[크롤링 프로세스] YouTube API 키가 설정되지 않았습니다. .env 파일에 YOUTUBE_API_KEY를 설정하세요.")
        sys.exit(1)
    
    # API 키 일부를 로그에 표시 (보안상 전체 키는 표시하지 않음)
    if len(api_key) > 10:
        key_preview = api_key[:5] + "..." + api_key[-5:]
        logger.info(f"[크롤링 프로세스] YouTube API 키 확인됨 (미리보기: {key_preview})")
    else:
        logger.info("[크롤링 프로세스] YouTube API 키 확인됨")
    
    return api_key

def parse_args() -> argparse.Namespace:
    """
    명령줄 인수 파싱
    
    Returns:
        파싱된 인수
    """
    parser = argparse.ArgumentParser(description='Pulse 팬캠 크롤러')
    
    # 기본 검색 옵션
    parser.add_argument('--artist', type=str, help='검색할 아티스트 이름')
    parser.add_argument('--group', type=str, help='검색할 그룹 이름')
    parser.add_argument('--event', type=str, help='검색할 이벤트 이름 (예: 뮤직뱅크, 인기가요)')
    parser.add_argument('--start-date', type=str, help='검색 시작 날짜 (YYYY-MM-DD)')
    parser.add_argument('--end-date', type=str, help='검색 종료 날짜 (YYYY-MM-DD)')
    
    # 결과 제한 및 처리 옵션
    parser.add_argument('--limit', type=int, default=50, help='검색 결과 최대 개수')
    parser.add_argument('--skip-existing', action='store_true', help='이미 존재하는 비디오 건너뛰기')
    parser.add_argument('--output', type=str, default='output', help='결과 저장 경로')
    parser.add_argument('--format', type=str, choices=['csv', 'json', 'both', 'none'], default='both', 
                        help='결과 저장 형식 (csv, json, both, none)')
    
    # 저장 옵션
    parser.add_argument('--save-to-db', action='store_true', help='결과를 데이터베이스에 저장')
    parser.add_argument('--download-thumbnails', action='store_true', help='썸네일 다운로드')
    
    # 데이터베이스 타입 (기본값은 환경 변수 또는 postgresql)
    parser.add_argument('--db-type', type=str, default=os.getenv("DB_TYPE", "postgresql"),
                        choices=['postgresql', 'mongodb', 'supabase'],
                        help='사용할 데이터베이스 타입 (postgresql, mongodb, supabase)')
    
    args = parser.parse_args()
    
    # 인수 처리 로그
    logger.info(f"[크롤링 프로세스] 명령줄 인수 파싱 완료:")
    logger.info(f"[크롤링 프로세스] - 아티스트: {args.artist or '지정되지 않음'}")
    logger.info(f"[크롤링 프로세스] - 그룹: {args.group or '지정되지 않음'}")
    logger.info(f"[크롤링 프로세스] - 이벤트: {args.event or '지정되지 않음'}")
    logger.info(f"[크롤링 프로세스] - 날짜 범위: {args.start_date or '시작일 없음'} ~ {args.end_date or '종료일 없음'}")
    logger.info(f"[크롤링 프로세스] - 결과 수 제한: {args.limit}")
    logger.info(f"[크롤링 프로세스] - 출력 디렉토리: {args.output}")
    logger.info(f"[크롤링 프로세스] - 저장 형식: {args.format}")
    logger.info(f"[크롤링 프로세스] - DB 저장: {'활성화' if args.save_to_db else '비활성화'}")
    logger.info(f"[크롤링 프로세스] - DB 타입: {args.db_type}")
    logger.info(f"[크롤링 프로세스] - 썸네일 다운로드: {'활성화' if args.download_thumbnails else '비활성화'}")
    
    return args

def build_search_query(args: argparse.Namespace) -> str:
    """
    명령줄 인수에서 검색어 구성
    
    Args:
        args: 명령줄 인수
        
    Returns:
        검색어
    """
    logger.info("[크롤링 프로세스] 검색어 구성 중...")
    query_parts = []
    
    if args.artist:
        query_parts.append(args.artist)
        logger.info(f"[크롤링 프로세스] 아티스트 키워드 추가: '{args.artist}'")
    
    if args.group:
        query_parts.append(args.group)
        logger.info(f"[크롤링 프로세스] 그룹 키워드 추가: '{args.group}'")
    
    if args.event:
        query_parts.append(args.event)
        logger.info(f"[크롤링 프로세스] 이벤트 키워드 추가: '{args.event}'")
    
    query = " ".join(query_parts)
    
    # 비어있으면 기본 검색어 사용
    if not query.strip():
        query = "kpop fancam"
        logger.info("[크롤링 프로세스] 검색어가 비어있어 기본 검색어 사용: 'kpop fancam'")
    
    # 항상 fancam 키워드 추가
    if "fancam" not in query.lower() and "직캠" not in query:
        query += " fancam"
        logger.info("[크롤링 프로세스] 'fancam' 키워드 자동 추가")
    
    logger.info(f"[크롤링 프로세스] 최종 검색어: '{query}'")
    return query

def save_results_to_file(videos: List[Dict[str, Any]], output_dir: str, format_type: str) -> None:
    """
    결과를 파일로 저장
    
    Args:
        videos: 비디오 목록
        output_dir: 출력 디렉토리
        format_type: 저장 형식 (csv, json, both, none)
    """
    if format_type == 'none':
        logger.info("[크롤링 프로세스] 파일 저장이 비활성화되어 있습니다 (format=none)")
        return
    
    logger.info(f"[크롤링 프로세스] 결과 파일 저장 시작 (형식: {format_type})")
    
    try:
        os.makedirs(output_dir, exist_ok=True)
        logger.info(f"[크롤링 프로세스] 출력 디렉토리 확인: {output_dir}")
        
        # 현재 시간을 파일명에 추가
        timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
        
        if format_type in ['csv', 'both']:
            try:
                import pandas as pd
                csv_path = os.path.join(output_dir, f'videos_{timestamp}.csv')
                logger.info(f"[크롤링 프로세스] CSV 파일 생성 중: {csv_path}")
                pd.DataFrame(videos).to_csv(csv_path, index=False, encoding='utf-8-sig')
                logger.info(f"[크롤링 프로세스] 결과가 {csv_path}에 CSV 형식으로 저장되었습니다.")
            except Exception as e:
                logger.error(f"[크롤링 프로세스] CSV 파일 저장 중 오류 발생: {str(e)}")
        
        if format_type in ['json', 'both']:
            try:
                json_path = os.path.join(output_dir, f'videos_{timestamp}.json')
                logger.info(f"[크롤링 프로세스] JSON 파일 생성 중: {json_path}")
                with open(json_path, 'w', encoding='utf-8') as f:
                    json.dump(videos, f, ensure_ascii=False, indent=2)
                logger.info(f"[크롤링 프로세스] 결과가 {json_path}에 JSON 형식으로 저장되었습니다.")
            except Exception as e:
                logger.error(f"[크롤링 프로세스] JSON 파일 저장 중 오류 발생: {str(e)}")
                
        logger.info("[크롤링 프로세스] 결과 파일 저장 완료")
        
    except Exception as e:
        logger.error(f"[크롤링 프로세스] 파일 저장 중 일반 오류 발생: {str(e)}")

def download_thumbnails(videos: List[Dict[str, Any]], output_dir: str) -> None:
    """
    썸네일 이미지 다운로드
    
    Args:
        videos: 비디오 목록
        output_dir: 출력 디렉토리
    """
    import requests
    from tqdm import tqdm
    
    thumbnails_dir = os.path.join(output_dir, 'thumbnails')
    os.makedirs(thumbnails_dir, exist_ok=True)
    
    logger.info(f"[크롤링 프로세스] {len(videos)}개 비디오의 썸네일을 다운로드합니다.")
    
    success_count = 0
    skipped_count = 0
    error_count = 0
    
    for video in tqdm(videos, desc="썸네일 다운로드"):
        # 필드명 확인 (thumbnailUrl 또는 thumbnail_url)
        thumbnail_url = None
        if 'thumbnailUrl' in video and video['thumbnailUrl']:
            thumbnail_url = video['thumbnailUrl']
        elif 'thumbnail_url' in video and video['thumbnail_url']:
            thumbnail_url = video['thumbnail_url']
            
        if thumbnail_url:
            # 비디오 ID로 파일 이름 생성
            video_id = video.get('id', '') or video.get('video_id', '')
            filename = f"{video_id}.jpg"
            file_path = os.path.join(thumbnails_dir, filename)
            
            # 이미 존재하는 파일 건너뛰기
            if os.path.exists(file_path):
                logger.debug(f"[크롤링 프로세스] 썸네일 파일이 이미 존재합니다: {filename}")
                skipped_count += 1
                continue
            
            try:
                response = requests.get(thumbnail_url, stream=True)
                if response.status_code == 200:
                    with open(file_path, 'wb') as f:
                        for chunk in response.iter_content(1024):
                            f.write(chunk)
                    success_count += 1
                else:
                    logger.warning(f"[크롤링 프로세스] 썸네일 다운로드 실패 {video_id}: HTTP 상태 코드 {response.status_code}")
                    error_count += 1
            except Exception as e:
                logger.error(f"[크롤링 프로세스] 썸네일 다운로드 오류 {video_id}: {e}")
                error_count += 1
    
    logger.info(f"[크롤링 프로세스] 썸네일 다운로드 결과: 성공 {success_count}개, 건너뜀 {skipped_count}개, 실패 {error_count}개")
    logger.info(f"[크롤링 프로세스] 썸네일이 {thumbnails_dir}에 저장되었습니다.")

def save_to_database(videos: List[Dict[str, Any]]) -> None:
    """
    비디오 데이터를 데이터베이스에 저장
    
    Args:
        videos: 비디오 목록
    """
    # 이 함수는 실제 구현 시 데이터베이스 연결 및 저장 로직을 구현해야 합니다.
    # 여기서는 간단한 예시만 제공합니다.
    logger.info(f"[크롤링 프로세스] {len(videos)}개 비디오를 데이터베이스에 저장합니다.")
    
    # DB_TYPE에 따라 다른 데이터베이스 연결 사용
    db_type = os.getenv("DB_TYPE", "postgresql").lower()
    
    try:
        if db_type == "postgresql":
            # PostgreSQL 연결 및 저장 로직
            import psycopg2
            from psycopg2.extras import execute_values
            
            conn = psycopg2.connect(
                host=os.getenv("DB_HOST", "localhost"),
                port=int(os.getenv("DB_PORT", "5432")),
                dbname=os.getenv("DB_NAME", "pulse"),
                user=os.getenv("DB_USER", "postgres"),
                password=os.getenv("DB_PASSWORD", "")
            )
            
            cursor = conn.cursor()
            
            # 여기에서 SQL 문 실행하여 데이터 저장
            # 예시:
            # execute_values(
            #     cursor,
            #     "INSERT INTO videos (id, title, description, ...) VALUES %s",
            #     [(v['id'], v['title'], v['description'], ...) for v in videos]
            # )
            
            conn.commit()
            cursor.close()
            conn.close()
            
        elif db_type == "mongodb":
            # MongoDB 연결 및 저장 로직
            from pymongo import MongoClient
            
            client = MongoClient(os.getenv("MONGO_URI", "mongodb://localhost:27017/"))
            db = client[os.getenv("DB_NAME", "pulse")]
            videos_collection = db.videos

            # 비디오 ID로 중복 확인 후 삽입 또는 업데이트
            for video in videos:
                videos_collection.update_one(
                    {"id": video["id"]},
                    {"$set": video},
                    upsert=True
                )
                
            client.close()
        
        elif db_type == "supabase":
            # Supabase 연결 및 저장 로직
            import requests
            import json
            from datetime import datetime
            
            # Supabase URL과 API 키 가져오기
            supabase_url = os.getenv("SUPABASE_URL")
            supabase_key = os.getenv("SUPABASE_SERVICE_KEY")  # service_role 키 사용
            
            if not supabase_url or not supabase_key:
                logger.error("[크롤링 프로세스] SUPABASE_URL 또는 SUPABASE_SERVICE_KEY가 설정되지 않았습니다.")
                return
                
            # 서비스 키가 제대로 설정되었는지 로그에 일부만 표시하여 확인 (보안상 전체 표시는 피함)
            key_preview = supabase_key[:10] + "..." + supabase_key[-5:] if len(supabase_key) > 15 else "설정되지 않음"
            logger.info(f"[크롤링 프로세스] Supabase 서비스 키 미리보기: {key_preview}")
            logger.info(f"[크롤링 프로세스] Supabase URL: {supabase_url}")
            
            # Supabase REST API 엔드포인트
            api_endpoint = f"{supabase_url}/rest/v1/videos"
            logger.info(f"[크롤링 프로세스] Supabase API 엔드포인트: {api_endpoint}")
            
            # API 요청 헤더 설정
            headers = {
                "apikey": supabase_key,
                "Authorization": f"Bearer {supabase_key}",
                "Content-Type": "application/json",
                "Prefer": "resolution=merge-duplicates"
            }
            logger.info(f"[크롤링 프로세스] Supabase API 헤더 설정 완료")
            
            # 현재 시간 (타임스탬프용)
            now = datetime.now().isoformat()
            
            # 데이터 변환 - Supabase videos 테이블 구조에 맞게 조정
            formatted_videos = []
            for video in videos:
                # 비디오 데이터를 Supabase 테이블 구조에 맞게 변환
                formatted_video = {
                    "id": str(uuid.uuid4()),  # 고유 UUID 생성
                    "platform_id": video.get("id", ""),  # YouTube 비디오 ID
                    "platform": "youtube",
                    "title": video.get("title", ""),
                    "description": video.get("description", ""),
                    "thumbnail_url": video.get("thumbnail_url", ""),
                    "published_at": video.get("published_at", now),
                    "view_count": int(video.get("view_count", 0)),
                    "like_count": int(video.get("like_count", 0)),
                    "comment_count": int(video.get("comment_count", 0)),
                    "tags": video.get("tags", []),  # 배열을 직접 전달 (Supabase가 자동으로 JSONB로 변환)
                    "is_fancam": True,  # 팬캠으로 표시
                    "created_at": now,
                    "updated_at": now,
                    "video_url": f"https://www.youtube.com/watch?v={video.get('id', '')}"  # 비디오 URL 추가
                }
                
                # 로깅
                logger.info(f"[크롤링 프로세스] 비디오 변환: {video.get('id', '')} -> {formatted_video['id']} (platform_id: {formatted_video['platform_id']})")
                
                formatted_videos.append(formatted_video)
            
            # 일괄 처리할 경우 100개씩 나누어 처리 (API 제한 고려)
            batch_size = 20
            for i in range(0, len(formatted_videos), batch_size):
                batch = formatted_videos[i:i+batch_size]
                
                try:
                    # 요청 전 정보 로깅
                    logger.info(f"[크롤링 프로세스] Supabase API 요청 시작 (배치 크기: {len(batch)})")
                    
                    # 첫 번째 항목의 데이터 형식을 로그에 기록 (디버깅용)
                    if batch and len(batch) > 0:
                        sample_item = batch[0]
                        logger.info(f"[크롤링 프로세스] 샘플 데이터 형식 - tags 타입: {type(sample_item.get('tags')).__name__}")
                        if 'tags' in sample_item and sample_item['tags']:
                            tag_sample = sample_item['tags'][:3] if len(sample_item['tags']) > 3 else sample_item['tags']
                            logger.info(f"[크롤링 프로세스] tags 샘플 내용(최대 3개): {tag_sample}")
                    
                    # Supabase REST API에 POST 요청
                    response = requests.post(
                        api_endpoint,
                        headers=headers,
                        json=batch
                    )
                    
                    # 응답 확인 및 자세한 로깅
                    logger.info(f"[크롤링 프로세스] Supabase API 응답 상태 코드: {response.status_code}")
                    
                    if response.status_code in [200, 201, 204]:
                        logger.info(f"[크롤링 프로세스] Supabase에 {len(batch)}개의 비디오 데이터를 성공적으로 저장했습니다. (상태 코드: {response.status_code})")
                    else:
                        logger.error(f"[크롤링 프로세스] Supabase API 오류: {response.status_code} - {response.text}")
                        # 응답 본문 전체 로깅 (디버깅용)
                        logger.error(f"[크롤링 프로세스] 응답 본문: {response.text}")
                        
                        # 오류 발생 시 요청 본문의 일부를 로그에 기록
                        try:
                            import json
                            req_json = json.dumps(batch[0])[:300] + "..." if batch else "{}"
                            logger.error(f"[크롤링 프로세스] 요청 본문 샘플(첫 항목): {req_json}")
                        except Exception as log_err:
                            logger.error(f"[크롤링 프로세스] 요청 본문 로깅 실패: {str(log_err)}")
                        
                except Exception as e:
                    logger.error(f"[크롤링 프로세스] Supabase API 요청 중 오류 발생: {str(e)}")
                    # 예외 추적 정보 추가
                    import traceback
                    logger.error(f"[크롤링 프로세스] 예외 추적: {traceback.format_exc()}")
        
        else:
            logger.error(f"지원되지 않는 데이터베이스 유형: {db_type}")
            
    except Exception as e:
        logger.error(f"데이터베이스 저장 중 오류 발생: {str(e)}", exc_info=True)

def main():
    """
    메인 함수
    """
    logger.info("[크롤링 프로세스] 크롤러 스크립트 실행 시작")
    
    # 인수 파싱
    args = parse_args()
    logger.info(f"[크롤링 프로세스] 명령줄 인수: {vars(args)}")
    
    # API 키 가져오기
    api_key = get_youtube_api_key()
    logger.info("[크롤링 프로세스] YouTube API 키 로드 완료")
    
    # 검색어 구성
    query = build_search_query(args)
    logger.info(f"[크롤링 프로세스] 검색어 구성: '{query}'")
    
    # 날짜 파싱
    start_date = None
    if args.start_date:
        start_date = datetime.datetime.strptime(args.start_date, '%Y-%m-%d')
        logger.info(f"[크롤링 프로세스] 시작 날짜: {start_date.strftime('%Y-%m-%d')}")
    
    end_date = None
    if args.end_date:
        end_date = datetime.datetime.strptime(args.end_date, '%Y-%m-%d')
        logger.info(f"[크롤링 프로세스] 종료 날짜: {end_date.strftime('%Y-%m-%d')}")
    
    # 크롤러 초기화 및 실행
    logger.info(f"[크롤링 프로세스] '{query}' 검색어로 크롤링을 시작합니다.")
    crawler = YouTubeCrawler(api_key)
    videos = crawler.search_videos(
        query=query,
        max_results=args.limit,
        published_after=start_date,
        published_before=end_date
    )
    
    logger.info(f"[크롤링 프로세스] 검색 결과: {len(videos)}개 비디오")
    
    # 비디오 ID 추출 및 세부 정보 가져오기
    if videos:
        video_ids = [video['id'] for video in videos]
        logger.info(f"[크롤링 프로세스] {len(video_ids)}개 비디오의 세부 정보를 가져옵니다.")
        video_details = crawler.get_video_details(video_ids)
        logger.info(f"[크롤링 프로세스] {len(video_details)}개 비디오 세부 정보 획득 완료")
        
        # 결과를 파일로 저장
        logger.info(f"[크롤링 프로세스] 결과를 {args.format} 형식으로 저장합니다.")
        save_results_to_file(video_details, args.output, args.format)
        
        # 썸네일 다운로드
        if args.download_thumbnails:
            logger.info("[크롤링 프로세스] 썸네일 다운로드 시작")
            download_thumbnails(video_details, args.output)
            logger.info("[크롤링 프로세스] 썸네일 다운로드 완료")
        
        # 데이터베이스에 저장
        if args.save_to_db:
            logger.info("[크롤링 프로세스] 데이터베이스 저장 시작")
            save_to_database(video_details)
            logger.info("[크롤링 프로세스] 데이터베이스 저장 완료")
    else:
        logger.warning(f"[크롤링 프로세스] '{query}' 검색어로 비디오를 찾을 수 없습니다.")
    
    logger.info("[크롤링 프로세스] 크롤링 완료")

if __name__ == "__main__":
    main() 