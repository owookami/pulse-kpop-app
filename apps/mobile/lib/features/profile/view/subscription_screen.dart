import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/routes/routes.dart';

/// 구독 관리 화면 (임시 버전)
class SubscriptionScreen extends ConsumerWidget {
  /// 생성자
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // 인증 상태 확인
    final authState = ref.watch(authControllerProvider);
    final isAuthenticated = authState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscription_title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '구독 관리 페이지',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '현재 이 페이지는 개발 중입니다.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 48),
            if (!isAuthenticated)
              ElevatedButton(
                onPressed: () {
                  context.push(AppRoutes.signup);
                },
                child: const Text('회원가입하기'),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                // 안전하게 뒤로 가기 처리
                if (Navigator.of(context).canPop()) {
                  Navigator.pop(context);
                } else {
                  // 스택이 비어있는 경우 홈 화면으로 이동
                  context.go(AppRoutes.home);
                }
              },
              child: const Text('뒤로 가기'),
            ),
          ],
        ),
      ),
    );
  }
}
