#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Pulse 크롤러 스케줄러 데몬
예약된 크롤링 작업을 실행하는 스케줄러 데몬
"""

import os
import sys
import time
import json
import logging
import threading
import subprocess
import signal
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, List

import schedule
from croniter import croniter
from dotenv import load_dotenv

# 로깅 설정
os.makedirs('logs', exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/scheduler.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("pulse-scheduler")

# 환경 변수 로드
load_dotenv()

# 스케줄 파일 경로
SCHEDULED_JOBS_FILE = Path("data/scheduled_jobs.json")

# 스케줄러 중지 플래그
stop_flag = threading.Event()

# 작업 인스턴스 추적
running_jobs = {}

def signal_handler(signum, frame):
    """시그널 핸들러"""
    logger.info(f"시그널 {signum} 수신, 종료 중...")
    stop_flag.set()
    
    # 실행 중인 모든 작업 중지
    for job_id, process in running_jobs.items():
        if process and process.poll() is None:
            logger.info(f"작업 {job_id} 종료 중...")
            process.terminate()
    
    sys.exit(0)

def load_scheduled_jobs() -> List[Dict[str, Any]]:
    """저장된 예약 작업 로드"""
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

def update_job_schedule(job: Dict[str, Any]):
    """작업 일정 업데이트"""
    try:
        # 다음 실행 시간 계산
        cron = croniter(job["cron_expression"], datetime.now())
        next_run = cron.get_next(datetime)
        
        # 작업 업데이트
        job["next_run"] = next_run.isoformat()
        
        # 모든 작업 가져오기
        jobs = load_scheduled_jobs()
        
        # 해당 작업 업데이트
        for i, j in enumerate(jobs):
            if j["id"] == job["id"]:
                jobs[i] = job
                break
        
        # 저장
        save_scheduled_jobs(jobs)
        
        logger.info(f"작업 '{job['name']}' 다음 실행 시간: {next_run.strftime('%Y-%m-%d %H:%M:%S')}")
    except Exception as e:
        logger.error(f"작업 일정 업데이트 오류: {e}")

def run_job(job_id: str):
    """예약된 작업 실행"""
    # 작업 정보 가져오기
    jobs = load_scheduled_jobs()
    job = None
    
    for j in jobs:
        if j["id"] == job_id:
            job = j
            break
    
    if not job:
        logger.error(f"작업 ID '{job_id}'를 찾을 수 없음")
        return
    
    try:
        # 작업이 활성화되어 있는지 확인
        if not job.get("is_active", True):
            logger.info(f"작업 '{job['name']}'이(가) 비활성화되어 있어 실행되지 않음")
            return
        
        logger.info(f"작업 '{job['name']}'(ID: {job_id}) 실행 중...")
        
        # 실행 시간 기록
        job["last_run"] = datetime.now().isoformat()
        update_job_schedule(job)
        
        # 작업 매개변수 설정
        params = job.get("params", {})
        cmd = ["python", "run_crawler.py"]
        
        if params.get("artist"):
            cmd.extend(["--artist", params["artist"]])
        
        if params.get("group"):
            cmd.extend(["--group", params["group"]])
        
        if params.get("event"):
            cmd.extend(["--event", params["event"]])
        
        if params.get("limit"):
            cmd.extend(["--limit", str(params["limit"])])
        
        if params.get("save_to_db", True):
            cmd.append("--save-to-db")
        
        # 작업 실행
        log_file = open(f"logs/job_{job_id}.log", "a")
        process = subprocess.Popen(
            cmd,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            text=True
        )
        
        # 실행 중인 작업 추적
        running_jobs[job_id] = process
        
        # 작업 완료 대기
        return_code = process.wait()
        
        # 작업 완료 후 실행 중인 작업에서 제거
        if job_id in running_jobs:
            del running_jobs[job_id]
        
        # 로그 파일 닫기
        log_file.close()
        
        if return_code == 0:
            logger.info(f"작업 '{job['name']}'이(가) 성공적으로 완료됨")
        else:
            logger.error(f"작업 '{job['name']}'이(가) 실패함 (코드: {return_code})")
        
    except Exception as e:
        logger.error(f"작업 '{job['name']}' 실행 오류: {e}")
        
        # 실행 중인 작업에서 제거
        if job_id in running_jobs:
            del running_jobs[job_id]

def schedule_jobs():
    """모든 예약 작업 스케줄링"""
    # 기존 작업 취소
    schedule.clear()
    
    # 예약 작업 로드
    jobs = load_scheduled_jobs()
    
    for job in jobs:
        if not job.get("is_active", True):
            logger.info(f"작업 '{job['name']}'이(가) 비활성화되어 있어 스케줄링되지 않음")
            continue
        
        # 작업 ID
        job_id = job["id"]
        
        try:
            # 다음 실행 시간 확인 및 업데이트
            next_run = None
            if "next_run" in job and job["next_run"]:
                try:
                    next_run = datetime.fromisoformat(job["next_run"])
                except (ValueError, TypeError):
                    next_run = None
            
            if not next_run or next_run < datetime.now():
                # 다음 실행 시간 계산
                cron = croniter(job["cron_expression"], datetime.now())
                next_run = cron.get_next(datetime)
                job["next_run"] = next_run.isoformat()
            
            # cron 표현식에 따라 작업 스케줄링
            schedule.every().day.at(next_run.strftime("%H:%M")).do(run_job, job_id)
            
            logger.info(f"작업 '{job['name']}' 스케줄링됨, 다음 실행: {next_run.strftime('%Y-%m-%d %H:%M:%S')}")
        except Exception as e:
            logger.error(f"작업 '{job['name']}' 스케줄링 오류: {e}")
    
    # 변경사항 저장
    save_scheduled_jobs(jobs)

def check_jobs_schedule():
    """모든 작업의 스케줄 확인 및 업데이트"""
    jobs = load_scheduled_jobs()
    now = datetime.now()
    
    for job in jobs:
        if not job.get("is_active", True):
            continue
        
        try:
            next_run = None
            if "next_run" in job and job["next_run"]:
                try:
                    next_run = datetime.fromisoformat(job["next_run"])
                except (ValueError, TypeError):
                    next_run = None
            
            # 다음 실행 시간이 없거나 지났으면 업데이트
            if not next_run or next_run < now:
                cron = croniter(job["cron_expression"], now)
                job["next_run"] = cron.get_next(datetime).isoformat()
                logger.info(f"작업 '{job['name']}' 다음 실행 시간 업데이트됨: {job['next_run']}")
        except Exception as e:
            logger.error(f"작업 '{job['name']}' 스케줄 확인 오류: {e}")
    
    # 변경사항 저장
    save_scheduled_jobs(jobs)

def main():
    """메인 함수"""
    # 시그널 핸들러 등록
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    logger.info("Pulse 크롤러 스케줄러 시작")
    
    # data 디렉토리 생성
    os.makedirs(os.path.dirname(SCHEDULED_JOBS_FILE), exist_ok=True)
    
    # 스케줄 업데이트
    check_jobs_schedule()
    
    # 작업 스케줄링
    schedule_jobs()
    
    # 매일 자정에 스케줄 다시 로드
    schedule.every().day.at("00:00").do(schedule_jobs)
    
    # 매시간 작업 스케줄 확인
    schedule.every().hour.do(check_jobs_schedule)
    
    try:
        while not stop_flag.is_set():
            schedule.run_pending()
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("Ctrl+C 입력됨, 종료 중...")
    finally:
        logger.info("Pulse 크롤러 스케줄러 종료")

if __name__ == "__main__":
    main() 