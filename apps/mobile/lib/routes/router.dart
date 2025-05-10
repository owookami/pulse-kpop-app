import 'dart:async';

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
import 'package:mobile/features/profile/view/language_screen.dart';
import 'package:mobile/features/profile/view/privacy_policy_screen.dart';
import 'package:mobile/features/profile/view/profile_screen.dart';
import 'package:mobile/features/profile/view/subscription_screen.dart' as profile_subscription;
import 'package:mobile/features/profile/view/terms_screen.dart';
import 'package:mobile/features/recommendations/view/for_you_screen.dart';
import 'package:mobile/features/search/view/discover_screen.dart';
import 'package:mobile/features/search/view/search_screen.dart';
import 'package:mobile/features/splash/view/splash_screen.dart';
import 'package:mobile/features/subscription/view/subscription_benefits_screen.dart';
import 'package:mobile/features/subscription/view/subscription_screen.dart';
import 'package:mobile/features/video_player/view/video_player_screen.dart';
import 'package:mobile/routes/routes.dart';

/// 스트림을 사용하여 go_router의 리프레시를 처리하는 유틸리티 클래스
class GoRouterRefreshStream extends ChangeNotifier {
  /// 생성자
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// 라우터 상태 프로바이더
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final onboardingState = ref.watch(onboardingProvider);

  // 인증 상태 변경을 감지하는 리스너 생성 (스트림 주기 늘리고 디바운스 추가)
  final authController = ref.read(authControllerProvider.notifier);

  // 마지막 인증 상태 저장용 변수 (closure에서 접근 가능하도록 함수 외부에 선언)
  bool? lastAuthState;

  // 리디렉션을 발생시키는 상태 변경만 감지 (로딩 상태는 무시)
  final authStateChangeStream = Stream<AuthState>.value(authState).asyncExpand((_) {
    return Stream<AuthState>.periodic(
      const Duration(seconds: 3), // 2초에서 3초로 늘림 (여유 있게)
      (_) => ref.read(authControllerProvider),
    ).where((state) {
      // 로딩 중인 상태는 무시
      if (state.isLoading) {
        print('인증 스트림: 로딩 중 상태 무시');
        return false;
      }

      // 최초 실행 시 초기 상태 저장
      if (lastAuthState == null) {
        lastAuthState = state.isAuthenticated;
        print('인증 스트림: 초기 상태 저장 - 로그인 상태: $lastAuthState');
        return false; // 초기 상태는 무시
      }

      // 인증 상태가 실제로 변경된 경우만 true 반환
      final changed = lastAuthState != state.isAuthenticated;

      if (changed) {
        print('인증 스트림: 상태 변경 감지 - 이전: $lastAuthState, 현재: ${state.isAuthenticated}');
        lastAuthState = state.isAuthenticated; // 상태 업데이트
      }

      return changed; // 변경된 경우만 스트림에 포함
    }).distinct(); // 동일한 상태는 한 번만 처리하도록 distinct() 추가
  });

  // 라우터 리프레시 리스너 생성
  final refreshListener = GoRouterRefreshStream(authStateChangeStream);

