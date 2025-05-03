# Pulse Fan Cam 앱 MCP 개발 계획서

## 개요

이 문서는 "Pulse" K-POP 팬캠 허브 앱을 Task Master MCP를 활용하여 개발하기 위한 상세 작업 계획을 제공합니다. 모노레포 구조로 Flutter(GoRouter+Riverpod), Supabase, Python(FastAPI)을 활용하여 개발합니다.

## 프로젝트 기본 정보

- **프로젝트명**: Pulse Fan Cam
- **Supabase 프로젝트**: owookami/pulse
- **GitHub 저장소**: [Pulse Fan Cam](https://github.com/owookami/pulse)
- **모노레포 관리 도구**: Melos

## 모노레포 구조

```
pulse/
├── apps/
│   ├── mobile/        # Flutter 모바일 앱
│   └── admin/         # React Admin SPA
├── packages/
│   ├── core/          # 공통 모델, 유틸리티
│   ├── api_client/    # Supabase API 클라이언트
│   └── ui_kit/        # 공통 UI 컴포넌트
├── services/
│   ├── crawler/       # Python FastAPI 크롤러
│   └── functions/     # Supabase Edge Functions
├── infrastructure/    # IaC (Terraform)
└── tools/             # 개발 스크립트
```

## 상세 작업 계획

### 1. 프로젝트 초기화 및 환경 설정

#### 1.1 모노레포 기본 구조 설정

**작업 내용**: 모노레포 기본 구조를 설정하고 필요한 패키지와 도구를 설치합니다.

**세부 작업**:
1. GitHub 저장소 생성
2. Melos 설치 및 초기화
3. 기본 디렉토리 구조 구성
4. .gitignore 및 기본 설정 파일 구성
5. CI/CD 파이프라인 기본 설정(GitHub Actions)

**커밋 메시지**: "feat: Initialize monorepo structure with Melos"

**예상 소요 시간**: 2시간

#### 1.2 Supabase 프로젝트 설정

**작업 내용**: Supabase 프로젝트를 설정하고 기본 환경을 구성합니다.

**세부 작업**:
1. Supabase Cloud에서 'pulse' 프로젝트 생성
2. 기본 환경 변수 설정
3. 인증 및 권한 정책 구성
4. RLS(Row Level Security) 기본 정책 설정
5. API 키 및 연결 정보 안전하게 저장

**커밋 메시지**: "feat: Configure Supabase project and security policies"

**예상 소요 시간**: 2시간

#### 1.3 개발 환경 구성

**작업 내용**: 로컬 개발 환경 및 공유 설정을 구성합니다.

**세부 작업**:
1. VS Code 설정 및 권장 확장 구성
2. Flutter 개발 환경 설정
3. Python 가상 환경 설정
4. 환경 변수 관리를 위한 dotenv 설정
5. 공통 린트 규칙 및 포맷터 설정

**커밋 메시지**: "chore: Set up development environment and shared configs"

**예상 소요 시간**: 2시간

### 2. 데이터베이스 모델 구현

#### 2.1 Supabase 데이터베이스 스키마 설계

**작업 내용**: 문서에 명시된 DB 스키마를 Supabase에 구현합니다.

**세부 작업**:
1. artists 테이블 생성 및 인덱스 설정
2. videos 테이블 생성 및 인덱스 설정
3. reviews 테이블 생성 및 인덱스 설정
4. bookmarks 테이블 생성
5. follows 테이블 생성
6. 외래 키 제약 조건 설정
7. RLS 정책 구현

**커밋 메시지**: "feat: Implement Supabase database schema"

**예상 소요 시간**: 3시간

#### 2.2 권한 정책 및 데이터 접근 구성

**작업 내용**: 데이터 접근 및 보안 정책을 구성합니다.

**세부 작업**:
1. 인증된 사용자 정책 설정
2. reviews 테이블에 대한 "insert_once" 정책 구현
3. 공개 데이터와 사용자별 데이터 접근 정책 구성
4. 관리자 전용 액세스 정책 설정
5. API 접근 제한 및 요청 제한 설정

**커밋 메시지**: "feat: Configure database access policies and security rules"

**예상 소요 시간**: 2시간

#### 2.3 Supabase Edge Functions 구현 (기본)

**작업 내용**: 핵심 Edge Functions를 구현합니다.

**세부 작업**:
1. rank_update.ts 함수 구현 (베이지안 점수 계산)
2. notify_followers.ts 함수 구현 (팔로워 푸시 알림)
3. cron_refresh.sql 스크립트 구현 (일일 리셋)
4. 디버깅 및 로컬 테스트
5. Supabase에 배포

**커밋 메시지**: "feat: Implement core Supabase Edge Functions"

**예상 소요 시간**: 4시간

### 3. 핵심 패키지 구현

#### 3.1 Core 패키지 구현

**작업 내용**: 공통 모델 및 유틸리티를 포함하는 core 패키지를 구현합니다.

**세부 작업**:
1. 기본 패키지 구조 설정
2. Artist 모델 구현
3. Video 모델 구현
4. Review 모델 구현
5. 기타 공통 모델 및 열거형 구현
6. 유틸리티 함수 및 확장 구현

**커밋 메시지**: "feat: Implement core package with shared models"

**예상 소요 시간**: 3시간

#### 3.2 API Client 패키지 구현

**작업 내용**: Supabase API와 통신하는 api_client 패키지를 구현합니다.

**세부 작업**:
1. Supabase 클라이언트 초기화 로직 구현
2. Repository 패턴 구현
3. 아티스트 API 메소드 구현
4. 비디오 API 메소드 구현
5. 리뷰 및 투표 API 메소드 구현
6. 북마크 및 팔로우 API 메소드 구현

**커밋 메시지**: "feat: Implement API client package with Supabase integration"

**예상 소요 시간**: 4시간

#### 3.3 UI Kit 패키지 구현

**작업 내용**: 공통 UI 컴포넌트를 포함하는 ui_kit 패키지를 구현합니다.

**세부 작업**:
1. 앱 테마 및 스타일 정의
2. 공통 버튼 및 입력 필드 구현
3. 비디오 카드 컴포넌트 구현
4. 아티스트 카드 컴포넌트 구현
5. 로딩 및 에러 상태 위젯 구현
6. 반응형 레이아웃 헬퍼 구현

**커밋 메시지**: "feat: Implement UI kit package with shared components"

**예상 소요 시간**: 5시간

### 4. 크롤러 서비스 구현

#### 4.1 FastAPI 크롤러 기본 구조 구현

**작업 내용**: FastAPI를 사용한 크롤러 서비스의 기본 구조를 구현합니다.

**세부 작업**:
1. FastAPI 앱 기본 구조 설정
2. Supabase 연결 설정
3. 스케줄러 설정 (APScheduler)
4. 기본 API 엔드포인트 구현
5. 로깅 및 모니터링 설정

**커밋 메시지**: "feat: Set up FastAPI crawler service structure"

**예상 소요 시간**: 3시간

#### 4.2 YouTube 크롤러 구현

**작업 내용**: YouTube 팬캠을 수집하는 크롤러를 구현합니다.

**세부 작업**:
1. YouTube Data API v3 연동
2. K-POP 팬캠 검색 로직 구현
3. 비디오 메타데이터 파싱 구현
4. 아티스트 및 곡 정보 추출 로직 구현
5. 중복 체크 및 필터링 로직 구현
6. 품질 점수 계산 구현

**커밋 메시지**: "feat: Implement YouTube crawler with data extraction logic"

**예상 소요 시간**: 5시간

#### 4.3 TikTok 크롤러 구현

**작업 내용**: TikTok 팬캠을 수집하는 크롤러를 구현합니다.

**세부 작업**:
1. TikTok Scraper API 연동
2. K-POP 해시태그 및 팬캠 검색 로직 구현
3. 비디오 메타데이터 파싱 구현
4. 아티스트 및 곡 정보 추출 로직 구현
5. 중복 체크 및 필터링 로직 구현
6. 품질 점수 계산 구현

**커밋 메시지**: "feat: Implement TikTok crawler with data extraction logic"

**예상 소요 시간**: 5시간

#### 4.4 크롤러 배포 구성

**작업 내용**: 크롤러 서비스 배포를 위한 설정을 구성합니다.

**세부 작업**:
1. Dockerfile 작성
2. docker-compose.yml 작성
3. 환경 변수 관리 설정
4. 자동 재시작 및 장애 복구 설정
5. 로그 관리 설정
6. 모니터링 설정 (Prometheus + Grafana)

**커밋 메시지**: "feat: Configure crawler service deployment"

**예상 소요 시간**: 3시간

### 5. Flutter 모바일 앱 구현

#### 5.1 Flutter 앱 기본 구조 설정

**작업 내용**: Flutter 앱의 기본 구조와 설정을 구성합니다.

**세부 작업**:
1. Flutter 프로젝트 초기화
2. 필요한 패키지 추가
3. 앱 테마 및 기본 스타일 설정
4. 다국어 지원 설정
5. 앱 아이콘 및 스플래시 화면 설정

**커밋 메시지**: "feat: Set up Flutter app structure and base configuration"

**예상 소요 시간**: 3시간

#### 5.2 상태 관리 및 라우팅 구현

**작업 내용**: Riverpod 및 GoRouter를 사용한 상태 관리 및 라우팅을 구현합니다.

**세부 작업**:
1. Provider 구조 설정
2. GoRouter 설정 및 경로 정의
3. 인증 상태에 따른 라우팅 로직 구현
4. 페이지 전환 애니메이션 구현
5. 딥 링크 처리 설정

**커밋 메시지**: "feat: Implement Riverpod state management and GoRouter navigation"

**예상 소요 시간**: 4시간

#### 5.3 인증 기능 구현

**작업 내용**: Supabase를 사용한 인증 기능을 구현합니다.

**세부 작업**:
1. 로그인 UI 구현
2. 회원가입 UI 구현
3. 소셜 로그인 연동 (Google, Apple)
4. 비밀번호 재설정 기능 구현
5. 인증 상태 관리 구현

**커밋 메시지**: "feat: Implement authentication with Supabase"

**예상 소요 시간**: 4시간

#### 5.4 홈 피드 화면 구현

**작업 내용**: 앱의 메인 피드 화면을 구현합니다.

**세부 작업**:
1. Trending/Rising 탭 UI 구현
2. 비디오 카드 리스트 구현
3. 무한 스크롤 구현
4. 새로고침 기능 구현
5. 데이터 로딩 및 에러 상태 처리

**커밋 메시지**: "feat: Implement home feed screen with trending and rising videos"

**예상 소요 시간**: 5시간

#### 5.5 비디오 플레이어 화면 구현

**작업 내용**: 임베디드 플레이어를 사용한 비디오 화면을 구현합니다.

**세부 작업**:
1. YouTube iFrame 플레이어 통합
2. TikTok WebView 플레이어 통합
3. 비디오 메타데이터 표시 UI 구현
4. 팬 투표(👍/👎, ★별점) UI 구현
5. 북마크 기능 구현

**커밋 메시지**: "feat: Implement video player screen with embedded players"

**예상 소요 시간**: 6시간

#### 5.6 아티스트 화면 구현

**작업 내용**: 아티스트 프로필 및 비디오 목록 화면을 구현합니다.

**세부 작업**:
1. 아티스트 프로필 헤더 UI 구현
2. 아티스트 비디오 리스트 구현
3. 필터 및 정렬 기능 구현
4. 팔로우 기능 구현
5. 아티스트 정보 UI 구현

**커밋 메시지**: "feat: Implement artist profile screen with video list"

**예상 소요 시간**: 4시간

#### 5.7 검색 화면 구현

**작업 내용**: 아티스트 검색 및 자동완성 기능을 구현합니다.

**세부 작업**:
1. 검색 UI 구현
2. 자동완성 기능 구현
3. 검색 결과 리스트 구현
4. 최근 검색어 기능 구현
5. 인기 검색어 표시 구현

**커밋 메시지**: "feat: Implement search screen with autocomplete"

**예상 소요 시간**: 4시간

#### 5.8 북마크 및 설정 화면 구현

**작업 내용**: 북마크 목록 및 앱 설정 화면을 구현합니다.

**세부 작업**:
1. 북마크 리스트 UI 구현
2. 북마크 관리 기능 구현
3. 설정 화면 UI 구현
4. 테마 변경 기능 구현
5. 알림 설정 구현
6. 프리미엄 구독 UI 구현

**커밋 메시지**: "feat: Implement bookmarks and settings screens"

**예상 소요 시간**: 4시간

#### 5.9 구독 및 인앱 결제 구현

**작업 내용**: 프리미엄 구독 및 인앱 결제 기능을 구현합니다.

**세부 작업**:
1. 인앱 결제 패키지 통합
2. 구독 상품 설정
3. 결제 처리 로직 구현
4. 프리미엄 기능 접근 제어 구현
5. 구독 상태 관리 구현

**커밋 메시지**: "feat: Implement subscription and in-app purchase features"

**예상 소요 시간**: 5시간

#### 5.10 푸시 알림 구현

**작업 내용**: 아티스트 팔로우 및 새 직캠 알림 기능을 구현합니다.

**세부 작업**:
1. FCM(Firebase Cloud Messaging) 설정
2. 알림 권한 요청 UI 구현
3. 토큰 관리 로직 구현
4. 알림 수신 및 처리 로직 구현
5. 알림 설정 관리 기능 구현

**커밋 메시지**: "feat: Implement push notifications for new fancams"

**예상 소요 시간**: 4시간

### 6. 관리자 패널 구현

#### 6.1 React Admin SPA 기본 구조 설정

**작업 내용**: 관리자 패널의 기본 구조를 설정합니다.

**세부 작업**:
1. React 프로젝트 초기화
2. React Admin 라이브러리 설정
3. Supabase 연동 설정
4. 기본 레이아웃 및 테마 설정
5. 인증 설정

**커밋 메시지**: "feat: Set up React Admin SPA structure"

**예상 소요 시간**: 3시간

#### 6.2 아티스트 및 비디오 관리 화면 구현

**작업 내용**: 아티스트 및 비디오 관리 기능을 구현합니다.

**세부 작업**:
1. 아티스트 목록 및 상세 화면 구현
2. 아티스트 추가/수정/삭제 기능 구현
3. 비디오 목록 및 상세 화면 구현
4. 비디오 수정/삭제 기능 구현
5. 필터 및 검색 기능 구현

**커밋 메시지**: "feat: Implement artist and video management in admin panel"

**예상 소요 시간**: 4시간

#### 6.3 사용자 및 리뷰 관리 화면 구현

**작업 내용**: 사용자 및 리뷰 관리 기능을 구현합니다.

**세부 작업**:
1. 사용자 목록 및 상세 화면 구현
2. 사용자 권한 관리 기능 구현
3. 리뷰 목록 및 상세 화면 구현
4. 리뷰 모더레이션 기능 구현
5. 신고 처리 기능 구현

**커밋 메시지**: "feat: Implement user and review management in admin panel"

**예상 소요 시간**: 4시간

#### 6.4 대시보드 및 분석 화면 구현

**작업 내용**: 관리자 대시보드 및 데이터 분석 화면을 구현합니다.

**세부 작업**:
1. 주요 지표 대시보드 구현
2. 사용자 통계 차트 구현
3. 콘텐츠 인기도 분석 차트 구현
4. 실시간 활동 모니터링 기능 구현
5. 데이터 내보내기 기능 구현

**커밋 메시지**: "feat: Implement dashboard and analytics in admin panel"

**예상 소요 시간**: 5시간

#### 6.5 관리자 패널 배포 구성

**작업 내용**: 관리자 패널 배포를 위한 설정을 구성합니다.

**세부 작업**:
1. 빌드 스크립트 구성
2. 환경 변수 설정
3. Supabase Storage 배포 설정
4. 접근 제어 설정
5. 배포 자동화 스크립트 구현

**커밋 메시지**: "feat: Configure admin panel deployment to Supabase Storage"

**예상 소요 시간**: 2시간

### 7. 통합 및 테스트

#### 7.1 단위 테스트 구현

**작업 내용**: 주요 기능에 대한 단위 테스트를 구현합니다.

**세부 작업**:
1. 모델 단위 테스트 구현
2. API 클라이언트 단위 테스트 구현
3. 주요 Provider 단위 테스트 구현
4. 크롤러 함수 단위 테스트 구현
5. Edge Function 단위 테스트 구현

**커밋 메시지**: "test: Implement unit tests for core functionality"

**예상 소요 시간**: 5시간

#### 7.2 통합 테스트 구현

**작업 내용**: 주요 기능 흐름에 대한 통합 테스트를 구현합니다.

**세부 작업**:
1. 인증 흐름 통합 테스트 구현
2. 피드 및 비디오 재생 흐름 통합 테스트 구현
3. 투표 및 랭킹 계산 통합 테스트 구현
4. 크롤러 통합 테스트 구현
5. 푸시 알림 통합 테스트 구현

**커밋 메시지**: "test: Implement integration tests for main workflows"

**예상 소요 시간**: 5시간

#### 7.3 UIth의 요쇼 테스트 구현

**작업 내용**: Flutter 앱의 UI 테스트를 구현합니다.

**세부 작업**:
1. 주요 화면 위젯 테스트 구현
2. 네비게이션 테스트 구현
3. 사용자 인터랙션 테스트 구현
4. 다양한 화면 크기 테스트 구현
5. 접근성 테스트 구현

**커밋 메시지**: "test: Implement UI tests for Flutter app"

**예상 소요 시간**: 4시간

#### 7.4 성능 최적화

**작업 내용**: 앱 성능을 최적화합니다.

**세부 작업**:
1. Flutter 앱 렌더링 성능 최적화
2. 이미지 및 네트워크 요청 캐싱 구현
3. 데이터베이스 쿼리 최적화
4. 크롤러 성능 최적화
5. Edge Function 성능 최적화

**커밋 메시지**: "perf: Optimize app performance and resource usage"

**예상 소요 시간**: 5시간

### 8. 배포 및 모니터링

#### 8.1 CI/CD 파이프라인 구현

**작업 내용**: 지속적 통합 및 배포 파이프라인을 구현합니다.

**세부 작업**:
1. GitHub Actions 워크플로우 설정
2. 테스트 자동화 설정
3. Flutter 앱 빌드 자동화 설정
4. 크롤러 배포 자동화 설정
5. 관리자 패널 배포 자동화 설정

**커밋 메시지**: "ci: Implement CI/CD pipeline with GitHub Actions"

**예상 소요 시간**: 4시간

#### 8.2 모니터링 시스템 구현

**작업 내용**: 시스템 모니터링 및 알림 시스템을 구현합니다.

**세부 작업**:
1. Prometheus + Grafana 설정
2. 주요 메트릭 대시보드 구성
3. 알림 규칙 설정
4. Slack 웹훅 연동
5. 로그 모니터링 설정

**커밋 메시지**: "ops: Implement monitoring system with Prometheus and Grafana"

**예상 소요 시간**: 3시간

#### 8.3 앱 스토어 배포 준비

**작업 내용**: 앱 스토어 배포를 위한 준비를 합니다.

**세부 작업**:
1. 앱 스토어 스크린샷 및 마케팅 자료 준비
2. 개인정보 처리방침 작성
3. iOS App Store Connect 설정
4. Google Play Console 설정
5. 앱 심사 체크리스트 검토

**커밋 메시지**: "release: Prepare app store submission materials"

**예상 소요 시간**: 3시간

## 시간 추정 및 우선순위

- **총 예상 소요 시간**: 약 123시간
- **우선순위 높은 작업**:
  1. 모노레포 기본 구조 설정 (1.1)
  2. Supabase 데이터베이스 스키마 설계 (2.1)
  3. API Client 패키지 구현 (3.2)
  4. FastAPI 크롤러 기본 구조 구현 (4.1)
  5. Flutter 앱 기본 구조 설정 (5.1)

## Task Master MCP 사용 가이드

1. 각 작업은 고유한 ID와 명확한 작업 내용을 포함합니다.
2. 각 작업의 커밋 메시지를 사용하여 GitHub에 커밋하세요.
3. Supabase 프로젝트(owookami/pulse)에 직접 액세스하여 데이터베이스 작업을 수행하세요.
4. 세부 작업은 필요에 따라 더 작은 단위로 나눌 수 있습니다.
5. MCP 서버를 통해 Supabase와 GitHub에 접근하여 작업을 수행하세요.

## 기술적 가이드라인

### Flutter 가이드라인
- 상태 관리: Riverpod 2를 일관되게 사용
- 라우팅: GoRouter 13 사용
- UI: Material Design 3 기반, 다크 모드 지원
- 코드 스타일: Flutter 공식 스타일 가이드 준수

### Supabase 가이드라인
- RLS 정책: 모든 테이블에 적용
- API: REST 기반 접근
- Edge Functions: TypeScript 사용
- 실시간 기능: 필요한 경우 Realtime 기능 활용

### Python 가이드라인
- Python 3.12 사용
- FastAPI 프레임워크 사용
- 비동기 처리: asyncio 활용
- 코드 스타일: Black 및 isort 사용

이 문서의 작업 계획을 따라 Task Master MCP로 체계적인 개발을 진행할 수 있습니다.
