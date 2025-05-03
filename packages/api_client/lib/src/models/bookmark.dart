import 'package:meta/meta.dart';

/// 북마크 모델
@immutable
class Bookmark {
  /// 북마크 생성자
  const Bookmark({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.createdAt,
  });

  /// 북마크 ID
  final String id;

  /// 사용자 ID
  final String userId;

  /// 비디오 ID
  final String videoId;

  /// 생성 일시
  final DateTime createdAt;

  /// JSON으로부터 북마크 객체 생성
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      videoId: json['video_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'video_id': videoId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// DB용 JSON으로 변환
  Map<String, dynamic> toDbJson() {
    return {
      'user_id': userId,
      'video_id': videoId,
    };
  }

  /// 복사본 생성
  Bookmark copyWith({
    String? id,
    String? userId,
    String? videoId,
    DateTime? createdAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoId: videoId ?? this.videoId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bookmark &&
        other.id == id &&
        other.userId == userId &&
        other.videoId == videoId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      videoId,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Bookmark(id: $id, userId: $userId, videoId: $videoId, createdAt: $createdAt)';
  }
}
