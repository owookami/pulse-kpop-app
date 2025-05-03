# Pulse 앱 실행 및 운영 매뉴얼

## 목차
1. 시스템 요구사항
2. 프로젝트 구조 개요
3. 개발 환경 설정
4. 백엔드 서비스 구성
5. 모바일 앱 실행
6. 데이터 관리
7. 일반적인 문제 해결

## 1. 시스템 요구사항

### 필수 소프트웨어
- Flutter SDK: 3.0.0 이상
- Dart SDK: 3.0.0 이상
- Node.js: 16.0.0 이상 (Supabase CLI용)
- Git: 최신 버전
- VS Code 또는 Android Studio (권장 IDE)

### 하드웨어 요구사항
- RAM: 8GB 이상 권장
- 저장 공간: 최소 5GB 여유 공간
- 모바일 기기 또는 에뮬레이터 (iOS/Android)

## 2. 프로젝트 구조 개요

Pulse는 Flutter/Dart 기반 모노레포 구조로 구성되어 있습니다:

```
pulse/
├── apps/
│   └── mobile/        # 메인 Flutter 앱
├── packages/
│   ├── api_client/    # Supabase API 클라이언트
│   ├── ui_kit/        # 공통 UI 컴포넌트
│   └── core/          # 공유 유틸리티 및 모델
├── scripts/           # 유틸리티 스크립트
└── supabase/          # Supabase 설정 및 스키마
```

## 3. 개발 환경 설정

### 초기 설정

1. **리포지토리 복제하기**:
   ```bash
   git clone https://github.com/owookami/pulse.git
   cd pulse
   ```

2. **Flutter SDK 설치 확인**:
   ```bash
   flutter --version
   ```
   Flutter 3.0.0 이상, Dart 3.0.0 이상이 필요합니다.

3. **종속성 설치**:
   ```bash
   # 루트 디렉토리에서
   flutter pub get
   
   # 모바일 앱 디렉토리에서
   cd apps/mobile
   flutter pub get
   
   # API 클라이언트 디렉토리에서
   cd ../../packages/api_client
   flutter pub get
   ```

4. **환경 변수 설정**:
   `apps/mobile/.env` 파일을 생성하고 다음 내용을 추가합니다:
   ```
   SUPABASE_URL=https://your-supabase-project-url.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   ```

5. **코드 생성 실행**:
   ```bash
   # 모바일 앱 디렉토리에서
   cd apps/mobile
   dart run build_runner build --delete-conflicting-outputs
   
   # API 클라이언트 디렉토리에서
   cd ../../packages/api_client
   dart run build_runner build --delete-conflicting-outputs
   ```

## 4. 백엔드 서비스 구성

### Supabase 셋업

