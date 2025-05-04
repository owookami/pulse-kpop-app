import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/vote/model/vote_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 비디오별 투표 상태 프로바이더
final voteProvider = StateNotifierProvider.family<VoteNotifier, VoteState, String>(
  (ref, videoId) {
    final videoService = ref.watch(videoServiceProvider);
    final authState = ref.watch(authControllerProvider);

    return VoteNotifier(
      videoId: videoId,
      videoService: videoService,
      isAuthenticated: authState.hasValue && authState.value!.isAuthenticated,
      ref: ref,
    );
  },
);

/// 투표 상태 관리 노티파이어
class VoteNotifier extends StateNotifier<VoteState> {
  /// 생성자
  VoteNotifier({
    required String videoId,
    required VideoService videoService,
    required bool isAuthenticated,
    required Ref ref,
  })  : _videoId = videoId,
        _videoService = videoService,
        _ref = ref,
        super(VoteState.initial()) {
    // 비디오 로드 시 투표 정보도 함께 로드
    loadVoteInfo();
  }

  final String _videoId;
  final VideoService _videoService;
  final Ref _ref;

  // 로컬 저장소 키
  String get _ratingKey => 'rating_$_videoId';
  String get _likeKey => 'like_$_videoId';
  String get _dislikeKey => 'dislike_$_videoId';

  /// 투표 정보 로드
  Future<void> loadVoteInfo() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      // 서버에서 투표 정보 로드
      final response = await _videoService.getVoteInfo(videoId: _videoId);

