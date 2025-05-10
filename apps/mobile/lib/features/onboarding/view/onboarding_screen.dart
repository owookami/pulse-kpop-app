import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/widgets/app_button.dart';
import 'package:mobile/routes/routes.dart';

/// 온보딩 화면 컨트롤러
final onboardingControllerProvider = StateProvider<int>((ref) => 0);

/// 온보딩 화면
class OnboardingScreen extends ConsumerWidget {
  /// 생성자
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(onboardingControllerProvider);
    final l10n = AppLocalizations.of(context);
    final pageController = PageController(initialPage: currentPage);

    final onboardingPages = [
      OnboardingPage(
        image: 'assets/images/onboarding_welcome.png',
        title: l10n.onboarding_welcome_title,
        description: l10n.onboarding_welcome_description,
      ),
      OnboardingPage(
        image: 'assets/images/onboarding_videos.png',
        title: l10n.onboarding_videos_title,
        description: l10n.onboarding_videos_description,
      ),
      OnboardingPage(
        image: 'assets/images/onboarding_premium.png',
        title: '프리미엄 구독으로 더 많은 혜택',
        description:
            '월 \$1.99의 합리적인 가격으로 모든 팬캠을 HD 화질로, 광고 없이 무제한 시청하세요. 비구독자에게는 하루 10개의 무료 시청 기회가 있습니다.',
        // 추가 구독 혜택 정보
        extraContent: _buildSubscriptionBenefits(context),
      ),
      OnboardingPage(
        image: 'assets/images/onboarding_community.png',
        title: l10n.onboarding_community_title,
        description: l10n.onboarding_community_description,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 16.0),
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(l10n.skip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: onboardingPages.length,
                onPageChanged: (index) =>
                    ref.read(onboardingControllerProvider.notifier).state = index,
                itemBuilder: (_, index) => onboardingPages[index],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingPages.length,
                      (index) => _buildDotIndicator(context, index == currentPage),
                    ),
                  ),
                  const SizedBox(height: 30),
                  AppButton(
                    onPressed: () {
                      if (currentPage == onboardingPages.length - 1) {
                        context.go(AppRoutes.home);
                      } else {
                        pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    text: currentPage == onboardingPages.length - 1 ? l10n.get_started : l10n.next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 페이지 인디케이터 위젯
  Widget _buildDotIndicator(BuildContext context, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 12 : 8,
      height: isActive ? 12 : 8,
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// 구독 혜택 위젯
  Widget _buildSubscriptionBenefits(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '프리미엄 구독 혜택',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(context, icon: Icons.videocam, text: '무제한 팬캠 시청'),
          _buildBenefitItem(context, icon: Icons.high_quality, text: '720p HD 화질'),
          _buildBenefitItem(context, icon: Icons.block, text: '광고 없음'),
          _buildBenefitItem(context, icon: Icons.cloud_download, text: '모든 영상 무제한 접근'),
          _buildBenefitItem(context, icon: Icons.how_to_vote, text: '투표 영향력 2배'),
        ],
      ),
    );
  }

  /// 혜택 아이템 위젯
  Widget _buildBenefitItem(BuildContext context, {required IconData icon, required String text}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// 온보딩 페이지 모델
class OnboardingPage extends StatelessWidget {
  /// 이미지 경로
  final String image;

  /// 제목
  final String title;

  /// 설명
  final String description;

  /// 추가 콘텐츠 위젯
  final Widget? extraContent;

  /// 생성자
  const OnboardingPage({
    Key? key,
    required this.image,
    required this.title,
    required this.description,
    this.extraContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            image,
            height: MediaQuery.of(context).size.height * 0.3,
          ),
          const SizedBox(height: 30),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          // 추가 콘텐츠가 있다면 표시
          if (extraContent != null) extraContent!,
        ],
      ),
    );
  }
}
