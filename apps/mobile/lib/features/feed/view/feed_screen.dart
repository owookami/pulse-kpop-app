import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/feed/model/feed_state.dart';
import 'package:mobile/features/feed/provider/feed_provider.dart';
import 'package:mobile/features/feed/widgets/video_card.dart';
import 'package:mobile/features/subscription/helpers/subscription_helpers.dart';
import 'package:mobile/features/subscription/provider/subscription_provider.dart';

/// 피드 화면
class FeedScreen extends ConsumerStatefulWidget {
  /// 생성자
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  late TabController _tabController;

  // 연속적인 로드 요청 방지를 위한 플래그
  bool _isLoadingMore = false;

  // 현재 시청 횟수
  int _viewCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);

    // 스크롤 위치 복원을 위한 포스트 프레임 콜백
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPosition();
      _loadViewCount();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 스크롤 위치 저장
    final feedState = ref.read(feedVideosProvider);
    ref.read(feedScrollPositionProvider.notifier).update((state) => {
          ...state,
          feedState.selectedTab: _scrollController.position.pixels,
        });

    // 무한 스크롤 처리
    if (!_isLoadingMore &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _isLoadingMore = true;
      ref.read(feedVideosProvider.notifier).loadMoreVideos().then((_) {
        _isLoadingMore = false;
      });
    }
  }

  void _restoreScrollPosition() {
    final feedState = ref.read(feedVideosProvider);
    final savedPositions = ref.read(feedScrollPositionProvider);
    final savedPosition = savedPositions[feedState.selectedTab] ?? 0.0;

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        savedPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    }
  }

  void _onTabChanged(FeedTab tab) {
    ref.read(feedVideosProvider.notifier).changeTab(tab);

    // 저장된 스크롤 위치로 이동
    final savedPositions = ref.read(feedScrollPositionProvider);
    final savedPosition = savedPositions[tab] ?? 0.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController
            .jumpTo(savedPosition.clamp(0.0, _scrollController.position.maxScrollExtent));
      }
    });
  }

  void _onVideoTap(Video video) {
    ref.read(selectedVideoProvider.notifier).update((_) => video);
    SubscriptionHelpers.handleVideoSelection(context, ref, video);

    // 시청 횟수 업데이트 - UI 반영을 위해
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadViewCount();
    });
  }

  // 시청 횟수 로드
  Future<void> _loadViewCount() async {
    final count = await SubscriptionHelpers.loadGuestViewCount();
    setState(() {
      _viewCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final feedState = ref.watch(feedVideosProvider);
    final currentTab = feedState.selectedTab;
    final videos = feedState.currentVideos;
    final error = feedState.error;
    final isLoadingMore = feedState.loadingMore;
    final isOffline = feedState.isOffline;

    // 무료 시청 정보
    final remainingViews = SubscriptionHelpers.maxGuestViewCount - _viewCount;
    final hasRemainingViews = remainingViews > 0;

    // 탭 컨트롤러 인덱스 업데이트
    if (_tabController.index != currentTab.index) {
      _tabController.animateTo(currentTab.index);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulse'),
        bottom: TabBar(
          tabs: const [
            Tab(text: '인기'),
            Tab(text: '최신'),
          ],
          onTap: (index) {
            _onTabChanged(FeedTab.values[index]);
          },
          controller: _tabController,
        ),
      ),
      body: Column(
        children: [
          // 오프라인 모드 표시
          if (isOffline)
            Container(
              color: Colors.amber.shade700,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              width: double.infinity,
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    '오프라인 모드',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // 프리미엄 구독 안내 배너
          if (!ref.watch(authControllerProvider).isAuthenticated ||
              !ref.watch(subscriptionProvider).isPremium)
            Container(
              color: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      !ref.watch(authControllerProvider).isAuthenticated
                          ? '무료 시청 $remainingViews회 남음 (총 ${SubscriptionHelpers.maxGuestViewCount}회)'
                          : '프리미엄 구독으로 모든 콘텐츠를 무제한 시청하세요',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      // 구독 화면으로 이동
                      Navigator.pushNamed(context, '/subscription');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text('무제한 시청하기'),
                  )
                ],
              ),
            ),
          // 피드 내용
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(feedVideosProvider.notifier).refresh(),
              child: error != null && videos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('오류가 발생했습니다: $error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.read(feedVideosProvider.notifier).refresh(),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    )
                  : videos.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: videos.length + (isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == videos.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final video = videos[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: VideoCard(
                                video: video,
                                onTap: () => _onVideoTap(video),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
