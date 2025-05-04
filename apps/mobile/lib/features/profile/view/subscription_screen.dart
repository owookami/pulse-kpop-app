import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/subscription/model/subscription_model.dart';
import 'package:mobile/features/subscription/provider/subscription_provider.dart';
import 'package:mobile/routes/routes.dart';

/// 구독 관리 화면
class SubscriptionScreen extends ConsumerWidget {
  /// 생성자
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 구독 상태와 상품 목록
    final subscriptionState = ref.watch(subscriptionProvider);
    final productsAsync = ref.watch(subscriptionProductsProvider);

    // 인증 상태 확인
    final authState = ref.watch(authControllerProvider);
    final isAuthenticated = authState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('구독 관리'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 비회원인 경우 로그인 안내 카드 표시
            if (!isAuthenticated) _buildLoginCard(context),

            // 구독 상태 카드
            _buildSubscriptionStatusCard(context, subscriptionState),
            const SizedBox(height: 24),

            // 이용 가능한 구독 상품
            Text(
              '이용 가능한 구독 상품',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // 구독 상품 목록
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('현재 구독 가능한 상품이 없습니다.'),
                    ),
                  );
                }

                return Column(
                  children: products.map((product) {
                    return _buildSubscriptionCard(
                      context,
                      product: product,
                      isAuthenticated: isAuthenticated,
                      onSubscribe: () {
                        if (isAuthenticated) {
                          _showSubscriptionDialog(context, ref, product);
                        } else {
                          _showLoginRequiredDialog(context);
                        }
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('구독 정보를 불러오는 중 오류가 발생했습니다: $error'),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 구독 관련 동작 버튼들
            if (isAuthenticated)
              OutlinedButton.icon(
                onPressed: () => _showRestoreDialog(context, ref),
                icon: const Icon(Icons.restore),
                label: const Text('구매 내역 복원'),
              ),

            const SizedBox(height: 12),

            // 구독 취소 버튼 (구독 중인 경우만 표시)
            if (isAuthenticated && subscriptionState.isActive)
              OutlinedButton.icon(
                onPressed: () => _showCancelDialog(context, ref),
                icon: const Icon(Icons.cancel),
                label: const Text('구독 관리 및 해지'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 로그인 안내 카드
  Widget _buildLoginCard(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '구독을 시작하려면 회원가입이 필요합니다',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '회원가입 후 프리미엄 구독을 통해 모든 동영상을 무제한으로 시청하실 수 있습니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.signup);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('회원가입하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 로그인 필요 다이얼로그
  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원가입 필요'),
        content: const Text('구독을 시작하려면 먼저 회원가입이 필요합니다. 회원가입 페이지로 이동하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.signup);
            },
            child: const Text('회원가입'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionStatusCard(BuildContext context, SubscriptionState state) {
    final isPremium = state.isActive;

    // 구독 만료일 형식화
    String expiryDateText = '현재 무료 플랜을 이용 중입니다.';
    if (isPremium && state.expiryDate != null) {
      final date = state.expiryDate!;
      expiryDateText = '구독 만료일: ${date.year}년 ${date.month}월 ${date.day}일';

      // 구독 취소 상태인 경우 표시
      if (state.isCancelled) {
        expiryDateText += ' (갱신 예정 없음)';
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isPremium
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.star : Icons.star_border,
                  size: 32,
                  color: isPremium
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium
                            ? state.type == SubscriptionType.monthly
                                ? '월간 프리미엄 멤버십'
                                : '연간 프리미엄 멤버십'
                            : '무료 멤버십',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        expiryDateText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (isPremium && state.isCancelled)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '구독이 취소되었습니다. 만료일까지 모든 기능을 이용하실 수 있습니다.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (isPremium) ...[
              const SizedBox(height: 16),
              const Text('프리미엄 혜택:'),
              const SizedBox(height: 8),
              _buildBenefitItem(context, '광고 없는 영상 시청'),
              _buildBenefitItem(context, '고화질 영상 재생'),
              _buildBenefitItem(context, '배경 재생 및 오프라인 저장'),
              _buildBenefitItem(context, '프리미엄 전용 콘텐츠 이용'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context, {
    required SubscriptionProduct product,
    required VoidCallback onSubscribe,
    required bool isAuthenticated,
  }) {
    // 가격 형식화
    final formattedPrice =
        '₩${product.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedPrice,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      product.type == SubscriptionType.monthly ? '월 결제' : '년 결제',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(!isAuthenticated
                    ? '로그인 후 구독하기'
                    : (product.type == SubscriptionType.monthly ? '월간 구독하기' : '연간 구독하기')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context, WidgetRef ref, SubscriptionProduct product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${product.type == SubscriptionType.monthly ? '월간' : '연간'} 구독을 시작하시겠습니까?'),
              const SizedBox(height: 8),
              Text(
                  '결제 금액: ₩${product.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'),
              const SizedBox(height: 16),
              const Text(
                '구독은 자동으로 갱신되며, 언제든지 해지할 수 있습니다. 결제는 iTunes 또는 Google Play 계정으로 청구됩니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // 로딩 다이얼로그 표시
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // 구독 시도
                final result = await ref.read(subscriptionProvider.notifier).purchase(product);

                // 로딩 다이얼로그 닫기
                if (context.mounted) {
                  Navigator.of(context).pop();

                  // 결과 알림
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result ? '구독이 성공적으로 완료되었습니다.' : '구독에 실패했습니다.'),
                      backgroundColor: result ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('구독하기'),
            ),
          ],
        );
      },
    );
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('구매 내역 복원'),
          content: const Text('이전에 구매한 구독을 복원하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // 로딩 다이얼로그 표시
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // 구독 복원 시도
                final result = await ref.read(subscriptionProvider.notifier).restore();

                // 로딩 다이얼로그 닫기
                if (context.mounted) {
                  Navigator.of(context).pop();

                  // 결과 알림
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result ? '구독이 성공적으로 복원되었습니다.' : '복원할 구독을 찾을 수 없습니다.'),
                      backgroundColor: result ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('복원하기'),
            ),
          ],
        );
      },
    );
  }

  // 구독 취소 확인 다이얼로그
  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('구독 취소'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('프리미엄 구독을 취소하시겠습니까?'),
            const SizedBox(height: 16),
            const Text(
              '구독 취소 시 다음 사항에 유의해주세요:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint('현재 결제 주기의 만료일까지 프리미엄 기능을 계속 이용하실 수 있습니다.'),
            _buildBulletPoint('만료일 이후에는 자동으로 무료 계정으로 전환됩니다.'),
            _buildBulletPoint('이미 결제된 금액은 환불되지 않습니다.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // 구독 관리 페이지 열기 시도
              final success =
                  await ref.read(subscriptionProvider.notifier).openManageSubscriptions();

              if (context.mounted) {
                if (!success) {
                  // 직접 취소가 불가능한 경우 안내 메시지 표시
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('구독 관리 페이지'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('구독 관리 페이지를 열 수 없습니다.'),
                          const SizedBox(height: 16),
                          const Text('다음 방법으로 구독을 취소할 수 있습니다:'),
                          const SizedBox(height: 8),
                          if (Platform.isIOS) ...[
                            _buildBulletPoint('기기의 설정 앱을 엽니다.'),
                            _buildBulletPoint('Apple ID를 탭합니다.'),
                            _buildBulletPoint('구독을 탭합니다.'),
                            _buildBulletPoint('Pulse 앱을 찾아 구독 취소를 진행합니다.'),
                          ] else if (Platform.isAndroid) ...[
                            _buildBulletPoint('Google Play 스토어 앱을 엽니다.'),
                            _buildBulletPoint('프로필 아이콘을 탭합니다.'),
                            _buildBulletPoint('결제 및 구독 > 구독으로 이동합니다.'),
                            _buildBulletPoint('Pulse 앱을 찾아 구독 취소를 진행합니다.'),
                          ],
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // 성공적으로 관리 페이지를 열었을 때 상태 확인을 위해 일정 시간 후 갱신
                  Future.delayed(const Duration(seconds: 5), () {
                    ref.read(subscriptionProvider.notifier).refreshSubscription();
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('구독 관리'),
          ),
        ],
      ),
    );
  }

  // 글머리 기호 포인트 위젯
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
