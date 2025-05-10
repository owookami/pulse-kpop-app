import 'package:api_client/api_client.dart';

/// 피드 탭 정의
enum FeedTab {
  /// 인기 탭
  trending,

  /// 최신 탭
  rising,
}

/// 피드 뷰 타입 정의
enum FeedViewType {
  /// 인기 비디오 (조회수 기준)
  popular,

  /// 최신 비디오 (최근 업로드순)
  latest,

  /// 즐겨찾기 (나중에 구현)
  favorites,
}

/// 피드 상태 모델
class FeedState {
  const FeedState({
    required this.videos,
    required this.isLoading,
    required this.hasMore,
    this.error,
  });

  factory FeedState.initial() => const FeedState(
        videos: [],
        isLoading: false,
        hasMore: true,
        error: null,
      );

  final List<Video> videos;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  FeedState copyWith({
    List<Video>? videos,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return FeedState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}
