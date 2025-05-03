import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../bookmark/widgets/bookmark_button.dart';
import '../../vote/widgets/rating_panel.dart';
import '../providers/video_player_provider.dart';
import '../widgets/related_videos_list.dart';
import '../widgets/video_info_card.dart';
import '../widgets/youtube_player_widget.dart';

/// 비디오 플레이어 화면
class VideoPlayerScreen extends HookConsumerWidget {
  /// 생성자
  const VideoPlayerScreen({
    super.key,
    required this.video,
  });

  /// ID 기반 생성자
  /// 비디오 ID를 기반으로 플레이어 화면 생성
  /// [videoId]는 데이터베이스의 비디오 ID
  static Widget fromId({required String videoId}) {
    return Consumer(
      builder: (context, ref, _) {
        final asyncVideo = ref.watch(videoByIdProvider(videoId));

        return asyncVideo.when(
          data: (video) => VideoPlayerScreen(video: video),
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text('비디오를 불러올 수 없습니다: $error'),
            ),
          ),
        );
      },
    );
  }

  /// 비디오 정보
  final Video video;

  /// YouTube URL 여부 확인
  bool _isYouTubeUrl(String url) {
    if (url.isEmpty) {
      debugPrint('URL이 비어있어 YouTube 동영상으로 처리할 수 없음');
      return false;
    }

    try {
      // 표준 YouTube URL 형식 확인
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        debugPrint('YouTube URL 패턴 감지됨: $url');
        return true;
      }

      // 유효한 URL인지 확인
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        debugPrint('YouTube 호스트 확인됨: ${uri.host}');
        return true;
      }

      // YouTube ID 형식인지 확인 (11자리 영숫자와 특수문자)
      if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(url)) {
        debugPrint('입력이 YouTube ID 형식으로 보임: $url');
        return true;
      }

      debugPrint('YouTube URL로 인식되지 않음: $url');
      return false;
    } catch (e) {
      // URL 파싱 실패 시 텍스트 패턴으로 판단
      debugPrint('URL 파싱 실패, 텍스트 패턴으로 판단: $e');
      return url.contains('youtube.com') || url.contains('youtu.be');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedVideos = ref.watch(relatedVideosProvider(video.id));
    final isFullScreen = useState(false);
    final isLoading = useState(true);
    final errorMessage = useState<String?>(null);

    // 비디오 컨트롤러 상태
    final controller = useState<VideoPlayerController?>(null);

    // 유튜브 비디오 여부 확인
    final isYouTubeVideo = _isYouTubeUrl(video.videoUrl);

    debugPrint('비디오 로드 시작: ${video.title}');
    debugPrint('비디오 URL: ${video.videoUrl}');
    debugPrint('YouTube 비디오 여부: $isYouTubeVideo');

    // 모델 디버깅용 로그
    if (kDebugMode) {
      debugPrint('비디오 정보: ID=${video.id}, 플랫폼=${video.platform}, 플랫폼ID=${video.platformId}');
    }

    // 화면이 처음 로드될 때 실행되는 효과
    useEffect(() {
      debugPrint('VideoPlayerScreen useEffect 실행');

      // 일반 모드 (상태 표시줄 표시)
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // 화면 방향을 세로로 고정
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

      // 비디오 URL 유효성 검사
      if (video.videoUrl.isEmpty) {
        errorMessage.value = '동영상 URL이 제공되지 않았습니다.';
        isLoading.value = false;
        debugPrint('동영상 URL이 비어있음');
        return null;
      }

      // YouTube 동영상인 경우 별도 처리
      if (isYouTubeVideo) {
        debugPrint('YouTube 비디오 URL 감지: ${video.videoUrl}');
        // YouTube 플레이어를 사용하므로 여기서는 로딩만 해제
        isLoading.value = false;
        return null;
      }

      try {
        debugPrint('표준 비디오 URL 처리: ${video.videoUrl}');
        // 비디오 컨트롤러 초기화
        final videoController = VideoPlayerController.networkUrl(
          Uri.parse(video.videoUrl),
        );

        controller.value = videoController;

        // 초기화 및 자동 재생
        videoController.initialize().then((_) {
          videoController.play();
          isLoading.value = false;
          debugPrint('표준 비디오 초기화 및 재생 시작 성공');
        }).catchError((error) {
          errorMessage.value = '동영상을 로드하는 중 오류가 발생했습니다: $error';
          isLoading.value = false;
          debugPrint('비디오 초기화 오류: $error');
        });

        // 화면이 언마운트될 때 컨트롤러 해제
        return () {
          debugPrint('VideoPlayerScreen dispose 호출됨');
          controller.value?.pause();
          controller.value?.dispose();

          // 화면 방향 원래대로 복원
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        };
      } catch (e) {
        errorMessage.value = '동영상 플레이어 초기화 중 오류가 발생했습니다: $e';
        isLoading.value = false;
        debugPrint('비디오 컨트롤러 생성 오류: $e');
        return null;
      }
    }, []);

    // 전체 화면 토글 함수
    void toggleFullScreen() {
      if (isFullScreen.value) {
        // 일반 모드로 돌아가기
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      } else {
        // 전체 화면 모드로 전환
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
      isFullScreen.value = !isFullScreen.value;
    }

    return Scaffold(
      backgroundColor: isFullScreen.value ? Colors.black : null,
      appBar: isFullScreen.value
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              iconTheme: Theme.of(context).iconTheme,
              title: Text(
                video.title,
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                // 북마크 버튼
                BookmarkButton(
                  videoId: video.id,
                  color: null,
                ),
              ],
            ),
      body: Padding(
        padding: EdgeInsets.only(
          top: isFullScreen.value ? MediaQuery.of(context).padding.top : 0,
        ),
        child: Column(
          children: [
            // 비디오 플레이어 영역
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // YouTube 플레이어
                    if (isYouTubeVideo && !isLoading.value)
                      YouTubePlayerWidget(
                        youtubeUrl: video.videoUrl,
                        onFullScreenToggle: (fullScreenState) {
                          // YouTubePlayerWidget에서 전체화면 상태가 변경되면 호출
                          isFullScreen.value = fullScreenState;
                        },
                      ),

                    // 일반 비디오 플레이어
                    if (!isYouTubeVideo &&
                        !isLoading.value &&
                        errorMessage.value == null &&
                        controller.value != null)
                      controller.value!.value.isInitialized
                          ? GestureDetector(
                              onTap: () {
                                if (controller.value!.value.isPlaying) {
                                  controller.value!.pause();
                                } else {
                                  controller.value!.play();
                                }
                              },
                              child: AspectRatio(
                                aspectRatio: controller.value!.value.aspectRatio,
                                child: VideoPlayer(controller.value!),
                              ),
                            )
                          : const Center(
                              child: Text(
                                '동영상 초기화 중...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),

                    // 로딩 인디케이터
                    if (isLoading.value)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),

                    // 오류 메시지
                    if (errorMessage.value != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage.value!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              if (kDebugMode)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'URL: ${video.videoUrl}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                    // 일반 비디오 컨트롤 오버레이 (유튜브 동영상은 자체 컨트롤 사용)
                    if (!isYouTubeVideo &&
                        !isLoading.value &&
                        errorMessage.value == null &&
                        controller.value != null &&
                        controller.value!.value.isInitialized)
                      Stack(
                        children: [
                          // 재생/일시정지 버튼
                          Center(
                            child: AnimatedOpacity(
                              opacity: controller.value!.value.isPlaying ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  controller.value!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 50.0,
                                ),
                              ),
                            ),
                          ),

                          // 전체 화면 버튼
                          Positioned(
                            right: 8,
                            bottom: 48,
                            child: IconButton(
                              icon: Icon(
                                isFullScreen.value ? Icons.fullscreen_exit : Icons.fullscreen,
                                color: Colors.white,
                              ),
                              onPressed: toggleFullScreen,
                            ),
                          ),

                          // 진행 표시줄 (하단)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: VideoProgressIndicator(
                              controller.value!,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: Colors.red,
                                bufferedColor: Colors.white54,
                                backgroundColor: Colors.black45,
                              ),
                              padding: const EdgeInsets.all(10),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // 비디오 정보 및 관련 비디오
            if (!isFullScreen.value)
              Expanded(
                child: ListView(
                  children: [
                    // 비디오 정보 카드
                    VideoInfoCard(video: video),

                    // 평가 패널
                    RatingPanel(videoId: video.id),

                    // 관련 비디오
                    relatedVideos.when(
                      data: (videos) => RelatedVideosList(
                        videos: videos,
                        onVideoTap: (selectedVideo) {
                          // 네비게이션 전에 현재 화면의 상태를 정리
                          // 선택된 비디오로 네비게이션할 때 route를 교체하여 메모리 관리 최적화
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) {
                                return VideoPlayerScreen(video: selectedVideo);
                              },
                            ),
                          );
                        },
                      ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('관련 동영상을 불러올 수 없습니다: $error'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
