import 'package:flutter/foundation.dart';

/// 사용자 프로필 상태 모델
@immutable
class ProfileState {
  /// 생성자
  const ProfileState({
    this.isLoading = false,
    this.error,
    this.username = '',
    this.email = '',
    this.avatarUrl,
    this.bio,
    this.bookmarksCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  /// 로딩 상태
  final bool isLoading;

  /// 에러 메시지
  final String? error;

  /// 사용자 이름
  final String username;

  /// 이메일
  final String email;

  /// 프로필 이미지 URL
  final String? avatarUrl;

  /// 자기소개
  final String? bio;

  /// 북마크 수
  final int bookmarksCount;

  /// 좋아요 수
  final int likesCount;

  /// 댓글 수
  final int commentsCount;

  /// 초기 상태
  factory ProfileState.initial() => const ProfileState();

  /// 로딩 상태로 변경
  ProfileState copyWithLoading() {
    return ProfileState(
      isLoading: true,
      username: username,
      email: email,
      avatarUrl: avatarUrl,
      bio: bio,
      bookmarksCount: bookmarksCount,
      likesCount: likesCount,
      commentsCount: commentsCount,
    );
  }

  /// 복사 생성자
  ProfileState copyWith({
    bool? isLoading,
    String? error,
    String? username,
    String? email,
    String? avatarUrl,
    String? bio,
    int? bookmarksCount,
    int? likesCount,
    int? commentsCount,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      bookmarksCount: bookmarksCount ?? this.bookmarksCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}
