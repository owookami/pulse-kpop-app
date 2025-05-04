import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/model/auth_user.dart';

/// 인증 상태 프로바이더
final authStateProvider = StateProvider<AuthState>((ref) {
  return const AuthState();
});

/// 현재 사용자 프로바이더
final currentUserProvider = Provider<AuthUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

/// 인증 상태 클래스
class AuthState {
  /// 생성자
  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  /// 현재 사용자
  final AuthUser? user;

  /// 인증 여부
  final bool isAuthenticated;

  /// 로딩 상태
  final bool isLoading;

  /// 오류 메시지
  final String? error;

  /// 복사 생성자
  AuthState copyWith({
    AuthUser? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
