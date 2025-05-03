import 'package:supabase_flutter/supabase_flutter.dart';

/// 인증 상태를 나타내는 모델 클래스
class AuthState {
  /// 인증 상태 생성자
  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.session,
    this.needsOnboarding = false,
  });

  /// 인증 여부
  final bool isAuthenticated;

  /// 사용자 정보
  final User? user;

  /// 세션 정보
  final Session? session;

  /// 온보딩 필요 여부
  final bool needsOnboarding;

  /// 초기 상태 - 로그인 되지 않음
  factory AuthState.initial() => const AuthState();

  /// 로그인 성공
  factory AuthState.authenticated(User user, Session session) {
    return AuthState(
      isAuthenticated: true,
      user: user,
      session: session,
      // 사용자 메타데이터에서 온보딩 완료 여부 확인
      // 기본값은 온보딩 필요 없음
      needsOnboarding: user.userMetadata?['has_completed_onboarding'] == null ||
          user.userMetadata!['has_completed_onboarding'] == false,
    );
  }

  /// 로그아웃
  factory AuthState.unauthenticated() => const AuthState();

  /// 온보딩 완료 상태로 복사
  AuthState copyWithOnboardingCompleted() {
    return AuthState(
      isAuthenticated: isAuthenticated,
      user: user,
      session: session,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.isAuthenticated == isAuthenticated &&
        other.user?.id == user?.id &&
        other.session?.accessToken == session?.accessToken &&
        other.needsOnboarding == needsOnboarding;
  }

  @override
  int get hashCode => Object.hash(
        isAuthenticated,
        user?.id,
        session?.accessToken,
        needsOnboarding,
      );
}
