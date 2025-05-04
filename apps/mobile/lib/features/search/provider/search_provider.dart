import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/search/model/search_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 비디오 검색 서비스 프로바이더
final videoSearchServiceProvider = Provider<VideoService>((ref) {
  final videoService = ref.watch(videoServiceProvider);
  return videoService;
});

/// 아티스트 검색 서비스 프로바이더
final artistSearchServiceProvider = Provider<ArtistService>((ref) {
  return artistServiceProvider;
});

/// 최근 검색어 저장소 프로바이더
final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('recent_searches') ?? [];
});

/// 인기 검색어 프로바이더 (실제로는 서버에서 가져와야 함)
final popularSearchesProvider = Provider<List<String>>((ref) {
  return [
    'BLACKPINK',
    'NewJeans',
    'BTS',
    'IVE',
    'TWICE',
    'aespa',
    'ITZY',
    'LE SSERAFIM',
    'SEVENTEEN',
    'Stray Kids',
  ];
});

/// 검색 프로바이더
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final videoService = ref.watch(videoSearchServiceProvider);
  final artistService = ref.watch(artistSearchServiceProvider);
  return SearchNotifier(
    videoService: videoService,
    artistService: artistService,
  );
});

/// 검색 디바운스 타이머
Timer? _debounceTimer;

/// 검색 Notifier
class SearchNotifier extends StateNotifier<SearchState> {
  /// 생성자
  SearchNotifier({
    required this.videoService,
    required this.artistService,
  }) : super(const SearchState()) {
    _loadRecentSearches();
  }

  /// 비디오 검색 서비스
  final VideoService videoService;

  /// 아티스트 검색 서비스
  final ArtistService artistService;

