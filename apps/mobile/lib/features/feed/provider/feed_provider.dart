import 'package:api_client/api_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/feed/model/feed_state.dart';

/// 피드 스크롤 위치 저장용 프로바이더
final feedScrollPositionProvider = StateProvider<Map<FeedTab, double>>((ref) {
  return {
    FeedTab.trending: 0,
    FeedTab.rising: 0,
  };
});

/// 비디오 선택 프로바이더
final selectedVideoProvider = StateProvider<Video?>((ref) {
  return null;
});

/// 현재 선택된 탭 프로바이더
final selectedFeedTabProvider = StateProvider<FeedTab>((ref) {
  return FeedTab.trending;
});

/// 네트워크 연결 상태 프로바이더
final connectivityProvider = Provider<Stream<ConnectivityResult>>((ref) {
  final connectivity = Connectivity();
  // 초기 연결 상태 확인 및 상태 변경 스트림 반환
  return connectivity.onConnectivityChanged.map((results) => results.first);
});

/// 현재 네트워크 상태 프로바이더
final currentConnectivityProvider = FutureProvider<ConnectivityResult>((ref) async {
  final connectivity = Connectivity();
  final results = await connectivity.checkConnectivity();
  return results.first;
});

/// 오프라인 모드 상태 프로바이더
final isOfflineModeProvider = Provider<bool>((ref) {
  final connectivityState = ref.watch(currentConnectivityProvider);
  return connectivityState.maybeWhen(
    data: (result) => result == ConnectivityResult.none,
    orElse: () => false,
  );
});

/// 피드 비디오 목록 프로바이더
final feedVideosProvider = StateNotifierProvider<FeedVideosNotifier, FeedState>((ref) {
  final videoService = ref.watch(videoServiceProvider);
  final isOffline = ref.watch(isOfflineModeProvider);
  return FeedVideosNotifier(
    videoService: videoService,
    isOffline: isOffline,
    ref: ref,
  );
});

/// 피드 비디오 목록 상태 관리 노티파이어
class FeedVideosNotifier extends StateNotifier<FeedState> {
  /// 생성자
  FeedVideosNotifier({
    required VideoService videoService,
    required bool isOffline,
    required Ref ref,
  })  : _videoService = videoService,
        _ref = ref,
        super(FeedState(isOffline: isOffline)) {
    // 네트워크 상태 변경 감지
    _ref.listen(isOfflineModeProvider, (_, isOffline) {
      state = state.copyWith(isOffline: isOffline);
      _videoService.setNetworkStatus(isOffline);
    });

    // 선택된 탭 감지
    _ref.listen(selectedFeedTabProvider, (_, tab) {
      changeTab(tab);
    });

    // 초기 데이터 로드
    _initializeData();
  }

  final VideoService _videoService;
  final Ref _ref;

  /// 초기 데이터 로드
  Future<void> _initializeData() async {
    await Future.wait([
      loadTrendingVideos(refresh: true),
      loadRisingVideos(refresh: true),
    ]);
  }

  /// 탭 변경
  void changeTab(FeedTab tab) {
    state = state.copyWith(selectedTab: tab);
  }

