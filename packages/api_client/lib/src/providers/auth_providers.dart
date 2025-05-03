import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 클라이언트 프로바이더
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Supabase 인증 프로바이더
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return ref.watch(supabaseClientProvider).auth;
});

/// 인증 리포지토리 프로바이더
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseAuthProvider));
});

/// 인증 관련 기능을 제공하는 리포지토리 클래스
class AuthRepository {
  final GoTrueClient _auth;

  AuthRepository(this._auth);

  /// 현재 사용자 정보
  User? get currentUser => _auth.currentUser;

  /// 현재 세션 정보
  Session? get currentSession => _auth.currentSession;

  /// 로그인 여부
  bool get isLoggedIn => currentUser != null && currentSession != null;

  /// 인증 상태 변경 스트림
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// 이메일 비밀번호로 로그인
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  /// 이메일 비밀번호로 회원가입
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      return response;
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  /// 비밀번호 재설정 (새 비밀번호 설정)
  Future<UserResponse> resetPassword({
    required String password,
  }) async {
    try {
      final response = await _auth.updateUser(
        UserAttributes(password: password),
      );
      return response;
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  /// 사용자 정보 업데이트
  Future<UserResponse> updateUserData({
    String? email,
    String? password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      final response = await _auth.updateUser(
        UserAttributes(
          email: email,
          password: password,
          data: userData,
        ),
      );
      return response;
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _handleAuthError(e);
      rethrow;
    }
  }

  /// 오류 처리
  void _handleAuthError(dynamic error) {
    // 에러 로깅 또는 처리
    if (error is AuthException) {
      switch (error.statusCode) {
        case '400':
          // 요청 오류 (잘못된 이메일/비밀번호 형식 등)
          break;
        case '401':
          // 인증 오류 (잘못된 자격 증명)
          break;
        case '404':
          // 사용자를 찾을 수 없음
          break;
        case '409':
          // 이미 존재하는 사용자
          break;
        case '422':
          // 처리할 수 없는 엔티티
          break;
        case '429':
          // 너무 많은 요청
          break;
        default:
          // 기타 오류
          break;
      }
    }
  }
}
