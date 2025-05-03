import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/bookmark_state.dart';

/// 북마크 노티파이어 프로바이더
final bookmarkProvider = StateNotifierProvider.family<BookmarkNotifier, BookmarkState, String>(
  (ref, videoId) {
    final bookmarkService = ref.watch(bookmarkServiceProvider);
    return BookmarkNotifier(
      bookmarkService: bookmarkService,
      videoId: videoId,
    );
  },
);

/// 북마크 모든 비디오 프로바이더
final bookmarkedVideosProvider = FutureProvider<List<Video>>((ref) async {
  final bookmarkService = ref.watch(bookmarkServiceProvider);

  final response = await bookmarkService.getBookmarkedVideos();
  if (response.isSuccess && response.dataOrNull != null) {
    // API 응답의 Map<String, dynamic> 데이터를 Video 객체로 변환
    return response.dataOrNull!.map((data) => Video.fromJson(data)).toList();
  }

  return [];
});

/// 북마크 상태 관리 노티파이어
class BookmarkNotifier extends StateNotifier<BookmarkState> {
  /// 생성자
  BookmarkNotifier({
    required BookmarkService bookmarkService,
    required String videoId,
  })  : _bookmarkService = bookmarkService,
        _videoId = videoId,
        super(const BookmarkState()) {
    // 초기 상태 로드
    _loadBookmarkState();
  }

  final BookmarkService _bookmarkService;
  final String _videoId;

  /// 초기 북마크 상태 로드
  Future<void> _loadBookmarkState() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _bookmarkService.isBookmarked(videoId: _videoId);
      if (response.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          isBookmarked: response.dataOrNull ?? false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.errorOrNull?.message ?? '북마크 상태를 확인할 수 없습니다.',
        );
      }
    } catch (e) {
      debugPrint('북마크 상태 로드 오류: $e');
      state = state.copyWith(
        isLoading: false,
        error: '북마크 상태를 확인하는 중 오류가 발생했습니다.',
      );
    }
  }

  /// 북마크 토글 (추가/제거)
  Future<void> toggleBookmark() async {
    try {
      // 이미 로딩 중이면 무시
      if (state.isLoading) return;

      // 로딩 상태로 변경
      state = state.copyWith(isLoading: true, error: null);

      // 북마크 토글 API 호출
      final response = await _bookmarkService.toggleBookmark(videoId: _videoId);

      if (response.isSuccess) {
        // 성공 시 상태 업데이트
        final isBookmarked = response.dataOrNull ?? !state.isBookmarked;
        state = state.copyWith(
          isLoading: false,
          isBookmarked: isBookmarked,
        );

        debugPrint('북마크 토글 성공: videoId=$_videoId, isBookmarked=$isBookmarked');
      } else {
        // 오류 처리
        debugPrint('북마크 토글 실패: ${response.errorOrNull?.message}');
        state = state.copyWith(
          isLoading: false,
          error: response.errorOrNull?.message ?? '북마크 처리 중 오류가 발생했습니다.',
        );
      }
    } catch (e) {
      // 예외 처리
      debugPrint('북마크 토글 예외: $e');
      state = state.copyWith(
        isLoading: false,
        error: '북마크 처리 중 오류가 발생했습니다.',
      );
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    await _loadBookmarkState();
  }
}
