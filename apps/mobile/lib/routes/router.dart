import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/widgets/main_scaffold.dart';
import 'package:mobile/features/artist/view/artist_list_screen.dart';
import 'package:mobile/features/artist/view/artist_profile_screen.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/auth/view/login_screen.dart';
import 'package:mobile/features/auth/view/reset_password_screen.dart';
import 'package:mobile/features/auth/view/signup_screen.dart';
import 'package:mobile/features/bookmarks/view/bookmarks_screen.dart';
import 'package:mobile/features/bookmarks/view/collection_details_screen.dart';
import 'package:mobile/features/bookmarks/view/collection_management_screen.dart';
import 'package:mobile/features/feed/view/feed_screen.dart';
import 'package:mobile/features/onboarding/provider/onboarding_provider.dart';
import 'package:mobile/features/onboarding/view/onboarding_screen.dart';
import 'package:mobile/features/profile/view/app_info_screen.dart';
import 'package:mobile/features/profile/view/deactivate_account_screen.dart';
import 'package:mobile/features/profile/view/feedback_screen.dart';
import 'package:mobile/features/profile/view/privacy_policy_screen.dart';
import 'package:mobile/features/profile/view/profile_screen.dart';
import 'package:mobile/features/profile/view/subscription_screen.dart';
import 'package:mobile/features/profile/view/terms_screen.dart';
import 'package:mobile/features/recommendations/view/for_you_screen.dart';
import 'package:mobile/features/search/view/discover_screen.dart';
import 'package:mobile/features/search/view/search_screen.dart';
import 'package:mobile/features/splash/view/splash_screen.dart';
import 'package:mobile/features/video_player/view/video_player_screen.dart';
import 'package:mobile/routes/routes.dart';

