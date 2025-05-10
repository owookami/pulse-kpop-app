import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
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
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _checkAppState();
  }

  /// 앱 상태 확인 및 적절한 화면으로 이동
  Future<void> _checkAppState() async {
    if (_isNavigating) return; // 중복 실행 방지
    _isNavigating = true;

    try {
      // 의도적인 지연 (최소 스플래시 표시 시간 확보)
      await Future.delayed(const Duration(milliseconds: 2500));

      if (!mounted) return;

      // 온보딩 필요 여부 확인
      final onboardingRequired = ref.read(onboardingProvider).isFirstLaunch;

      // 인증 상태 확인
      final authState = ref.read(authControllerProvider);
      final isAuthenticated = authState.isAuthenticated;
      final hasAuthError = authState.hasError;

      print('스플래시 화면 상태 확인:');
      print('- 온보딩 필요: $onboardingRequired');
      print('- 인증됨: $isAuthenticated');
      print('- 인증 오류 있음: $hasAuthError');
      if (hasAuthError) {
        print('- 오류 메시지: ${authState.error}');
      }

      // 앱 초기 데이터 로드 (실제 앱에서는 필요한 초기 데이터 로딩 구현)
      // await _loadInitialData();

      if (!mounted) return;

      // context.go 사용하여 라우팅 - GoRouter 내부 리디렉션 문제를 방지하기 위한 딜레이 추가
      Future.microtask(() {
        if (!mounted) return;

        // 인증 오류가 있으면 로그인 화면으로 이동
        if (hasAuthError) {
          print('인증 오류 발견 - 로그인 화면으로 이동');

          // 로그인 화면으로 안전하게 이동
          // 로그인 화면에서 authState의 오류를 확인하여 표시함
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              context.go(AppRoutes.login);
            }
          });
          return;
        }

        // 온보딩 처리
        if (onboardingRequired) {
          // 온보딩이 필요한 경우
          context.go(AppRoutes.onboarding);
          return;
        }

        // 인증 상태 확인 후 적절한 화면으로 이동
        if (isAuthenticated) {
          // 로그인된 사용자는 홈 화면으로 이동
          context.go(AppRoutes.home);
        } else {
          // 로그인되지 않은 사용자도 홈 화면으로 이동 (북마크/프로필에서 로그인 유도)
          context.go(AppRoutes.home);
        }
      });
    } catch (e) {
      print('스플래시 화면 오류 발생: $e');
      // 오류 발생 시 로그인 화면으로 이동
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            print('예외 발생으로 로그인 화면으로 이동');
            context.go(AppRoutes.login);
          }
        });
      }
    } finally {
      _isNavigating = false;
    }
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
