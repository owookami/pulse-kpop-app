#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Pulse 크롤러 웹 어드민 API
크롤러를 웹 인터페이스를 통해 제어하기 위한 API 서버
"""

import os
import sys
import json
import logging
from datetime import datetime, timedelta
import asyncio
import subprocess
import uuid
import schedule
import threading
import time
import platform
from typing import List, Dict, Any, Optional, Union
from pathlib import Path

import uvicorn
from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends, Query, status, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.encoders import jsonable_encoder
from pydantic import BaseModel, Field, validator
from dotenv import load_dotenv
from croniter import croniter

# 환경 변수 로드
load_dotenv()

# 로깅 설정
os.makedirs('logs', exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/admin_api.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("admin-api")

# 현재 실행 파일의 디렉토리 경로 확인 - 초기에 설정하여 전체 파일에서 사용
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
WEB_DIR = os.path.join(CURRENT_DIR, "web")

# 작업 디렉터리 설정
JOBS_DIR = os.path.join(os.getcwd(), 'jobs')
os.makedirs(JOBS_DIR, exist_ok=True)

# 작업 이력 저장 파일
JOBS_HISTORY_FILE = Path("data/jobs_history.json")

# 스케줄러 작업 저장 경로
SCHEDULED_JOBS_FILE = Path("data/scheduled_jobs.json")

# 작업 보관 기간 (일)
JOB_RETENTION_DAYS = 30

# 스케줄러 스레드 종료 플래그
scheduler_stop_flag = threading.Event()

# FastAPI 앱 초기화
app = FastAPI(
    title="Pulse 크롤러 관리자 API",
    description="K-POP 팬캠 데이터 수집 크롤러 관리 API",
    version="1.0.0"
)

# CORS 설정 - 개발 환경에서는 모든 오리진 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 정적 파일 마운트
app.mount("/admin", StaticFiles(directory=WEB_DIR, html=True), name="admin")

# 기본 경로를 admin 페이지로 리디렉션
@app.get("/")
async def redirect_to_admin():
    from fastapi.responses import RedirectResponse
    return RedirectResponse(url="/admin/")

# 데이터 모델 정의
class ArtistBase(BaseModel):
    id: str
    name: str
    groupName: Optional[str] = None

class GroupBase(BaseModel):
    id: str
    name: str

class JobParams(BaseModel):
    artist: Optional[str] = None
    group: Optional[str] = None
    event: Optional[str] = None
    limit: int = 50
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    format: str = "json"
    output: str = "output"
    save_to_db: bool = True
    download_thumbnails: bool = False
    skip_existing: bool = False

class JobResult(BaseModel):
    message: Optional[str] = None
    output_dir: Optional[str] = None
    files: Optional[List[str]] = None
    error: Optional[str] = None

class JobBase(BaseModel):
    id: str
    status: str
    params: JobParams
    start_time: datetime
    end_time: Optional[datetime] = None
    result: Optional[JobResult] = None

class Stats(BaseModel):
    total_jobs: int
    running_jobs: int
    completed_jobs: int
    failed_jobs: int

class ScheduledJob(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    cron_expression: str
    is_active: bool = True
    params: Dict[str, Any] = {}
    last_run: Optional[Union[datetime, str]] = None
    next_run: Optional[Union[datetime, str]] = None
    
    @validator('cron_expression')
    def validate_cron_expression(cls, value):
        """Cron 표현식 유효성 검사"""
        if not value or value.strip() == "":
            logger.error("Cron 표현식이 비어 있습니다.")
            raise ValueError("Cron 표현식이 비어 있습니다.")
            
        # 형식 검증 (5-6개의 공백으로 구분된 필드)
        parts = value.strip().split()
        if len(parts) < 5 or len(parts) > 6:
            error_msg = f"Cron 표현식은 5개 또는 6개의 필드로 구성되어야 합니다 (현재: {len(parts)}개 필드). 올바른 형식: '분 시 일 월 요일 [년]'"
            logger.error(f"올바르지 않은 Cron 표현식: {value}, 오류: {error_msg}")
            raise ValueError(error_msg)
        
        try:
            croniter(value, datetime.now())
            return value
        except Exception as e:
            error_msg = f"올바르지 않은 Cron 표현식: {value}, 오류: {str(e)}"
            logger.error(error_msg)
            raise ValueError(error_msg)
    
    @validator('params')
    def ensure_params_dict(cls, value):
        """params가 없거나 None인 경우 빈 딕셔너리 반환"""
        if value is None:
            return {}
        return value

class ScheduledJobStatus(BaseModel):
    is_active: bool

# 아티스트 목록 (샘플 데이터)
# 실제 환경에서는 이 부분이 데이터베이스에서 로드됨
DEFAULT_ARTISTS = [
    {"id": "1", "name": "지수", "groupName": "블랙핑크"},
    {"id": "2", "name": "제니", "groupName": "블랙핑크"},
    {"id": "3", "name": "로제", "groupName": "블랙핑크"},
    {"id": "4", "name": "리사", "groupName": "블랙핑크"},
    {"id": "5", "name": "윈터", "groupName": "에스파"},
    {"id": "6", "name": "카리나", "groupName": "에스파"},
    {"id": "7", "name": "닝닝", "groupName": "에스파"},
    {"id": "8", "name": "지젤", "groupName": "에스파"}
]

# 그룹 목록 (샘플 데이터)
DEFAULT_GROUPS = [
    {"id": "1", "name": "블랙핑크"},
    {"id": "2", "name": "에스파"},
    {"id": "3", "name": "뉴진스"},
    {"id": "4", "name": "아이브"},
    {"id": "5", "name": "르세라핌"}
]

# 작업 상태
JOB_STATUS = {
    "pending": "대기 중",
    "running": "실행 중",
    "completed": "완료",
    "failed": "실패"
}

# 작업 데이터 로드
def load_jobs() -> List[JobBase]:
    jobs = []
    
    # 작업 이력 파일이 존재하면 로드
    if os.path.exists(JOBS_HISTORY_FILE):
        try:
            with open(JOBS_HISTORY_FILE, 'r', encoding='utf-8') as f:
                try:
                    jobs_data = json.load(f)
                    
                    for job_data in jobs_data:
                        # datetime 문자열을 datetime 객체로 변환
                        if 'start_time' in job_data and job_data['start_time']:
                            try:
                                job_data['start_time'] = datetime.fromisoformat(job_data['start_time'])
                            except (ValueError, TypeError):
                                job_data['start_time'] = datetime.now()
                                
                        if 'end_time' in job_data and job_data['end_time']:
                            try:
                                job_data['end_time'] = datetime.fromisoformat(job_data['end_time'])
                            except (ValueError, TypeError):
                                job_data['end_time'] = None
                        
                        jobs.append(JobBase(**job_data))
                except json.JSONDecodeError as e:
                    logger.error(f"작업 이력 파일 읽기 오류: {e}")
        except Exception as e:
            logger.error(f"작업 이력 파일 로드 오류: {e}")
    
    # 개별 작업 파일도 로드 (이전 방식과의 호환성 유지)
    for filename in os.listdir(JOBS_DIR):
        if filename.endswith('.json'):
            try:
                with open(os.path.join(JOBS_DIR, filename), 'r', encoding='utf-8') as f:
                    try:
                        job_data = json.load(f)
                        # datetime 문자열을 datetime 객체로 변환
                        if 'start_time' in job_data and job_data['start_time']:
                            try:
                                job_data['start_time'] = datetime.fromisoformat(job_data['start_time'])
                            except (ValueError, TypeError):
                                job_data['start_time'] = datetime.now()
                                
                        if 'end_time' in job_data and job_data['end_time']:
                            try:
                                job_data['end_time'] = datetime.fromisoformat(job_data['end_time'])
                            except (ValueError, TypeError):
                                job_data['end_time'] = None
                        
                        # 중복 작업 방지 (ID가 같은 작업이 이미 리스트에 있는지 확인)
                        if not any(job.id == job_data['id'] for job in jobs):
                            jobs.append(JobBase(**job_data))
                    except Exception as e:
                        logger.error(f"작업 파일 {filename} 읽기 오류: {e}")
            except Exception as e:
                logger.error(f"작업 파일 {filename} 로드 오류: {e}")
    
    # 오래된 작업 필터링 (30일 이상 지난 작업 제외)
    retention_date = datetime.now() - timedelta(days=JOB_RETENTION_DAYS)
    
    # start_time이 None인 작업은 최근 작업으로 간주
    filtered_jobs = [job for job in jobs if job.start_time is None or job.start_time > retention_date]
    
    # 필터링된 작업 수가 다르면 자동 정리가 이루어진 것이므로 기록 저장
    if len(filtered_jobs) != len(jobs):
        logger.info(f"{len(jobs) - len(filtered_jobs)}개의 오래된 작업이 자동 정리되었습니다.")
        # 필터링된 작업 목록 저장
        save_jobs_history(filtered_jobs)
    
    # 최신 작업 순으로 정렬 (start_time이 None인 경우는 가장 마지막에 배치)
    filtered_jobs.sort(key=lambda j: j.start_time if j.start_time else datetime.min, reverse=True)
    return filtered_jobs

# 모든 작업 저장
def save_jobs_history(jobs: List[JobBase]):
    try:
        # 작업 목록을 직렬화
        jobs_data = []
        for job in jobs:
            job_dict = jsonable_encoder(job)
            jobs_data.append(job_dict)
        
        # 파일에 저장
        os.makedirs(os.path.dirname(JOBS_HISTORY_FILE), exist_ok=True)
        with open(JOBS_HISTORY_FILE, 'w', encoding='utf-8') as f:
            json.dump(jobs_data, f, ensure_ascii=False, indent=2)
        
        logger.info(f"{len(jobs)}개의 작업 이력이 저장되었습니다.")
    except Exception as e:
        logger.error(f"작업 이력 저장 오류: {e}")

# 작업 저장
def save_job(job: JobBase):
    try:
        # 개별 작업 파일 저장 (이전 방식과의 호환성 유지)
        job_data = jsonable_encoder(job)
        with open(os.path.join(JOBS_DIR, f"{job.id}.json"), 'w', encoding='utf-8') as f:
            json.dump(job_data, f, ensure_ascii=False, indent=2)
        
        # 전체 작업 이력 업데이트
        jobs = load_jobs()
        
        # 기존 작업 업데이트 또는 새 작업 추가
        updated = False
        for i, existing_job in enumerate(jobs):
            if existing_job.id == job.id:
                jobs[i] = job
                updated = True
                break
        
        if not updated:
            jobs.append(job)
        
        # 작업 이력 저장
        save_jobs_history(jobs)
        logger.info(f"작업 저장 완료: {job.id}")
    except Exception as e:
        logger.error(f"작업 저장 오류 (ID: {job.id}): {e}")

# 작업 가져오기
def get_job(job_id: str) -> Optional[JobBase]:
    try:
        with open(os.path.join(JOBS_DIR, f"{job_id}.json"), 'r', encoding='utf-8') as f:
            job_data = json.load(f)
            # datetime 문자열을 datetime 객체로 변환
            if 'start_time' in job_data:
                job_data['start_time'] = datetime.fromisoformat(job_data['start_time'])
            if 'end_time' in job_data and job_data['end_time']:
                job_data['end_time'] = datetime.fromisoformat(job_data['end_time'])
            
            return JobBase(**job_data)
    except Exception as e:
        logger.error(f"Error getting job {job_id}: {e}")
        return None

# 작업 삭제
def delete_job(job_id: str) -> bool:
    try:
        # 개별 작업 파일 삭제 (이전 방식과의 호환성 유지)
        job_file = os.path.join(JOBS_DIR, f"{job_id}.json")
        if os.path.exists(job_file):
            os.remove(job_file)
            logger.info(f"작업 파일이 삭제됨: {job_file}")
        
        # 작업 이력에서도 삭제
        jobs = load_jobs()
        initial_count = len(jobs)
        jobs = [job for job in jobs if job.id != job_id]
        
        # 작업이 실제로 제거되었으면 저장
        if len(jobs) < initial_count:
            save_jobs_history(jobs)
            logger.info(f"작업 ID {job_id}가 작업 이력에서 삭제됨")
            return True
        else:
            logger.warning(f"작업 ID {job_id}를 작업 이력에서 찾을 수 없음")
            return False
    except Exception as e:
        logger.error(f"작업 삭제 오류 (ID: {job_id}): {e}")
        return False

# 통계 계산
def calculate_stats() -> Stats:
    jobs = load_jobs()
    
    total_jobs = len(jobs)
    running_jobs = sum(1 for job in jobs if job.status == "running")
    completed_jobs = sum(1 for job in jobs if job.status == "completed")
    failed_jobs = sum(1 for job in jobs if job.status == "failed")
    
    return Stats(
        total_jobs=total_jobs,
        running_jobs=running_jobs,
        completed_jobs=completed_jobs,
        failed_jobs=failed_jobs
    )

# Python 명령어 결정 함수
def get_python_command():
    """OS 플랫폼에 따라 적절한 Python 명령어를 반환합니다."""
    system = platform.system().lower()
    
    # 명시적으로 python3로 설정 (macOS와 대부분의 Unix 시스템에서 필요)
    if system in ('darwin', 'linux'):
        logger.info("macOS/Linux 환경 감지: python3 명령 사용")
        return 'python3'
    
    # Windows에서는 'python'을 사용
    elif system == 'windows':
        logger.info("Windows 환경 감지: python 명령 사용")
        return 'python'
    
    # 기타 환경에서는 검증 후 사용
    else:
        logger.info(f"알 수 없는 OS: {system}. Python 명령어 검증 중...")
        # python3 명령어 존재 여부 확인
        try:
            subprocess.run(['python3', '--version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
            logger.info("python3 명령 사용 가능 확인")
            return 'python3'
        except FileNotFoundError:
            logger.info("python3 명령 없음. python 명령 사용")
            return 'python'

# 크롤러 실행 함수
async def run_crawler(job_id: str, params: Dict[str, Any]):
    job = get_job(job_id)
    
    if not job:
        logger.error(f"Job {job_id} not found")
        return
    
    try:
        # 작업 상태 업데이트
        job.status = "running"
        save_job(job)
        
        # OS에 맞는 Python 명령어 가져오기
        python_cmd = get_python_command()
        
        # 현재 디렉토리 기준으로 run_crawler.py의 절대 경로 구성
        crawler_script = os.path.join(os.getcwd(), "run_crawler.py")
        
        # 명령줄 인수 생성
        cmd = [python_cmd, crawler_script]
        
        if params.get("artist"):
            cmd.extend(["--artist", params["artist"]])
        
        if params.get("group"):
            cmd.extend(["--group", params["group"]])
        
        if params.get("event"):
            cmd.extend(["--event", params["event"]])
        
        if params.get("limit"):
            cmd.extend(["--limit", str(params["limit"])])
        
        if params.get("start_date"):
            cmd.extend(["--start-date", params["start_date"]])
        
        if params.get("end_date"):
            cmd.extend(["--end-date", params["end_date"]])
        
        if params.get("format"):
            cmd.extend(["--format", params["format"]])
        
        if params.get("output"):
            cmd.extend(["--output", params["output"]])
        
        if params.get("save_to_db"):
            cmd.append("--save-to-db")
        
        if params.get("download_thumbnails"):
            cmd.append("--download-thumbnails")
        
        if params.get("skip_existing"):
            cmd.append("--skip-existing")
        
        # 작업 디렉토리 생성
        output_dir = os.path.join("output", job_id)
        os.makedirs(output_dir, exist_ok=True)
        
        # 로그 파일 경로
        log_file = os.path.join("logs", f"crawler_{job_id}.log")
        
        # 환경 변수 설정 - .env 파일에서 읽어온 값을 명시적으로 전달
        env = os.environ.copy()
        env["YOUTUBE_API_KEY"] = os.getenv("YOUTUBE_API_KEY")
        env["SUPABASE_URL"] = os.getenv("SUPABASE_URL")
        env["SUPABASE_KEY"] = os.getenv("SUPABASE_KEY")
        env["SUPABASE_SERVICE_KEY"] = os.getenv("SUPABASE_SERVICE_KEY")
        env["DB_HOST"] = os.getenv("DB_HOST")
        env["DB_PORT"] = os.getenv("DB_PORT")
        env["DB_NAME"] = os.getenv("DB_NAME")
        env["DB_USER"] = os.getenv("DB_USER")
        env["DB_PASSWORD"] = os.getenv("DB_PASSWORD")
        env["DB_TYPE"] = "supabase"  # DB 타입을 명시적으로 설정

        # 환경 변수 설정 로깅 (보안을 위해 키의 일부만 표시)
        logger.info(f"환경 변수 설정: SUPABASE_URL={env['SUPABASE_URL']}")
        
        if env.get("SUPABASE_KEY"):
            key_preview = env["SUPABASE_KEY"][:5] + "..." + env["SUPABASE_KEY"][-5:] if len(env["SUPABASE_KEY"]) > 10 else "설정되지 않음"
            logger.info(f"환경 변수 설정: SUPABASE_KEY={key_preview}")
        else:
            logger.warning("환경 변수 설정: SUPABASE_KEY가 설정되지 않았습니다.")
            
        if env.get("SUPABASE_SERVICE_KEY"):
            key_preview = env["SUPABASE_SERVICE_KEY"][:5] + "..." + env["SUPABASE_SERVICE_KEY"][-5:] if len(env["SUPABASE_SERVICE_KEY"]) > 10 else "설정되지 않음"
            logger.info(f"환경 변수 설정: SUPABASE_SERVICE_KEY={key_preview}")
        else:
            logger.warning("환경 변수 설정: SUPABASE_SERVICE_KEY가 설정되지 않았습니다.")
        
        logger.info(f"환경 변수 설정: DB_TYPE=supabase (명시적으로 설정됨)")
        
        # 크롤링 작업 명령 로깅
        logger.info(f"실행 명령: {' '.join(cmd)}")
        
        # 명령 실행 - 환경 변수 전달
        with open(log_file, "w", encoding="utf-8") as f:
            process = subprocess.Popen(
                cmd,
                stdout=f,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                env=env  # 환경 변수 전달
            )
        
        # 프로세스가 완료될 때까지 대기
        return_code = process.wait()
        
        # 작업 상태 및 결과 업데이트
        job = get_job(job_id)  # 최신 상태 로드
        job.end_time = datetime.now()
        
        if return_code == 0:
            job.status = "completed"
            # 생성된 파일 목록 가져오기
            files = []
            for root, _, filenames in os.walk(output_dir):
                for filename in filenames:
                    files.append(os.path.join(root, filename))
            
            job.result = JobResult(
                message="크롤링 작업이 성공적으로 완료되었습니다.",
                output_dir=output_dir,
                files=files
            )
        else:
            job.status = "failed"
            
            # 로그 파일에서 오류 읽기
            error_message = "알 수 없는 오류가 발생했습니다."
            try:
                with open(log_file, "r", encoding="utf-8") as f:
                    log_content = f.read()
                    error_message = log_content[-500:] if len(log_content) > 500 else log_content
            except Exception as e:
                logger.error(f"Error reading log file: {e}")
            
            job.result = JobResult(
                error=error_message
            )
        
        save_job(job)
        
    except Exception as e:
        logger.error(f"Error running crawler for job {job_id}: {e}")
        
        # 작업 상태 업데이트
        job = get_job(job_id)
        if job:
            job.status = "failed"
            job.end_time = datetime.now()
            job.result = JobResult(
                error=str(e)
            )
            save_job(job)

# API 엔드포인트
@app.get("/api/artists", response_model=List[ArtistBase])
async def get_artists():
    """아티스트 목록 반환"""
    return DEFAULT_ARTISTS

@app.get("/api/groups", response_model=List[GroupBase])
async def get_groups():
    """그룹 목록 반환"""
    return DEFAULT_GROUPS

@app.get("/api/jobs")
def get_jobs():
    """크롤링 작업 목록 조회"""
    try:
        jobs = load_jobs()
        logger.info(f"작업 목록 조회: {len(jobs)}개의 작업이 반환됨")
        return {"jobs": jobs}
    except Exception as e:
        logger.error(f"작업 목록 조회 오류: {str(e)}")
        return JSONResponse(
            status_code=500,
            content={"message": f"작업 목록 조회 오류: {str(e)}"}
        )

@app.get("/api/jobs/{job_id}", response_model=JobBase)
async def get_job_by_id(job_id: str):
    """특정 작업 정보 반환"""
    job = get_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail=f"Job {job_id} not found")
    return job

@app.post("/api/jobs", response_model=JobBase)
async def create_job(params: JobParams, background_tasks: BackgroundTasks):
    """새 크롤링 작업 생성"""
    # 작업 ID 생성
    job_id = str(uuid.uuid4())
    
    # 작업 생성
    now = datetime.now()
    job = JobBase(
        id=job_id,
        status="pending",
        params=params,
        start_time=now
    )
    
    # 작업 저장
    save_job(job)
    
    # 백그라운드에서 크롤러 실행
    background_tasks.add_task(run_crawler, job_id, params.dict())
    
    return job

@app.delete("/api/jobs/{job_id}")
async def delete_job_by_id(job_id: str):
    """작업 삭제"""
    job = get_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail=f"Job {job_id} not found")
    
    if job.status in ["running", "pending"]:
        raise HTTPException(status_code=400, detail="Cannot delete a running or pending job")
    
    # 작업 삭제
    if delete_job(job_id):
        return {"message": f"Job {job_id} deleted successfully"}
    else:
        raise HTTPException(status_code=500, detail=f"Failed to delete job {job_id}")

@app.get("/api/stats", response_model=Stats)
async def get_stats():
    """작업 통계 반환"""
    return calculate_stats()

# 크론 스케줄러 초기화
def init_scheduler():
    # 저장된 스케줄 작업 로드
    os.makedirs(os.path.dirname(SCHEDULED_JOBS_FILE), exist_ok=True)
    
    if SCHEDULED_JOBS_FILE.exists():
        try:
            with open(SCHEDULED_JOBS_FILE, "r", encoding="utf-8") as f:
                jobs_data = json.load(f)
                
            for job_data in jobs_data:
                # datetime 문자열을 datetime 객체로 변환
                if "last_run" in job_data and job_data["last_run"]:
                    job_data["last_run"] = datetime.fromisoformat(job_data["last_run"])
                if "next_run" in job_data and job_data["next_run"]:
                    job_data["next_run"] = datetime.fromisoformat(job_data["next_run"])
                
                job = ScheduledJob(**job_data)
                schedule_job(job)
        except Exception as e:
            logger.error(f"스케줄 작업 로드 오류: {e}")
    
    # 스케줄러 스레드 시작
    scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
    scheduler_thread.start()

# 스케줄러 실행 함수
def run_scheduler():
    while not scheduler_stop_flag.is_set():
        schedule.run_pending()
        time.sleep(1)

# 작업 스케줄링 함수
def schedule_job(job: ScheduledJob):
    if not job.is_active:
        return
    
    # 다음 실행 시간 계산
    cron = croniter(job.cron_expression, datetime.now())
    next_run = cron.get_next(datetime)
    job.next_run = next_run
    
    # 작업 저장
    save_scheduled_jobs()

# 예약 작업 저장
def save_scheduled_jobs():
    # 모든 작업 가져오기
    jobs_data = get_all_scheduled_jobs()
    
    # datetime 객체를 문자열로 변환
    for job in jobs_data:
        if "last_run" in job and job["last_run"]:
            job["last_run"] = job["last_run"].isoformat()
        if "next_run" in job and job["next_run"]:
            job["next_run"] = job["next_run"].isoformat()
    
    # 파일에 저장
    with open(SCHEDULED_JOBS_FILE, "w", encoding="utf-8") as f:
        json.dump(jobs_data, f, ensure_ascii=False, indent=2)

# 모든 예약 작업 가져오기
def get_all_scheduled_jobs():
    """모든 예약 작업 목록 반환"""
    try:
        if os.path.exists(SCHEDULED_JOBS_FILE):
            with open(SCHEDULED_JOBS_FILE, "r", encoding="utf-8") as f:
                try:
                    jobs = json.load(f)
                    
                    # 모든 작업에 대해 날짜 필드 처리
                    for job in jobs:
                        # next_run과 last_run이 이미 문자열 형태로 저장되어 있으므로 그대로 사용
                        # 필드가 없는 경우에 대비하여 기본값 설정
                        if "params" not in job or job["params"] is None:
                            job["params"] = {}
                    
                    return jobs
                except json.JSONDecodeError as e:
                    logger.error(f"JSON 디코딩 오류: {str(e)}")
                    return []
        else:
            # 파일이 없으면 빈 목록 반환
            return []
    except Exception as e:
        logger.error(f"스케줄 작업 로드 오류: {str(e)}")
        return []

# 작업 ID로 예약 작업 가져오기
def get_scheduled_job(job_id: str):
    """특정 예약 작업 조회"""
    jobs = get_all_scheduled_jobs()
    
    # 작업 ID로 검색
    for job in jobs:
        if job["id"] == job_id:
            # datetime 문자열은 그대로 사용
            # 클라이언트 측에서 변환 필요
            return job
    return None

# 예약 작업 추가
def add_scheduled_job(job: ScheduledJob):
    try:
        logger.info(f"예약 작업 추가 프로세스 시작: {job.id}")
        jobs = get_all_scheduled_jobs()
        
        # 작업 ID 중복 확인
        for existing_job in jobs:
            if existing_job["id"] == job.id:
                logger.warning(f"중복된 작업 ID 발견: {job.id}")
                raise ValueError(f"중복된 작업 ID: {job.id}")
        
        # 필수 필드 확인
        if not job.name:
            logger.warning("작업 이름이 비어 있음")
            raise ValueError("작업 이름은 필수입니다")
            
        # params 필드가 없으면 빈 딕셔너리로 초기화
        if not job.params:
            logger.info("params 필드가 없어 빈 딕셔너리로 초기화")
            job.params = {}
        
        try:
            # 다음 실행 시간 계산
            logger.info(f"Cron 표현식 파싱: {job.cron_expression}")
            cron = croniter(job.cron_expression, datetime.now())
            next_run_time = cron.get_next(datetime)
            # datetime 객체를 문자열로 변환하여 저장
            job.next_run = next_run_time.isoformat()
            logger.info(f"다음 실행 시간 계산됨: {job.next_run}")
        except Exception as cron_error:
            logger.error(f"Cron 표현식 파싱 오류: {str(cron_error)}")
            raise ValueError(f"잘못된 Cron 표현식: {str(cron_error)}")
        
        # 객체를 딕셔너리로 변환 (에러 발생 가능한 부분)
        try:
            job_dict = job.dict()
            logger.info("모델을 딕셔너리로 변환 성공")
        except Exception as dict_error:
            logger.error(f"모델 직렬화 오류: {str(dict_error)}")
            raise ValueError(f"작업 데이터 형식 오류: {str(dict_error)}")
        
        # 목록에 추가
        jobs.append(job_dict)
        logger.info(f"작업 목록에 추가됨: {job.id}")
        
        # 파일에 저장
        try:
            with open(SCHEDULED_JOBS_FILE, "w", encoding="utf-8") as f:
                # datetime 객체를 문자열로 변환 (이미 문자열인 경우 그대로 유지)
                for j in jobs:
                    # last_run과 next_run이 이미 문자열인지 확인
                    if "last_run" in j and j["last_run"] and not isinstance(j["last_run"], str):
                        j["last_run"] = j["last_run"].isoformat() if isinstance(j["last_run"], datetime) else str(j["last_run"])
                    if "next_run" in j and j["next_run"] and not isinstance(j["next_run"], str):
                        j["next_run"] = j["next_run"].isoformat() if isinstance(j["next_run"], datetime) else str(j["next_run"])
                
                json.dump(jobs, f, ensure_ascii=False, indent=2)
                logger.info("작업 목록 파일에 저장 성공")
        except Exception as file_error:
            logger.error(f"파일 저장 오류: {str(file_error)}")
            raise IOError(f"작업 목록 파일 저장 오류: {str(file_error)}")
        
        # 작업 스케줄링
        if job.is_active:
            try:
                schedule_job(job)
                logger.info(f"작업 {job.id} 스케줄링 성공")
            except Exception as sched_error:
                logger.warning(f"작업 스케줄링 경고 (작업은 저장됨): {str(sched_error)}")
        
        logger.info(f"예약 작업 추가 완료: {job.id}")
        return job
    
    except ValueError as ve:
        # 이미 로깅된 검증 오류 - 다시 발생
        logger.error(f"작업 검증 오류: {str(ve)}")
        raise
    
    except Exception as e:
        # 예상치 못한 오류
        logger.error(f"예약 작업 추가 중 오류 발생: {str(e)}", exc_info=True)
        raise ValueError(f"예약 작업 처리 오류: {str(e)}")

# 예약 작업 업데이트
def update_scheduled_job(job_id: str, job_data: ScheduledJob):
    try:
        logger.info(f"예약 작업 업데이트 시작: {job_id}")
        jobs = get_all_scheduled_jobs()
        
        # 작업 ID로 검색
        found = False
        for i, job in enumerate(jobs):
            if job["id"] == job_id:
                # 다음 실행 시간 계산
                if job_data.is_active:
                    try:
                        logger.info(f"Cron 표현식 파싱: {job_data.cron_expression}")
                        cron = croniter(job_data.cron_expression, datetime.now())
                        next_run_time = cron.get_next(datetime)
                        # datetime 객체를 문자열로 변환
                        job_data.next_run = next_run_time.isoformat()
                        logger.info(f"다음 실행 시간 계산됨: {job_data.next_run}")
                    except Exception as cron_error:
                        logger.error(f"Cron 표현식 파싱 오류: {str(cron_error)}")
                        raise ValueError(f"잘못된 Cron 표현식: {str(cron_error)}")
                
                # 업데이트
                jobs[i] = job_data.dict()
                found = True
                logger.info(f"작업 {job_id} 업데이트됨")
                break
        
        if not found:
            logger.warning(f"작업 ID를 찾을 수 없음: {job_id}")
            raise ValueError(f"작업 ID를 찾을 수 없음: {job_id}")
        
        # 파일에 저장
        try:
            with open(SCHEDULED_JOBS_FILE, "w", encoding="utf-8") as f:
                # datetime 객체를 문자열로 변환 (이미 문자열인 경우 그대로 유지)
                for j in jobs:
                    # last_run과 next_run이 이미 문자열인지 확인
                    if "last_run" in j and j["last_run"] and not isinstance(j["last_run"], str):
                        j["last_run"] = j["last_run"].isoformat() if isinstance(j["last_run"], datetime) else str(j["last_run"])
                    if "next_run" in j and j["next_run"] and not isinstance(j["next_run"], str):
                        j["next_run"] = j["next_run"].isoformat() if isinstance(j["next_run"], datetime) else str(j["next_run"])
                
                json.dump(jobs, f, ensure_ascii=False, indent=2)
                logger.info("작업 목록 파일에 저장 성공")
        except Exception as file_error:
            logger.error(f"파일 저장 오류: {str(file_error)}")
            raise IOError(f"작업 목록 파일 저장 오류: {str(file_error)}")
        
        # 작업 스케줄링
        if job_data.is_active:
            try:
                schedule_job(job_data)
                logger.info(f"작업 {job_id} 스케줄링 성공")
            except Exception as sched_error:
                logger.warning(f"작업 스케줄링 경고 (작업은 저장됨): {str(sched_error)}")
        
        logger.info(f"예약 작업 업데이트 완료: {job_id}")
        return job_data
    
    except ValueError as ve:
        # 이미 로깅된 검증 오류 - 다시 발생
        logger.error(f"작업 검증 오류: {str(ve)}")
        raise
    
    except Exception as e:
        # 예상치 못한 오류
        logger.error(f"예약 작업 업데이트 중 오류 발생: {str(e)}", exc_info=True)
        raise ValueError(f"예약 작업 처리 오류: {str(e)}")

# 예약 작업 삭제
def delete_scheduled_job(job_id: str):
    try:
        logger.info(f"예약 작업 삭제 시작: {job_id}")
        jobs = get_all_scheduled_jobs()
        
        # 작업 ID로 검색
        found = False
        for i, job in enumerate(jobs):
            if job["id"] == job_id:
                del jobs[i]
                found = True
                logger.info(f"작업 ID {job_id}가 목록에서 삭제됨")
                break
        
        if not found:
            logger.warning(f"작업 ID를 찾을 수 없음: {job_id}")
            raise ValueError(f"작업 ID를 찾을 수 없음: {job_id}")
        
        # 파일에 저장
        try:
            with open(SCHEDULED_JOBS_FILE, "w", encoding="utf-8") as f:
                # datetime 객체를 문자열로 변환 (이미 문자열인 경우 그대로 유지)
                for j in jobs:
                    # last_run과 next_run이 이미 문자열인지 확인
                    if "last_run" in j and j["last_run"] and not isinstance(j["last_run"], str):
                        j["last_run"] = j["last_run"].isoformat() if isinstance(j["last_run"], datetime) else str(j["last_run"])
                    if "next_run" in j and j["next_run"] and not isinstance(j["next_run"], str):
                        j["next_run"] = j["next_run"].isoformat() if isinstance(j["next_run"], datetime) else str(j["next_run"])
                
                json.dump(jobs, f, ensure_ascii=False, indent=2)
                logger.info("작업 목록 파일에 저장 성공")
        except Exception as file_error:
            logger.error(f"파일 저장 오류: {str(file_error)}")
            raise IOError(f"작업 목록 파일 저장 오류: {str(file_error)}")
        
        logger.info(f"예약 작업 삭제 완료: {job_id}")
        return {"message": f"작업 ID {job_id}가 삭제되었습니다."}
    
    except ValueError as ve:
        # 이미 로깅된 검증 오류 - 다시 발생
        logger.error(f"작업 검증 오류: {str(ve)}")
        raise
    
    except Exception as e:
        # 예상치 못한 오류
        logger.error(f"예약 작업 삭제 중 오류 발생: {str(e)}", exc_info=True)
        raise ValueError(f"예약 작업 처리 오류: {str(e)}")

# 예약 작업 상태 업데이트
def update_scheduled_job_status(job_id: str, status: ScheduledJobStatus):
    try:
        logger.info(f"예약 작업 상태 업데이트 시작: {job_id}, 활성화: {status.is_active}")
        jobs = get_all_scheduled_jobs()
        
        # 작업 ID로 검색
        found = False
        for i, job in enumerate(jobs):
            if job["id"] == job_id:
                job["is_active"] = status.is_active
                found = True
                
                # 활성화된 경우 다음 실행 시간 계산
                if status.is_active:
                    try:
                        cron = croniter(job["cron_expression"], datetime.now())
                        next_run_time = cron.get_next(datetime)
                        job["next_run"] = next_run_time.isoformat()
                        logger.info(f"다음 실행 시간 계산됨: {job['next_run']}")
                    except Exception as cron_error:
                        logger.error(f"Cron 표현식 파싱 오류: {str(cron_error)}")
                        raise ValueError(f"잘못된 Cron 표현식: {str(cron_error)}")
                else:
                    job["next_run"] = None
                    logger.info("작업 비활성화: 다음 실행 시간 설정 해제")
                
                logger.info(f"작업 ID {job_id}의 상태가 {status.is_active}로 업데이트됨")
                break
        
        if not found:
            logger.warning(f"작업 ID를 찾을 수 없음: {job_id}")
            raise ValueError(f"작업 ID를 찾을 수 없음: {job_id}")
        
        # 파일에 저장
        try:
            with open(SCHEDULED_JOBS_FILE, "w", encoding="utf-8") as f:
                # datetime 객체를 문자열로 변환 (이미 문자열인 경우 그대로 유지)
                for j in jobs:
                    # last_run과 next_run이 이미 문자열인지 확인
                    if "last_run" in j and j["last_run"] and not isinstance(j["last_run"], str):
                        j["last_run"] = j["last_run"].isoformat() if isinstance(j["last_run"], datetime) else str(j["last_run"])
                    if "next_run" in j and j["next_run"] and not isinstance(j["next_run"], str):
                        j["next_run"] = j["next_run"].isoformat() if isinstance(j["next_run"], datetime) else str(j["next_run"])
                
                json.dump(jobs, f, ensure_ascii=False, indent=2)
                logger.info("작업 목록 파일에 저장 성공")
        except Exception as file_error:
            logger.error(f"파일 저장 오류: {str(file_error)}")
            raise IOError(f"작업 목록 파일 저장 오류: {str(file_error)}")
        
        logger.info(f"예약 작업 상태 업데이트 완료: {job_id}")
        return {"id": job_id, "is_active": status.is_active}
    
    except ValueError as ve:
        # 이미 로깅된 검증 오류 - 다시 발생
        logger.error(f"작업 검증 오류: {str(ve)}")
        raise
    
    except Exception as e:
        # 예상치 못한 오류
        logger.error(f"예약 작업 상태 업데이트 중 오류 발생: {str(e)}", exc_info=True)
        raise ValueError(f"예약 작업 처리 오류: {str(e)}")

# 예약 작업 관련 라우트
@app.get("/api/scheduled-jobs", response_model=List[ScheduledJob])
async def list_scheduled_jobs():
    """모든 예약 작업 목록 조회"""
    jobs = get_all_scheduled_jobs()
    
    # datetime 문자열을 datetime 객체로 변환
    for job in jobs:
        if "last_run" in job and job["last_run"]:
            try:
                job["last_run"] = datetime.fromisoformat(job["last_run"])
            except (ValueError, TypeError):
                job["last_run"] = None
        if "next_run" in job and job["next_run"]:
            try:
                job["next_run"] = datetime.fromisoformat(job["next_run"])
            except (ValueError, TypeError):
                job["next_run"] = None
    
    return jobs

@app.get("/api/scheduled-jobs/{job_id}", response_model=ScheduledJob)
async def get_scheduled_job_by_id(job_id: str):
    """특정 예약 작업 조회"""
    job = get_scheduled_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail=f"작업 ID {job_id}를 찾을 수 없습니다.")
    return job

@app.post("/api/scheduled-jobs", response_model=ScheduledJob)
async def create_scheduled_job(job: ScheduledJob):
    """새 예약 작업 생성"""
    try:
        logger.info(f"새 예약 작업 생성 요청: {job.name}")
        return add_scheduled_job(job)
    except ValueError as ve:
        logger.error(f"예약 작업 생성 유효성 오류: {str(ve)}")
        raise HTTPException(status_code=422, detail=str(ve))
    except Exception as e:
        logger.error(f"예약 작업 생성 중 오류 발생: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.put("/api/scheduled-jobs/{job_id}", response_model=ScheduledJob)
async def update_scheduled_job_by_id(job_id: str, job: ScheduledJob):
    """기존 예약 작업 업데이트"""
    try:
        logger.info(f"예약 작업 업데이트 요청: {job_id}")
        return update_scheduled_job(job_id, job)
    except ValueError as ve:
        logger.error(f"예약 작업 업데이트 유효성 오류: {str(ve)}")
        raise HTTPException(status_code=422, detail=str(ve))
    except Exception as e:
        logger.error(f"예약 작업 업데이트 중 오류 발생: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.delete("/api/scheduled-jobs/{job_id}")
async def delete_scheduled_job_by_id(job_id: str):
    """예약 작업 삭제"""
    try:
        logger.info(f"예약 작업 삭제 요청: {job_id}")
        return delete_scheduled_job(job_id)
    except ValueError as ve:
        logger.error(f"예약 작업 삭제 유효성 오류: {str(ve)}")
        raise HTTPException(status_code=422, detail=str(ve))
    except Exception as e:
        logger.error(f"예약 작업 삭제 중 오류 발생: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@app.patch("/api/scheduled-jobs/{job_id}/status")
async def update_job_status(job_id: str, status: ScheduledJobStatus):
    """예약 작업 활성화/비활성화"""
    try:
        logger.info(f"예약 작업 상태 변경 요청: {job_id}, 활성화: {status.is_active}")
        return update_scheduled_job_status(job_id, status)
    except ValueError as ve:
        logger.error(f"예약 작업 상태 변경 유효성 오류: {str(ve)}")
        raise HTTPException(status_code=422, detail=str(ve))
    except Exception as e:
        logger.error(f"예약 작업 상태 변경 중 오류 발생: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

# 주기적인 작업 정리 함수
def cleanup_old_jobs():
    """30일 이상 지난 작업 자동 정리"""
    try:
        logger.info("오래된 작업 정리 시작...")
        # load_jobs 함수 내에서 자동 정리 수행
        jobs = load_jobs()
        logger.info(f"작업 정리 완료. 현재 {len(jobs)}개의 작업이 유지되고 있습니다.")
    except Exception as e:
        logger.error(f"작업 정리 중 오류 발생: {e}")

# 애플리케이션 시작 시 실행
@app.on_event("startup")
async def startup_event():
    """애플리케이션 시작 시 실행되는 이벤트 핸들러"""
    try:
        # 데이터 디렉토리 확인
        os.makedirs(os.path.dirname(JOBS_HISTORY_FILE), exist_ok=True)
        os.makedirs(os.path.dirname(SCHEDULED_JOBS_FILE), exist_ok=True)
        
        # 스케줄러 초기화
        init_scheduler()
        
        # 오래된 작업 정리 (시작 시 한 번 실행)
        cleanup_old_jobs()
        
        # 매일 자정에 오래된 작업 정리하도록 스케줄링
        schedule.every().day.at("00:00").do(cleanup_old_jobs)
        
        logger.info(f"애플리케이션이 시작되었습니다. 작업 보관 기간: {JOB_RETENTION_DAYS}일")
    except Exception as e:
        logger.error(f"애플리케이션 시작 중 오류 발생: {e}")

@app.on_event("shutdown")
async def shutdown_event():
    """애플리케이션 종료 시 실행되는 이벤트 핸들러"""
    try:
        # 스케줄러 스레드 종료
        scheduler_stop_flag.set()
        if scheduler_thread.is_alive():
            scheduler_thread.join(timeout=2.0)
            
        logger.info("애플리케이션이 정상적으로 종료되었습니다.")
    except Exception as e:
        logger.error(f"애플리케이션 종료 중 오류 발생: {e}")

# 서버 실행
if __name__ == "__main__":
    # 현재 실행 파일의 디렉토리 경로 확인
    current_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 만약 현재 디렉토리가 apps/crawler_api가 아니라면 해당 디렉토리로 이동
    if os.path.basename(current_dir) == "crawler_api":
        os.chdir(current_dir)
        print(f"작업 디렉토리가 '{current_dir}'로 변경되었습니다.")
    else:
        crawler_api_dir = None
        # 현재 디렉토리의 부모 경로가 apps이고 crawler_api 디렉토리가 있는지 확인
        parent_dir = os.path.dirname(current_dir)
        if os.path.basename(parent_dir) == "apps" and os.path.exists(os.path.join(parent_dir, "crawler_api")):
            crawler_api_dir = os.path.join(parent_dir, "crawler_api")
            os.chdir(crawler_api_dir)
            print(f"작업 디렉토리가 '{crawler_api_dir}'로 변경되었습니다.")
        else:
            # 모든 상위 디렉토리에서 apps/crawler_api 경로 찾기
            search_dir = current_dir
            found = False
            
            # 루트 디렉토리까지 탐색
            while search_dir != os.path.dirname(search_dir):  # 루트 디렉토리에 도달할 때까지
                apps_dir = os.path.join(search_dir, "apps")
                if os.path.exists(apps_dir) and os.path.exists(os.path.join(apps_dir, "crawler_api")):
                    crawler_api_dir = os.path.join(apps_dir, "crawler_api")
                    os.chdir(crawler_api_dir)
                    print(f"작업 디렉토리가 '{crawler_api_dir}'로 변경되었습니다.")
                    found = True
                    break
                search_dir = os.path.dirname(search_dir)
            
            if not found:
                print("경고: apps/crawler_api 디렉토리를 찾을 수 없습니다.")
                print(f"현재 작업 디렉토리: {os.getcwd()}")
    
    # 작업 디렉토리에 필요한 하위 디렉토리 생성
    os.makedirs("logs", exist_ok=True)
    os.makedirs("jobs", exist_ok=True)
    os.makedirs("data", exist_ok=True)
    os.makedirs("output", exist_ok=True)
    
    # 서버 실행
    uvicorn.run("admin_api:app", host="0.0.0.0", port=8000, reload=True) 