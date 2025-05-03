import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 현재 활성화된 NavigationShell을 저장하는 전역 상태 프로바이더
final activeNavigationShellProvider = StateProvider<StatefulNavigationShell?>((ref) => null);

/// 메인 스캐폴드 위젯
/// 하단 탭 네비게이션과 앱 바를 포함한 기본 레이아웃을 제공합니다.
class MainScaffold extends ConsumerWidget {
  /// 생성자
  const MainScaffold({
    required this.navigationShell,
    super.key,
  });

  /// 네비게이션 셸
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 선택된 탭 인덱스
    final selectedIndex = navigationShell.currentIndex;

    // 전역 상태에 navigationShell 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeNavigationShellProvider.notifier).state = navigationShell;
    });

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          // 다른 탭으로 이동
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          // 홈/피드 탭
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          // 검색 탭
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '검색',
          ),
          // 북마크 탭
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: '북마크',
          ),
          // 프로필 탭
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
        // Material 3 스타일링
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
      ),
    );
  }
}