  return GoRouter(
    initialLocation: AppRoutes.splash, // 초기 위치는 스플래시 화면으로 유지
    debugLogDiagnostics: true, // 디버그 로그 활성화 (문제 해결을 위해)
    refreshListenable: refreshListener, // 인증 상태 변경 시 라우터 새로고침
    redirect: (context, state) {
      print('==== GoRouter redirect 호출됨 ====');
      print('현재 경로: ${state.matchedLocation}');
      print('인증 상태: ${authState.isAuthenticated ? '로그인됨' : '로그인되지 않음'}');
      print('로딩 상태: ${authState.isLoading ? '로딩 중' : '로딩 안 함'}');
      print('현재 상태에 오류가 있는지: ${authState.hasError ? '오류 있음' : '오류 없음'}');

      // 1. 특정 화면에서는 리디렉션하지 않음 - 직접 화면 내에서 처리하도록 함
      final noRedirectPaths = [
        AppRoutes.splash, // 스플래시 화면 (내부 로직으로 처리)
        AppRoutes.login, // 로그인 화면 (로그인 성공/실패 처리를 직접 함)
        AppRoutes.signup, // 회원가입 화면 (회원가입 성공/실패 처리를 직접 함)
      ];

      // 위 경로들에서는 어떤 인증 상태에서도 리디렉션하지 않음
      if (noRedirectPaths.contains(state.matchedLocation)) {
        print('리디렉션 없는 경로 (${state.matchedLocation}) - 직접 처리');
        return null;
      }

      // 2. 인증 프로세스 중에는 리디렉션하지 않음
      if (authState.isLoading) {
        print('인증 진행 중 - 리디렉션 없음');
        return null;
      }

      // 3. 인증 오류가 있고 현재 로그인 화면이 아니면 로그인 화면으로 리디렉션
      if (authState.hasError && state.matchedLocation != AppRoutes.login) {
        print('인증 오류 상태에서 로그인 화면이 아님 - 로그인 화면으로 리디렉션');
        return AppRoutes.login;
      }

      // 4. 루트 경로는 항상 홈으로 리디렉션
      if (state.matchedLocation == '/') {
        print('루트 경로 - 홈으로 리디렉션');
        return AppRoutes.home;
      }

      // 5. 로그인이 필요한 경로들 (인증되지 않은 사용자 리디렉션)
      final requiresAuth = [
            // AppRoutes.profile,      // 프로필 메뉴 자체는 비회원도 접근 가능
            AppRoutes.subscription, // 구독 관련 기능은 로그인 필요
            AppRoutes.fullscreenPlayer,
            // AppRoutes.bookmarks,    // 북마크 메뉴 자체는 비회원도 접근 가능
            '/profile/app-info',
            '/profile/terms',
            '/profile/privacy',
            '/profile/deactivate', // 계정 비활성화는 로그인 필요
            '/profile/feedback',
            '/profile/language',
            '/bookmarks/manage', // 북마크 관리는 로그인 필요
            '/bookmarks/collection', // 컬렉션 접근도 로그인 필요
          ].contains(state.matchedLocation) ||
          state.matchedLocation.startsWith('/bookmarks/collection/');

      // 6. 인증 상태인 사용자가 접근하지 말아야 할 경로들
      final restrictedWhenAuthenticated = [
        AppRoutes.resetPassword,
        AppRoutes.onboarding,
      ]; // 로그인/회원가입 화면은 이미 noRedirectPaths에 있음

      // 7. 인증이 필요한 경로에 접근하려는데 인증되지 않은 상태
      if (requiresAuth && !authState.isAuthenticated) {
        print('인증 필요 경로 (${state.matchedLocation}) 접근 시도 - 로그인으로 리디렉션');
        return AppRoutes.login;
      }

      // 8. 이미 인증된 사용자가 로그인/회원가입 화면 등에 접근하려는 경우
      if (authState.isAuthenticated &&
          restrictedWhenAuthenticated.contains(state.matchedLocation)) {
        print('인증된 사용자가 제한된 경로 (${state.matchedLocation}) 접근 시도 - 홈으로 리디렉션');
        return AppRoutes.home;
      }

      // 9. 위의 조건에 해당하지 않는 경우 리디렉션 없음
      print('리디렉션 없음 - 현재 경로 유지: ${state.matchedLocation}');
      return null;
    },
    routes: [
      // 스플래시 화면
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
        redirect: (context, state) {
          // 스플래시 화면에서는 리다이렉트를 하지 않음 (SplashScreen에서 처리)
          return null;
        },
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
        name: AppRoutes.subscription,
        builder: (context, state) => const profile_subscription.SubscriptionScreen(),
      ),

      // 구독 상품 화면 (인앱 결제 화면)
      GoRoute(
        path: AppRoutes.subscriptionPlans,
        name: AppRoutes.subscriptionPlans,
        builder: (context, state) => const SubscriptionScreen(),
      ),

      // 구독 혜택 화면
      GoRoute(
        path: AppRoutes.subscriptionBenefits,
        name: AppRoutes.subscriptionBenefits,
        builder: (context, state) => const SubscriptionBenefitsScreen(),
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
                  // 컬렉션 관리 화면 - 로그인 필요
                  GoRoute(
                    path: 'manage',
                    builder: (context, state) {
                      final authState = ref.read(authControllerProvider);

                      // 로그인된 사용자만 컬렉션 관리 가능
                      if (!authState.isAuthenticated) {
                        // 로그인 필요 팝업 표시 후 로그인 화면으로 리다이렉트
                        Future.microtask(() {
                          // 스낵바로 로그인 필요 안내
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('컬렉션 관리는 로그인 후 이용 가능합니다.'),
                              action: SnackBarAction(
                                label: '로그인',
                                onPressed: () {
                                  context.push(AppRoutes.login);
                                },
                              ),
                            ),
                          );
                        });

                        // 로그인하지 않은 상태에서는 북마크 기본 화면 표시
                        return const BookmarksScreen();
                      }

                      return const CollectionManagementScreen();
                    },
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
                  // 앱 정보
                  GoRoute(
                    path: 'app-info',
                    builder: (context, state) => const AppInfoScreen(),
                  ),
                  // 이용약관
                  GoRoute(
                    path: 'terms',
                    builder: (context, state) => const TermsScreen(),
                  ),
                  // 개인정보 처리방침
                  GoRoute(
                    path: 'privacy',
                    builder: (context, state) => const PrivacyPolicyScreen(),
                  ),
                  // 회원 탈퇴
                  GoRoute(
                    path: 'deactivate',
                    builder: (context, state) {
                      final authState = ref.read(authControllerProvider);

                      // 로그인된 사용자만 회원 탈퇴 가능
                      if (!authState.isAuthenticated) {
                        // 로그인 필요 팝업 표시 후 로그인 화면으로 리다이렉트
                        Future.microtask(() {
                          // 스낵바로 로그인 필요 안내
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('회원 탈퇴는 로그인 후 이용 가능합니다.'),
                              action: SnackBarAction(
                                label: '로그인',
                                onPressed: () {
                                  context.push(AppRoutes.login);
                                },
                              ),
                            ),
                          );

                          // 로그인 화면으로 이동
                          context.push(AppRoutes.login);
                        });

                        // 로그인하지 않은 상태에서는 프로필 기본 화면으로 이동
                        return const ProfileScreen();
                      }

                      return const DeactivateAccountScreen();
                    },
                  ),
                  // 건의하기
                  GoRoute(
                    path: 'feedback',
                    builder: (context, state) => const FeedbackScreen(),
                  ),
                  // 언어 설정
                  GoRoute(
                    path: 'language',
                    builder: (context, state) => const LanguageScreen(),
                  ),
                  // 구독 관리
                  GoRoute(
                    path: 'subscription',
                    builder: (context, state) {
                      final authState = ref.read(authControllerProvider);

                      // 로그인된 사용자만 구독 관리 가능
                      if (!authState.isAuthenticated) {
                        // 로그인 필요 팝업 표시 후 로그인 화면으로 리다이렉트
                        Future.microtask(() {
                          // 스낵바로 로그인 필요 안내
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('구독 관리는 로그인 후 이용 가능합니다.'),
                              action: SnackBarAction(
                                label: '로그인',
                                onPressed: () {
                                  context.push(AppRoutes.login);
                                },
                              ),
                            ),
                          );

                          // 로그인 화면으로 이동
                          context.push(AppRoutes.login);
                        });

                        // 로그인하지 않은 상태에서는 프로필 기본 화면으로 이동
                        return const ProfileScreen();
                      }

                      return const profile_subscription.SubscriptionScreen();
                    },
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
