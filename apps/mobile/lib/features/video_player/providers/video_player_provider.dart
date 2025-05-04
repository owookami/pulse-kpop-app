import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 특정 ID의 비디오를 가져오는 프로바이더
final videoByIdProvider = FutureProvider.family<Video, String>((ref, videoId) async {
  final videoService = ref.watch(videoServiceProvider);
  final response = await videoService.getVideoDetails(videoId: videoId);

  return response.fold(
    onSuccess: (video) => video,
    onFailure: (error) => throw error,
  );
});

/// 관련 비디오를 가져오는 프로바이더
final relatedVideosProvider = FutureProvider.family<List<Video>, String>((ref, videoId) async {
  try {
    final video = await ref.watch(videoByIdProvider(videoId).future);
    final videoService = ref.watch(videoServiceProvider);

    // artist_id가 비어있거나 null인 경우 검증
    if (video.artistId.isEmpty) {
      debugPrint('관련 비디오를 artist_id 기반으로 불러올 수 없음: 비디오의 artist_id가 비어있습니다.');

      // 대체 방법: 인기 비디오 가져오기
      debugPrint('대신 인기 비디오를 가져옵니다.');

      final response = await videoService.getTrendingVideos(limit: 10);

      return response.fold(
        onSuccess: (videos) {
          // 타입 안전성 보장을 위한 변환 로직 개선
          final typeSafeVideos = videos
              .map((dynamic v) {
                if (v is Video) {
                  return v;
                } else if (v is Map) {
                  try {
                    // Map을 안전하게 Video로 변환하기 위해 Map<String, dynamic>으로 먼저 캐스팅
                    final Map<String, dynamic> videoMap = Map<String, dynamic>.from(v);
                    return Video.fromJson(videoMap);
                  } catch (e) {
                    debugPrint('Video 변환 오류: $e');
                    return null;
                  }
                } else {
                  debugPrint('지원되지 않는 데이터 타입: ${v.runtimeType}');
                  return null;
                }
              })
              .whereType<Video>()
              .where((v) => v.id != videoId)
              .toList();

          return typeSafeVideos;
        },
        onFailure: (error) {
          debugPrint('인기 비디오 로딩 오류: $error');
          return []; // 오류 발생시 빈 배열 반환
        },
      );
    }

    // UUID 형식 검증 (간단한 검증)
    final uuidRegExp = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
    if (!uuidRegExp.hasMatch(video.artistId)) {
      debugPrint('관련 비디오를 불러올 수 없음: 유효하지 않은 artist_id 형식: ${video.artistId}');

      // 대체 방법: 인기 비디오 가져오기
      debugPrint('대신 인기 비디오를 가져옵니다.');

      final response = await videoService.getTrendingVideos(limit: 10);

      return response.fold(
        onSuccess: (videos) {
          // 타입 안전성 보장을 위한 변환 로직 개선
          final typeSafeVideos = videos
              .map((dynamic v) {
                if (v is Video) {
                  return v;
                } else if (v is Map) {
                  try {
                    // Map을 안전하게 Video로 변환하기 위해 Map<String, dynamic>으로 먼저 캐스팅
                    final Map<String, dynamic> videoMap = Map<String, dynamic>.from(v);
                    return Video.fromJson(videoMap);
                  } catch (e) {
                    debugPrint('Video 변환 오류: $e');
                    return null;
                  }
                } else {
                  debugPrint('지원되지 않는 데이터 타입: ${v.runtimeType}');
                  return null;
                }
              })
              .whereType<Video>()
              .where((v) => v.id != videoId)
              .toList();

          return typeSafeVideos;
        },
        onFailure: (error) {
          debugPrint('인기 비디오 로딩 오류: $error');
          return []; // 오류 발생시 빈 배열 반환
        },
      );
    }

    // 아티스트 ID 기반으로 관련 비디오 가져오기
    final response = await videoService.getArtistVideos(
      artistId: video.artistId,
    );

    return response.fold(
      onSuccess: (videos) {
        // 타입 안전성 보장을 위한 변환 로직 개선
        final typeSafeVideos = videos
            .map((dynamic v) {
              if (v is Video) {
                return v;
              } else if (v is Map) {
                try {
                  // Map을 안전하게 Video로 변환하기 위해 Map<String, dynamic>으로 먼저 캐스팅
                  final Map<String, dynamic> videoMap = Map<String, dynamic>.from(v);
                  return Video.fromJson(videoMap);
                } catch (e) {
                  debugPrint('Video 변환 오류: $e');
                  return null;
                }
              } else {
                debugPrint('지원되지 않는 데이터 타입: ${v.runtimeType}');
                return null;
              }
            })
            .whereType<Video>()
            .where((v) => v.id != videoId)
            .toList();

        return typeSafeVideos;
      },
      onFailure: (error) {
        debugPrint('관련 비디오 로딩 오류: $error');
        return []; // 오류 발생시 빈 배열 반환
      },
    );
  } catch (e) {
    debugPrint('관련 비디오 로딩 중 예외 발생: $e');
    return []; // 예외 발생시 빈 배열 반환
  }
});

