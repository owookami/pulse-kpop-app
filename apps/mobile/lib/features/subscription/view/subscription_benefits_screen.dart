import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/core/services/locale_service.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/subscription/model/subscription_models.dart';
import 'package:mobile/routes/routes.dart';

/// 구독 혜택 소개 화면
class SubscriptionBenefitsScreen extends ConsumerStatefulWidget {
  /// 생성자
  const SubscriptionBenefitsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionBenefitsScreen> createState() => _SubscriptionBenefitsScreenState();
}

class _SubscriptionBenefitsScreenState extends ConsumerState<SubscriptionBenefitsScreen> {
  String? _userCountry;
  bool _isLoadingCountry = true;

  @override
  void initState() {
    super.initState();
    _loadUserCountry();
  }

  // 사용자 국가 정보 로드
  Future<void> _loadUserCountry() async {
    setState(() {
      _isLoadingCountry = true;
    });

    try {
      // LocaleService에서 사용자 국가 정보 가져오기
      final country = await LocaleService.getUserCountry();

      if (mounted) {
        setState(() {
          _userCountry = country;
          _isLoadingCountry = false;
        });
      }
    } catch (e) {
      // 오류 발생 시 기본 국가로 설정
      if (mounted) {
        setState(() {
          _userCountry = LocaleService.defaultCountry;
          _isLoadingCountry = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isAuthenticated = authState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.premium_features),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // 스택이 비어있는 경우 홈 화면으로 이동
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 프리미엄 소개 카드
                _buildPremiumCard(context),
                const SizedBox(height: 24),

                // 구독 플랜 비교
                _buildSubscriptionPlansComparison(context),
                const SizedBox(height: 24),

                // 혜택 목록 섹션
                _buildBenefitsSection(context),
                const SizedBox(height: 32),

                // 주요 지역별 가격
                _buildRegionalPricing(context),
                const SizedBox(height: 32),

                // FAQ 섹션
                _buildFaqSection(context),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // 하단 구독 버튼 고정
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (isAuthenticated) {
                  // 로그인 상태면 구독 상품 화면으로 이동
                  context.push(AppRoutes.subscriptionPlans);
                } else {
                  // 비로그인 상태면 회원가입 안내 다이얼로그 표시
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.subscription_signup_required),
                      content: Text(l10n.subscription_limit_message_guest),
                      actions: [
                        TextButton(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(l10n.common_cancel),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.pop(context);
                            }
                            // 회원가입 페이지로 이동
                            context.go(AppRoutes.signup);
                          },
                          child: Text(l10n.subscription_signup),
                        ),
                      ],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isAuthenticated ? l10n.premium_banner_button : l10n.subscription_signup,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 프리미엄 소개 카드
  Widget _buildPremiumCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                l10n.premium_features,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.premium_banner_description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildPriceChip(context, l10n.monthly_plan_description),
              const SizedBox(width: 8),
              _buildPriceChip(
                context,
                l10n.yearly_plan_description,
                isPopular: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 가격 칩 위젯
  Widget _buildPriceChip(BuildContext context, String text, {bool isPopular = false}) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isPopular ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.best_value_tag,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isPopular) const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isPopular ? theme.colorScheme.primary : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 구독 플랜 비교 테이블
  Widget _buildSubscriptionPlansComparison(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.subscription_benefits_title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 비교 테이블 헤더
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.subscription_benefits_title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      l10n.free_tier,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      l10n.premium_tier,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // 무제한 시청
            _buildComparisonRow(
              context,
              l10n.premium_benefit_1,
              false,
              true,
            ),

            // HD 화질
            // _buildComparisonRow(
            //   context,
            //   l10n.premium_benefit_2,
            //   false,
            //   true,
            // ),

            // 광고 제거
            _buildComparisonRow(
              context,
              l10n.premium_benefit_3,
              false,
              true,
            ),

            // 전체 콘텐츠 접근
            // _buildComparisonRow(
            //   context,
            //   l10n.premium_benefit_4,
            //   false,
            //   true,
            // ),

            // 투표 영향력
            _buildComparisonRow(
              context,
              l10n.premium_benefit_5,
              '일반',
              '2배',
            ),

            // 다중 기기 지원
            // _buildComparisonRow(
            //   context,
            //   l10n.premium_benefit_6,
            //   '1대',
            //   '최대 5대',
            // ),
          ],
        ),
      ),
    );
  }

  // 비교 테이블 행
  Widget _buildComparisonRow(
    BuildContext context,
    String feature,
    dynamic free,
    dynamic premium,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(feature),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: free is bool
                  ? Icon(
                      free ? Icons.check_circle : Icons.cancel,
                      color: free ? Colors.green : Colors.grey,
                      size: 20,
                    )
                  : Text(
                      free.toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: premium is bool
                  ? Icon(
                      premium ? Icons.check_circle : Icons.cancel,
                      color: premium ? Colors.green : Colors.grey,
                      size: 20,
                    )
                  : Text(
                      premium.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // 혜택 목록 섹션
  Widget _buildBenefitsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.premium_features,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 혜택 1
        _buildBenefitItem(
          context,
          icon: Icons.videocam,
          title: l10n.premium_benefit_1,
          description: '광고 없이 무제한으로 모든 팬캠 시청',
        ),

        // 혜택 2
        // _buildBenefitItem(
        //   context,
        //   icon: Icons.high_quality,
        //   title: l10n.premium_benefit_2,
        //   description: '모든 영상을 HD 화질로 시청',
        // ),

        // 혜택 3
        _buildBenefitItem(
          context,
          icon: Icons.block,
          title: l10n.premium_benefit_3,
          description: '방해 없이 콘텐츠 시청',
        ),

        // 혜택 4
        _buildBenefitItem(
          context,
          icon: Icons.cloud_download,
          title: l10n.premium_benefit_4,
          description: '모든 아티스트의 최신 팬캠에 즉시 접근',
        ),

        // 혜택 5
        _buildBenefitItem(
          context,
          icon: Icons.how_to_vote,
          title: l10n.premium_benefit_5,
          description: '투표 시 2배의 영향력으로 좋아하는 아티스트 지원',
        ),

        // 혜택 6
        // _buildBenefitItem(
        //   context,
        //   icon: Icons.devices,
        //   title: l10n.premium_benefit_6,
        //   description: '최대 5대의 기기에서 동시에 사용 가능',
        // ),
      ],
    );
  }

  // 혜택 아이템 위젯
  Widget _buildBenefitItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 지역별 가격 정보
  Widget _buildRegionalPricing(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // 유저 지역 정보와 가격을 함께 가져오는 FutureBuilder
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCountryPricingInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 가격 정보를 가져오지 못한 경우
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('가격 정보를 가져올 수 없습니다.'));
        }

        final pricingInfo = snapshot.data!;
        final countryName = pricingInfo['countryName'] as String;
        final monthlyProduct = pricingInfo['monthlyProduct'] as SubscriptionProduct;
        final yearlyProduct = pricingInfo['yearlyProduct'] as SubscriptionProduct;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 지역 가격 정보',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 현재 사용자 국가의 가격만 표시
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          countryName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPriceCard(
                          context,
                          '월간 구독',
                          monthlyProduct.price,
                          '매월 자동 결제',
                          currencyCode: monthlyProduct.currencyCode,
                        ),
                        _buildPriceCard(
                          context,
                          '연간 구독',
                          yearlyProduct.price,
                          '연 단위 구독 시 약 16% 절약',
                          isHighlighted: true,
                          currencyCode: yearlyProduct.currencyCode,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 가격 정책 관련 정보
            Text(
              '* 표시된 가격은 지역 및 환율에 따라 달라질 수 있습니다.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '* 앱스토어/구글플레이 정책에 따라 최종 결제 금액이 다를 수 있습니다.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        );
      },
    );
  }

  // 현재 국가 코드와 가격 정보를 가져오는 함수
  Future<Map<String, dynamic>> _getCountryPricingInfo() async {
    // 사용자 국가 정보 가져오기
    final countryCode = await LocaleService.getUserCountry();

    // 국가별 가격 정보 생성
    final monthlyProduct = SubscriptionProduct.monthlyPremium(countryCode: countryCode);
    final yearlyProduct = SubscriptionProduct.yearlyPremium(countryCode: countryCode);

    // 국가 이름 가져오기
    final countryName = LocaleService.getCountryLocalName(countryCode);

    return {
      'countryCode': countryCode,
      'countryName': countryName,
      'monthlyProduct': monthlyProduct,
      'yearlyProduct': yearlyProduct,
    };
  }

  // 가격 카드 UI
  Widget _buildPriceCard(BuildContext context, String title, String price, String description,
      {bool isHighlighted = false, String currencyCode = 'USD'}) {
    final theme = Theme.of(context);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isHighlighted ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.surface,
        border: Border.all(
          color: isHighlighted
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlighted ? theme.colorScheme.primary : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // FAQ 섹션
  Widget _buildFaqSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '자주 묻는 질문',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // FAQ 아이템들
        _buildFaqItem(
          context,
          question: '구독은 언제든지 취소할 수 있나요?',
          answer: '네, 언제든지 취소할 수 있으며 취소 후 요금 청구 기간이 끝날 때까지 프리미엄 혜택을 계속 이용할 수 있습니다.',
        ),

        _buildFaqItem(
          context,
          question: '구독 후에도 광고가 보이나요?',
          answer: '프리미엄 구독자는 모든 영상에서 광고 없이 시청할 수 있습니다.',
        ),

        // _buildFaqItem(
        //   context,
        //   question: '가족 계정은 어떻게 이용하나요?',
        //   answer: '패밀리 플랜 구독 후 최대 5명의 가족 구성원을 초대하여 함께 이용할 수 있습니다.',
        // ),

        _buildFaqItem(
          context,
          question: '무료 체험 기간이 있나요?',
          answer: '첫 구독 시 7일 무료 체험 기간을 제공합니다. 이 기간 동안 모든 프리미엄 혜택을 경험하실 수 있습니다.',
        ),
      ],
    );
  }

  // FAQ 아이템 위젯
  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    final theme = Theme.of(context);

    return ExpansionTile(
      title: Text(
        question,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      childrenPadding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
      ),
      children: [
        Text(
          answer,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