      response.fold(
        onSuccess: (voteInfo) {
          final likeCount = voteInfo['likeCount'] ?? 0;

          state = state.copyWith(
            isLoading: false,
            error: null,
            userRating: voteInfo['userRating'],
            isLiked: voteInfo['isLiked'] ?? false,
            isDisliked: voteInfo['isDisliked'] ?? false,
            averageRating: voteInfo['averageRating'] ?? 0.0,
            totalVotes: voteInfo['totalVotes'] ?? 0,
            likeCount: likeCount,
            originalLikeCount: likeCount, // 원본 좋아요 수 저장
            dislikeCount: voteInfo['dislikeCount'] ?? 0,
          );
        },
        onFailure: (error) {
          state = state.copyWith(
            isLoading: false,
            error: '투표 정보를 불러오는 중 오류가 발생했습니다: ${error.message}',
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '투표 정보를 불러오는 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  /// 별점 평가
  Future<void> rateVideo(double rating) async {
    if (state.isLoading) return;
    if (rating < 0 || rating > 5) return;

    // 낙관적 UI 업데이트
    final previousRating = state.userRating;
    final previousTotalVotes = state.totalVotes;
    final previousAverage = state.averageRating;

    // 새로운 평가인지 확인 (기존 평점이 없으면 새 평가)
    final isNewRating = previousRating == null;

    // 낙관적 UI 업데이트를 위한 새 평균 계산
    double newAverage = previousAverage;
    if (isNewRating && previousTotalVotes > 0) {
      // 새 평가라면: (기존총점 + 새별점) / (기존참여자수 + 1)
      double totalScore = previousAverage * previousTotalVotes + rating;
      newAverage = totalScore / (previousTotalVotes + 1);
    } else if (!isNewRating && previousTotalVotes > 0) {
      // 기존 평가 수정: (기존총점 - 이전별점 + 새별점) / 참여자수
      double totalScore = previousAverage * previousTotalVotes - (previousRating ?? 0) + rating;
      newAverage = totalScore / previousTotalVotes;
    }

    // 낙관적 UI 업데이트: 평가자 수 증가 및 별점 업데이트
    state = state.copyWith(
      userRating: rating,
      // 새로운 평가라면 참여자 수 1 증가
      totalVotes: isNewRating ? previousTotalVotes + 1 : previousTotalVotes,
      // 평균 별점도 즉시 업데이트 (소수점 둘째자리까지)
      averageRating: double.parse(newAverage.toStringAsFixed(2)),
      isLoading: true,
    );

    try {
      print('별점 평가 시작: rating=$rating, previousRating=$previousRating, isNewRating=$isNewRating');

      // 서버에 별점 저장
      final response = await _videoService.rateVideo(videoId: _videoId, rating: rating);

      response.fold(
        onSuccess: (_) async {
          print('별점 평가 성공');
          // 성공적으로 별점이 저장된 경우, 최신 투표 정보 로드
          try {
            await loadVoteInfo();
            print('별점 평가 후 데이터 로드 성공');
          } catch (loadError) {
            print('별점 평가 후 데이터 로드 오류: $loadError');
            // loadVoteInfo에 실패하더라도 isLoading은 false로 설정
            state = state.copyWith(isLoading: false);
          }
        },
        onFailure: (error) {
          // 서버 에러 처리
          print('별점 평가 실패: ${error.message}');
          // 이전 상태로 복구
          state = state.copyWith(
            userRating: previousRating,
            totalVotes: previousTotalVotes,
            averageRating: previousAverage,
            isLoading: false,
            error: error.message,
          );
        },
      );
    } catch (e) {
      // 예외 발생 시
      print('별점 평가 예외: $e');
      // 이전 상태로 복구
      state = state.copyWith(
        userRating: previousRating,
        totalVotes: previousTotalVotes,
        averageRating: previousAverage,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 좋아요/싫어요 토글
  Future<void> toggleLike(bool isLike) async {
    if (state.isLoading) return;

    // 이미 선택된 같은 상태라면 취소
    final isSelected = isLike ? state.isLiked : state.isDisliked;
    final willCancel = isSelected;

    // 낙관적 UI 업데이트
    final previousState = state;

    // 상태 업데이트 전에 isLoading을 true로 설정
    state = state.copyWith(isLoading: true);

    try {
      // 상태 업데이트 (낙관적 UI)
      if (isLike) {
        // 좋아요의 경우 원본 좋아요 수에 +1을 한 값 사용
        final newLikeCount = willCancel ? state.originalLikeCount : state.originalLikeCount + 1;

        state = state.copyWith(
          isLiked: !willCancel,
          isDisliked: false, // 좋아요 선택 시 싫어요는 해제
          likeCount: newLikeCount,
          dislikeCount: state.isDisliked ? state.dislikeCount - 1 : state.dislikeCount,
          isLoading: true, // 계속 로딩 상태 유지
        );
      } else {
        state = state.copyWith(
          isDisliked: !willCancel,
          isLiked: false, // 싫어요 선택 시 좋아요는 해제
          dislikeCount: willCancel ? state.dislikeCount - 1 : state.dislikeCount + 1,
          // 좋아요 취소시 원본 값으로 복원
          likeCount: state.isLiked ? state.originalLikeCount : state.likeCount,
          isLoading: true, // 계속 로딩 상태 유지
        );
      }

      // API 호출
      final response = await _videoService.likeVideo(
        videoId: _videoId,
        isLike: isLike,
        cancel: willCancel,
      );

      if (response.isFailure) {
        // API 호출 실패 시 이전 상태로 복원
        state = previousState.copyWith(
          isLoading: false,
          error: '좋아요/싫어요 처리 중 오류가 발생했습니다: ${response.errorOrNull?.message}',
        );
        debugPrint('좋아요/싫어요 토글 오류: ${response.errorOrNull?.message}');
        return;
      }

      // API 호출 성공 시 최신 데이터 로드 시도
      try {
        await loadVoteInfo();

        // API에서 가져온 원본 좋아요 값에 사용자의 좋아요 여부에 따라 +1 적용
        if (state.isLiked) {
          state = state.copyWith(
            likeCount: state.originalLikeCount + 1,
          );
        }
      } catch (loadError) {
        debugPrint('좋아요/싫어요 후 데이터 로드 오류: $loadError');
        // loadVoteInfo에 실패하더라도 isLoading은 false로 설정
        state = state.copyWith(isLoading: false);
      }

      // 만약 loadVoteInfo에서 상태 업데이트가 제대로 안 되었을 수 있으므로 명시적으로 isLoading을 false로 설정
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }

      // 디버그 로그 추가
      debugPrint(
          '좋아요/싫어요 토글 완료: isLike=$isLike, willCancel=$willCancel, 결과=${isLike ? state.isLiked : state.isDisliked}');
    } catch (e) {
      // 오류 발생 시 이전 상태로 복원
      state = previousState.copyWith(
        isLoading: false,
        error: '좋아요/싫어요 처리 중 오류가 발생했습니다: ${e.toString()}',
      );
      debugPrint('좋아요/싫어요 토글 오류: $e');
    }
  }

  /// 투표 초기화 (내부 테스트용)
  Future<void> resetVotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ratingKey);
      await prefs.remove(_likeKey);
      await prefs.remove(_dislikeKey);

      state = VoteState.initial().copyWith(
        averageRating: state.averageRating,
        totalVotes: state.totalVotes,
        likeCount: state.likeCount,
        dislikeCount: state.dislikeCount,
      );
    } catch (e) {
      state = state.copyWith(
        error: '초기화 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }
}
