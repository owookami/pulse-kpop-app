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

# Google Play Store 자동 배포 설정 가이드

이 프로젝트는 GitHub Actions를 사용하여 Google Play Store에 자동으로 앱을 배포할 수 있습니다.

## 사전 준비 사항

1. **Google Play 개발자 계정**
   - [Google Play Console](https://play.google.com/console)에서 개발자 계정이 필요합니다.
   - 개발자 계정 등록비 $25(일회성)가 필요합니다.

2. **서비스 계정 설정**
   - Google Play Console에서 API 액세스를 위한 서비스 계정을 생성해야 합니다.
   - Google Play Console > 설정 > 개발자 계정 > API 액세스 > 서비스 계정 생성
   - JSON 키를 다운로드하여 안전하게 보관

3. **앱 서명 키 생성**
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

## GitHub Secrets 설정

GitHub 저장소에 다음 보안 정보를 설정해야 합니다:

1. GitHub 저장소 > Settings > Secrets and variables > Actions에서 다음 값들을 추가:
   - `KEYSTORE_JKS_BASE64`: 키스토어 파일을 base64로 인코딩한 문자열
     ```bash
     base64 -i upload-keystore.jks
     ```
   - `KEYSTORE_PASSWORD`: 키스토어 비밀번호
   - `KEY_PASSWORD`: 키 비밀번호
   - `KEY_ALIAS`: 키 별칭 (예: 'upload')
   - `PLAY_STORE_SERVICE_ACCOUNT_JSON`: 서비스 계정의 JSON 키 내용

## 배포 방법

앱을 새 버전으로 배포하려면 다음 중 하나를 수행하세요:

1. **새 태그 푸시**:
   ```bash
   git tag v1.0.0  # 버전 형식: v{major}.{minor}.{patch}
   git push origin v1.0.0
   ```

2. **수동 실행**:
   - GitHub 저장소 > Actions > Android Release 워크플로우 > Run workflow 버튼 클릭

## 배포 트랙 변경

GitHub Actions의 워크플로우 파일(.github/workflows/android-release.yml)에서 다음 부분을 수정하여 배포 트랙을 변경할 수 있습니다:

```yaml
track: production  # 'internal', 'alpha', 'beta', 'production' 중 선택
```

테스트를 위해서는 'internal' 트랙부터 시작하는 것을 권장합니다. 