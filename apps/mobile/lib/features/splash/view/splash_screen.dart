import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
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
    // 스플래시 화면 최소 표시 시간 (1.5초로 수정)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // 앱 초기화를 위한 추가 지연
    await Future.delayed(const Duration(milliseconds: 500));

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
      // 이전 방식으로 이동 (go 메서드 사용)
      context.go(AppRoutes.onboarding);
      return;
    }

    // 인증 상태에 관계없이 항상 홈 화면으로 이동
    // pushReplacement 대신 go 메서드 사용
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
            Text(
              l10n.splash_app_name,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.splash_app_description,
              style: const TextStyle(
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
