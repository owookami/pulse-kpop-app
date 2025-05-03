import 'package:api_client/api_client.dart';

/// 비디오 플레이어 상태 모델
class VideoPlayerState {
  /// 기본 생성자
  const VideoPlayerState({
    this.currentVideo,
    this.isLoading = false,
    this.isPlaying = false,
    this.isMuted = false,
    this.currentPosition = 0,
    this.duration = 0,
    this.isBuffering = false,
    this.isFullScreen = false,
    this.isPipMode = false,
    this.playbackSpeed = 1.0,
    this.areControlsVisible = true,
    this.errorMessage,
    this.relatedVideos = const [],
  });

  /// 현재 재생 중인 비디오
  final Video? currentVideo;

  /// 비디오가 로딩 중인지 여부
  final bool isLoading;

  /// 비디오가 재생 중인지 여부
  final bool isPlaying;

  /// 비디오가 음소거되었는지 여부
  final bool isMuted;

  /// 현재 영상 재생 위치 (초)
  final int currentPosition;

  /// 영상 전체 길이 (초)
  final int duration;

  /// 버퍼링 중인지 여부
  final bool isBuffering;

  /// 전체 화면 모드인지 여부
  final bool isFullScreen;

  /// PIP(Picture-in-Picture) 모드인지 여부
  final bool isPipMode;

  /// 재생 속도 (1.0 = 기본 속도)
  final double playbackSpeed;

  /// 컨트롤이 표시되고 있는지 여부
  final bool areControlsVisible;

  /// 오류 메시지
  final String? errorMessage;

  /// 관련 영상 목록
  final List<Video> relatedVideos;

  /// 상태 복사본 생성
  VideoPlayerState copyWith({
    Video? currentVideo,
    bool? isLoading,
    bool? isPlaying,
    bool? isMuted,
    int? currentPosition,
    int? duration,
    bool? isBuffering,
    bool? isFullScreen,
    bool? isPipMode,
    double? playbackSpeed,
    bool? areControlsVisible,
    String? errorMessage,
    List<Video>? relatedVideos,
  }) {
    return VideoPlayerState(
      currentVideo: currentVideo ?? this.currentVideo,
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      isMuted: isMuted ?? this.isMuted,
      currentPosition: currentPosition ?? this.currentPosition,
      duration: duration ?? this.duration,
      isBuffering: isBuffering ?? this.isBuffering,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      isPipMode: isPipMode ?? this.isPipMode,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      areControlsVisible: areControlsVisible ?? this.areControlsVisible,
      errorMessage: errorMessage ?? this.errorMessage,
      relatedVideos: relatedVideos ?? this.relatedVideos,
    );
  }
}
