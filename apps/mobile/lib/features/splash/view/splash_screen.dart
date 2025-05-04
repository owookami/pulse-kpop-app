import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/onboarding/provider/onboarding_provider.dart';
import 'package:mobile/routes/routes.dart';

/// 스플래시 화면
class SplashScreen extends ConsumerStatefulWidget {
  /// 생성자
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppState();
  }

  /// 앱 상태 확인 및 적절한 화면으로 이동
  Future<void> _checkAppState() async {
    // 스플래시 화면 최소 표시 시간 (2초)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 앱 최초 실행 여부 확인
    final onboardingState = ref.read(onboardingProvider);

    // 로딩 중이면 조금 더 기다림
    if (onboardingState.isLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
    }

    // 최초 실행 시 온보딩 화면으로 이동
    if (onboardingState.isFirstLaunch) {
      context.go(AppRoutes.onboarding);
      return;
    }

    // 인증 상태 확인
    final authState = ref.read(authControllerProvider);

    // 인증 상태에 관계없이 홈 화면으로 이동
    if (authState.hasValue && !authState.isLoading) {
      // 모든 사용자를 홈 화면으로 이동
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
              // 이미지 에셋이 없는 경우 대체 위젯으로 아이콘 표시
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.music_note,
                size: 120,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pulse',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'K-POP 팬캠 플랫폼',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
