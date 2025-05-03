import 'package:api_client/api_client.dart';

/// 추천 알고리즘 상태 모델
class RecommendationState {
  /// 생성자
  const RecommendationState({
    this.forYouVideos = const [],
    this.trendingVideos = const [],
    this.basedOnHistoryVideos = const [],
    this.similarArtistsVideos = const [],
    this.isLoading = false,
  });

  /// 'For You' 섹션 비디오 목록
  final List<Video> forYouVideos;

  /// 트렌딩 비디오 목록
  final List<Video> trendingVideos;

  /// 시청 기록 기반 추천 비디오 목록
  final List<Video> basedOnHistoryVideos;

  /// 비슷한 아티스트 비디오 목록
  final List<Video> similarArtistsVideos;

  /// 로딩 상태
  final bool isLoading;

  /// 빈 상태 생성
  factory RecommendationState.empty() => const RecommendationState();

  /// 로딩 상태 복사본 생성
  RecommendationState copyWith({
    List<Video>? forYouVideos,
    List<Video>? trendingVideos,
    List<Video>? basedOnHistoryVideos,
    List<Video>? similarArtistsVideos,
    bool? isLoading,
  }) {
    return RecommendationState(
      forYouVideos: forYouVideos ?? this.forYouVideos,
      trendingVideos: trendingVideos ?? this.trendingVideos,
      basedOnHistoryVideos: basedOnHistoryVideos ?? this.basedOnHistoryVideos,
      similarArtistsVideos: similarArtistsVideos ?? this.similarArtistsVideos,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
