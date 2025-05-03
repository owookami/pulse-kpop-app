# Pulse - K-Pop 팬캠 앱

## 소개
Pulse는 K-Pop 팬캠 영상을 쉽게 찾고, 저장하고, 평가할 수 있는 모바일 앱입니다. 팬들이 좋아하는 아티스트의 영상을 발견하고 관리할 수 있는 플랫폼을 제공합니다.

## 기술 스택
- **프론트엔드**: Flutter, Dart, Riverpod
- **백엔드**: Supabase, FastAPI, Python
- **데이터베이스**: PostgreSQL
- **인프라**: Docker, GitHub Actions

## 주요 기능
- 인기 K-Pop 팬캠 영상 탐색
- 아티스트별 영상 검색 및 필터링
- 영상 평가 (별점, 좋아요/싫어요)
- 북마크 및 컬렉션 관리
- 아티스트 팔로우 기능
- YouTube 통합 재생

## 설치 및 설정

### 사전 요구사항
- Flutter SDK 3.10 이상
- Dart SDK 3.0 이상
- Python 3.9 이상 (백엔드용)
- Docker (선택 사항)

### 모바일 앱 설정
```bash
# 저장소 클론
git clone https://github.com/your-username/pulse.git
cd pulse

# 의존성 설치
cd apps/mobile
flutter pub get

# 앱 실행
flutter run
```

### 백엔드 API 설정
```bash
# API 디렉토리로 이동
cd apps/crawler_api

# 가상 환경 설정
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 환경 변수 설정
cp .env.example .env
# .env 파일을 편집하여 필요한 키 추가

# API 서버 실행
python app/main.py
```

## 개발 시작하기
1. 저장소를 포크하고 클론하세요
2. 최신 `main` 브랜치에서 새 브랜치를 생성하세요
3. 변경사항을 구현하세요
4. 테스트를 실행하세요
5. Pull Request를 제출하세요

## 라이선스
이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 기여자
- 첫 번째 기여자
- 두 번째 기여자 