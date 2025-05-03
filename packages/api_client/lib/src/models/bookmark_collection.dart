import 'package:meta/meta.dart';

/// 북마크 컬렉션 모델
@immutable
class BookmarkCollection {
  /// 북마크 컬렉션 생성자
  const BookmarkCollection({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.coverImageUrl,
    this.isPublic = false,
    this.bookmarkCount = 0,
  });

  /// 컬렉션 ID
  final String id;

  /// 사용자 ID
  final String userId;

  /// 컬렉션 이름
  final String name;

  /// 컬렉션 설명
  final String? description;

  /// 생성 일시
  final DateTime createdAt;

  /// 업데이트 일시
  final DateTime updatedAt;

  /// 커버 이미지 URL
  final String? coverImageUrl;

  /// 공개 여부
  final bool isPublic;

  /// 북마크 수
  final int bookmarkCount;

  /// JSON으로부터 북마크 컬렉션 객체 생성
  factory BookmarkCollection.fromJson(Map<String, dynamic> json) {
    // isPublic 처리: 'true' 문자열이나 true 불리언 모두 처리
    bool isPublicValue = false;
    final dynamic isPublicRaw = json['is_public'];
    if (isPublicRaw is bool) {
      isPublicValue = isPublicRaw;
    } else if (isPublicRaw is String) {
      isPublicValue = isPublicRaw.toLowerCase() == 'true';
    }

    return BookmarkCollection(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      coverImageUrl: json['cover_image_url'] as String?,
      isPublic: isPublicValue,
      bookmarkCount: json['bookmark_count'] as int? ?? 0,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cover_image_url': coverImageUrl,
      'is_public': isPublic,
      'bookmark_count': bookmarkCount,
    };
  }

  /// 복사본 생성
  BookmarkCollection copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverImageUrl,
    bool? isPublic,
    int? bookmarkCount,
  }) {
    return BookmarkCollection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isPublic: isPublic ?? this.isPublic,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookmarkCollection &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.coverImageUrl == coverImageUrl &&
        other.isPublic == isPublic &&
        other.bookmarkCount == bookmarkCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      name,
      description,
      createdAt,
      updatedAt,
      coverImageUrl,
      isPublic,
      bookmarkCount,
    );
  }

  @override
  String toString() {
    return 'BookmarkCollection(id: $id, name: $name, userId: $userId)';
  }
}
