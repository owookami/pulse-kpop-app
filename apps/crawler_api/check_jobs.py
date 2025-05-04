#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import json
import subprocess
import datetime
from pathlib import Path

# 스케줄 파일 경로
SCHEDULED_JOBS_FILE = Path("data/scheduled_jobs.json")

def main():
    """스케줄 작업 디버깅"""
    print("스케줄 작업 디버깅 도구")
    
    # 저장된 스케줄 작업 로드
    if not SCHEDULED_JOBS_FILE.exists():
        print(f"파일이 존재하지 않음: {SCHEDULED_JOBS_FILE}")
        return
    
    try:
        with open(SCHEDULED_JOBS_FILE, "r", encoding="utf-8") as f:
            jobs = json.load(f)
        
        if not jobs:
            print("스케줄 작업이 없습니다.")
            return
            
        print(f"{len(jobs)}개의 스케줄 작업이 있습니다.")
        
        for i, job in enumerate(jobs):
            print(f"\n작업 {i+1}: {job['name']}")
            print(f"  ID: {job['id']}")
            print(f"  Cron 표현식: {job['cron_expression']}")
            print(f"  활성화: {job['is_active']}")
            
            params = job.get("params", {})
            print(f"  매개변수: {params}")
            
            last_run = job.get("last_run")
            if last_run:
                print(f"  마지막 실행: {last_run}")
                
            next_run = job.get("next_run")
            if next_run:
                print(f"  다음 실행: {next_run}")
                
            # 테스트 실행
            print("\n테스트 실행 중...")
            
            # Python 경로 설정 (파라미터에 있다면 그것을 사용하고, 없다면 기본값으로 /usr/bin/python3 사용)
            python_path = params.get("python_path", "/usr/bin/python3")
            cmd = [python_path, "run_crawler.py"]
            
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
                
            print(f"실행 명령: {' '.join(cmd)}")
                
            try:
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
                print(f"실행 결과 (코드: {result.returncode}):")
                print(f"  출력: {result.stdout[:500]}...")
                print(f"  오류: {result.stderr[:500]}...")
            except subprocess.TimeoutExpired:
                print("  실행 시간 초과 (5초)")
            except Exception as e:
                print(f"  실행 오류: {e}")
                
    except Exception as e:
        print(f"오류 발생: {e}")

if __name__ == "__main__":
    main() 