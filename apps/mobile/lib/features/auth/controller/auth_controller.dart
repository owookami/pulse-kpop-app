import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/model/auth_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// 인증 상태 클래스
class AuthState {
  /// 생성자
  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.needsOnboarding = false,
  });

  /// 현재 사용자
  final AuthUser? user;

  /// 인증 여부
  final bool isAuthenticated;

  /// 로딩 상태
  final bool isLoading;

  /// 오류 메시지
  final String? error;

  /// 온보딩 필요 여부
  final bool needsOnboarding;

  /// 오류 여부
  bool get hasError => error != null;

  /// 값이 있는지 여부
  bool get hasValue => !isLoading && !hasError;

  /// 현재 상태 값 (자기 자신)
  AuthState? get value => hasValue ? this : null;

  /// whenData 메서드 - AsyncValue와 비슷한 패턴 제공
  T whenData<T>(T Function(AuthState state) fn) {
    if (hasValue) {
      return fn(this);
    }
    return fn(const AuthState());
  }

  /// 복사 생성자
  AuthState copyWith({
    AuthUser? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool? needsOnboarding,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
    );
  }

  /// 온보딩 완료 처리
  AuthState copyWithOnboardingCompleted() {
    return copyWith(needsOnboarding: false);
  }
}

/// 인증 컨트롤러 프로바이더
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});

/// 인증 컨트롤러
/// 사용자 로그인/로그아웃 등 인증 관련 기능 처리
class AuthController extends StateNotifier<AuthState> {
  /// 생성자
  AuthController() : super(const AuthState()) {
    // 초기화 시 현재 세션 확인
    _initSession();
  }

  /// 초기 세션 확인
  Future<void> _initSession() async {
    try {
      final supabaseClient = supabase.Supabase.instance.client;
      final currentUser = supabaseClient.auth.currentUser;

      if (currentUser != null) {
        // 현재 세션이 있으면 로그인 상태로 설정
        final user = AuthUser(
          id: currentUser.id,
          email: currentUser.email ?? '',
          displayName: currentUser.userMetadata?['name'] as String? ?? '',
          photoUrl: currentUser.userMetadata?['avatar_url'] as String?,
          createdAt: DateTime.parse(currentUser.createdAt),
          lastSignInAt:
              currentUser.updatedAt != null ? DateTime.parse(currentUser.updatedAt!) : null,
          isAdmin: currentUser.email == 'loupslim@gmail.com',
        );

        state = state.copyWith(
          user: user,
          isAuthenticated: true,
        );
      }
    } catch (e) {
      // 세션 확인 중 오류 발생 시 처리
      print('세션 초기화 중 오류: $e');
    }
  }

  /// 로그인
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final supabaseClient = supabase.Supabase.instance.client;

      // Supabase 로그인 요청
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final currentUser = response.user;

      if (currentUser == null) {
        throw Exception('로그인 실패: 사용자 정보를 가져올 수 없습니다.');
      }

      // 사용자 정보 설정
      final user = AuthUser(
        id: currentUser.id,
        email: currentUser.email ?? '',
        displayName: currentUser.userMetadata?['name'] as String? ?? '',
        photoUrl: currentUser.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.parse(currentUser.createdAt),
        lastSignInAt: currentUser.updatedAt != null ? DateTime.parse(currentUser.updatedAt!) : null,
        isAdmin: currentUser.email == 'loupslim@gmail.com',
      );

      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '로그인에 실패했습니다: $e',
      );
      return false;
    }
  }

  /// 회원가입
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final supabaseClient = supabase.Supabase.instance.client;

      // 사용자 메타데이터 설정
      final userData = {
        'name': displayName ?? '',
      };

      // Supabase 회원가입 요청
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );

      final currentUser = response.user;

      if (currentUser == null) {
        throw Exception('회원가입 실패: 사용자 정보를 가져올 수 없습니다.');
      }

      // 사용자 정보 설정
      final user = AuthUser(
        id: currentUser.id,
        email: currentUser.email ?? '',
        displayName: userData['name'] as String,
        photoUrl: null,
        createdAt: DateTime.parse(currentUser.createdAt),
        lastSignInAt: currentUser.updatedAt != null ? DateTime.parse(currentUser.updatedAt!) : null,
      );

      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '회원가입에 실패했습니다: $e',
      );
      return false;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final supabaseClient = supabase.Supabase.instance.client;
      await supabaseClient.auth.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '로그아웃에 실패했습니다: $e',
      );
    }
  }

  /// 회원 탈퇴
  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 현재 사용자 계정 삭제
      final supabaseClient = supabase.Supabase.instance.client;

      if (supabaseClient.auth.currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 1. 서버 측 함수를 호출하여 사용자 관련 데이터 삭제
      await supabaseClient.rpc('delete_user_account');

      // 2. 로그아웃 처리
      await supabaseClient.auth.signOut();

      // 상태 업데이트
      state = const AuthState();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '회원 탈퇴에 실패했습니다: $e',
      );
      return false;
    }
  }

  /// 패스워드 리셋
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: 실제 구현에서는 API 호출로 패스워드 리셋 이메일 발송
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '패스워드 재설정에 실패했습니다: $e',
      );
      return false;
    }
  }

  /// 온보딩 완료 처리
  Future<void> completeOnboarding() async {
    if (state.user == null || !state.isAuthenticated) {
      return;
    }

    try {
      // 실제 구현에서는 사용자 메타데이터 업데이트 등의 처리
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(needsOnboarding: false);
    } catch (e) {
      state = state.copyWith(
        error: '온보딩 완료 처리에 실패했습니다: $e',
      );
    }
  }
}
