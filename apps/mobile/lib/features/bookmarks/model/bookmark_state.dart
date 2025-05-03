import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';

/// 북마크 상태
@immutable
class BookmarkState {
  /// 생성자
  const BookmarkState({
    this.bookmarkedVideos = const [],
    this.collections = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.lastBookmarkId,
    this.loadingMore = false,
  });

  /// 북마크된 비디오 목록
  final List<Video> bookmarkedVideos;

  /// 북마크 컬렉션 목록
  final List<BookmarkCollection> collections;

  /// 로딩 중 여부
  final bool isLoading;

  /// 에러 메시지
  final ApiError? error;

  /// 추가 북마크가 있는지 여부
  final bool hasMore;

  /// 마지막 북마크 ID
  final String? lastBookmarkId;

  /// 추가 북마크 로딩 중 여부
  final bool loadingMore;

  /// 초기 상태
  factory BookmarkState.initial() => const BookmarkState();

  /// 빈 상태
  factory BookmarkState.empty() => const BookmarkState(
        bookmarkedVideos: [],
        collections: [],
        hasMore: false,
      );

  /// 복사본 생성
  BookmarkState copyWith({
    List<Video>? bookmarkedVideos,
    List<BookmarkCollection>? collections,
    bool? isLoading,
    ApiError? error,
    bool? hasMore,
    String? lastBookmarkId,
    bool? loadingMore,
  }) {
    return BookmarkState(
      bookmarkedVideos: bookmarkedVideos ?? this.bookmarkedVideos,
      collections: collections ?? this.collections,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      lastBookmarkId: lastBookmarkId ?? this.lastBookmarkId,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookmarkState &&
        listEquals(other.bookmarkedVideos, bookmarkedVideos) &&
        listEquals(other.collections, collections) &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.hasMore == hasMore &&
        other.lastBookmarkId == lastBookmarkId &&
        other.loadingMore == loadingMore;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(bookmarkedVideos),
        Object.hashAll(collections),
        isLoading,
        error,
        hasMore,
        lastBookmarkId,
        loadingMore,
      );
}
