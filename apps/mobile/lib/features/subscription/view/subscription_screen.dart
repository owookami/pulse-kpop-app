import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/subscription/model/subscription_model.dart';
import 'package:mobile/features/subscription/providers/subscription_provider.dart';

/// 구독 화면
class SubscriptionScreen extends ConsumerWidget {
  /// 생성자
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionStateProvider);
    final productsAsync = ref.watch(subscriptionProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프리미엄 구독'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(subscriptionProductsProvider);
          ref.read(subscriptionStateProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 현재 구독 상태 표시
              _buildSubscriptionStatus(context, subscriptionState, ref),

              const SizedBox(height: 24),

              // 구독 상품 목록
              productsAsync.when(
                data: (products) => _buildSubscriptionProducts(context, products, ref),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: SelectableText.rich(
                    TextSpan(
                      text: '구독 상품 정보를 불러오는 중 오류가 발생했습니다.\n',
                      children: [
                        TextSpan(
                          text: error.toString(),
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 구매 복원 및 취소 버튼
              _buildActionButtons(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  /// 구독 상태 위젯 생성
  Widget _buildSubscriptionStatus(
    BuildContext context,
    AsyncValue<SubscriptionState> subscriptionState,
    WidgetRef ref,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: subscriptionState.when(
          data: (state) {
            if (state.isActive) {
              // 활성 구독 상태
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '구독 중',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('구독 유형: ${_getSubscriptionTypeText(state.type)}'),
                  if (state.expiryDate != null) Text('만료일: ${_formatDate(state.expiryDate!)}'),
                  const SizedBox(height: 8),
                  const Text('모든 컨텐츠를 무제한으로 시청하실 수 있습니다.'),
                ],
              );
            } else {
              // 비활성 구독 상태
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '구독 필요',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('무료 시청 횟수: ${ref.watch(freeVideoWatchCountProvider)}회 남음'),
                  const SizedBox(height: 8),
                  const Text('프리미엄 구독으로 모든 컨텐츠를 무제한으로 즐겨보세요!'),
                ],
              );
            }
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: SelectableText.rich(
              TextSpan(
                text: '구독 상태를 확인하는 중 오류가 발생했습니다.\n',
                children: [
                  TextSpan(
                    text: error.toString(),
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 구독 상품 목록 위젯 생성
  Widget _buildSubscriptionProducts(
    BuildContext context,
    List<SubscriptionProduct> products,
    WidgetRef ref,
  ) {
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('구독 상품이 없습니다.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '구독 상품',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...products.map((product) => _buildProductCard(context, product, ref)),
      ],
    );
  }

  /// 구독 상품 카드 위젯 생성
  Widget _buildProductCard(
    BuildContext context,
    SubscriptionProduct product,
    WidgetRef ref,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _purchase(context, product, ref),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatPrice(product),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(product.description),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _purchase(context, product, ref),
                child: const Text('구독하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 구매 복원 및 취소 버튼 위젯 생성
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final isActive = ref
        .watch(subscriptionStateProvider)
        .maybeWhen(data: (state) => state.isActive, orElse: () => false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () => _restorePurchases(context, ref),
          child: const Text('구매 복원'),
        ),
        const SizedBox(height: 12),
        if (isActive)
          OutlinedButton(
            onPressed: () => _openManageSubscriptions(context, ref),
            child: const Text('구독 관리'),
          ),
      ],
    );
  }

  /// 구독 구매 처리
  Future<void> _purchase(
    BuildContext context,
    SubscriptionProduct product,
    WidgetRef ref,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 이미 구독 중인지 확인
    final isAlreadySubscribed = ref
        .read(subscriptionStateProvider)
        .maybeWhen(data: (state) => state.isActive, orElse: () => false);

    if (isAlreadySubscribed) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('이미 구독 중입니다.')),
      );
      return;
    }

    // 구매 진행 알림
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('구독 진행 중...')),
    );

    // 구매 시도
    final success = await ref.read(subscriptionStateProvider.notifier).purchase(product);

    // 구매 결과 처리
    if (context.mounted) {
      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('구독이 완료되었습니다.')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('구독에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    }
  }

  /// 구매 복원 처리
  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 복원 진행 알림
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('구매 복원 중...')),
    );

    // 복원 시도
    final success = await ref.read(subscriptionStateProvider.notifier).restorePurchases();

    // 복원 결과 처리
    if (context.mounted) {
      if (success) {
        // 복원 성공 - 구독 상태에 따라 다른 메시지 표시
        final isActive = ref
            .read(subscriptionStateProvider)
            .maybeWhen(data: (state) => state.isActive, orElse: () => false);

        if (isActive) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('구독이 복원되었습니다.')),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('복원할 구독이 없습니다.')),
          );
        }
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('구매 복원에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    }
  }

  /// 구독 관리 페이지 열기
  Future<void> _openManageSubscriptions(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await ref.read(subscriptionStateProvider.notifier).openManageSubscriptions();

    if (!success && context.mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('구독 관리 페이지를 열 수 없습니다.')),
      );
    }
  }

  /// 구독 유형 텍스트 변환
  String _getSubscriptionTypeText(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return '월간 구독';
      case SubscriptionType.yearly:
        return '연간 구독';
      case SubscriptionType.free:
        return '무료';
    }
  }

  /// 날짜 형식 변환
  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  /// 가격 형식 변환
  String _formatPrice(SubscriptionProduct product) {
    final price = product.price.toInt();
    return '${product.currencySymbol}$price';
  }
}