  /// 인기 비디오 로드
  Future<void> loadTrendingVideos({bool refresh = false}) async {
    if (!refresh && !state.hasMoreTrending) return;
    if (state.loadingMore) return;

    state = state.copyWith(loadingMore: true);

    try {
      const limit = 10;

      final response = await _videoService.getTrendingVideos(
        forceRefresh: refresh,
        lastId: refresh ? null : state.lastTrendingId,
      );

      response.fold(
        onSuccess: (newVideos) {
          final hasMore = newVideos.length >= limit;

          if (refresh) {
            state = state.copyWith(
              trendingVideos: newVideos,
              hasMoreTrending: hasMore,
              lastTrendingId: newVideos.isNotEmpty ? newVideos.last.id : null,
              lastRefreshed: DateTime.now(),
              loadingMore: false,
              error: null,
            );
          } else {
            state = state.copyWith(
              trendingVideos: [...state.trendingVideos, ...newVideos],
              hasMoreTrending: hasMore,
              lastTrendingId: newVideos.isNotEmpty ? newVideos.last.id : state.lastTrendingId,
              loadingMore: false,
              error: null,
            );
          }
        },
        onFailure: (error) {
          state = state.copyWith(
            loadingMore: false,
            error: error.message,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        loadingMore: false,
        error: '인기 비디오를 불러오는 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  /// 최신 비디오 로드
  Future<void> loadRisingVideos({bool refresh = false}) async {
    if (!refresh && !state.hasMoreRising) {
      print('더 이상 로드할 최신 비디오가 없음 (hasMoreRising: ${state.hasMoreRising})');
      return;
    }
    if (state.loadingMore) {
      print('이미 비디오 로딩 중 (loadingMore: ${state.loadingMore})');
      return;
    }

    print('최신 비디오 로드 시작: refresh=$refresh, lastRisingId=${state.lastRisingId}');
    state = state.copyWith(loadingMore: true);

    try {
      const limit = 10;

      final response = await _videoService.getRisingVideos(
        forceRefresh: refresh,
        lastId: refresh ? null : state.lastRisingId,
      );

      response.fold(
        onSuccess: (newVideos) {
          print('최신 비디오 ${newVideos.length}개 로드 완료');
          final hasMore = newVideos.length >= limit;
          final newLastId = newVideos.isNotEmpty ? newVideos.last.id : null;

          print('hasMore=$hasMore, newLastId=$newLastId, 현재 lastRisingId=${state.lastRisingId}');

          // 동일한
          if (!refresh && newLastId != null && newLastId == state.lastRisingId) {
            print('경고: 이전과 동일한 lastId - 무한 루프 방지를 위해 hasMore=false로 설정');
            state = state.copyWith(
              hasMoreRising: false,
              loadingMore: false,
              error: null,
            );
            return;
          }

          if (refresh) {
            state = state.copyWith(
              risingVideos: newVideos,
              hasMoreRising: hasMore,
              lastRisingId: newLastId,
              lastRefreshed: DateTime.now(),
              loadingMore: false,
              error: null,
            );
          } else {
            // 이미 존재하는 비디오와 중복 방지
            final existingIds = state.risingVideos.map((v) => v.id).toSet();
            final uniqueNewVideos = newVideos.where((v) => !existingIds.contains(v.id)).toList();

            print('중복 제거 후 새 비디오 ${uniqueNewVideos.length}개 추가');

            if (uniqueNewVideos.isEmpty && newVideos.isNotEmpty) {
              print('새 비디오가 모두 중복됨 - 더 이상 불러올 수 없음');
              state = state.copyWith(
                hasMoreRising: false,
                loadingMore: false,
                error: null,
              );
              return;
            }

            state = state.copyWith(
              risingVideos: [...state.risingVideos, ...uniqueNewVideos],
              hasMoreRising: hasMore,
              lastRisingId: newLastId,
              loadingMore: false,
              error: null,
            );
          }
        },
        onFailure: (error) {
          print('최신 비디오 로드 실패: ${error.message}');
          state = state.copyWith(
            loadingMore: false,
            error: error.message,
          );
        },
      );
    } catch (e) {
      print('최신 비디오 로드 예외 발생: $e');
      state = state.copyWith(
        loadingMore: false,
        error: '최신 비디오를 불러오는 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  /// 현재 탭에 따라 비디오 로드
  Future<void> loadMoreVideos() async {
    if (state.selectedTab == FeedTab.trending) {
      await loadTrendingVideos();
    } else {
      await loadRisingVideos();
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    if (state.selectedTab == FeedTab.trending) {
      await loadTrendingVideos(refresh: true);
    } else {
      await loadRisingVideos(refresh: true);
    }
  }

  /// 비디오 선택
  void selectVideo(Video video) {
    _ref.read(selectedVideoProvider.notifier).update((_) => video);
  }
}
