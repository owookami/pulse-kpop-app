# Pulse 데이터 수집 매뉴얼

## 개요

이 문서는 Pulse 앱을 위한 데이터 수집 파이썬 크롤러의 설치 및 사용 방법을 설명합니다. 이 크롤러는 K-POP 아티스트의 팬캠 동영상과 관련 데이터를 수집하여 Pulse 데이터베이스에 저장합니다.

## 1. 환경 설정

### 1.1 요구사항

- Python 3.8 이상
- pip (Python 패키지 관리자)
- 가상 환경 관리 도구 (권장: virtualenv 또는 conda)

### 1.2 필수 라이브러리

```
requests
beautifulsoup4
selenium
python-dotenv
pymongo (MongoDB 사용 시)
psycopg2 (PostgreSQL 사용 시)
google-api-python-client (YouTube API 사용 시)
pandas
tqdm
fastapi
uvicorn
jinja2
```

## 2. 설치 방법

### 2.1 저장소 복제

```bash
git clone https://github.com/your-organization/pulse-crawler.git
cd pulse-crawler
```

### 2.2 가상 환경 설정

```bash
# virtualenv 사용 시
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 또는
venv\Scripts\activate  # Windows

# conda 사용 시
conda create -n pulse-crawler python=3.9
conda activate pulse-crawler
```

### 2.3 의존성 설치

```bash
pip install -r requirements.txt
```

### 2.4 환경 변수 설정

`.env` 파일을 생성하고 다음과 같이 설정합니다:

```
# 데이터베이스 설정
DB_TYPE=postgresql # 또는 mongodb
DB_HOST=localhost
DB_PORT=5432
DB_NAME=pulse
DB_USER=username
DB_PASSWORD=password

# MongoDB 설정 (DB_TYPE이 mongodb인 경우)
MONGO_URI=mongodb://localhost:27017/

# YouTube API 키 (필수)
YOUTUBE_API_KEY=your_youtube_api_key

# 로깅 설정
LOG_LEVEL=INFO

# 기타 설정
MAX_THREADS=4
DEFAULT_LIMIT=50
```

## 3. 크롤러 실행 방법

### 3.1 기본 실행

```bash
python run_crawler.py
```

### 3.2 특정 아티스트 데이터 수집

```bash
python run_crawler.py --artist "아티스트명"
```

### 3.3 특정 그룹 데이터 수집

```bash
python run_crawler.py --group "그룹명"
```

### 3.4 특정 기간 데이터 수집

```bash
python run_crawler.py --start-date "YYYY-MM-DD" --end-date "YYYY-MM-DD"
```

### 3.5 모든 매개변수 조합 예시

```bash
python run_crawler.py --artist "아티스트명" --group "그룹명" --start-date "2023-01-01" --end-date "2023-12-31" --limit 100 --skip-existing
```

## 4. 웹 어드민 인터페이스 사용법

크롤러를 쉽게 관리하고 모니터링하기 위한 웹 기반 관리자 패널이 제공됩니다.

### 4.1 웹 어드민 서버 시작

```bash
# 리눅스/윈도우
python start_admin.py

# macOS
python3 start_admin.py
```

이 명령어는 기본적으로 8000번 포트에서 웹 서버를 시작하고 자동으로 브라우저를 열어 관리자 페이지를 표시합니다.

#### 추가 옵션:

```bash
# 다른 포트 사용
python start_admin.py --port 8080

# 브라우저 자동 실행 안 함
python start_admin.py --no-browser

# 특정 호스트에서 실행 (기본값: 0.0.0.0)
python start_admin.py --host 127.0.0.1
```

### 4.2 관리자 대시보드 기능

#### 4.2.1 대시보드

대시보드에서는 다음과 같은 정보를 확인할 수 있습니다:
- 총 크롤링 작업 수
- 완료된 작업 수
- 실행 중인 작업 수
- 실패한 작업 수
- 최근 5개 작업 목록

#### 4.2.2 새 크롤링 작업

이 페이지에서는 새로운 크롤링 작업을 설정하고 실행할 수 있습니다:
- 아티스트 선택
- 그룹 선택
- 이벤트(무대) 이름 지정
- 검색 결과 수 설정
- 날짜 범위 설정
- 출력 형식 선택
- 데이터베이스 저장 여부
- 썸네일 다운로드 여부
- 중복 건너뛰기 여부

#### 4.2.3 작업 목록

모든 크롤링 작업의 전체 목록을 확인할 수 있으며, 각 작업에 대해 다음 작업이 가능합니다:
- 상세 정보 확인
- 완료되거나 실패한 작업 삭제

#### 4.2.4 아티스트 관리

시스템에 등록된 모든 아티스트 목록을 확인할 수 있습니다.

#### 4.2.5 그룹 관리

시스템에 등록된 모든 그룹 목록을 확인할 수 있습니다.

#### 4.2.6 예약 작업 관리

정기적으로 실행되는 크롤링 작업을 예약하고 관리할 수 있습니다:

