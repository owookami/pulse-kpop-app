import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';

/// 아티스트 상태 모델
@immutable
class ArtistState {
  /// 생성자
  const ArtistState({
    this.selectedArtist,
    this.artistVideos = const [],
    this.isLoading = false,
    this.error,
    this.followedArtists = const [],
    this.isFollowingSelectedArtist = false,
    this.isLoadingFollow = false,
    this.followedArtistsCount = 0,
  });

  /// 현재 선택된 아티스트
  final Artist? selectedArtist;

  /// 아티스트의 비디오 목록
  final List<Video> artistVideos;

  /// 로딩 중 여부
  final bool isLoading;

  /// 에러 정보
  final String? error;

  /// 팔로우한 아티스트 목록
  final List<Artist> followedArtists;

  /// 현재 선택된 아티스트 팔로우 여부
  final bool isFollowingSelectedArtist;

  /// 팔로우/언팔로우 로딩 중 여부
  final bool isLoadingFollow;

  /// 팔로우한 아티스트 수
  final int followedArtistsCount;

  /// 초기 상태
  factory ArtistState.initial() => const ArtistState();

  /// 복사본 생성
  ArtistState copyWith({
    Artist? selectedArtist,
    List<Video>? artistVideos,
    bool? isLoading,
    String? error,
    List<Artist>? followedArtists,
    bool? isFollowingSelectedArtist,
    bool? isLoadingFollow,
    int? followedArtistsCount,
  }) {
    return ArtistState(
      selectedArtist: selectedArtist ?? this.selectedArtist,
      artistVideos: artistVideos ?? this.artistVideos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      followedArtists: followedArtists ?? this.followedArtists,
      isFollowingSelectedArtist: isFollowingSelectedArtist ?? this.isFollowingSelectedArtist,
      isLoadingFollow: isLoadingFollow ?? this.isLoadingFollow,
      followedArtistsCount: followedArtistsCount ?? this.followedArtistsCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ArtistState &&
        other.selectedArtist == selectedArtist &&
        listEquals(other.artistVideos, artistVideos) &&
        other.isLoading == isLoading &&
        other.error == error &&
        listEquals(other.followedArtists, followedArtists) &&
        other.isFollowingSelectedArtist == isFollowingSelectedArtist &&
        other.isLoadingFollow == isLoadingFollow &&
        other.followedArtistsCount == followedArtistsCount;
  }

  @override
  int get hashCode {
    return selectedArtist.hashCode ^
        artistVideos.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        followedArtists.hashCode ^
        isFollowingSelectedArtist.hashCode ^
        isLoadingFollow.hashCode ^
        followedArtistsCount.hashCode;
  }
}