  /// 최근 검색어 불러오기
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final recentSearches = prefs.getStringList('recent_searches') ?? [];
    state = state.copyWith(recentSearches: recentSearches);
  }

  /// 최근 검색어 저장
  Future<void> _saveRecentSearches(List<String> searches) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', searches);
  }

  /// 최근 검색어에 추가
  Future<void> _addToRecentSearches(String query) async {
    if (query.trim().isEmpty) return;

    // 이미 있는 검색어라면 제거 후 맨 앞에 추가
    final updatedSearches = [...state.recentSearches];
    updatedSearches.remove(query);
    updatedSearches.insert(0, query);

    // 최대 10개만 유지
    final limitedSearches = updatedSearches.take(10).toList();
    state = state.copyWith(recentSearches: limitedSearches);
    await _saveRecentSearches(limitedSearches);
  }

  /// 최근 검색어 삭제
  Future<void> removeRecentSearch(String query) async {
    final updatedSearches = [...state.recentSearches];
    updatedSearches.remove(query);
    state = state.copyWith(recentSearches: updatedSearches);
    await _saveRecentSearches(updatedSearches);
  }

  /// 모든 최근 검색어 삭제
  Future<void> clearRecentSearches() async {
    state = state.copyWith(recentSearches: []);
    await _saveRecentSearches([]);
  }

  /// 검색어 변경 처리
  void onQueryChanged(String query) {
    state = state.copyWith(query: query);

    // 디바운스 처리 - 입력이 멈춘 후 300ms 후에 검색 제안 요청
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        _fetchSuggestions(query);
      } else {
        state = state.copyWith(suggestions: []);
      }
    });
  }

  /// 검색 제안 가져오기
  Future<void> _fetchSuggestions(String query) async {
    if (query.length < 2) {
      state = state.copyWith(suggestions: []);
      return;
    }

    // 여기서는 간단하게 최근 검색어와 인기 검색어에서 필터링
    final combinedSuggestions = <String>{};

    // 최근 검색어에서 필터링
    for (final recentSearch in state.recentSearches) {
      if (recentSearch.toLowerCase().contains(query.toLowerCase())) {
        combinedSuggestions.add(recentSearch);
      }
    }

    // 인기 검색어에서 필터링
    final popularSearches = [
      'BLACKPINK',
      'NewJeans',
      'BTS',
      'IVE',
      'TWICE',
      'aespa',
      'ITZY',
      'LE SSERAFIM',
      'SEVENTEEN',
      'Stray Kids'
    ];

    for (final popularSearch in popularSearches) {
      if (popularSearch.toLowerCase().contains(query.toLowerCase())) {
        combinedSuggestions.add(popularSearch);
      }
    }

    state = state.copyWith(
      suggestions: combinedSuggestions.toList(),
    );
  }

  /// 검색 실행
  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    // 최근 검색어에 추가
    await _addToRecentSearches(query);

    // 로딩 상태로 변경
    state = state.copyWith(
      query: query,
      isLoading: true,
      error: null,
      hasMore: true,
      isSubmitted: true,
    );

    // 선택된 필터에 따라 검색 수행
    await _performFilteredSearch();
  }

  /// 필터에 따른 검색 수행
  Future<void> _performFilteredSearch() async {
    final query = state.query;

    switch (state.selectedFilter) {
      case SearchFilterType.all:
        // 모든 결과 검색 (비디오 + 아티스트)
        await _searchVideos(query);
        await _searchArtists(query);
        break;
      case SearchFilterType.video:
        // 비디오만 검색
        await _searchVideos(query);
        state = state.copyWith(artistResults: []);
        break;
      case SearchFilterType.artist:
        // 아티스트만 검색
        await _searchArtists(query);
        state = state.copyWith(results: []);
        break;
      default:
        break;
    }
  }

  /// 비디오 검색
  Future<void> _searchVideos(String query) async {
    try {
      final response = await videoService.searchVideos(query: query);

      response.fold(
        onSuccess: (videos) {
          state = state.copyWith(
            results: videos,
            isLoading: false,
            hasMore: videos.length >= 20, // 20개 이상이면 더 있다고 가정
          );
        },
        onFailure: (error) {
          state = state.copyWith(
            error: error.message,
            isLoading: false,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        error: '검색 중 오류가 발생했습니다: $e',
        isLoading: false,
      );
    }
  }

  /// 아티스트 검색
  Future<void> _searchArtists(String query) async {
    try {
      final response = await artistService.searchArtists(query: query);

      response.fold(
        onSuccess: (artists) {
          // 빈 배열이 반환되더라도 성공으로 처리
          state = state.copyWith(
            artistResults: artists,
            isLoading: false,
            // 결과가 없어도 에러 상태는 null로 유지
            error: null,
          );
        },
        onFailure: (error) {
          // PostgrestException 관련 오류는 무시
          if (error.message.contains('테이블이 존재하지 않습니다') ||
              error.message.contains('relation') && error.message.contains('does not exist')) {
            // 테이블이 없는 경우 빈 결과를 반환하고 에러는 표시하지 않음
            state = state.copyWith(
              artistResults: [],
              isLoading: false,
              error: null,
            );
          } else {
            // 다른 오류는 정상적으로 표시
            state = state.copyWith(
              error: error.message,
              isLoading: false,
            );
          }
        },
      );
    } catch (e) {
      // 예외가 발생해도 테이블 관련 오류는 무시
      if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
        state = state.copyWith(
          artistResults: [],
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          error: '아티스트 검색 중 오류가 발생했습니다: $e',
          isLoading: false,
        );
      }
    }
  }

  /// 필터 변경
  void setFilter(SearchFilterType filter) {
    if (state.selectedFilter == filter) return;

    state = state.copyWith(selectedFilter: filter);

    // 현재 검색어가 있으면 필터 변경 후 다시 검색
    if (state.query.isNotEmpty) {
      _performFilteredSearch();
    }
  }

  /// 정렬 옵션 변경
  void setSortOption(SearchSortOption option) {
    if (state.sortOption == option) return;

    state = state.copyWith(sortOption: option);

    // 이미 검색 결과가 있는 경우 정렬 적용
    _applySorting();
  }

  /// 검색 결과 정렬 적용
  void _applySorting() {
    if (state.results.isEmpty) return;

    final sortedResults = [...state.results];

    switch (state.sortOption) {
      case SearchSortOption.latest:
        sortedResults.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SearchSortOption.popularity:
        sortedResults.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case SearchSortOption.relevance:
        // 기본 정렬은 관련성 (API에서 이미 정렬된 상태)
        break;
    }

    state = state.copyWith(results: sortedResults);
  }

  /// 날짜 범위 필터 설정
  void setDateRange(DateTimeRange? dateRange) {
    state = state.copyWith(dateRange: dateRange);

    // 필터가 변경되었고 검색어가 있으면 다시 검색
    if (state.query.isNotEmpty) {
      _performFilteredSearch();
    }
  }

  /// 더 많은 결과 로드 (페이지네이션)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.results.isEmpty) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final lastId = state.results.last.id;
      final response = await videoService.searchVideos(
        query: state.query,
        lastId: lastId,
      );

      response.fold(
        onSuccess: (moreVideos) {
          if (moreVideos.isEmpty) {
            state = state.copyWith(
              hasMore: false,
              isLoadingMore: false,
            );
          } else {
            state = state.copyWith(
              results: [...state.results, ...moreVideos],
              isLoadingMore: false,
              hasMore: moreVideos.length >= 20,
            );
          }
        },
        onFailure: (error) {
          state = state.copyWith(
            error: error.message,
            isLoadingMore: false,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        error: '추가 결과를 불러오는 중 오류가 발생했습니다: $e',
        isLoadingMore: false,
      );
    }
  }
}
