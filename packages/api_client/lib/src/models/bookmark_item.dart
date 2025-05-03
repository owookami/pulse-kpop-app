import 'package:meta/meta.dart';

/// 북마크 아이템 모델
@immutable
class BookmarkItem {
  /// 북마크 아이템 생성자
  const BookmarkItem({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.collectionId,
    required this.createdAt,
  });

  /// 아이템 ID
  final String id;

  /// 사용자 ID
  final String userId;

  /// 비디오 ID
  final String videoId;

  /// 컬렉션 ID
  final String collectionId;

  /// 생성 일시
  final DateTime createdAt;

  /// JSON으로부터 북마크 아이템 객체 생성
  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      videoId: json['video_id'] as String,
      collectionId: json['collection_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'video_id': videoId,
      'collection_id': collectionId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 복사본 생성
  BookmarkItem copyWith({
    String? id,
    String? userId,
    String? videoId,
    String? collectionId,
    DateTime? createdAt,
  }) {
    return BookmarkItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      videoId: videoId ?? this.videoId,
      collectionId: collectionId ?? this.collectionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookmarkItem &&
        other.id == id &&
        other.userId == userId &&
        other.videoId == videoId &&
        other.collectionId == collectionId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      videoId,
      collectionId,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'BookmarkItem(id: $id, videoId: $videoId, collectionId: $collectionId)';
  }
}
