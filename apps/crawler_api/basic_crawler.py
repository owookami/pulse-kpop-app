#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
기본 YouTube 크롤러 스크립트
K-POP 아티스트 팬캠 동영상을 수집합니다.
"""

import os
import sys
import json
import logging
import argparse
import datetime
from typing import List, Dict, Any, Optional

import requests
from dotenv import load_dotenv
import pandas as pd
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from tqdm import tqdm

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/crawler.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("youtube-crawler")

# 환경 변수 로드
load_dotenv()

# YouTube API 키 가져오기
YOUTUBE_API_KEY = os.getenv("YOUTUBE_API_KEY")
if not YOUTUBE_API_KEY:
    logger.error("YouTube API 키가 설정되지 않았습니다. .env 파일에 YOUTUBE_API_KEY를 설정하세요.")
    sys.exit(1)

# 데이터베이스 설정
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", "5432")),
    "dbname": os.getenv("DB_NAME", "pulse"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "")
}

class YouTubeCrawler:
    """YouTube API를 사용하여 K-POP 팬캠 동영상을 크롤링하는 클래스"""
    
    def __init__(self, api_key: str):
        """
        크롤러 초기화
        
        Args:
            api_key: YouTube API 키
        """
        self.api_key = api_key
        self.youtube = build('youtube', 'v3', developerKey=api_key)
        self.results = []
        logger.info("YouTube 크롤러가 초기화되었습니다.")
    
    def search_videos(self, 
                     query: str, 
                     max_results: int = 50,
                     published_after: Optional[datetime.datetime] = None,
                     published_before: Optional[datetime.datetime] = None) -> List[Dict[str, Any]]:
        """
        YouTube에서 비디오 검색
        
        Args:
            query: 검색어
            max_results: 최대 검색 결과 수
            published_after: 이 시간 이후에 업로드된 비디오만 검색
            published_before: 이 시간 이전에 업로드된 비디오만 검색
            
        Returns:
            검색된 비디오 목록
        """
        logger.info(f"'{query}' 검색 시작. 최대 {max_results}개 결과")
        
        # 날짜 형식 변환
        published_after_str = None
        if published_after:
            published_after_str = published_after.strftime('%Y-%m-%dT%H:%M:%SZ')
            
        published_before_str = None
        if published_before:
            published_before_str = published_before.strftime('%Y-%m-%dT%H:%M:%SZ')
        
        videos = []
        next_page_token = None
        
        # 페이지네이션을 사용하여 여러 페이지 결과 수집
        while len(videos) < max_results:
            try:
                search_response = self.youtube.search().list(
                    q=query,
                    part='id,snippet',
                    maxResults=min(50, max_results - len(videos)),  # YouTube API 한 번에 최대 50개 결과
                    pageToken=next_page_token,
                    type='video',
                    videoEmbeddable='true',
                    publishedAfter=published_after_str,
                    publishedBefore=published_before_str,
                    order='relevance'
                ).execute()
                
                # 결과 처리
                for item in search_response.get('items', []):
                    if item['id']['kind'] == 'youtube#video':
                        video_id = item['id']['videoId']
                        videos.append({
                            'id': video_id,
                            'title': item['snippet']['title'],
                            'published_at': item['snippet']['publishedAt'],
                            'channel_id': item['snippet']['channelId'],
                            'channel_title': item['snippet']['channelTitle'],
                            'thumbnail_url': item['snippet']['thumbnails']['high']['url'],
                        })
                
                # 다음 페이지 토큰 확인
                next_page_token = search_response.get('nextPageToken')
                if not next_page_token:
                    break
                    
            except HttpError as e:
                logger.error(f"YouTube API 오류: {e}")
                break
        
        logger.info(f"{len(videos)}개의 비디오를 찾았습니다.")
        self.results = videos
        return videos
    
    def get_video_details(self, video_ids: List[str]) -> List[Dict[str, Any]]:
        """
        비디오 세부 정보 가져오기
        
        Args:
            video_ids: 비디오 ID 목록
            
        Returns:
            비디오 세부 정보 목록
        """
        if not video_ids:
            return []
            
        logger.info(f"{len(video_ids)}개 비디오의 세부 정보를 가져옵니다.")
        
        # 한 번에 최대 50개 비디오 정보만 가져올 수 있음
        video_details = []
        for i in range(0, len(video_ids), 50):
            batch = video_ids[i:i+50]
            try:
                response = self.youtube.videos().list(
                    part='snippet,contentDetails,statistics',
                    id=','.join(batch)
                ).execute()
                
                for item in response.get('items', []):
                    # 필드명을 run_crawler.py에서 사용하는 형식과 일치시킴
                    video_detail = {
                        'id': item['id'],
                        'title': item['snippet']['title'],
                        'description': item['snippet']['description'],
                        'published_at': item['snippet']['publishedAt'],
                        'channel_id': item['snippet']['channelId'],
                        'channel_title': item['snippet']['channelTitle'],
                        'thumbnail_url': item['snippet']['thumbnails']['high']['url'],
                        'duration': item['contentDetails']['duration'],
                        'view_count': int(item['statistics'].get('viewCount', 0)),
                        'like_count': int(item['statistics'].get('likeCount', 0)),
                        'comment_count': int(item['statistics'].get('commentCount', 0)),
                        'tags': item['snippet'].get('tags', [])
                    }
                    video_details.append(video_detail)
            
            except HttpError as e:
                logger.error(f"비디오 세부 정보 가져오기 오류: {e}")
        
        logger.info(f"{len(video_details)}개 비디오의 세부 정보를 가져왔습니다.")
        return video_details
    
    def extract_artist_from_title(self, title: str, artists: List[str]) -> Optional[str]:
        """
        비디오 제목에서 아티스트 이름 추출
        
        Args:
            title: 비디오 제목
            artists: 아티스트 이름 목록
            
        Returns:
            추출된 아티스트 이름 또는 None
        """
        title_lower = title.lower()
        for artist in artists:
            if artist.lower() in title_lower:
                return artist
        return None
    
    def save_to_csv(self, filename: str = 'youtube_videos.csv'):
        """
        결과를 CSV 파일로 저장
        
        Args:
            filename: 저장할 파일 이름
        """
        if not self.results:
            logger.warning("저장할 결과가 없습니다.")
            return
            
        df = pd.DataFrame(self.results)
        df.to_csv(filename, index=False, encoding='utf-8-sig')
        logger.info(f"결과가 {filename}에 저장되었습니다.")
    
    def save_to_json(self, filename: str = 'youtube_videos.json'):
        """
        결과를 JSON 파일로 저장
        
        Args:
            filename: 저장할 파일 이름
        """
        if not self.results:
            logger.warning("저장할 결과가 없습니다.")
            return
            
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.results, f, ensure_ascii=False, indent=2)
        logger.info(f"결과가 {filename}에 저장되었습니다.")

def parse_args() -> argparse.Namespace:
    """
    명령줄 인수 파싱
    
    Returns:
        파싱된 인수
    """
    parser = argparse.ArgumentParser(description='YouTube에서 K-POP 팬캠 동영상 크롤링')
    
    parser.add_argument('--artist', type=str, help='검색할 아티스트 이름')
    parser.add_argument('--group', type=str, help='검색할 그룹 이름')
    parser.add_argument('--query', type=str, help='사용자 정의 검색어')
    parser.add_argument('--start-date', type=str, help='검색 시작 날짜 (YYYY-MM-DD)')
    parser.add_argument('--end-date', type=str, help='검색 종료 날짜 (YYYY-MM-DD)')
    parser.add_argument('--limit', type=int, default=50, help='검색 결과 최대 개수')
    parser.add_argument('--output', type=str, default='output', help='결과 저장 경로')
    parser.add_argument('--format', type=str, choices=['csv', 'json', 'both'], default='both', 
                        help='결과 저장 형식 (csv, json, both)')
    
    return parser.parse_args()

def main():
    """메인 함수"""
    # 로그 디렉토리 생성
    os.makedirs('logs', exist_ok=True)
    
    # 명령줄 인수 파싱
    args = parse_args()
    
    # 검색어 구성
    query = ""
    if args.artist:
        query += f"{args.artist} "
    if args.group:
        query += f"{args.group} "
    if args.query:
        query += f"{args.query} "
    
    if not query.strip():
        query = "kpop fancam"
    
    query += " fancam"
    
    # 날짜 파싱
    start_date = None
    if args.start_date:
        start_date = datetime.datetime.strptime(args.start_date, '%Y-%m-%d')
    
    end_date = None
    if args.end_date:
        end_date = datetime.datetime.strptime(args.end_date, '%Y-%m-%d')
    
    # 크롤러 초기화 및 실행
    crawler = YouTubeCrawler(YOUTUBE_API_KEY)
    videos = crawler.search_videos(
        query=query,
        max_results=args.limit,
        published_after=start_date,
        published_before=end_date
    )
    
    # 비디오 ID 추출
    video_ids = [video['id'] for video in videos]
    
    # 비디오 세부 정보 가져오기
    video_details = crawler.get_video_details(video_ids)
    
    # 결과 업데이트
    crawler.results = video_details
    
    # 결과 디렉토리 생성
    os.makedirs(args.output, exist_ok=True)
    
    # 결과 저장
    if args.format in ['csv', 'both']:
        crawler.save_to_csv(f"{args.output}/youtube_videos.csv")
    
    if args.format in ['json', 'both']:
        crawler.save_to_json(f"{args.output}/youtube_videos.json")
    
    logger.info("크롤링 완료")

if __name__ == "__main__":
    main() 