import 'package:api_client/api_client.dart';

/// 피드 탭
enum FeedTab {
  /// 인기 비디오
  trending,

  /// 최신 비디오
  rising,
}

/// 피드 상태
class FeedState {
  /// 기본 생성자
  const FeedState({
    this.trendingVideos = const [],
    this.risingVideos = const [],
    this.selectedTab = FeedTab.trending,
    this.hasMoreTrending = true,
    this.hasMoreRising = true,
    this.lastTrendingId,
    this.lastRisingId,
    this.loadingMore = false,
    this.lastRefreshed,
    this.error,
    this.isOffline = false,
  });

  /// 인기 비디오 목록
  final List<Video> trendingVideos;

  /// 최신 비디오 목록
  final List<Video> risingVideos;

  /// 현재 선택된 탭
  final FeedTab selectedTab;

  /// 인기 비디오 더 있는지 여부
  final bool hasMoreTrending;

  /// 최신 비디오 더 있는지 여부
  final bool hasMoreRising;

  /// 마지막 인기 비디오 ID
  final String? lastTrendingId;

  /// 마지막 최신 비디오 ID
  final String? lastRisingId;

  /// 추가 로딩 중 여부
  final bool loadingMore;

  /// 마지막 새로고침 시간
  final DateTime? lastRefreshed;

  /// 오류 메시지
  final String? error;

  /// 오프라인 모드 여부
  final bool isOffline;

  /// 현재 선택된 탭의 비디오 목록
  List<Video> get currentVideos => selectedTab == FeedTab.trending ? trendingVideos : risingVideos;

  /// 현재 선택된 탭의 더 불러올 수 있는지 여부
  bool get hasMore => selectedTab == FeedTab.trending ? hasMoreTrending : hasMoreRising;

  /// 현재 선택된 탭의 마지막 비디오 ID
  String? get lastId => selectedTab == FeedTab.trending ? lastTrendingId : lastRisingId;

  /// 상태 복사본 생성
  FeedState copyWith({
    List<Video>? trendingVideos,
    List<Video>? risingVideos,
    FeedTab? selectedTab,
    bool? hasMoreTrending,
    bool? hasMoreRising,
    String? lastTrendingId,
    String? lastRisingId,
    bool? loadingMore,
    DateTime? lastRefreshed,
    String? error,
    bool? isOffline,
  }) {
    return FeedState(
      trendingVideos: trendingVideos ?? this.trendingVideos,
      risingVideos: risingVideos ?? this.risingVideos,
      selectedTab: selectedTab ?? this.selectedTab,
      hasMoreTrending: hasMoreTrending ?? this.hasMoreTrending,
      hasMoreRising: hasMoreRising ?? this.hasMoreRising,
      lastTrendingId: lastTrendingId ?? this.lastTrendingId,
      lastRisingId: lastRisingId ?? this.lastRisingId,
      loadingMore: loadingMore ?? this.loadingMore,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      error: error ?? this.error,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
