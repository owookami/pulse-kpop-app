import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/artist_state.dart';

/// 아티스트 프로바이더
final artistProvider = StateNotifierProvider<ArtistNotifier, ArtistState>((ref) {
  return ArtistNotifier(artistService: artistServiceProvider);
});

/// 아티스트 Notifier 클래스
class ArtistNotifier extends StateNotifier<ArtistState> {
  /// 생성자
  ArtistNotifier({
    required this.artistService,
  }) : super(ArtistState.initial());

  /// 아티스트 서비스
  final ArtistService artistService;

  /// 모든 아티스트 목록 가져오기
  Future<void> getAllArtists() async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await artistService.getAllArtists();

    response.fold(
      onSuccess: (artists) {
        state = state.copyWith(
          followedArtists: artists,
          isLoading: false,
        );
      },
      onFailure: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
      },
    );
  }

  /// 아티스트 상세 정보 가져오기
  Future<void> getArtistDetails(String artistId) async {
    state = state.copyWith(isLoading: true, error: null);

    // 1. 아티스트 기본 정보
    final artistResponse = await artistService.getArtistDetails(artistId: artistId);

    final artistData = artistResponse.dataOrNull;
    if (artistData == null) {
      state = state.copyWith(
        isLoading: false,
        error: artistResponse.errorOrNull?.message ?? '아티스트 정보를 불러오는데 실패했습니다',
      );
      return;
    }

    // 2. 아티스트 팔로우 여부
    final isFollowingResponse = await artistService.isFollowingArtist(artistId: artistId);
    final isFollowing =
        isFollowingResponse.isSuccess ? isFollowingResponse.dataOrNull ?? false : false;

    // 3. 아티스트 팔로워 수
    final followersCountResponse = await artistService.getArtistFollowersCount(artistId: artistId);
    final followersCount =
        followersCountResponse.isSuccess ? followersCountResponse.dataOrNull ?? 0 : 0;

    state = state.copyWith(
      selectedArtist: artistData,
      isFollowingSelectedArtist: isFollowing,
      followedArtistsCount: followersCount,
      isLoading: false,
    );

    // 아티스트 영상 목록은 별도 API로 가져옴 (비동기적으로 UI 업데이트)
    await _loadArtistVideos(artistId);
  }

  /// 팔로우/언팔로우 토글
  Future<void> toggleFollow(String artistId) async {
    if (state.isLoadingFollow) return;

    state = state.copyWith(isLoadingFollow: true);

    final response = state.isFollowingSelectedArtist
        ? await artistService.unfollowArtist(artistId: artistId)
        : await artistService.followArtist(artistId: artistId);

    response.fold(
      onSuccess: (_) async {
        // 팔로워 수 업데이트
        int newCount = state.followedArtistsCount;
        if (state.isFollowingSelectedArtist) {
          newCount = newCount > 0 ? newCount - 1 : 0;
        } else {
          newCount = newCount + 1;
        }

        state = state.copyWith(
          isFollowingSelectedArtist: !state.isFollowingSelectedArtist,
          followedArtistsCount: newCount,
          isLoadingFollow: false,
        );

        // 팔로우 목록 새로고침
        await loadFollowedArtists();
      },
      onFailure: (error) {
        state = state.copyWith(
          isLoadingFollow: false,
          error: error.message,
        );
      },
    );
  }

  /// 사용자가 팔로우한 아티스트 목록 가져오기
  Future<void> loadFollowedArtists() async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await artistService.getFollowedArtists();

    response.fold(
      onSuccess: (artists) {
        state = state.copyWith(
          followedArtists: artists,
          isLoading: false,
        );
      },
      onFailure: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
      },
    );
  }

  /// 아티스트 검색
  Future<List<Artist>> searchArtists(String query) async {
    if (query.isEmpty) return [];

    final response = await artistService.searchArtists(query: query);

    return response.fold(
      onSuccess: (artists) => artists,
      onFailure: (error) {
        state = state.copyWith(
          error: error.message,
        );
        return [];
      },
    );
  }

  /// 아티스트의 비디오 목록 가져오기
  Future<void> _loadArtistVideos(String artistId) async {
    // 실제로는 VideoService에서 아티스트 ID로 비디오 목록을 가져오는 로직을 구현해야 함
    // 임시로 빈 목록 반환
    state = state.copyWith(artistVideos: []);
  }

  /// 현재 선택된 아티스트 변경
  void setSelectedArtist(Artist artist) {
    state = state.copyWith(selectedArtist: artist);
    getArtistDetails(artist.id);
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }
}