- 작업 이름 설정
- Cron 표현식을 사용한 일정 지정 (예: 매일 00:00, 매주 월요일 09:00)
- 검색 매개변수 설정 (아티스트, 그룹, 이벤트 등)
- 작업 활성화/비활성화
- 데이터베이스 저장 여부 설정

##### Cron 표현식 사용법

Cron 표현식은 다음 형식을 가집니다: `분 시 일 월 요일`

- **분**: 0-59
- **시**: 0-23
- **일**: 1-31
- **월**: 1-12 (또는 JAN-DEC)
- **요일**: 0-6 (일요일=0 또는 7, 또는 SUN-SAT)

예시:
- `0 0 * * *`: 매일 자정 (00:00)
- `0 9 * * 1`: 매주 월요일 09:00
- `0 0 1 * *`: 매월 1일 00:00
- `0 12 * * 1-5`: 평일(월-금) 정오 12:00
- `0 0 1 1 *`: 매년 1월 1일 00:00

Cron 표현식 도움말은 [https://crontab.guru/](https://crontab.guru/)에서 확인할 수 있습니다.

#### 4.2.7 설정

시스템 설정 정보를 확인할 수 있습니다:
- 데이터베이스 유형
- YouTube API 키
- 기타 환경 변수 설정

### 4.3 작업 모니터링 및 관리

#### 4.3.1 작업 상세 정보 확인

작업 목록에서 '상세' 버튼을 클릭하면 다음과 같은 정보를 확인할 수 있습니다:
- 작업 기본 정보 (ID, 상태, 시작/종료 시간)
- 검색 매개변수
- 작업 결과 (성공 시)
- 생성된 파일 목록 (있는 경우)
- 오류 메시지 (실패 시)

#### 4.3.2 작업 삭제

작업이 더 이상 필요하지 않은 경우, 작업 목록에서 '삭제' 버튼을 클릭하여 삭제할 수 있습니다. 단, 실행 중이거나 대기 중인 작업은 삭제할 수 없습니다.

## 5. 추가 기능

### 5.1 데이터 내보내기

```bash
python export_data.py --format csv --output ./exports
```

지원 형식: csv, json, excel

### 5.2 데이터 검증

```bash
python validate_data.py
```

### 5.3 썸네일 일괄 다운로드

```bash
python download_thumbnails.py --output ./thumbnails
```

## 6. 문제 해결

### 6.1 일반적인 오류

- **API 할당량 초과**: YouTube API를 사용할 때 발생할 수 있습니다. 24시간 후에 다시 시도하세요.
- **네트워크 연결 오류**: 인터넷 연결을 확인하세요.
- **데이터베이스 연결 오류**: DB 자격 증명과 연결 정보를 확인하세요.

### 6.2 로그 확인

로그 파일은 `logs` 디렉토리에 저장됩니다:

```bash
# 크롤러 로그
cat logs/crawler.log

# 웹 어드민 API 로그
cat logs/admin_api.log

# 웹 어드민 시작 스크립트 로그
cat logs/admin.log

# 특정 작업 로그
cat logs/crawler_<작업ID>.log
```

### 6.3 웹 어드민 문제 해결

- **서버 시작 실패**: 포트가 이미 사용 중인지 확인하세요. `--port` 옵션으로 다른 포트를 지정할 수 있습니다.
- **API 요청 실패**: 로그를 확인하고 네트워크 연결이 정상인지 확인하세요.
- **백그라운드 작업 실패**: 크롤러 로그 파일을 확인하여 자세한 오류 메시지를 확인하세요.

## 7. 예약 작업 설정 및 관리 (명령줄)

웹 어드민 패널 외에도 명령줄에서 예약 작업을 설정하고 관리할 수 있습니다.

### 7.1 예약 작업 추가

```bash
python schedule_job.py --name "매일_블랙핑크_팬캠" --cron "0 0 * * *" --artist "블랙핑크" --limit 20 --save-to-db
```

### 7.2 예약 작업 목록 확인

```bash
python schedule_job.py --list
```

### 7.3 예약 작업 삭제

```bash
python schedule_job.py --delete <job_id>
```

### 7.4 예약 작업 활성화/비활성화

```bash
# 활성화
python schedule_job.py --enable <job_id>

# 비활성화
python schedule_job.py --disable <job_id>
```

### 7.5 서비스로 등록하기

크론 작업 스케줄러를 시스템 서비스로 등록하려면:

#### Linux (systemd)

```bash
sudo nano /etc/systemd/system/pulse-crawler-scheduler.service
```

파일 내용:
```
[Unit]
Description=Pulse Crawler Scheduler Service
After=network.target

[Service]
User=<your_username>
WorkingDirectory=/path/to/crawler_api
ExecStart=/usr/bin/python3 /path/to/crawler_api/scheduler_daemon.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

서비스 활성화 및 시작:
```bash
sudo systemctl daemon-reload
sudo systemctl enable pulse-crawler-scheduler
sudo systemctl start pulse-crawler-scheduler
```

#### macOS (launchd)

```bash
nano ~/Library/LaunchAgents/com.pulse.crawler-scheduler.plist
```

파일 내용:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.pulse.crawler-scheduler</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/path/to/crawler_api/scheduler_daemon.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>/path/to/crawler_api</string>
    <key>StandardErrorPath</key>
    <string>/path/to/crawler_api/logs/scheduler_error.log</string>
    <key>StandardOutPath</key>
    <string>/path/to/crawler_api/logs/scheduler_output.log</string>
</dict>
</plist>
```

서비스 로드 및 시작:
```bash
launchctl load ~/Library/LaunchAgents/com.pulse.crawler-scheduler.plist
```

#### Windows

Windows Task Scheduler를 사용하여 등록하거나, NSSM(Non-Sucking Service Manager)을 사용하여 서비스로 등록할 수 있습니다.

```bash
nssm install PulseCrawlerScheduler "C:\path\to\python.exe" "C:\path\to\crawler_api\scheduler_daemon.py"
nssm set PulseCrawlerScheduler AppDirectory "C:\path\to\crawler_api"
nssm start PulseCrawlerScheduler
```

## 8. 문제 해결

### 8.1 일반적인 오류

- **API 할당량 초과**: YouTube API를 사용할 때 발생할 수 있습니다. 24시간 후에 다시 시도하세요.
- **네트워크 연결 오류**: 인터넷 연결을 확인하세요.
- **데이터베이스 연결 오류**: DB 자격 증명과 연결 정보를 확인하세요.

### 8.2 로그 확인

로그 파일은 `logs` 디렉토리에 저장됩니다:

```bash
# 크롤러 로그
cat logs/crawler.log

# 웹 어드민 API 로그
cat logs/admin_api.log

# 웹 어드민 시작 스크립트 로그
cat logs/admin.log

# 특정 작업 로그
cat logs/crawler_<작업ID>.log
```

### 8.3 웹 어드민 문제 해결

- **서버 시작 실패**: 포트가 이미 사용 중인지 확인하세요. `--port` 옵션으로 다른 포트를 지정할 수 있습니다.
- **API 요청 실패**: 로그를 확인하고 네트워크 연결이 정상인지 확인하세요.
- **백그라운드 작업 실패**: 크롤러 로그 파일을 확인하여 자세한 오류 메시지를 확인하세요.

## 9. 자동화 설정

### 9.1 Cron 작업 설정 (Linux/Mac)

매일 자정에 크롤러를 실행하는 Cron 작업 예시:

```bash
0 0 * * * cd /path/to/pulse-crawler && source venv/bin/activate && python run_crawler.py >> logs/cron.log 2>&1
```

### 9.2 작업 스케줄러 설정 (Windows)

Windows 작업 스케줄러를 사용하여 정기적인 크롤링 작업을 설정할 수 있습니다.

## 10. 데이터 구조

수집된 데이터는 다음과 같은 구조로 데이터베이스에 저장됩니다:

### 10.1 비디오 (videos)

- id: 비디오 고유 ID
- title: 비디오 제목
- description: 비디오 설명
- videoUrl: 비디오 URL
- thumbnailUrl: 썸네일 URL
- artistId: 아티스트 ID (외래 키)
- eventId: 이벤트 ID (외래 키, 있는 경우)
- recordedDate: 녹화 날짜
- viewCount: 조회수
- likeCount: 좋아요 수
- createdAt: 생성 날짜
- updatedAt: 업데이트 날짜

### 10.2 아티스트 (artists)

- id: 아티스트 고유 ID
- name: 아티스트 이름
- groupName: 그룹 이름 (해당되는 경우)
- imageUrl: 아티스트 이미지 URL
- createdAt: 생성 날짜
- updatedAt: 업데이트 날짜

### 10.3 이벤트 (events)

- id: 이벤트 고유 ID
- name: 이벤트 이름
- date: 이벤트 날짜
- venue: 이벤트 장소
- createdAt: 생성 날짜
- updatedAt: 업데이트 날짜

## 11. 라이선스 및 법적 고려사항

이 크롤러는 교육 및 연구 목적으로만 사용해야 합니다. 항상 다음 사항을 준수하세요:

- 각 플랫폼의 이용 약관을 존중합니다.
- robots.txt 파일을 준수합니다.
- 과도한 요청으로 서버에 부담을 주지 않습니다.
- 수집한 데이터의 개인정보 보호 규정을 준수합니다.

## 12. 기여 방법

프로젝트에 기여하려면 다음 단계를 따르세요:

1. 저장소를 포크합니다.
2. 새 브랜치를 만듭니다: `git checkout -b feature/your-feature-name`
3. 변경 사항을 커밋합니다: `git commit -m 'Add some feature'`
4. 브랜치를 푸시합니다: `git push origin feature/your-feature-name`
5. Pull Request를 제출합니다.

## 13. 연락처

문제가 발생하거나 질문이 있는 경우 다음 연락처로 문의하세요:
- 이메일: support@pulsapp.com
- 이슈 트래커: https://github.com/your-organization/pulse-crawler/issues 