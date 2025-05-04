import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/profile/model/profile_state.dart';
import 'package:mobile/features/profile/service/profile_service.dart';

/// 사용자 프로필 프로바이더
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return ProfileNotifier(profileService, ref);
});

/// 프로필 노티파이어 클래스
class ProfileNotifier extends StateNotifier<ProfileState> {
  /// 생성자
  ProfileNotifier(this._profileService, this._ref) : super(ProfileState.initial()) {
    // 인증 상태 변경 감지
    _ref.listen(authControllerProvider, (previous, next) {
      if (next.isAuthenticated && next.user != null) {
        // 로그인 상태가 변경되면 프로필 정보 갱신
        loadProfile();
      } else {
        // 로그아웃된 경우 초기 상태로 복원
        state = ProfileState.initial();
      }
    });

    // 초기 로딩
    final authState = _ref.read(authControllerProvider);
    if (authState.isAuthenticated && authState.user != null) {
      loadProfile();
    }
  }

  final ProfileService _profileService;
  final Ref _ref;

  /// 프로필 정보 로드
  Future<void> loadProfile() async {
    state = state.copyWithLoading();

    try {
      // 현재 로그인된 사용자 정보 가져오기
      final currentUser = _profileService.getCurrentUser();
      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: '로그인이 필요합니다',
        );
        return;
      }

      // 기본 이메일 설정
      state = state.copyWith(
        email: currentUser.email ?? '',
      );

      // 프로필 정보 로드
      final profileResponse = await _profileService.getUserProfile();
      profileResponse.fold(
        onSuccess: (profileData) {
          // 프로필 정보 업데이트
          state = state.copyWith(
            isLoading: false,
            username: profileData['username'] ?? currentUser.email?.split('@')[0] ?? '사용자',
            avatarUrl: profileData['avatar_url'],
            bio: profileData['bio'],
          );
        },
        onFailure: (error) {
          // 프로필 정보가 없으면 기본 정보 사용
          state = state.copyWith(
            isLoading: false,
            username: currentUser.email?.split('@')[0] ?? '사용자',
          );
        },
      );

      // 북마크, 좋아요, 댓글 수 로드
      await _loadCounts();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '프로필 정보를 불러오는 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 통계 정보 로드 (북마크, 좋아요, 댓글 수)
  Future<void> _loadCounts() async {
    try {
      // 북마크 수 조회
      final bookmarksResponse = await _profileService.getBookmarksCount();
      final bookmarksCount = bookmarksResponse.fold(
        onSuccess: (count) => count,
        onFailure: (_) => 0,
      );

      // 좋아요 수 조회
      final likesResponse = await _profileService.getLikesCount();
      final likesCount = likesResponse.fold(
        onSuccess: (count) => count,
        onFailure: (_) => 0,
      );

      // 댓글 수 조회
      final commentsResponse = await _profileService.getCommentsCount();
      final commentsCount = commentsResponse.fold(
        onSuccess: (count) => count,
        onFailure: (_) => 0,
      );

      // 상태 업데이트
      state = state.copyWith(
        bookmarksCount: bookmarksCount,
        likesCount: likesCount,
        commentsCount: commentsCount,
      );
    } catch (e) {
      // 통계 정보를 불러오지 못해도 기본 프로필 정보는 표시
      print('통계 정보를 불러오는 중 오류 발생: $e');
    }
  }

  /// 프로필 정보 업데이트
  Future<bool> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    state = state.copyWithLoading();

    try {
      final response = await _profileService.updateProfile(
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      return response.fold(
        onSuccess: (_) {
          state = state.copyWith(
            isLoading: false,
            username: username ?? state.username,
            bio: bio ?? state.bio,
            avatarUrl: avatarUrl ?? state.avatarUrl,
          );
          return true;
        },
        onFailure: (error) {
          state = state.copyWith(
            isLoading: false,
            error: '프로필 업데이트에 실패했습니다: ${error.message}',
          );
          return false;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '프로필 업데이트 중 오류가 발생했습니다: $e',
      );
      return false;
    }
  }

  /// 통계 정보 새로고침
  Future<void> refreshCounts() async {
    await _loadCounts();
  }
}
