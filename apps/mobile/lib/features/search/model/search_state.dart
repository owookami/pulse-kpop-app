import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';

/// 검색 필터 옵션
enum SearchFilterType {
  /// 모든 결과
  all,

  /// 아티스트 필터
  artist,

  /// 영상 필터
  video,

  /// 이벤트 필터
  event,
}

/// 검색 정렬 옵션
enum SearchSortOption {
  /// 관련성순
  relevance,

  /// 최신순
  latest,

  /// 인기순(조회수)
  popularity,
}

/// 검색 상태
@immutable
class SearchState {
  /// 생성자
  const SearchState({
    this.query = '',
    this.results = const [],
    this.artistResults = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.recentSearches = const [],
    this.suggestions = const [],
    this.popularSearches = const [],
    this.selectedFilter = SearchFilterType.all,
    this.sortOption = SearchSortOption.relevance,
    this.dateRange,
    this.isLoadingMore = false,
  });

  /// 검색어
  final String query;

  /// 검색 결과 (비디오 목록)
  final List<Video> results;

  /// 아티스트 검색 결과
  final List<Artist> artistResults;

  /// 로딩 중 여부
  final bool isLoading;

  /// 에러 메시지
  final String? error;

  /// 추가 결과가 있는지 여부
  final bool hasMore;

  /// 최근 검색어 목록
  final List<String> recentSearches;

  /// 검색어 제안 목록
  final List<String> suggestions;

  /// 인기 검색어 목록
  final List<String> popularSearches;

  /// 현재 선택된 필터
  final SearchFilterType selectedFilter;

  /// 정렬 옵션
  final SearchSortOption sortOption;

  /// 날짜 범위 필터 (시작일, 종료일)
  final DateTimeRange? dateRange;

  /// 추가 로딩 상태
  final bool isLoadingMore;

  /// 초기 상태
  factory SearchState.initial() => const SearchState();

  /// 복사본 생성
  SearchState copyWith({
    String? query,
    List<Video>? results,
    List<Artist>? artistResults,
    bool? isLoading,
    String? error,
    bool? hasMore,
    List<String>? recentSearches,
    List<String>? suggestions,
    List<String>? popularSearches,
    SearchFilterType? selectedFilter,
    SearchSortOption? sortOption,
    DateTimeRange? dateRange,
    bool? isLoadingMore,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      artistResults: artistResults ?? this.artistResults,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      recentSearches: recentSearches ?? this.recentSearches,
      suggestions: suggestions ?? this.suggestions,
      popularSearches: popularSearches ?? this.popularSearches,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      sortOption: sortOption ?? this.sortOption,
      dateRange: dateRange ?? this.dateRange,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchState &&
        other.query == query &&
        listEquals(other.results, results) &&
        listEquals(other.artistResults, artistResults) &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.hasMore == hasMore &&
        listEquals(other.recentSearches, recentSearches) &&
        listEquals(other.suggestions, suggestions) &&
        listEquals(other.popularSearches, popularSearches) &&
        other.selectedFilter == selectedFilter &&
        other.sortOption == sortOption &&
        other.dateRange == dateRange &&
        other.isLoadingMore == isLoadingMore;
  }

  @override
  int get hashCode => Object.hash(
        query,
        Object.hashAll(results),
        Object.hashAll(artistResults),
        isLoading,
        error,
        hasMore,
        Object.hashAll(recentSearches),
        Object.hashAll(suggestions),
        Object.hashAll(popularSearches),
        selectedFilter,
        sortOption,
        dateRange,
        isLoadingMore,
      );
}

/// 날짜 범위 필터
class DateTimeRange {
  /// 생성자
  const DateTimeRange({
    required this.start,
    required this.end,
  });

  /// 시작일
  final DateTime start;

  /// 종료일
  final DateTime end;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateTimeRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}
