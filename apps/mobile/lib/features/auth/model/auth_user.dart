import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// 인증된 사용자 모델
@immutable
class AuthUser {
  /// 생성자
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
    this.lastSignInAt,
    this.isAdmin = false,
  });

  /// 사용자 ID
  final String id;

  /// 이메일
  final String email;

  /// 표시 이름
  final String? displayName;

  /// 프로필 사진 URL
  final String? photoUrl;

  /// 계정 생성일
  final DateTime? createdAt;

  /// 마지막 로그인 시간
  final DateTime? lastSignInAt;

  /// 관리자 여부
  final bool isAdmin;

  /// Empty 사용자 (비로그인 상태)
  static const empty = AuthUser(
    id: '',
    email: '',
  );

  /// Supabase 사용자로부터 AuthUser 생성
  static AuthUser fromSupabaseUser(supabase.User user) {
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['name'] as String? ?? '',
      photoUrl: user.userMetadata?['avatar_url'] as String?,
      createdAt: DateTime.parse(user.createdAt),
      lastSignInAt: user.updatedAt != null ? DateTime.parse(user.updatedAt!) : null,
      isAdmin: user.email == 'loupslim@gmail.com',
    );
  }

  /// 관리자 여부 확인
  bool get isSuperAdmin => email == 'loupslim@gmail.com';

  /// 사용자 정보 복사
  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    bool? isAdmin,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.createdAt == createdAt &&
        other.lastSignInAt == lastSignInAt &&
        other.isAdmin == isAdmin;
  }

  @override
  int get hashCode => Object.hash(
        id,
        email,
        displayName,
        photoUrl,
        createdAt,
        lastSignInAt,
        isAdmin,
      );
}
