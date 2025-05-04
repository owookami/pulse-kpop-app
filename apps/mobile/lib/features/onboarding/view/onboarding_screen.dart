import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/onboarding/provider/onboarding_provider.dart';
import 'package:mobile/routes/routes.dart';

/// 온보딩 화면
class OnboardingScreen extends ConsumerStatefulWidget {
  /// 생성자
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  final List<_OnboardingPage> _pages = [
    const _OnboardingPage(
      title: 'Pulse에 오신 것을 환영합니다',
      description: '최고의 K-POP 팬캠을 위한 앱, Pulse와 함께 여러분이 좋아하는 아티스트들의 최신 영상을 만나보세요.',
      icon: Icons.celebration,
    ),
    const _OnboardingPage(
      title: '최신 팬캠 탐색',
      description: '최신 인기 팬캠과 트렌딩 비디오를 확인하고, 좋아하는 아티스트의 새로운 콘텐츠를 놓치지 마세요.',
      icon: Icons.video_library,
    ),
    const _OnboardingPage(
      title: '북마크 및 저장',
      description: '좋아하는 팬캠을 북마크하고 저장하여 언제든지 다시 볼 수 있습니다.',
      icon: Icons.bookmark,
    ),
    const _OnboardingPage(
      title: '시작할 준비가 되셨나요?',
      description: '이제 Pulse의 모든 기능을 이용해 보세요!',
      icon: Icons.rocket_launch,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 온보딩 완료 처리
  Future<void> _completeOnboarding() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      // 온보딩 완료 상태 업데이트
      await ref.read(onboardingProvider.notifier).completeOnboarding();

      if (mounted) {
        // 홈 화면으로 이동
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        // 오류 발생 시 스낵바로 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('온보딩 완료 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  /// 다음 페이지로 이동
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 건너뛰기 버튼 (마지막 페이지가 아닌 경우에만 표시)
            if (!isLastPage)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _isCompleting ? null : _completeOnboarding,
                    child: const Text('건너뛰기'),
                  ),
                ),
              ),

            // 페이지 뷰
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: _pages.map((page) {
                  return _OnboardingPageView(page: page);
                }).toList(),
              ),
            ),

            // 하단 인디케이터 및 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 페이지 인디케이터
                  Row(
                    children: List.generate(_pages.length, (index) {
                      return Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),

                  // 다음/시작 버튼
                  ElevatedButton(
                    onPressed: _isCompleting ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isCompleting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(isLastPage ? '시작하기' : '다음'),
                              const SizedBox(width: 8),
                              Icon(
                                isLastPage ? Icons.check : Icons.arrow_forward,
                                size: 16,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 온보딩 페이지 데이터 모델
class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// 온보딩 페이지 뷰 위젯
class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘
          Icon(
            page.icon,
            size: 120,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 40),

          // 제목
          Text(
            page.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // 설명
          Text(
            page.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
