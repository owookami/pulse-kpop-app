import 'package:meta/meta.dart';

/// 팔로우 모델
@immutable
class Follow {
  /// 팔로우 생성자
  const Follow({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  /// 팔로우 ID
  final String id;

  /// 팔로우하는 사용자 ID
  final String followerId;

  /// 팔로우받는 사용자 ID
  final String followingId;

  /// 생성 일시
  final DateTime createdAt;

  /// JSON으로부터 팔로우 객체 생성
  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(
      id: json['id'] as String,
      followerId: json['follower_id'] as String,
      followingId: json['following_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'follower_id': followerId,
      'following_id': followingId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 복사본 생성
  Follow copyWith({
    String? id,
    String? followerId,
    String? followingId,
    DateTime? createdAt,
  }) {
    return Follow(
      id: id ?? this.id,
      followerId: followerId ?? this.followerId,
      followingId: followingId ?? this.followingId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Follow &&
        other.id == id &&
        other.followerId == followerId &&
        other.followingId == followingId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      followerId,
      followingId,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Follow(id: $id, followerId: $followerId, followingId: $followingId)';
  }
}
