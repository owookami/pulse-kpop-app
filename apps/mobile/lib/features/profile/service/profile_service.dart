import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 프로필 서비스 프로바이더
final profileServiceProvider = Provider<ProfileService>((ref) {
  final supabase = Supabase.instance.client;
  return ProfileService(supabase);
});

// 프로필 서비스 클래스
class ProfileService {
  final SupabaseClient _supabase;

  ProfileService(this._supabase);

  // 현재 로그인된 사용자 정보 조회
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // 사용자 프로필 정보 조회
  Future<ApiResponse<Map<String, dynamic>>> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return ApiResponse.failure(
          const ApiError(
            code: 'auth/not-authenticated',
            message: '로그인이 필요한 기능입니다.',
          ),
        );
      }

      // 프로필 정보 조회
      final profileData = await _supabase.from('profiles').select().eq('id', user.id).single();

      return ApiResponse.success(profileData);
    } catch (e) {
      // 프로필이 없는 경우 기본 데이터 반환
      if (e.toString().contains('Row not found')) {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          return ApiResponse.success({
            'id': user.id,
            'username': user.email?.split('@')[0] ?? '사용자',
            'avatar_url': null,
            'bio': null,
          });
        }
      }

      return ApiResponse.failure(
        ApiError(
          code: 'profile/fetch-error',
          message: '프로필 정보를 가져오는 데 실패했습니다: $e',
        ),
      );
    }
  }

  // 북마크 수 조회
  Future<ApiResponse<int>> getBookmarksCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return ApiResponse.success(0);
      }

      final response = await _supabase.from('bookmarks').select().eq('user_id', user.id).count();

      // count 결과는 Map 형태로 반환되며 count 필드에 실제 카운트 값이 있음
      final count = response.count;
      return ApiResponse.success(count);
    } catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'bookmark/count-error',
          message: '북마크 수를 가져오는 데 실패했습니다: $e',
        ),
      );
    }
  }

  // 좋아요 수 조회
  Future<ApiResponse<int>> getLikesCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return ApiResponse.success(0);
      }

      final response =
          await _supabase.from('reviews').select().eq('user_id', user.id).eq('liked', true).count();

      // count 결과는 Map 형태로 반환되며 count 필드에 실제 카운트 값이 있음
      final count = response.count;
      return ApiResponse.success(count);
    } catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'likes/count-error',
          message: '좋아요 수를 가져오는 데 실패했습니다: $e',
        ),
      );
    }
  }

  // 댓글 수 조회
  Future<ApiResponse<int>> getCommentsCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return ApiResponse.success(0);
      }

      final response = await _supabase
          .from('reviews')
          .select()
          .eq('user_id', user.id)
          .not('comment', 'is', null)
          .count();

      // count 결과는 Map 형태로 반환되며 count 필드에 실제 카운트 값이 있음
      final count = response.count;
      return ApiResponse.success(count);
    } catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'comments/count-error',
          message: '댓글 수를 가져오는 데 실패했습니다: $e',
        ),
      );
    }
  }

  // 프로필 정보 업데이트
  Future<ApiResponse<void>> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return ApiResponse.failure(
          const ApiError(
            code: 'auth/not-authenticated',
            message: '로그인이 필요한 기능입니다.',
          ),
        );
      }

      // 업데이트할 데이터 구성
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) {
        return ApiResponse.success(null);
      }

      // 프로필 업데이트 또는 생성 (upsert)
      await _supabase.from('profiles').upsert({
        'id': user.id,
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'profile/update-error',
          message: '프로필 정보를 업데이트하는 데 실패했습니다: $e',
        ),
      );
    }
  }
}
