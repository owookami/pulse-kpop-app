/// 앱 라우트 이름 정의
class AppRoutes {
  /// 스플래시 화면
  static const splash = '/splash';

  /// 온보딩 화면
  static const onboarding = '/onboarding';

  /// 로그인 화면
  static const login = '/login';

  /// 회원가입 화면
  static const signup = '/signup';

  /// 비밀번호 재설정 화면
  static const resetPassword = '/reset-password';

  /// 홈 화면
  static const home = '/';

  /// 피드 화면
  static const feed = '/feed';

  /// 검색 화면
  static const search = '/search';

  /// 발견 화면
  static const discover = '/discover';

  /// 북마크 화면
  static const bookmarks = '/bookmarks';

  /// 프로필 화면
  static const profile = '/profile';

  /// 구독 관리 화면
  static const subscription = '/profile/subscription';

  /// 비디오 상세 화면
  static const video = '/video/:id';

  /// 아티스트 기본 경로
  static const artistBase = '/artist';

  /// 아티스트 상세 화면
  static const artist = '/artist/:id';

  /// 전체화면 비디오 플레이어 화면 (새로운 독립 화면)
  static const fullscreenVideoPlayer = '/fullscreen-video-player';

  /// 전체화면 비디오 플레이어 베이스 경로 (새로운 독립 화면)
  static const fullscreenPlayerBase = '/fullscreen-player';

  /// 전체화면 비디오 플레이어 경로 (ID 포함) (새로운 독립 화면)
  static const fullscreenPlayer = '/fullscreen-player/:id';

  /// 컬렉션 세부 화면
  static const collection = 'collection/:id';

  /// 'For You' 화면
  static const String forYou = '/for-you';
}
