import 'package:meta/meta.dart';

/// 사용자 프로필 모델
@immutable
class UserProfile {
  /// 사용자 프로필 생성자
  const UserProfile({
    required this.id,
    required this.userId,
    required this.username,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.websiteUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.reviewsCount = 0,
  });

  /// 프로필 ID
  final String id;

  /// 사용자 ID (Auth)
  final String userId;

  /// 사용자명 (고유)
  final String username;

  /// 생성 일시
  final DateTime createdAt;

  /// 수정 일시
  final DateTime updatedAt;

  /// 표시 이름
  final String? displayName;

  /// 자기 소개
  final String? bio;

  /// 프로필 이미지 URL
  final String? avatarUrl;

  /// 웹사이트 URL
  final String? websiteUrl;

  /// 팔로워 수
  final int followersCount;

  /// 팔로잉 수
  final int followingCount;

  /// 리뷰 수
  final int reviewsCount;

  /// JSON으로부터 프로필 객체 생성
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'website_url': websiteUrl,
      'followers_count': followersCount,
      'following_count': followingCount,
      'reviews_count': reviewsCount,
    };
  }

  /// 복사본 생성
  UserProfile copyWith({
    String? id,
    String? userId,
    String? username,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? websiteUrl,
    int? followersCount,
    int? followingCount,
    int? reviewsCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      reviewsCount: reviewsCount ?? this.reviewsCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.userId == userId &&
        other.username == username &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.displayName == displayName &&
        other.bio == bio &&
        other.avatarUrl == avatarUrl &&
        other.websiteUrl == websiteUrl &&
        other.followersCount == followersCount &&
        other.followingCount == followingCount &&
        other.reviewsCount == reviewsCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      username,
      createdAt,
      updatedAt,
      displayName,
      bio,
      avatarUrl,
      websiteUrl,
      followersCount,
      followingCount,
      reviewsCount,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, username: $username, displayName: $displayName)';
  }
}
