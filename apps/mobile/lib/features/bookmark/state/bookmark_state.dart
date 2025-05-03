import 'package:flutter/foundation.dart';

/// 북마크 상태
@immutable
class BookmarkState {
  /// 북마크 상태 생성자
  const BookmarkState({
    this.isLoading = false,
    this.isBookmarked = false,
    this.error,
  });

  /// 로딩 중 여부
  final bool isLoading;

  /// 북마크 여부
  final bool isBookmarked;

  /// 오류 메시지
  final String? error;

  /// 복사본 생성
  BookmarkState copyWith({
    bool? isLoading,
    bool? isBookmarked,
    String? error,
  }) {
    return BookmarkState(
      isLoading: isLoading ?? this.isLoading,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookmarkState &&
        other.isLoading == isLoading &&
        other.isBookmarked == isBookmarked &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(isLoading, isBookmarked, error);
}
