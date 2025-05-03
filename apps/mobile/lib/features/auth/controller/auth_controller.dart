import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/model/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

/// 인증 컨트롤러 프로바이더
final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  () => AuthController(),
);

/// 인증 컨트롤러
/// 사용자 로그인/로그아웃 등 인증 관련 기능 처리
class AuthController extends AsyncNotifier<AuthState> {
  // 인증 리포지토리
  late final AuthRepository _authRepository;

  @override
  Future<AuthState> build() async {
    // 인증 리포지토리 초기화
    _authRepository = ref.watch(authRepositoryProvider);

    // 현재 세션 확인
    final currentSession = _authRepository.currentSession;
    final currentUser = _authRepository.currentUser;

    // 인증 상태 변경 리스너 설정
    _setupAuthStateChanges();

    // 세션이 있으면 인증됨 상태 반환
    if (currentSession != null && currentUser != null) {
      return AuthState.authenticated(currentUser, currentSession);
    }

    // 세션이 없으면 인증되지 않음 상태 반환
    return AuthState.initial();
  }

  /// 인증 상태 변경 리스너 설정
  void _setupAuthStateChanges() {
    _authRepository.authStateChanges.listen((data) async {
      final event = data.event;
      final session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session != null && _authRepository.currentUser != null) {
            state = AsyncData(AuthState.authenticated(_authRepository.currentUser!, session));
          }
          break;
        case AuthChangeEvent.signedOut:
        case AuthChangeEvent.userDeleted:
          state = AsyncData(AuthState.initial());
          break;
        case AuthChangeEvent.tokenRefreshed:
          if (session != null && _authRepository.currentUser != null) {
            state = AsyncData(AuthState.authenticated(_authRepository.currentUser!, session));
          }
          break;
        case AuthChangeEvent.userUpdated:
          if (session != null && _authRepository.currentUser != null) {
            state = AsyncData(AuthState.authenticated(_authRepository.currentUser!, session));
          }
          break;
        case AuthChangeEvent.passwordRecovery:
        default:
          // 그 외 이벤트는 현재 상태 유지
          break;
      }
    });
  }

  /// 이메일/비밀번호로 로그인
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final response = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );

      final user = response.user;
      final session = response.session;

      if (user != null && session != null) {
        state = AsyncData(AuthState.authenticated(user, session));
      } else {
        state = AsyncError(
          Exception('로그인에 실패했습니다. 이메일과 비밀번호를 확인해주세요.'),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// 이메일/비밀번호로 회원가입
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? username,
  }) async {
    state = const AsyncLoading();

    try {
      final userData = username != null ? {'username': username} : null;

      final response = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        userData: userData,
      );

      final user = response.user;
      final session = response.session;

      if (user != null && session != null) {
        state = AsyncData(AuthState.authenticated(user, session));
      } else {
        // 이메일 확인이 필요한 경우
        state = AsyncData(AuthState.initial());
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    state = const AsyncLoading();

    try {
      await _authRepository.sendPasswordResetEmail(email: email);

      // 상태 유지
      if (state.hasValue) {
        state = AsyncData(state.value!);
      } else {
        state = AsyncData(AuthState.initial());
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    state = const AsyncLoading();

    try {
      await _authRepository.signOut();
      state = AsyncData(AuthState.initial());
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  /// 온보딩 완료 처리
  Future<void> completeOnboarding() async {
    if (!state.hasValue || state.value!.isAuthenticated == false) {
      return;
    }

    try {
      // 사용자 메타데이터 업데이트
      await _authRepository.updateUserData(
        userData: {'has_completed_onboarding': true},
      );

      // 상태 업데이트
      if (state.hasValue) {
        state = AsyncData(state.value!.copyWithOnboardingCompleted());
      }
    } catch (e) {
      debugPrint('온보딩 완료 처리 중 오류: $e');
    }
  }
}