1. **Supabase 프로젝트 생성**:
   - [Supabase 대시보드](https://app.supabase.io)에 로그인합니다.
   - '새 프로젝트'를 클릭하고 프로젝트 이름을 입력합니다.
   - 데이터베이스 비밀번호를 설정하고 지역을 선택합니다.
   - '프로젝트 생성'을 클릭합니다.

2. **데이터베이스 스키마 설정**:
   - `supabase/schema.sql` 파일에 있는 SQL을 복사합니다.
   - Supabase 대시보드의 SQL 편집기에 붙여넣고 실행합니다.

3. **API 키 확인**:
   - 대시보드의 '설정 > API' 섹션에서 URL과 anon key를 확인합니다.
   - 이 값들을 `apps/mobile/.env` 파일에 입력합니다.

4. **인증 설정**:
   - 대시보드의 '인증 > 제공자' 섹션에서 이메일 인증을 활성화합니다.
   - 이메일 템플릿을 원하는 대로 커스터마이징합니다.

### 초기 데이터 로드

1. **아티스트 데이터 추가**:
   ```sql
   INSERT INTO artists (id, name, group_name, profile_image_url)
   VALUES 
     ('1', 'Jisoo', 'BLACKPINK', 'https://example.com/jisoo.jpg'),
     ('2', 'Jennie', 'BLACKPINK', 'https://example.com/jennie.jpg');
   ```

2. **비디오 데이터 추가**:
   ```sql
   INSERT INTO videos (id, title, artist_id, thumbnail_url, video_url, platform, platform_id)
   VALUES
     ('1', 'BLACKPINK - Pink Venom (Jisoo Focus)', '1', 'https://example.com/thumbnail1.jpg', 'https://www.youtube.com/watch?v=abcdef', 'youtube', 'abcdef'),
     ('2', 'BLACKPINK - Shut Down (Jennie Focus)', '2', 'https://example.com/thumbnail2.jpg', 'https://www.youtube.com/watch?v=ghijkl', 'youtube', 'ghijkl');
   ```

## 5. 모바일 앱 실행

### 앱 실행 방법

1. **에뮬레이터 또는 실제 기기 연결**:
   ```bash
   flutter devices
   ```
   실행 가능한 기기 목록을 확인합니다.

2. **앱 실행**:
   ```bash
   # 모바일 앱 디렉토리에서
   cd apps/mobile
   flutter run
   ```
   특정 기기를 선택하려면:
   ```bash
   flutter run -d device_id
   ```

3. **릴리스 빌드 생성**:
   
   **Android**:
   ```bash
   flutter build apk --release
   # 또는 App Bundle
   flutter build appbundle --release
   ```
   
   **iOS**:
   ```bash
   flutter build ios --release
   # 그 다음 Xcode에서 Archive 과정을 진행
   ```

### 중요 화면 및 기능

1. **로그인/회원가입**: 이메일과 비밀번호로 계정을 생성하거나 로그인합니다.
2. **홈 피드**: 인기 팬캠 비디오를 확인할 수 있습니다.
3. **검색**: 아티스트 또는 비디오 검색이 가능합니다.
4. **북마크**: 즐겨찾기한 비디오를 관리합니다.
5. **프로필**: 사용자 정보 및 설정을 관리합니다.
6. **비디오 플레이어**: 팬캠 비디오를 시청합니다.
7. **컬렉션 관리**: 북마크한 비디오를 컬렉션으로 구성합니다.
8. **For You**: 개인화된 추천 비디오를 확인합니다.

## 6. 데이터 관리

### 데이터베이스 관리

1. **테이블 구조**:
   - `users`: 사용자 계정 정보
   - `artists`: 아티스트 정보
   - `videos`: 팬캠 비디오 정보
   - `bookmarks`: 사용자 북마크
   - `bookmark_collections`: 북마크 컬렉션
   - `bookmark_items`: 컬렉션 내 북마크 항목

2. **백업 및 복원**:
   - Supabase 대시보드에서 정기적인 데이터베이스 백업을 설정합니다.
   - 중요한 업데이트 전에는 수동 백업을 실행하세요.

3. **데이터 마이그레이션**:
   ```bash
   # 루트 디렉토리에서
   cd supabase
   supabase db push
   ```

### 사용자 데이터 관리

1. **사용자 관리**:
   - Supabase 대시보드 > 인증 > 사용자에서 사용자 계정을 관리할 수 있습니다.
   - 계정 비활성화, 비밀번호 재설정 등의 작업을 수행할 수 있습니다.

2. **이용 통계**:
   - 대시보드에서 API 사용량, 인증 통계, 스토리지 사용량 등을 모니터링합니다.

## 7. 일반적인 문제 해결

### 빌드 오류

1. **종속성 충돌**:
   ```bash
   flutter clean
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **API 오류**:
   - 환경 변수가 올바르게 설정되었는지 확인합니다.
   - Supabase 프로젝트가 활성 상태인지 확인합니다.
   - 네트워크 연결을 확인합니다.

3. **코드 생성 오류**:
   - 모든 모델 클래스가 올바르게 정의되었는지 확인합니다.
   - 주석 형식이 정확한지 확인합니다.

### 런타임 오류

1. **인증 문제**:
   - Supabase 인증 설정을 확인합니다.
   - 로그인 과정에서 정확한 이메일과 비밀번호를 사용하는지 확인합니다.

2. **데이터 로딩 오류**:
   - 네트워크 연결을 확인합니다.
   - 로그에서 API 응답 오류를 확인합니다.
   - 테이블 권한 설정이 올바른지 확인합니다.

3. **UI 렌더링 문제**:
   - 기기의 Flutter 버전이 프로젝트 요구사항과 일치하는지 확인합니다.
   - 화면 크기에 따라 반응형 디자인이 올바르게 작동하는지 확인합니다.

### 로그 확인 방법

```bash
# 자세한 로그 출력
flutter run -v

# 로그 파일로 저장
flutter run 2>&1 | tee log.txt
```

## 부록: 유용한 명령어

```bash
# Flutter 버전 확인
flutter --version

# 프로젝트 진단
flutter doctor

# 캐시 정리
flutter clean

# 코드 생성
dart run build_runner build --delete-conflicting-outputs

# 특정 화면으로 앱 실행
flutter run --route=/login

# 성능 프로파일링
flutter run --profile
```

---

이 매뉴얼은 Pulse 앱 v1.0.0을 기준으로 작성되었습니다. 최신 정보는 프로젝트 리포지토리를 참조하세요. 