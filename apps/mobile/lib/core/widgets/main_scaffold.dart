import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/video_player/providers/video_player_provider.dart';

/// 현재 활성화된 NavigationShell을 저장하는 전역 상태 프로바이더
final activeNavigationShellProvider = StateProvider<StatefulNavigationShell?>((ref) => null);

/// 메인 스캐폴드 위젯
/// 하단 탭 네비게이션과 앱 바를 포함한 기본 레이아웃을 제공합니다.
class MainScaffold extends ConsumerStatefulWidget {
  /// 생성자
  const MainScaffold({
    required this.navigationShell,
    super.key,
  });

  /// 네비게이션 셸
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  @override
  void initState() {
    super.initState();
    // 빌드 사이클 외부에서 프로바이더 상태 업데이트
    Future.microtask(() {
      ref.read(activeNavigationShellProvider.notifier).state = widget.navigationShell;
    });
  }

  @override
  void didUpdateWidget(MainScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // navigationShell이 변경되었을 때만 상태 업데이트
    if (oldWidget.navigationShell != widget.navigationShell) {
      Future.microtask(() {
        ref.read(activeNavigationShellProvider.notifier).state = widget.navigationShell;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 선택된 탭 인덱스
    final selectedIndex = widget.navigationShell.currentIndex;

    // 현지화 리소스 가져오기
    final l10n = AppLocalizations.of(context);

    // 화면 방향 감지 - 가로 모드에서는 탭 바를 숨김
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // 현재 실행 중인 비디오 플레이어 리소스 정리 함수
    void cleanupVideoPlayerResources(BuildContext context) {
      try {
        // 전역 비디오 플레이어 상태 관리를 통해 리소스 정리
        final videoLifecycle = ref.read(videoPlayerLifecycleProvider);

        if (videoLifecycle.isPlaying && videoLifecycle.activeVideoId != null) {
          debugPrint('탭 전환: 비디오 플레이어 리소스 정리 시작 (ID: ${videoLifecycle.activeVideoId})');

          // 빌드 사이클 이후에 Provider 상태 변경을 위해 Future.microtask 사용
          Future.microtask(() {
            ref.read(videoPlayerLifecycleProvider.notifier).stopPlaying();
          });
        }
      } catch (e) {
        debugPrint('비디오 리소스 정리 오류: $e');
      }
    }

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: isLandscape
          ? null
          : NavigationBar(
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: l10n.nav_home,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.search_outlined),
                  selectedIcon: const Icon(Icons.search),
                  label: l10n.nav_search,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.bookmark_border_outlined),
                  selectedIcon: const Icon(Icons.bookmark),
                  label: l10n.nav_bookmarks,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outlined),
                  selectedIcon: const Icon(Icons.person),
                  label: l10n.nav_profile,
                ),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                if (selectedIndex == index) {
                  // 이미 선택된 탭을 다시 눌렀을 때의 처리
                  // 홈 탭에서는 맨 위로 스크롤, 다른 탭에서는 루트 경로로 이동
                  return;
                }

                // 탭 변경 시 동영상 플레이어 자원 정리
                cleanupVideoPlayerResources(context);

                // 탭 전환
                widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == selectedIndex,
                );
              },
            ),
    );
  }
}
