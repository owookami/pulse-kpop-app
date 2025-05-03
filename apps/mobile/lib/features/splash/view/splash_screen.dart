import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
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
    _checkAuthState();
  }

  /// 인증 상태 확인 및 적절한 화면으로 이동
  Future<void> _checkAuthState() async {
    // 인증 상태 확인을 위한 최소 표시 시간 (1초)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);

    // 인증 상태에 따라 분기
    if (authState.hasValue && !authState.isLoading) {
      if (authState.value!.isAuthenticated) {
        if (authState.value!.needsOnboarding) {
          // 온보딩이 필요한 경우
          context.go(AppRoutes.onboarding);
        } else {
          // 인증된 사용자는 메인 화면으로
          context.go(AppRoutes.home);
        }
      } else {
        // 인증되지 않은 사용자는 로그인 화면으로
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 로고
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.music_video,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // 앱 이름
            Text(
              'Pulse',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),

            // 앱 설명
            Text(
              'K-POP 팬캠 플랫폼',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 48),

            // 로딩 인디케이터
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
