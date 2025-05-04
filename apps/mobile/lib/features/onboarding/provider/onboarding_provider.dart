import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 온보딩 상태를 나타내는 클래스
class OnboardingState {
  /// 생성자
  const OnboardingState({
    required this.isFirstLaunch,
    this.isLoading = false,
  });

  /// 앱 최초 실행 여부
  final bool isFirstLaunch;

  /// 로딩 상태
  final bool isLoading;

  /// 초기 상태 - 기본적으로 최초 실행으로 가정
  factory OnboardingState.initial() => const OnboardingState(
        isFirstLaunch: true,
        isLoading: true,
      );

  /// 복사 생성자
  OnboardingState copyWith({
    bool? isFirstLaunch,
    bool? isLoading,
  }) {
    return OnboardingState(
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 온보딩 상태 관리 프로바이더
final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

/// 온보딩 상태 관리 노티파이어
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  /// 생성자
  OnboardingNotifier() : super(OnboardingState.initial()) {
    // 초기화 시 앱 최초 실행 여부 확인
    _checkFirstLaunch();
  }

  /// SharedPreferences 키
  static const String _firstLaunchKey = 'is_first_launch';

  /// 앱 최초 실행 여부 확인
  Future<void> _checkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 키가 없거나 true인 경우 최초 실행으로 간주
      final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

      state = state.copyWith(
        isFirstLaunch: isFirstLaunch,
        isLoading: false,
      );
    } catch (e) {
      // 오류 발생 시 기본적으로 온보딩 표시 (안전하게)
      state = state.copyWith(
        isFirstLaunch: true,
        isLoading: false,
      );
    }
  }

  /// 온보딩 완료 처리
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 온보딩 완료 상태 저장 (더 이상 최초 실행이 아님)
      await prefs.setBool(_firstLaunchKey, false);

      state = state.copyWith(
        isFirstLaunch: false,
      );
    } catch (e) {
      // 저장 오류 발생 시에도 로컬 상태는 업데이트
      state = state.copyWith(
        isFirstLaunch: false,
      );
    }
  }

  /// 온보딩 상태 초기화 (테스트용)
  Future<void> resetOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLaunchKey, true);

      state = state.copyWith(
        isFirstLaunch: true,
      );
    } catch (e) {
      // 오류 무시
    }
  }
}
