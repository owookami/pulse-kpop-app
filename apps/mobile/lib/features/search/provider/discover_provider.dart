import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/search/model/discover_state.dart';

/// 발견 화면 프로바이더
final discoverProvider = StateNotifierProvider<DiscoverNotifier, DiscoverState>((ref) {
  return DiscoverNotifier(
    videoService: ref.watch(videoServiceProvider),
    artistService: artistServiceProvider,
  );
});

/// 발견 화면 Notifier
class DiscoverNotifier extends StateNotifier<DiscoverState> {
  /// 생성자
  DiscoverNotifier({
    required this.videoService,
    required this.artistService,
  }) : super(DiscoverState.initial()) {
    // 초기 데이터 로드
    _loadInitialData();
  }

  /// 비디오 서비스
  final VideoService videoService;

  /// 아티스트 서비스
  final ArtistService artistService;

  /// 초기 데이터 로드
  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 병렬로 여러 API 호출
      await Future.wait([
        _loadPopularArtists(),
        _loadTrendingVideos(),
        _loadRecentVideos(),
        _loadGroupVideos(),
      ]);

      // 로딩 완료
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '데이터를 불러오는 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    return _loadInitialData();
  }

  /// 인기 아티스트 로드
  Future<void> _loadPopularArtists() async {
    try {
      final response = await artistService.getPopularArtists();

      response.fold(
        onSuccess: (artists) {
          state = state.copyWith(popularArtists: artists);
        },
        onFailure: (error) {
          // 부분 에러는 무시하고 빈 목록 사용
          state = state.copyWith(popularArtists: []);
        },
      );
    } catch (e) {
      // 에러 처리
      state = state.copyWith(popularArtists: []);
    }
  }

  /// 인기 비디오 로드
  Future<void> _loadTrendingVideos() async {
    try {
      final response = await videoService.getTrendingVideos();

      response.fold(
        onSuccess: (videos) {
          state = state.copyWith(trendingVideos: videos);
        },
        onFailure: (error) {
          // 부분 에러는 무시하고 빈 목록 사용
          state = state.copyWith(trendingVideos: []);
        },
      );
    } catch (e) {
      // 에러 처리
      state = state.copyWith(trendingVideos: []);
    }
  }

  /// 최신 비디오 로드
  Future<void> _loadRecentVideos() async {
    try {
      final response = await videoService.getRisingVideos();

      response.fold(
        onSuccess: (videos) {
          state = state.copyWith(recentVideos: videos);
        },
        onFailure: (error) {
          // 부분 에러는 무시하고 빈 목록 사용
          state = state.copyWith(recentVideos: []);
        },
      );
    } catch (e) {
      // 에러 처리
      state = state.copyWith(recentVideos: []);
    }
  }

  /// 그룹별 비디오 로드
  Future<void> _loadGroupVideos() async {
    try {
      // 인기 그룹 (실제로는 API에서 받아와야 함)
      final popularGroups = [
        'BLACKPINK',
        'BTS',
        'NewJeans',
        'TWICE',
        'aespa',
      ];

      final groupVideosMap = <String, List<Video>>{};

      // 각 그룹별로 비디오 가져오기
      for (final group in popularGroups) {
        try {
          // 그룹명 검색으로 비디오 가져오기
          final response = await videoService.searchVideos(query: group);

          response.fold(
            onSuccess: (videos) {
              if (videos.isNotEmpty) {
                groupVideosMap[group] = videos;
              }
            },
            onFailure: (_) {
              // 개별 그룹 에러는 무시
            },
          );
        } catch (e) {
          // 개별 그룹 에러는 무시
        }
      }

      state = state.copyWith(groupVideos: groupVideosMap);
    } catch (e) {
      // 전체 에러 처리
      state = state.copyWith(groupVideos: {});
    }
  }
}
