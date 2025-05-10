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
  final Object? error;

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
    Object? error,
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

  /// 로딩 상태 생성
  AuthState loading() {
    return copyWith(
      isLoading: true,
      error: null,
    );
  }

  /// 인증된 상태 생성
  AuthState authenticated(AuthUser user) {
    return copyWith(
      user: user,
      isAuthenticated: true,
      isLoading: false,
      error: null,
    );
  }

  /// 오류 상태 생성
  AuthState withError(Object error) {
    return copyWith(
      isAuthenticated: false,
      isLoading: false,
      error: error.toString(),
      user: null,
    );
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

  /// 로그인 실행
  ///
  /// [email] 사용자 이메일
  /// [password] 사용자 비밀번호
  ///
  /// 성공 여부를 반환
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthController: 로그인 시도 시작 - $email');

      // 로딩 상태로 업데이트
      state = state.loading();

      // Supabase 로그인 시도
      final response = await supabase.Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // 응답에서 사용자 정보 추출
      final user = response.user;

      // 사용자 정보가 없으면 로그인 실패
      if (user == null) {
        print('AuthController: 로그인 실패 - 사용자 정보 없음');
        state = state.withError('로그인에 실패했습니다. 잠시 후 다시 시도해주세요.');
        return false;
      }

      // 이메일 인증 여부 확인
      if (user.emailConfirmedAt == null) {
        print('AuthController: 로그인 실패 - 이메일 미인증');
        state = state.withError('이메일 인증이 완료되지 않았습니다');
        return false;
      }

      // 로그인 성공 시 사용자 정보 업데이트
      final authUser = AuthUser.fromSupabaseUser(user);
      print('AuthController: 로그인 성공 - ${authUser.displayName}');

      // 로그인 결과를 인증된 상태로 업데이트
      state = state.authenticated(authUser);

      // 사용자 프로필 정보 가져오기 (별도 처리)
      _fetchUserProfile(user.id);

      return true;
    } catch (e, stack) {
      print('AuthController: 로그인 오류 발생');
      print(e);
      print(stack);

      // 오류 메시지 설정 - Exception 접두사 제거
      state = state.withError(e.toString());

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
        emailRedirectTo: 'pulse://login', // 이메일 인증 후 앱으로 돌아오도록 설정
      );

      final currentUser = response.user;

      if (currentUser == null) {
        throw Exception('회원가입 실패: 사용자 정보를 가져올 수 없습니다.');
      }

      // 이메일 인증이 완료되지 않았으면 로그인 상태로 설정하지 않음
      if (currentUser.emailConfirmedAt == null) {
        state = state.copyWith(
          isLoading: false,
          error: null, // 이메일 인증은 오류가 아니므로 오류 메시지 설정하지 않음
        );

        // 회원가입은 성공했지만, 이메일 인증이 필요한 상태
        return true;
      }

      // 사용자 정보 설정 (이메일 인증이 이미 완료된 경우)
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
      // 오류 메시지 처리
      String errorMessage;
      if (e.toString().contains('already registered')) {
        errorMessage = '이미 가입된 이메일 주소입니다. 로그인을 시도해보세요.';
      } else if (e.toString().contains('network')) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      } else if (e.toString().contains('weak password')) {
        errorMessage = '보안에 취약한 비밀번호입니다. 다른 비밀번호를 사용해주세요.';
      } else {
        errorMessage = '회원가입에 실패했습니다: $e';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
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
      print('패스워드 재설정 시도: $email');
      final supabaseClient = supabase.Supabase.instance.client;

      // 실제 Supabase API 호출로 패스워드 리셋 이메일 발송
      await supabaseClient.auth.resetPasswordForEmail(email);

      print('패스워드 재설정 이메일 발송 성공');
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      print('패스워드 재설정 오류: $e');
      String errorMessage = '패스워드 재설정에 실패했습니다';

      if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = '네트워크 연결을 확인하고 다시 시도해주세요.';
      } else if (e.toString().contains('email') || e.toString().contains('Email')) {
        errorMessage = '유효하지 않은 이메일 주소입니다.';
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
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

  /// 사용자 프로필 정보 가져오기
  Future<void> _fetchUserProfile(String userId) async {
    try {
      // 필요한 경우 Supabase에서 사용자 프로필 추가 정보 조회
      // 예: 프로필 이미지, 닉네임 등
      print('사용자 프로필 정보 조회: $userId');

      // 여기에 Supabase에서 사용자 프로필 정보를 가져오는 코드 구현
      // 간소화된 예시:
      /* final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      if (response != null && response.isNotEmpty) {
        // 프로필 정보가 있으면 상태 업데이트
        final currentUser = state.user;
        if (currentUser != null) {
          // 프로필 정보로 사용자 정보 업데이트
          // 예시 코드이므로 실제 구현 시 수정 필요
        }
      } */
    } catch (error) {
      print('사용자 프로필 정보 조회 실패: $error');
      // 프로필 정보 조회 실패는 로그인 자체의 실패로 처리하지 않음
    }
  }
}
