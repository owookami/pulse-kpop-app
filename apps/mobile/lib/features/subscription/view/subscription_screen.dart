import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/subscription/model/subscription_models.dart';
import 'package:mobile/features/subscription/service/subscription_service.dart' as service;
import 'package:mobile/routes/routes.dart';

/// 구독 관리 화면
class SubscriptionScreen extends ConsumerWidget {
  /// 생성자
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // 인증 상태 확인
    final authState = ref.watch(authControllerProvider);
    final isAuthenticated = authState.isAuthenticated;

    // 구독 서비스 객체
    final subscriptionService = ref.read(service.subscriptionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subscription_title),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 기존 pop() 메서드 대신 canPop() 확인 후 처리
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // 스택이 비어있는 경우 홈 화면으로 이동
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<SubscriptionProduct>>(
          future: subscriptionService.getSubscriptionProducts(),
          builder: (context, productsSnapshot) {
            return FutureBuilder<SubscriptionStatus>(
              future: subscriptionService.checkSubscriptionStatus(),
              builder: (context, statusSnapshot) {
                // 로딩 중인 경우
                if (!productsSnapshot.hasData || !statusSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 에러가 발생한 경우
                if (productsSnapshot.hasError) {
                  return Center(
                    child: Text('구독 상품을 불러올 수 없습니다: ${productsSnapshot.error}'),
                  );
                }

                if (statusSnapshot.hasError) {
                  return Center(
                    child: Text('구독 상태를 불러올 수 없습니다: ${statusSnapshot.error}'),
                  );
                }

                // 데이터 로드 완료
                final products = productsSnapshot.data!;
                final status = statusSnapshot.data!;

                // 구독 상품 목록
                final monthlyProduct = products
                    .where((product) =>
                        product.period == SubscriptionPeriod.monthly &&
                        product.tier == SubscriptionTier.premium)
                    .firstOrNull;

                final yearlyProduct = products
                    .where((product) =>
                        product.period == SubscriptionPeriod.yearly &&
                        product.tier == SubscriptionTier.premium)
                    .firstOrNull;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 구독 헤더 카드
                      _buildSubscriptionHeaderCard(context, theme),

                      const SizedBox(height: 24),

                      // 구독 상태 카드 (로그인 필요 또는 현재 구독 정보)
                      if (!isAuthenticated)
                        _buildLoginRequiredCard(context, theme)
                      else
                        _buildSubscriptionStatusCard(context, theme, status),

                      const SizedBox(height: 24),

                      // 구독 상품 섹션
                      if (products.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '구독 상품',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 월간 구독 상품
                            if (monthlyProduct != null)
                              _buildSubscriptionProductCard(
                                context,
                                monthlyProduct,
                                isAuthenticated,
                                onSubscribe: () =>
                                    _handleSubscription(context, ref, monthlyProduct),
                              ),

                            const SizedBox(height: 16),

                            // 연간 구독 상품
                            if (yearlyProduct != null)
                              _buildSubscriptionProductCard(
                                context,
                                yearlyProduct,
                                isAuthenticated,
                                onSubscribe: () => _handleSubscription(context, ref, yearlyProduct),
                              ),
                          ],
                        )
                      else
                        Center(
                          child: Text(
                            '현재 이용 가능한 구독 상품이 없습니다',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // 구독 혜택 섹션
                      _buildSubscriptionBenefits(context, theme),

                      const SizedBox(height: 24),

                      // 구독 복원 및 관리 버튼
                      if (isAuthenticated) ...[
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              final result = await subscriptionService.restorePurchases();
                              if (result && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('구독이 복원되었습니다')),
                                );
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('복원할 구독이 없습니다')),
                                );
                              }
                            },
                            icon: const Icon(Icons.restore),
                            label: const Text('구매 내역 복원'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              final result = await subscriptionService.openManageSubscriptions();
                              if (!result && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('구독 관리 페이지를 열 수 없습니다')),
                                );
                              }
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('구독 관리'),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // 구독 헤더 카드
  Widget _buildSubscriptionHeaderCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 32,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(width: 12),
                Text(
                  '프리미엄 구독',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '하루 커피 한 잔보다 저렴한 가격으로\n월 내내 최고 화질의 팬캠을',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '광고 없이 끊김 없이 720p HD 화질로 시청하세요',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 로그인 필요 카드
  Widget _buildLoginRequiredCard(BuildContext context, ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.account_circle, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              '구독 관리를 위해 로그인이 필요합니다',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.push(AppRoutes.signup);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('로그인 하기'),
            ),
          ],
        ),
      ),
    );
  }

  // 구독 상태 카드
  Widget _buildSubscriptionStatusCard(
      BuildContext context, ThemeData theme, SubscriptionStatus status) {
    final isPremium = status.isActive && status.planType != SubscriptionPlanType.free;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.verified : Icons.info_outline,
                  color: isPremium ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isPremium ? '프리미엄 구독 중' : '무료 체험 중',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPremium ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isPremium) ...[
              _buildInfoRow(context, '구독 유형', _getPlanTypeName(status.planType)),
              const SizedBox(height: 8),
              if (status.expiryDate != null)
                _buildInfoRow(context, '만료일', _formatDate(status.expiryDate!)),
              const SizedBox(height: 16),
              Text(
                '모든 콘텐츠 무제한 이용 가능',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green,
                ),
              ),
            ] else ...[
              _buildInfoRow(context, '무료 시청 횟수', '10회 중 남은 시청 횟수'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // 구독 상품 섹션으로 스크롤
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Text('프리미엄으로 업그레이드'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 구독 상품 카드
  Widget _buildSubscriptionProductCard(
      BuildContext context, SubscriptionProduct product, bool isAuthenticated,
      {required VoidCallback onSubscribe}) {
    final theme = Theme.of(context);
    final bool isYearly = product.period == SubscriptionPeriod.yearly;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isYearly ? theme.colorScheme.primary : Colors.transparent,
            width: isYearly ? 2 : 0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 태그 (인기 or 가성비)
              if (product.isMostPopular || product.isBestValue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.isBestValue ? Colors.green : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    product.isBestValue ? '최고 가성비' : '인기',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // 구독 제목 및 가격
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: product.price,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        TextSpan(
                          text: product.period == SubscriptionPeriod.monthly ? '/월' : '/년',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 구독 설명
              Text(
                product.description,
                style: theme.textTheme.bodyMedium,
              ),

              const SizedBox(height: 16),

              // 구독 기능 목록
              ...product.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 구독 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isAuthenticated
                      ? onSubscribe
                      : () {
                          _showLoginRequiredDialog(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isYearly ? Colors.green : theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('구독하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 구독 혜택 섹션
  Widget _buildSubscriptionBenefits(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '프리미엄 구독 혜택',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(
          context,
          icon: Icons.videocam,
          title: '무제한 팬캠 시청',
          description: '시청 횟수 제한 없이 모든 팬캠을 마음껏 시청하세요',
        ),
        // _buildBenefitItem(
        //   context,
        //   icon: Icons.high_quality,
        //   title: '720p HD 화질',
        //   description: '고화질로 더 선명하게 좋아하는 아이돌의 영상을 즐기세요',
        // ),
        _buildBenefitItem(
          context,
          icon: Icons.block,
          title: '광고 제거',
          description: '광고 없이 끊김 없는 시청 경험을 제공합니다',
        ),
        _buildBenefitItem(
          context,
          icon: Icons.how_to_vote,
          title: '투표 영향력 2배',
          description: '좋아하는 아티스트에 대한 투표시 2배의 영향력을 행사하세요',
        ),
      ],
    );
  }

  // 혜택 아이템
  Widget _buildBenefitItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 정보 행 위젯
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 구독 처리 함수
  Future<void> _handleSubscription(
      BuildContext context, WidgetRef ref, SubscriptionProduct product) async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 플랫폼 확인 및 각 플랫폼별 구독 로직 실행
      final subscriptionService = ref.read(service.subscriptionServiceProvider);
      bool success = false;

      if (Platform.isIOS) {
        // iOS 플랫폼에서의 구독 처리
        debugPrint('iOS 플랫폼에서 구독 시작: ${product.productId}');
        success = await _handleIosSubscription(ref, product);
      } else if (Platform.isAndroid) {
        // Android 플랫폼에서의 구독 처리
        debugPrint('Android 플랫폼에서 구독 시작: ${product.productId}');
        success = await _handleAndroidSubscription(ref, product);
      } else {
        // 웹 또는 기타 플랫폼
        debugPrint('지원되지 않는 플랫폼에서 구독 시도');
        success = await subscriptionService.purchaseSubscription(product);
      }

      if (context.mounted) {
        // 로딩 다이얼로그 닫기
        Navigator.pop(context);

        if (success) {
          // 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('구독이 성공적으로 완료되었습니다'),
              backgroundColor: Colors.green,
            ),
          );

          // 화면 갱신
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
            );
          }
        } else {
          // 실패 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('구독 처리 중 오류가 발생했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // 로딩 다이얼로그 닫기
        Navigator.pop(context);

        // 오류 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구독 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // iOS에서의 구독 처리
  Future<bool> _handleIosSubscription(WidgetRef ref, SubscriptionProduct product) async {
    try {
      final subscriptionService = ref.read(service.subscriptionServiceProvider);

      // iOS 앱스토어를 통한 구독 구매 시작
      final success = await subscriptionService.purchaseSubscription(product);

      // StoreKit 결과 처리
      if (success) {
        debugPrint('iOS 앱스토어 구독 성공: ${product.productId}');
        return true;
      } else {
        debugPrint('iOS 앱스토어 구독 실패 또는 취소됨: ${product.productId}');
        return false;
      }
    } catch (e) {
      debugPrint('iOS 구독 처리 중 오류: $e');
      return false;
    }
  }

  // Android에서의 구독 처리
  Future<bool> _handleAndroidSubscription(WidgetRef ref, SubscriptionProduct product) async {
    try {
      final subscriptionService = ref.read(service.subscriptionServiceProvider);

      // Google Play를 통한 구독 구매 시작
      final success = await subscriptionService.purchaseSubscription(product);

      // Google Play 결과 처리
      if (success) {
        debugPrint('Google Play 구독 성공: ${product.productId}');
        return true;
      } else {
        debugPrint('Google Play 구독 실패 또는 취소됨: ${product.productId}');
        return false;
      }
    } catch (e) {
      debugPrint('Android 구독 처리 중 오류: $e');
      return false;
    }
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
            onPressed: () {
              // 안전하게 pop 처리
              if (Navigator.of(context).canPop()) {
                Navigator.pop(context);
              }
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // 다이얼로그 닫기
              if (Navigator.of(context).canPop()) {
                Navigator.pop(context);
              }
              // 회원가입 페이지로 이동
              context.push(AppRoutes.signup);
            },
            child: const Text('회원가입하기'),
          ),
        ],
      ),
    );
  }

  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  // 플랜 타입 이름
  String _getPlanTypeName(SubscriptionPlanType type) {
    switch (type) {
      case SubscriptionPlanType.premiumMonthly:
        return '월간 프리미엄';
      case SubscriptionPlanType.premiumYearly:
        return '연간 프리미엄';
      case SubscriptionPlanType.basicMonthly:
        return '월간 베이직';
      case SubscriptionPlanType.basicYearly:
        return '연간 베이직';
      case SubscriptionPlanType.free:
        return '무료';
    }
  }
}