/// 라우터 상태 프로바이더
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final onboardingState = ref.watch(onboardingProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // 현재 경로가 인증 관련 경로인지 확인
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.resetPassword;
      final isSplashRoute = state.matchedLocation == AppRoutes.splash;
      final isOnboardingRoute = state.matchedLocation == AppRoutes.onboarding;

      // 로딩 중일 때는 스플래시 화면 유지
      if (authState.isLoading || onboardingState.isLoading) {
        return isSplashRoute ? null : AppRoutes.splash;
      }

      // 스플래시 화면에서는 별도의 리다이렉트 로직 없음 (스플래시 화면에서 처리)
      if (isSplashRoute) {
        return null;
      }

      // 앱 최초 실행 시 온보딩으로 리다이렉트 (로그인 상태와 관계없이)
      if (onboardingState.isFirstLaunch && !isOnboardingRoute) {
        return AppRoutes.onboarding;
      }

      // 인증 관련 페이지에 있고 이미 로그인한 상태라면 홈으로 리다이렉트
      if (isAuthRoute && authState.value?.isAuthenticated == true) {
        return AppRoutes.home;
      }

      // 온보딩 페이지에 있지만 온보딩이 필요없는 경우 홈으로 리다이렉트
      if (isOnboardingRoute && !onboardingState.isFirstLaunch) {
        return AppRoutes.home;
      }

      // 다른 모든 경로는 리다이렉트 없이 접근 허용
      return null;
    },
    routes: [
      // 스플래시 화면
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // 온보딩 화면
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // 인증 관련 라우트
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // 독립적인 전체 화면 비디오 플레이어 (하단 네비게이션 표시 없음)
      GoRoute(
        path: '/fullscreen-video-player',
        name: 'fullscreen-video-player',
        pageBuilder: (context, state) {
          final video = state.extra as Video;
          return CustomTransitionPage<void>(
            key: ValueKey('fullscreen_player_${video.id}'),
            child: VideoPlayerScreen(video: video),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            opaque: true,
            barrierDismissible: false,
          );
        },
      ),

      // ID 기반 독립적인 전체 화면 비디오 플레이어 (하단 네비게이션 표시 없음)
      GoRoute(
        path: '/fullscreen-player/:id',
        name: 'fullscreen-player',
        pageBuilder: (context, state) {
          final videoId = state.pathParameters['id']!;
          return CustomTransitionPage<void>(
            key: ValueKey('fullscreen_player_id_$videoId'),
            child: VideoPlayerScreen.fromId(videoId: videoId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            opaque: true,
            barrierDismissible: false,
          );
        },
      ),

      // 아티스트 상세 화면
      GoRoute(
        path: '/artist/:id',
        builder: (context, state) {
          final artistId = state.pathParameters['id']!;
          return ArtistProfileScreen(artistId: artistId);
        },
      ),

      // 아티스트 목록 화면
      GoRoute(
        path: '/artists',
        builder: (context, state) => const ArtistListScreen(),
      ),

      // 'For You' 화면
      GoRoute(
        path: AppRoutes.forYou,
        builder: (context, state) => const ForYouScreen(),
      ),

      // 구독 화면 (직접 접근용)
      GoRoute(
        path: AppRoutes.subscription,
        builder: (context, state) => const SubscriptionScreen(),
      ),

      // 메인 탭 라우트 (StatefulShellRoute)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // 홈/피드 탭
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const FeedScreen(),
                routes: [
                  // 비디오 상세 화면
                  GoRoute(
                    path: 'video/:id',
                    builder: (context, state) {
                      final videoId = state.pathParameters['id']!;
                      // TODO: 비디오 상세 화면 구현
                      return Scaffold(
                        appBar: AppBar(title: Text('비디오 $videoId')),
                        body: Center(child: Text('비디오 $videoId 상세 화면')),
                      );
                    },
                  ),
                  // 아티스트 상세 화면 - 홈 내부 라우트
                  GoRoute(
                    path: 'artist/:id',
                    builder: (context, state) {
                      final artistId = state.pathParameters['id']!;
                      return ArtistProfileScreen(artistId: artistId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // 검색 탭
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (context, state) => const SearchScreen(),
                routes: [
                  GoRoute(
                    path: 'discover',
                    builder: (context, state) => const DiscoverScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.discover,
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),

          // 북마크 탭
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bookmarks,
                builder: (context, state) {
                  return const BookmarksScreen();
                },
                routes: [
                  // 컬렉션 세부 화면
                  GoRoute(
                    path: 'collection/:id',
                    builder: (context, state) {
                      // 컬렉션 ID
                      final collectionId = state.pathParameters['id']!;

                      // Extra로 전달된 컬렉션이 있으면 사용, 없으면 ID만 사용
                      final collection = state.extra as BookmarkCollection?;

                      if (collection != null) {
                        return CollectionDetailsScreen(collection: collection);
                      } else {
                        // TODO: ID로 컬렉션을 불러오는 기능 구현
                        // 임시 구현: 스낵바로 안내 메시지 표시 후 북마크 화면으로 복귀
                        return const BookmarksScreen();
                      }
                    },
                  ),
                  // 컬렉션 관리 화면
                  GoRoute(
                    path: 'manage',
                    builder: (context, state) => const CollectionManagementScreen(),
                  ),
                ],
              ),
            ],
          ),

          // 프로필 탭
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  // 프로필에서 아티스트 목록 화면으로 이동
                  GoRoute(
                    path: 'artists',
                    builder: (context, state) => const ArtistListScreen(),
                  ),
                  // 앱 정보 화면
                  GoRoute(
                    path: 'app-info',
                    builder: (context, state) => const AppInfoScreen(),
                  ),
                  // 이용약관 화면
                  GoRoute(
                    path: 'terms',
                    builder: (context, state) => const TermsScreen(),
                  ),
                  // 개인정보 처리방침 화면
                  GoRoute(
                    path: 'privacy',
                    builder: (context, state) => const PrivacyPolicyScreen(),
                  ),
                  // 구독 관리 화면
                  GoRoute(
                    path: 'subscription',
                    builder: (context, state) => const SubscriptionScreen(),
                  ),
                  // 회원 탈퇴 화면
                  GoRoute(
                    path: 'deactivate',
                    builder: (context, state) => const DeactivateAccountScreen(),
                  ),
                  // 건의하기 화면
                  GoRoute(
                    path: 'feedback',
                    builder: (context, state) => const FeedbackScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    // 에러 핸들링
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                '오류가 발생했습니다',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${state.error}',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