/// 비디오 플레이어 라이프사이클 관리 프로바이더
/// 이 프로바이더를 통해 앱 내 다른 부분에서 동영상 재생 상태를 제어할 수 있습니다.
final videoPlayerLifecycleProvider =
    StateNotifierProvider<VideoPlayerLifecycleNotifier, VideoPlayerLifecycleState>((ref) {
  return VideoPlayerLifecycleNotifier();
});

/// 비디오 플레이어의 상태
class VideoPlayerLifecycleState {
  /// 활성화된 비디오 ID
  final String? activeVideoId;

  /// 재생 중 여부
  final bool isPlaying;

  /// 자원이 해제되었는지 여부
  final bool isResourcesReleased;

  /// 마지막 업데이트 시간 (디버깅 및 로깅 목적)
  final DateTime lastUpdated;

  /// 비디오 플레이어 오류 상태
  final String? errorMessage;

  /// 현재 화면 상태 (화면 전환 감지용)
  final bool isScreenActive;

  /// 생성자
  VideoPlayerLifecycleState({
    this.activeVideoId,
    this.isPlaying = false,
    this.isResourcesReleased = true,
    DateTime? lastUpdated,
    this.errorMessage,
    this.isScreenActive = true,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// 복사본 생성
  VideoPlayerLifecycleState copyWith({
    String? activeVideoId,
    bool? isPlaying,
    bool? isResourcesReleased,
    DateTime? lastUpdated,
    String? errorMessage,
    bool? isScreenActive,
  }) {
    return VideoPlayerLifecycleState(
      activeVideoId: activeVideoId ?? this.activeVideoId,
      isPlaying: isPlaying ?? this.isPlaying,
      isResourcesReleased: isResourcesReleased ?? this.isResourcesReleased,
      lastUpdated: lastUpdated ?? DateTime.now(),
      errorMessage: errorMessage ?? this.errorMessage,
      isScreenActive: isScreenActive ?? this.isScreenActive,
    );
  }

  /// 오류 상태인지 확인
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  /// 상태 초기화를 위한 팩토리 메서드
  factory VideoPlayerLifecycleState.initial() {
    return VideoPlayerLifecycleState(
      activeVideoId: null,
      isPlaying: false,
      isResourcesReleased: true,
      isScreenActive: true,
    );
  }

  @override
  String toString() {
    return 'VideoPlayerLifecycleState(activeVideoId: $activeVideoId, isPlaying: $isPlaying, '
        'isResourcesReleased: $isResourcesReleased, lastUpdated: $lastUpdated, '
        'hasError: $hasError, isScreenActive: $isScreenActive)';
  }
}

/// 비디오 플레이어 라이프사이클 상태 관리 노티파이어
class VideoPlayerLifecycleNotifier extends StateNotifier<VideoPlayerLifecycleState> {
  /// 생성자
  VideoPlayerLifecycleNotifier() : super(VideoPlayerLifecycleState.initial());

  /// 동영상 재생 시작 알림
  void startPlaying(String videoId) {
    debugPrint('VideoPlayerLifecycle: 동영상 $videoId 재생 시작');

    try {
      // 이미 동일한 비디오가 재생 중인지 확인
      if (state.activeVideoId == videoId && state.isPlaying) {
        debugPrint('VideoPlayerLifecycle: 동일한 동영상 $videoId이(가) 이미 재생 중입니다.');

        // 화면 활성화 상태만 업데이트
        state = state.copyWith(
          isScreenActive: true,
          errorMessage: null,
        );
        return;
      }

      // 다른 비디오가 재생 중이면 자원 해제
      if (state.activeVideoId != null && state.activeVideoId != videoId) {
        debugPrint('VideoPlayerLifecycle: 이전 비디오 ${state.activeVideoId}에서 새 비디오 $videoId로 전환');
        _releaseCurrentResources();
      }

      state = state.copyWith(
        activeVideoId: videoId,
        isPlaying: true,
        isResourcesReleased: false,
        isScreenActive: true,
        errorMessage: null,
      );

      if (kDebugMode) {
        debugPrint('VideoPlayerLifecycle 상태 업데이트: $state');
      }
    } catch (e) {
      debugPrint('VideoPlayerLifecycle: 재생 시작 중 오류 발생: $e');
      state = state.copyWith(
        errorMessage: '재생 시작 중 오류 발생: $e',
      );
    }
  }

  /// 동영상 재생 중지 알림
  void stopPlaying() {
    if (state.activeVideoId != null) {
      debugPrint('VideoPlayerLifecycle: 동영상 ${state.activeVideoId} 재생 중지');
      state = state.copyWith(
        isPlaying: false,
      );

      if (kDebugMode) {
        debugPrint('VideoPlayerLifecycle 상태 업데이트: $state');
      }
    }
  }

  /// 동영상 리소스 해제 알림
  void releaseResources() {
    try {
      _releaseCurrentResources();

      // 완전히 초기 상태로 리셋
      state = VideoPlayerLifecycleState.initial();

      if (kDebugMode) {
        debugPrint('VideoPlayerLifecycle 상태 초기화 완료: $state');
      }
    } catch (e) {
      debugPrint('VideoPlayerLifecycle: 리소스 해제 중 오류 발생: $e');
      state = state.copyWith(
        errorMessage: '리소스 해제 중 오류 발생: $e',
        isResourcesReleased: true, // 에러가 발생해도 해제됐다고 간주
      );
    }
  }

  /// 내부용 리소스 해제 함수
  void _releaseCurrentResources() {
    final currentVideoId = state.activeVideoId;
    if (currentVideoId != null) {
      debugPrint('VideoPlayerLifecycle: 동영상 $currentVideoId 리소스 내부 해제 중');
    } else {
      debugPrint('VideoPlayerLifecycle: 모든 동영상 리소스 내부 해제 중');
    }

    // 리소스 해제 상태로 업데이트
    state = state.copyWith(
      isPlaying: false,
      isResourcesReleased: true,
    );
  }

  /// 현재 활성화된 비디오 ID 가져오기
  String? getActiveVideoId() {
    return state.activeVideoId;
  }

  /// 비디오 재생 상태 확인
  bool isVideoPlaying(String videoId) {
    return state.activeVideoId == videoId && state.isPlaying && state.isScreenActive;
  }

  /// 화면 활성화 상태 설정
  void setScreenActive(bool isActive) {
    debugPrint('VideoPlayerLifecycle: 화면 활성화 상태 변경: $isActive');
    state = state.copyWith(
      isScreenActive: isActive,
    );

    // 화면이 비활성화되면 재생 중지 (리소스는 유지)
    if (!isActive && state.isPlaying) {
      stopPlaying();
    }
  }

  /// 오류 상태 설정
  void setError(String? errorMessage) {
    debugPrint('VideoPlayerLifecycle: 오류 상태 설정: $errorMessage');
    state = state.copyWith(
      errorMessage: errorMessage,
    );
  }

  /// 오류 상태 초기화
  void clearError() {
    debugPrint('VideoPlayerLifecycle: 오류 상태 초기화');
    state = state.copyWith(
      errorMessage: null,
    );
  }
}
