import 'package:flutter/foundation.dart';

/// 투표 상태
@immutable
class VoteState {
  /// 생성자
  const VoteState({
    this.isLoading = false,
    this.error,
    this.userRating,
    this.isLiked = false,
    this.isDisliked = false,
    this.averageRating = 0.0,
    this.totalVotes = 0,
    this.likeCount = 0,
    this.dislikeCount = 0,
  });

  /// 로딩 중 여부
  final bool isLoading;

  /// 에러 정보
  final String? error;

  /// 사용자의 별점 (0.0-5.0, null은 평가하지 않음)
  final double? userRating;

  /// 좋아요 여부
  final bool isLiked;

  /// 싫어요 여부
  final bool isDisliked;

  /// 평균 별점 (0.0-5.0)
  final double averageRating;

  /// 총 투표 수
  final int totalVotes;

  /// 좋아요 수
  final int likeCount;

  /// 싫어요 수
  final int dislikeCount;

  /// 초기 상태
  factory VoteState.initial() => const VoteState();

  /// 복사본 생성
  VoteState copyWith({
    bool? isLoading,
    String? error,
    double? userRating,
    bool? isLiked,
    bool? isDisliked,
    double? averageRating,
    int? totalVotes,
    int? likeCount,
    int? dislikeCount,
  }) {
    return VoteState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userRating: userRating ?? this.userRating,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      averageRating: averageRating ?? this.averageRating,
      totalVotes: totalVotes ?? this.totalVotes,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VoteState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.userRating == userRating &&
        other.isLiked == isLiked &&
        other.isDisliked == isDisliked &&
        other.averageRating == averageRating &&
        other.totalVotes == totalVotes &&
        other.likeCount == likeCount &&
        other.dislikeCount == dislikeCount;
  }

  @override
  int get hashCode {
    return isLoading.hashCode ^
        error.hashCode ^
        userRating.hashCode ^
        isLiked.hashCode ^
        isDisliked.hashCode ^
        averageRating.hashCode ^
        totalVotes.hashCode ^
        likeCount.hashCode ^
        dislikeCount.hashCode;
  }
}
