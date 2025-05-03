# Pulse 데이터 크롤러 API

이 저장소는 Pulse 앱을 위한 YouTube 데이터 크롤러 및 데이터 수집 도구를 포함하고 있습니다.

## 개요

Pulse 크롤러는 K-POP 아티스트의 팬캠 동영상과 관련 데이터를 YouTube에서 수집하여 Pulse 데이터베이스에 저장합니다. 이 도구는 다음과 같은 기능을 제공합니다:

- 특정 아티스트, 그룹 또는 이벤트에 대한 팬캠 비디오 검색
- 검색 결과를 CSV 또는 JSON 형식으로 저장
- 비디오 썸네일 다운로드
- 데이터베이스에 수집된 데이터 저장
- 자동화된 주기적 데이터 수집 지원

## 시작하기

### 요구사항

- Python 3.8 이상
- YouTube Data API v3 키

### 설치

```bash
# 저장소 복제
git clone https://github.com/your-organization/pulse-crawler.git
cd pulse-crawler

# 가상 환경 설정
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 또는
venv\Scripts\activate  # Windows

# 의존성 설치
pip install -r requirements.txt

# 환경 변수 설정
cp .env.example .env
# .env 파일을 편집하여 API 키와 데이터베이스 정보 추가
```

## 사용 방법

### 기본 실행

```bash
python run_crawler.py
```

### 특정 아티스트 데이터 수집

```bash
python run_crawler.py --artist "아티스트명"
```

### 특정 그룹 데이터 수집

```bash
python run_crawler.py --group "그룹명"
```

### 모든 옵션 조합 예시

```bash
python run_crawler.py --artist "아티스트명" --group "그룹명" --event "음악방송명" --start-date "2023-01-01" --end-date "2023-12-31" --limit 100 --output "./data" --format "json" --download-thumbnails --save-to-db
```

## 주요 파일

- `run_crawler.py`: 메인 크롤러 실행 스크립트
- `basic_crawler.py`: YouTube API 크롤링 핵심 로직
- `requirements.txt`: 필요한 Python 패키지 목록
- `.env.example`: 환경 변수 설정 예시
- `manual.md`: 상세 사용 매뉴얼

## 상세 매뉴얼

자세한 사용 방법 및 API 레퍼런스는 [manual.md](manual.md) 파일을 참조하세요.

## 라이선스

이 프로젝트는 내부용으로 개발되었으며, 모든 권리는 Pulse 앱 개발팀에 있습니다.

## 기여

내부 개발팀은 이슈 트래커를 통해 버그를 보고하거나 기능 요청을 할 수 있습니다.

## 연락처

- 개발팀: dev@pulseapp.com
- 이슈 트래커: https://github.com/your-organization/pulse-crawler/issues 