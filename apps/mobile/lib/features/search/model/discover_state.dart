import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';

/// 발견 화면 상태
@immutable
class DiscoverState {
  /// 생성자
  const DiscoverState({
    this.isLoading = false,
    this.error,
    this.popularArtists = const [],
    this.trendingVideos = const [],
    this.recentVideos = const [],
    this.groupVideos = const {},
  });

  /// 로딩 중 여부
  final bool isLoading;

  /// 에러 메시지
  final String? error;

  /// 인기 아티스트 목록
  final List<Artist> popularArtists;

  /// 인기 영상 목록
  final List<Video> trendingVideos;

  /// 최신 영상 목록
  final List<Video> recentVideos;

  /// 그룹별 인기 영상 (그룹 이름 -> 영상 목록 맵)
  final Map<String, List<Video>> groupVideos;

  /// 데이터 존재 여부
  bool get hasData =>
      popularArtists.isNotEmpty ||
      trendingVideos.isNotEmpty ||
      recentVideos.isNotEmpty ||
      groupVideos.isNotEmpty;

  /// 초기 상태
  factory DiscoverState.initial() {
    return const DiscoverState();
  }

  /// 복사본 생성
  DiscoverState copyWith({
    bool? isLoading,
    String? error,
    List<Artist>? popularArtists,
    List<Video>? trendingVideos,
    List<Video>? recentVideos,
    Map<String, List<Video>>? groupVideos,
  }) {
    return DiscoverState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      popularArtists: popularArtists ?? this.popularArtists,
      trendingVideos: trendingVideos ?? this.trendingVideos,
      recentVideos: recentVideos ?? this.recentVideos,
      groupVideos: groupVideos ?? this.groupVideos,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscoverState &&
        other.isLoading == isLoading &&
        other.error == error &&
        listEquals(other.popularArtists, popularArtists) &&
        listEquals(other.trendingVideos, trendingVideos) &&
        listEquals(other.recentVideos, recentVideos) &&
        mapEquals(other.groupVideos, groupVideos);
  }

  @override
  int get hashCode {
    return Object.hash(
      isLoading,
      error,
      Object.hashAll(popularArtists),
      Object.hashAll(trendingVideos),
      Object.hashAll(recentVideos),
      Object.hashAll(groupVideos.entries),
    );
  }
}
