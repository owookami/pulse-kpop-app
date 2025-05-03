# Pulse 배포 가이드

이 문서는 Pulse 애플리케이션의 배포 프로세스에 대한 가이드를 제공합니다.

## 목차

1. [환경 설정](#환경-설정)
2. [CI/CD 파이프라인](#cicd-파이프라인)
3. [수동 배포 방법](#수동-배포-방법)
4. [배포 환경](#배포-환경)
5. [문제 해결](#문제-해결)

## 환경 설정

Pulse 애플리케이션을 배포하기 전에 다음 환경 설정이 필요합니다:

1. **환경 변수 설정**:
   - `.env.example` 파일을 복사하여 `.env` 파일 생성
   - 모든 필수 환경 변수 값 입력
   - 시크릿 설정 스크립트 실행: `./scripts/setup_secrets.sh`

2. **필수 도구 설치**:
   - Flutter SDK 3.10.0 이상
   - Dart SDK 3.0.0 이상
   - Melos
   - GitHub CLI (시크릿 설정용)
   - Firebase CLI (Firebase 배포용)

## CI/CD 파이프라인

Pulse는 다음과 같은 자동화된 CI/CD 파이프라인을 사용합니다:

### GitHub Actions

1. **코드 품질 검사** (`code_quality.yml`):
   - 모든 브랜치의 PR과 기본 브랜치 푸시에서 실행
   - 린트, 정적 분석, 테스트 실행

2. **Flutter 앱 빌드** (`flutter_workflow.yml`):
   - `main` 및 `develop` 브랜치에 푸시할 때 실행
   - Android APK/AAB 및 iOS IPA 빌드
   - Firebase App Distribution으로 테스트 빌드 배포 (develop 브랜치)

3. **Python 크롤러 서비스** (`python_workflow.yml`):
   - 크롤러 서비스의 코드 품질 검사, 테스트, 빌드, 배포
   - Docker 이미지 빌드 및 Google Kubernetes Engine 배포

### Codemagic

Codemagic CI/CD는 프로덕션 릴리스를 위해 사용됩니다:

1. **설정**:
   - `codemagic.yaml` 파일을 통해 워크플로우 구성
   - GitHub Actions에서 API를 통해 트리거 (`flutter_codemagic.yml`)

2. **기능**:
   - iOS/Android 앱 빌드
   - App Store Connect 및 Google Play 스토어 자동 배포
   - 팀 이메일 알림

## 수동 배포 방법

자동화된 파이프라인 외에도 수동 배포가 필요한 경우:

### 모바일 앱

1. **Android 빌드**:
   ```bash
   cd apps/mobile
   flutter build appbundle --flavor production --release
   ```

2. **iOS 빌드**:
   ```bash
   cd apps/mobile
   flutter build ios --flavor production --release --no-codesign
   ```

3. **Firebase 테스트 배포**:
   ```bash
   firebase appdistribution:distribute <빌드_파일_경로> --app <FIREBASE_APP_ID> --groups "testers"
   ```

### 크롤러 서비스

1. **Docker 이미지 빌드**:
   ```bash
   cd crawler
   docker build -t pulse-crawler:latest .
   ```

2. **Kubernetes 배포**:
   ```bash
   kubectl apply -f k8s/deployment.yaml
   ```

## 배포 환경

Pulse는 다음 환경을 지원합니다:

1. **개발 (Development)**:
   - 브랜치: `develop` 및 기능 브랜치
   - 환경 변수: `APP_ENV=development`
   - Firebase 테스트 배포

2. **스테이징 (Staging)**:
   - 브랜치: `staging`
   - 환경 변수: `APP_ENV=staging`
   - Codemagic 테스트플라이트/내부 테스트 트랙

3. **프로덕션 (Production)**:
   - 브랜치: `main`
   - 환경 변수: `APP_ENV=production`
   - 앱 스토어/플레이 스토어 배포

## 문제 해결

### 일반적인 배포 이슈

1. **인증서 문제 (iOS)**:
   - Codemagic 팀 설정에서 인증서와 프로비저닝 프로파일 확인
   - Apple Developer 계정 권한 확인

2. **Google Play API 액세스 (Android)**:
   - 서비스 계정 키 권한 확인
   - Google Play Console API 액세스 활성화 확인

3. **CI/CD 파이프라인 실패**:
   - GitHub Actions 및 Codemagic 로그 확인
   - 시크릿 및 환경 변수 설정 확인

### 도움 얻기

배포 과정에서 문제가 발생하면 다음을 통해 도움을 받을 수 있습니다:

- GitHub Issues에 문제 보고
- 팀 Slack 채널에서 배포 담당자에게 연락 