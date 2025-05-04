#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Pulse 크롤러 작업 스케줄러
크론 작업을 관리하는 명령줄 도구
"""

import os
import sys
import json
import uuid
import argparse
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List, Optional

from croniter import croniter
from dotenv import load_dotenv

# 로깅 설정
os.makedirs('logs', exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/schedule_job.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("schedule-job")

# 환경 변수 로드
load_dotenv()

# 스케줄 파일 경로
SCHEDULED_JOBS_FILE = Path("data/scheduled_jobs.json")

def load_scheduled_jobs() -> List[Dict[str, Any]]:
    """저장된 예약 작업 로드"""
    os.makedirs(os.path.dirname(SCHEDULED_JOBS_FILE), exist_ok=True)
    
    if not SCHEDULED_JOBS_FILE.exists():
        return []
    
    try:
        with open(SCHEDULED_JOBS_FILE, "r", encoding="utf-8") as f:
            jobs = json.load(f)
        return jobs
    except Exception as e:
        logger.error(f"예약 작업 로드 오류: {e}")
        return []

def save_scheduled_jobs(jobs: List[Dict[str, Any]]):
    """예약 작업 저장"""
    os.makedirs(os.path.dirname(SCHEDULED_JOBS_FILE), exist_ok=True)
    
    try:
        with open(SCHEDULED_JOBS_FILE, "w", encoding="utf-8") as f:
            json.dump(jobs, f, ensure_ascii=False, indent=2)
    except Exception as e:
        logger.error(f"예약 작업 저장 오류: {e}")

def add_job(args):
    """새 예약 작업 추가"""
    # 명령줄 인수 검증
    if not args.name:
        logger.error("작업 이름이 필요합니다.")
        return 1
    
    if not args.cron:
        logger.error("Cron 표현식이 필요합니다.")
        return 1
    
    # Cron 표현식 검증
    try:
        croniter(args.cron)
    except Exception as e:
        logger.error(f"잘못된 Cron 표현식: {e}")
        return 1
    
    # 예약 작업 목록 로드
    jobs = load_scheduled_jobs()
    
    # 작업 ID 생성
    job_id = str(uuid.uuid4())
    
    # 다음 실행 시간 계산
    cron = croniter(args.cron, datetime.now())
    next_run = cron.get_next(datetime).isoformat()
    
    # 작업 매개변수 설정
    params = {}
    
    if args.artist:
        params["artist"] = args.artist
    
    if args.group:
        params["group"] = args.group
    
    if args.event:
        params["event"] = args.event
    
    if args.limit:
        params["limit"] = args.limit
    
    params["save_to_db"] = args.save_to_db
    
    # 새 작업 생성
    job = {
        "id": job_id,
        "name": args.name,
        "cron_expression": args.cron,
        "is_active": True,
        "params": params,
        "last_run": None,
        "next_run": next_run
    }
    
    # 작업 목록에 추가
    jobs.append(job)
    
    # 저장
    save_scheduled_jobs(jobs)
    
    logger.info(f"작업 '{args.name}'이(가) 추가되었습니다. (ID: {job_id})")
    logger.info(f"다음 실행: {datetime.fromisoformat(next_run).strftime('%Y-%m-%d %H:%M:%S')}")
    
    return 0

def list_jobs(args):
    """모든 예약 작업 목록 표시"""
    jobs = load_scheduled_jobs()
    
    if not jobs:
        print("예약된 작업이 없습니다.")
        return 0
    
    print(f"\n{'ID':<36} | {'이름':<20} | {'Cron 표현식':<15} | {'상태':<8} | {'다음 실행':<20} | {'검색 조건'}")
    print("-" * 120)
    
    for job in jobs:
        # 다음 실행 시간 포맷팅
        next_run = job.get("next_run")
        if next_run:
            try:
                next_run = datetime.fromisoformat(next_run).strftime("%Y-%m-%d %H:%M:%S")
            except (ValueError, TypeError):
                next_run = "알 수 없음"
        else:
            next_run = "알 수 없음"
        
        # 상태 포맷팅
        status = "활성" if job.get("is_active", True) else "비활성"
        
        # 검색 조건 포맷팅
        params = job.get("params", {})
        search_conditions = []
        
        if "artist" in params and params["artist"]:
            search_conditions.append(f"아티스트: {params['artist']}")
        
        if "group" in params and params["group"]:
            search_conditions.append(f"그룹: {params['group']}")
        
        if "event" in params and params["event"]:
            search_conditions.append(f"이벤트: {params['event']}")
        
        if "limit" in params:
            search_conditions.append(f"제한: {params['limit']}")
        
        search_condition = ", ".join(search_conditions) if search_conditions else "기본값"
        
        print(f"{job['id']:<36} | {job['name']:<20} | {job['cron_expression']:<15} | {status:<8} | {next_run:<20} | {search_condition}")
    
    print("")
    return 0

def delete_job(args):
    """예약 작업 삭제"""
    if not args.id:
        logger.error("작업 ID가 필요합니다.")
        return 1
    
    # 예약 작업 목록 로드
    jobs = load_scheduled_jobs()
    
    # 작업 ID로 검색
    found = False
    job_name = ""
    
    for i, job in enumerate(jobs):
        if job["id"] == args.id:
            job_name = job["name"]
            del jobs[i]
            found = True
            break
    
    if not found:
        logger.error(f"작업 ID '{args.id}'를 찾을 수 없습니다.")
        return 1
    
    # 저장
    save_scheduled_jobs(jobs)
    
    logger.info(f"작업 '{job_name}'(ID: {args.id})이(가) 삭제되었습니다.")
    
    return 0

def enable_job(args):
    """예약 작업 활성화"""
    if not args.id:
        logger.error("작업 ID가 필요합니다.")
        return 1
    
    # 예약 작업 목록 로드
    jobs = load_scheduled_jobs()
    
    # 작업 ID로 검색
    found = False
    
    for i, job in enumerate(jobs):
        if job["id"] == args.id:
            job["is_active"] = True
            
            # 다음 실행 시간 계산
            cron = croniter(job["cron_expression"], datetime.now())
            job["next_run"] = cron.get_next(datetime).isoformat()
            
            found = True
            break
    
    if not found:
        logger.error(f"작업 ID '{args.id}'를 찾을 수 없습니다.")
        return 1
    
    # 저장
    save_scheduled_jobs(jobs)
    
    logger.info(f"작업 ID '{args.id}'이(가) 활성화되었습니다.")
    
    return 0

def disable_job(args):
    """예약 작업 비활성화"""
    if not args.id:
        logger.error("작업 ID가 필요합니다.")
        return 1
    
    # 예약 작업 목록 로드
    jobs = load_scheduled_jobs()
    
    # 작업 ID로 검색
    found = False
    
    for i, job in enumerate(jobs):
        if job["id"] == args.id:
            job["is_active"] = False
            found = True
            break
    
    if not found:
        logger.error(f"작업 ID '{args.id}'를 찾을 수 없습니다.")
        return 1
    
    # 저장
    save_scheduled_jobs(jobs)
    
    logger.info(f"작업 ID '{args.id}'이(가) 비활성화되었습니다.")
    
    return 0

def main():
    """메인 함수"""
    # 명령줄 인수 파서 설정
    parser = argparse.ArgumentParser(description="Pulse 크롤러 예약 작업 관리 도구")
    subparsers = parser.add_subparsers(dest="command", help="하위 명령")
    
    # 작업 추가 명령
    add_parser = subparsers.add_parser("add", help="새 예약 작업 추가")
    add_parser.add_argument("--name", help="작업 이름")
    add_parser.add_argument("--cron", help="Cron 표현식 (예: '0 0 * * *' - 매일 자정)")
    add_parser.add_argument("--artist", help="아티스트 이름")
    add_parser.add_argument("--group", help="그룹 이름")
    add_parser.add_argument("--event", help="이벤트(무대) 이름")
    add_parser.add_argument("--limit", type=int, default=50, help="검색 결과 수 제한")
    add_parser.add_argument("--save-to-db", action="store_true", default=True, help="결과를 데이터베이스에 저장")
    
    # 작업 목록 명령
    list_parser = subparsers.add_parser("list", help="모든 예약 작업 목록 표시")
    
    # 작업 삭제 명령
    delete_parser = subparsers.add_parser("delete", help="예약 작업 삭제")
    delete_parser.add_argument("--id", help="삭제할 작업 ID")
    
    # 작업 활성화 명령
    enable_parser = subparsers.add_parser("enable", help="예약 작업 활성화")
    enable_parser.add_argument("--id", help="활성화할 작업 ID")
    
    # 작업 비활성화 명령
    disable_parser = subparsers.add_parser("disable", help="예약 작업 비활성화")
    disable_parser.add_argument("--id", help="비활성화할 작업 ID")
    
    # 인수 파싱
    args = parser.parse_args()
    
    # 하위 명령 실행
    if args.command == "add":
        return add_job(args)
    elif args.command == "list":
        return list_jobs(args)
    elif args.command == "delete":
        return delete_job(args)
    elif args.command == "enable":
        return enable_job(args)
    elif args.command == "disable":
        return disable_job(args)
    else:
        parser.print_help()
        return 0

if __name__ == "__main__":
    sys.exit(main()) 