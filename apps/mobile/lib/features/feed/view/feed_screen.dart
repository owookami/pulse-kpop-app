import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/ads/service/ad_service.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/feed/model/feed_state.dart';
import 'package:mobile/features/feed/provider/feed_provider.dart';
import 'package:mobile/features/feed/widgets/video_card.dart';
import 'package:mobile/features/subscription/helpers/subscription_helpers.dart';
import 'package:mobile/features/subscription/provider/new_subscription_provider.dart';
import 'package:mobile/features/video_player/view/video_player_screen.dart';
import 'package:mobile/routes/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 피드 화면
class FeedScreen extends ConsumerStatefulWidget {
  /// 생성자
  const FeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final AdService _adService = AdService();

  // 미리 로드 트리거 위치 (스크롤이 끝에서 이만큼 픽셀 남았을 때 로드 시작)
  static const double _preloadOffset = 200.0;

  // 연속적인 로드 요청 방지를 위한 플래그
  bool _isLoadingMore = false;

  // 새로고침 상태 추적
  bool _isRefreshing = false;

  // 스크롤 최적화를 위한 스로틀 타이머
  DateTime? _lastLoadTime;

  // 현재 시청 횟수
  int _viewCount = 0;

  // 비디오 캐시 관리
  final Map<FeedViewType, List<Video>> _videoCache = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // 초기 설정 및 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadViewCount();

      // 로딩 상태 리셋 - 무한 스크롤 버그 수정
      ref.read(videoLoadingStateProvider(FeedViewType.popular).notifier).state = false;
      setState(() {
        _isLoadingMore = false;
      });

