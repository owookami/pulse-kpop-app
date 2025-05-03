import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/bookmarks/provider/bookmark_provider.dart';
import 'package:mobile/features/recommendations/model/recommendation_state.dart';

/// 추천 프로바이더
final recommendationProvider =
    AsyncNotifierProvider<RecommendationNotifier, RecommendationState>(() {
  return RecommendationNotifier();
});

/// 추천 알고리즘 노티파이어
class RecommendationNotifier extends AsyncNotifier<RecommendationState> {
  late VideoService _videoService;
  String? _userId;

  @override
  Future<RecommendationState> build() async {
    _videoService = ref.watch(videoServiceProvider);

    // 인증 상태 감시하고 사용자 ID 접근
    final authState = ref.watch(authControllerProvider);
    _userId = authState.whenData((state) => state.user?.id).value;

    // 사용자가 로그인되지 않았으면 빈 상태 반환
    if (_userId == null) {
      return RecommendationState.empty();
    }

    // 북마크 데이터를 사용해 추천 생성
    ref.listen(bookmarkProvider, (prev, next) {
      // 북마크 데이터가 변경되면 추천 생성
      next.whenData((bookmarkState) {
        if (!bookmarkState.isLoading) {
          refreshRecommendations();
        }
      });
    });

    return await _fetchRecommendations();
  }

  /// 추천 항목 새로고침
  Future<void> refreshRecommendations() async {
    if (_userId == null) {
      state = AsyncValue.error(
        const ApiError(
          code: 'auth/not-authenticated',
          message: '추천을 생성하려면 로그인이 필요합니다.',
        ),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchRecommendations());
  }

  /// 추천 항목 가져오기
  Future<RecommendationState> _fetchRecommendations() async {
    // 북마크 데이터 가져오기
    final bookmarkState = ref.read(bookmarkProvider).value;

    if (bookmarkState == null || bookmarkState.bookmarkedVideos.isEmpty) {
      // 북마크된 비디오가 없으면 인기 비디오 추천
      final popularVideos = await _videoService.getPopularVideos(limit: 10);
      return RecommendationState(
        forYouVideos: popularVideos,
        trendingVideos: popularVideos.take(5).toList(),
        basedOnHistoryVideos: const [],
        similarArtistsVideos: const [],
      );
    }

    // 북마크된 비디오를 기반으로 추천
    final bookmarkedVideos = bookmarkState.bookmarkedVideos;

    // 사용자가 좋아하는 아티스트 ID 추출
    final favoriteArtistIds = bookmarkedVideos.map((video) => video.artistId).toSet().toList();

    // 비슷한 아티스트의 비디오 가져오기
    final similarArtistsVideos = await _videoService.getVideosByArtistIds(
      artistIds: favoriteArtistIds,
      limit: 10,
    );

    // 인기 비디오 가져오기
    final trendingVideos = await _videoService.getPopularVideos(limit: 5);

    // 시청 기록 기반 추천 (실제로는 백엔드에서 구현)
    // 여기서는 단순하게 유사한 아티스트 비디오와 인기 비디오를 조합
    final basedOnHistoryVideos = [
      ...similarArtistsVideos.take(3).toList(),
      ...trendingVideos.take(2).toList(),
    ];

    // 'For You' 비디오는 모든 추천 소스의 조합
    final forYouVideos = [
      ...similarArtistsVideos.take(5).toList(),
      ...trendingVideos.take(3).toList(),
      ...basedOnHistoryVideos.take(2).toList(),
    ];

    return RecommendationState(
      forYouVideos: forYouVideos,
      trendingVideos: trendingVideos,
      basedOnHistoryVideos: basedOnHistoryVideos,
      similarArtistsVideos: similarArtistsVideos,
    );
  }
}
