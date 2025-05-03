import 'package:meta/meta.dart';

/// 리뷰 모델
@immutable
class Review {
  /// 리뷰 생성자
  const Review({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.content,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.likes = 0,
  });

  /// 리뷰 ID
  final String id;

  /// 사용자 ID
  final String userId;

  /// 비디오 ID
  final String videoId;

  /// 리뷰 내용
  final String content;

  /// 평점 (1-5)
  final int rating;

  /// 생성 일시
  final DateTime createdAt;

  /// 수정 일시
  final DateTime updatedAt;

  /// 좋아요 수
  final int likes;

  /// JSON으로부터 리뷰 객체 생성
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      videoId: json['video_id'] as String,
      content: json['content'] as String,
      rating: json['rating'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      likes: json['likes'] as int? ?? 0,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'video_id': videoId,
      'content': content,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'likes': likes,
    };
  }

  /// 복사본 생성
  Review copyWith({
    String? id,
    String? userId,
    String? videoId,
    String? content,
    int? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoId: videoId ?? this.videoId,
      content: content ?? this.content,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review &&
        other.id == id &&
        other.userId == userId &&
        other.videoId == videoId &&
        other.content == content &&
        other.rating == rating &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.likes == likes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      videoId,
      content,
      rating,
      createdAt,
      updatedAt,
      likes,
    );
  }

  @override
  String toString() {
    return 'Review(id: $id, userId: $userId, videoId: $videoId, rating: $rating)';
  }
}