      // 초기 데이터 로드 - 항상 인기 탭으로 시작
      ref.read(feedViewTypeProvider.notifier).state = FeedViewType.popular;
      _refreshFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 화면 활성화 시 로딩 상태 체크 및 초기화
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 로딩 상태가 stuck된 경우를 위한 안전장치
    final isLoading = ref.read(videoLoadingStateProvider(FeedViewType.popular));
    if ((isLoading && !_isLoadingMore) || (!isLoading && _isLoadingMore)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isLoading && !_isLoadingMore) {
          debugPrint('로딩 상태 불일치 감지 및 수정 (provider=true, local=false)');
          ref.read(videoLoadingStateProvider(FeedViewType.popular).notifier).state = false;
        } else if (!isLoading && _isLoadingMore) {
          debugPrint('로딩 상태 불일치 감지 및 수정 (provider=false, local=true)');
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  // 하단에 도달했는지 확인하고 추가 비디오 로드
  bool _handleScrollNotification(ScrollNotification notification) {
    // 스크롤 상태 확인 - 로딩 중이면 무시
    if (_isLoadingMore) {
      // 이미 로딩 중이므로 이벤트 무시
      return false;
    }

    // 관련 스크롤 이벤트만 처리
    if (notification is! ScrollUpdateNotification && notification is! ScrollEndNotification) {
      return false;
    }

    // 스크롤 위치 정보 계산
    final pixels = notification.metrics.pixels;
    final maxExtent = notification.metrics.maxScrollExtent;
    final viewportDimension = notification.metrics.viewportDimension;

    // 로그 추가 - 현재 스크롤 포지션 디버깅
    if (notification is ScrollUpdateNotification && (pixels / maxExtent) > 0.5) {
      // 스크롤이 50% 이상일 때만 로깅
      debugPrint(
          '스크롤 위치: ${pixels.toStringAsFixed(1)}/${maxExtent.toStringAsFixed(1)} (${(pixels / maxExtent * 100).toStringAsFixed(1)}%)');
    }

    // 스크롤 위치가 하단에 가까워지면 더 일찍 로드 시작 (70% 지점)
    const triggerThreshold = 0.7; // 70% 위치에서 트리거

    // 스크롤이 최대치에 가까워지면 로드 시작
    final shouldLoadMore = pixels >= (maxExtent * triggerThreshold);

    if (shouldLoadMore) {
      debugPrint(
          '무한 스크롤 트리거됨: 현재=${pixels.toStringAsFixed(1)}px, 최대=${maxExtent.toStringAsFixed(1)}px, 임계점=${(maxExtent * triggerThreshold).toStringAsFixed(1)}px');
      _triggerInfiniteScroll();
    }

    return false; // 이벤트 계속 전파
  }

  // 무한 스크롤 트리거 - 스로틀링 적용
  void _triggerInfiniteScroll() {
    // 상태 확인 간단화 - 로컬 플래그만 확인
    if (_isLoadingMore) {
      debugPrint('이미 로딩 중이므로 추가 로드 요청 무시 (화면 상태)');
      return;
    }

    // 스로틀링 적용 (1000ms 내 중복 호출 방지) - 더 길게 설정
    final now = DateTime.now();
    if (_lastLoadTime != null && now.difference(_lastLoadTime!).inMilliseconds < 1000) {
      debugPrint('스로틀링으로 인해 요청 무시 (1초 이내 중복 요청)');
      return;
    }

    // 항상 인기 탭만 사용
    const viewType = FeedViewType.popular;

    // 더 로드할 데이터가 있는지 확인
    if (!ref.read(feedVideosProvider.notifier).hasMoreData(viewType)) {
      debugPrint('더 이상 로드할 데이터가 없음: $viewType');
      return;
    }

    // 양쪽 로딩 상태 모두 설정 - 빌드 사이클 완료 후 실행
    debugPrint('무한 스크롤 로드 시작 - 로딩 상태 설정');
    setState(() {
      _isLoadingMore = true;
      _lastLoadTime = now;
    });

    // 프로바이더 상태 변경을 마이크로태스크로 감싸서 빌드 사이클 이후에 실행
    Future.microtask(() {
      // 프로바이더 로딩 상태도 직접 설정
      ref.read(videoLoadingStateProvider(viewType).notifier).state = true;

      // 추가 데이터 로드 요청
      ref.read(feedVideosProvider.notifier).loadMoreVideos(viewType).then((videos) {
        debugPrint('무한 스크롤 로드 완료됨, 로딩 상태 해제');

        if (mounted) {
          // 안전하게 비디오 데이터 접근 - 배열 인덱스 오류 방지
          try {
            // 실제 불러온 비디오 개수 계산
            final currentVideos = _videoCache[viewType] ?? [];
            final newVideosCount = videos.isEmpty ? 0 : (videos.length - currentVideos.length);

            debugPrint('무한 스크롤 로드 완료: 새로 불러온 비디오 $newVideosCount개, 전체 ${videos.length}개');

            // 새 비디오 캐시 저장 - 비어있지 않은 경우에만
            if (videos.isNotEmpty) {
              _videoCache[viewType] = videos;
            }
          } catch (e) {
            debugPrint('비디오 데이터 처리 중 오류: $e');
          }

          // 로딩 상태 해제 - 양쪽 모두 명시적으로 설정
          setState(() {
            _isLoadingMore = false;
          });
          ref.read(videoLoadingStateProvider(viewType).notifier).state = false;
          debugPrint('로딩 상태 해제 완료 (화면 및 프로바이더)');
        } else {
          // 위젯 마운트 해제 상태에서도 프로바이더 상태 리셋
          ref.read(videoLoadingStateProvider(viewType).notifier).state = false;
          debugPrint('위젯 마운트 해제됨 - 프로바이더 로딩 상태만 리셋');
        }
      }).catchError((error) {
        debugPrint('무한 스크롤 로드 오류: $error');

        // 반드시 양쪽 상태 모두 리셋
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
        ref.read(videoLoadingStateProvider(viewType).notifier).state = false;
        debugPrint('오류 발생 후 로딩 상태 모두 해제됨');
      });
    });
  }

  Future<void> _refreshFeed() async {
    // 항상 인기 탭만 사용
    const viewType = FeedViewType.popular;
    await ref.read(feedVideosProvider.notifier).loadVideos(viewType, forceRefresh: true);
  }

  // 시청 횟수 로드
  Future<void> _loadViewCount() async {
    final count = await SubscriptionHelpers.loadGuestViewCount();
    if (mounted) {
      setState(() {
        _viewCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final feedState = ref.watch(feedVideosProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pulse',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black54),
            onPressed: () {
              // 검색 화면으로 이동
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _refreshFeed,
          ),
        ],
      ),
      body: Column(
        children: [
          // 구독 프로모션 배너 - 비회원이거나 비구독 사용자에게만 표시
          if (!SubscriptionHelpers.isPremiumUser(ref)) _buildSubscriptionBanner(context, ref),

          // 기존 body 내용
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _isRefreshing = true;
                });

                try {
                  await ref
                      .read(feedVideosProvider.notifier)
                      .loadVideos(FeedViewType.popular, forceRefresh: true);
                } finally {
                  if (mounted) {
                    setState(() {
                      _isRefreshing = false;
                    });
                  }
                }
              },
              child: feedState.when(
                data: (videos) => _buildVideoList(context, videos),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(l10n.app_error_generic),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToVideoPlayer(BuildContext context, WidgetRef ref, Video video) {
    // 프로바이더 상태 변경을 빌드 사이클 이후로 지연
    Future.microtask(() {
      ref.read(feedVideosProvider.notifier).selectVideo(video);
    });

    // 구독 상태 확인
    final isSubscribed = ref.read(isPremiumUserProvider).maybeWhen(
          data: (value) => value,
          orElse: () => false,
        );

    if (isSubscribed) {
      // 구독자는 바로 비디오 플레이어로 이동
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(video: video),
          fullscreenDialog: true,
        ),
      );
    } else {
      // 비구독자는 광고 표시 후 이동 - 이 시점에서 광고 로드
      _adService.loadInterstitialAd();

      // 광고 표시 후 비디오 플레이어로 이동
      _adService.showInterstitialAd(
        onAdDismissed: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(video: video),
              fullscreenDialog: true,
            ),
          );
        },
        onAdFailedToShow: () {
          // 광고 표시 실패 시 바로 비디오 플레이어로 이동
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(video: video),
              fullscreenDialog: true,
            ),
          );
        },
      );
    }
  }

  // 로딩 인디케이터 또는 '더 이상 콘텐츠 없음' 표시
  Widget _buildLoadingIndicator() {
    // 로딩 중이면 로딩 인디케이터 표시
    if (_isLoadingMore) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        alignment: Alignment.center,
        child: Column(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '더 많은 동영상 로드 중...',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // 더 로드할 데이터가 있는지 확인
    final hasMoreData = ref.read(feedVideosProvider.notifier).hasMoreData(FeedViewType.popular);

    // 더 로드할 데이터가 있으면 안내 메시지 표시
    if (hasMoreData) {
      return GestureDetector(
        onTap: () {
          debugPrint('더 불러오기 버튼 클릭');
          _triggerInfiniteScroll(); // 탭으로도 추가 로드 가능하게
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_downward, size: 18, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                '스크롤하여 더 많은 동영상 보기',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 더 이상 데이터가 없으면 안내 메시지 표시
    final loadedVideos = ref.read(feedVideosProvider).valueOrNull?.length ?? 0;
    final totalVideoCount = ref.read(feedVideosProvider.notifier).getTotalVideoCount();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 32, color: Colors.grey[500]),
          const SizedBox(height: 8),
          Text(
            '모든 동영상을 불러왔습니다 ($loadedVideos/$totalVideoCount)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '총 $totalVideoCount개 중 $loadedVideos개 로드 완료',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          TextButton(
            onPressed: _refreshFeed,
            child: const Text('새로고침'),
          )
        ],
      ),
    );
  }

  // 비디오 삭제 확인 대화상자
  void _showDeleteConfirmation(BuildContext context, Video video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('동영상 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('정말 이 동영상을 삭제하시겠습니까?'),
            const SizedBox(height: 12),
            Text(
              video.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('ID: ${video.id}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => _deleteVideo(context, video),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 비디오 삭제 기능
  Future<void> _deleteVideo(BuildContext context, Video video) async {
    Navigator.of(context).pop(); // 대화상자 닫기

    try {
      final supabase = Supabase.instance.client;

      // 로딩 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('동영상 삭제 중...'),
          duration: Duration(seconds: 2),
        ),
      );

      // 실제 비디오 삭제 API 호출
      final response = await supabase.from('videos').delete().eq('id', video.id);

      // 피드 새로고침
      if (mounted) {
        _refreshFeed();

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('동영상 삭제 완료: ${video.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('동영상 삭제 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 비디오 목록을 표시하는 위젯 생성
  Widget _buildVideoList(BuildContext context, List<Video> videos) {
    if (videos.isEmpty) {
      return const Center(
        child: Text('표시할 동영상이 없습니다.'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: videos.length + 1, // 마지막에 로딩 인디케이터 추가
      itemBuilder: (context, index) {
        // 마지막 항목은 로딩 인디케이터 또는 '더 이상 없음' 메시지
        if (index == videos.length) {
          return _buildLoadingIndicator();
        }

        // 일반 비디오 카드 표시
        final video = videos[index];
        return VideoCard(
          video: video,
          onTap: () => _navigateToVideoPlayer(context, ref, video),
        );
      },
    );
  }

  /// 구독 프로모션 배너 위젯
  Widget _buildSubscriptionBanner(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const videoViewsLeft = 10; // 실제 구현에서는 서비스에서 남은 시청 수 가져오기

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
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
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '무료 시청 $videoViewsLeft회 남음',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () {
                  // 배너 닫기 상태 저장 - 로컬에서만 처리
                  setState(() {
                    // 배너 숨기기 처리
                  });
                },
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '프리미엄 구독으로 모든 영상을 광고 없이 무제한 시청하세요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // 로그인 상태 확인
                final authState = ref.read(authControllerProvider);
                final isAuthenticated = authState.isAuthenticated;

                if (isAuthenticated) {
                  // 로그인 상태이면 바로 구독 상품 페이지로 이동
                  context.go(AppRoutes.subscriptionPlans);
                } else {
                  // 비로그인 상태이면 안내 다이얼로그 표시
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
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('구독하기'),
            ),
          ),
        ],
      ),
    );
  }
}

// 더 가벼운 항목 유지 헬퍼 위젯
class KeepAlive extends StatefulWidget {
  const KeepAlive({
    Key? key,
    required this.keepAlive,
    required this.child,
  }) : super(key: key);

  final bool keepAlive;
  final Widget child;

  @override
  KeepAliveState createState() => KeepAliveState();
}

class KeepAliveState extends State<KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  void didUpdateWidget(KeepAlive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keepAlive != widget.keepAlive) {
      updateKeepAlive();
    }
  }
}
