import 'package:meta/meta.dart';

/// 아티스트 모델
@immutable
class Artist {
  /// 아티스트 생성자
  const Artist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.groupName,
  });

  /// 아티스트 ID
  final String id;

  /// 아티스트 이름
  final String name;

  /// 생성 일시
  final DateTime createdAt;

  /// 수정 일시
  final DateTime updatedAt;

  /// 프로필 이미지 URL
  final String? imageUrl;

  /// 소속 그룹 이름
  final String? groupName;

  /// JSON으로부터 아티스트 객체 생성
  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      imageUrl: json['image_url'] as String?,
      groupName: json['group_name'] as String?,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'image_url': imageUrl,
      'group_name': groupName,
    };
  }

  /// 복사본 생성
  Artist copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
    String? groupName,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      groupName: groupName ?? this.groupName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Artist &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.imageUrl == imageUrl &&
        other.groupName == groupName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      createdAt,
      updatedAt,
      imageUrl,
      groupName,
    );
  }

  @override
  String toString() {
    return 'Artist(id: $id, name: $name, groupName: $groupName)';
  }
}
