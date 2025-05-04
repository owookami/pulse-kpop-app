import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../auth/controller/auth_controller.dart';
import '../../bookmark/widgets/bookmark_button.dart';
import '../../subscription/helpers/subscription_helpers.dart';
import '../../subscription/provider/subscription_provider.dart';
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
  static Widget fromId({
    required String videoId,
    Key? key,
  }) {
    return Consumer(
      key: key,
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
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  /// 비디오 공유 처리
  void _shareVideo(BuildContext context) {
    Share.share(
      '펄스 앱에서 "${video.title}" 비디오를 확인해보세요!\n'
      '${video.videoUrl}',
      subject: '펄스 비디오 공유: ${video.title}',
    );
  }

  // 비디오 정보 표시
  void _showVideoInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비디오 정보'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('제목: ${video.title}'),
              const SizedBox(height: 8),
              Text('ID: ${video.id}'),
              const SizedBox(height: 8),
              Text('플랫폼: ${video.platform}'),
              const SizedBox(height: 8),
              Text('플랫폼 ID: ${video.platformId}'),
              const SizedBox(height: 8),
              Text('URL: ${video.videoUrl}'),
              const SizedBox(height: 8),
              Text('설명: ${video.description ?? "설명 없음"}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedVideosAsync = ref.watch(relatedVideosProvider(video.id));
    final isFullScreen = useState(false);
    final isLoading = useState(true);
    final errorMessage = useState<String?>(null);

    // 화면 방향 감지
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // 비디오 컨트롤러 상태
    final controller = useState<VideoPlayerController?>(null);

    // 유튜브 비디오 여부 확인
    final isYouTubeVideo = _isYouTubeUrl(video.videoUrl);

    // 인증 및 구독 상태 확인
    final authState = ref.watch(authControllerProvider);
    final subscriptionState = ref.watch(subscriptionProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isPremium = subscriptionState.isPremium;

    // 접근 권한 여부
    final hasAccessToVideo = isAuthenticated && isPremium;
    final shouldShowSubscriptionPrompt = useState(false);

    // 화면 활성화 상태 트래킹
    final isScreenActive = useState(true);

    debugPrint('비디오 로드 시작: ${video.title}');
    debugPrint('비디오 URL: ${video.videoUrl}');
    debugPrint('YouTube 비디오 여부: $isYouTubeVideo');
    debugPrint('인증 상태: $isAuthenticated, 프리미엄 상태: $isPremium');

    // 모델 디버깅용 로그
    if (kDebugMode) {
      debugPrint('비디오 정보: ID=${video.id}, 플랫폼=${video.platform}, 플랫폼ID=${video.platformId}');
    }

    // 구독 안내 다이얼로그 표시
    void showSubscriptionPrompt() {
      SubscriptionHelpers.showSubscriptionDialog(
        context,
        isAuthenticated,
        isPremium,
      );
    }

    // 비디오 초기화 & 정리를 위한 이펙트
    useEffect(() {
      debugPrint('VideoPlayerScreen useEffect 실행');
      isScreenActive.value = true;

      // 전역 동영상 상태 관리 - 현재 동영상 활성화
      // 빌드 사이클 이후에 Provider 상태 변경을 위해 Future.microtask 사용
      Future.microtask(() {
        if (isScreenActive.value) {
          ref.read(videoPlayerLifecycleProvider.notifier).startPlaying(video.id);
        }
      });

      // 일반 모드 (상태 표시줄 표시)
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // 화면 방향을 세로로 고정
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

      // 비디오 액세스 확인 및 초기화 함수
      Future<void> initializePlayer() async {
        if (!isScreenActive.value) return;

        // 권한 체크: 수정된 로직으로 비회원도 10개까지 시청 가능
        final hasAccess = await SubscriptionHelpers.checkVideoAccess(context, ref, video);

        if (!isScreenActive.value) return;
        if (!hasAccess) {
          if (isScreenActive.value) {
            isLoading.value = false;
            shouldShowSubscriptionPrompt.value = true;
          }
          return;
        }

        // 비디오 URL 유효성 검사
        if (video.videoUrl.isEmpty) {
          if (isScreenActive.value) {
            errorMessage.value = '동영상 URL이 제공되지 않았습니다.';
            isLoading.value = false;
          }
          debugPrint('동영상 URL이 비어있음');
          return;
        }

        // YouTube 동영상인 경우 별도 처리
        if (isYouTubeVideo) {
          debugPrint('YouTube 비디오 URL 감지: ${video.videoUrl}');
          // YouTube 플레이어를 사용하므로 여기서는 로딩만 해제
          if (isScreenActive.value) {
            isLoading.value = false;
          }
        }
        // 일반 비디오 처리
        else {
          // 기존 컨트롤러 해제
          controller.value?.dispose();

          try {
            // 새 비디오 컨트롤러 초기화
            final newController = VideoPlayerController.networkUrl(
              Uri.parse(video.videoUrl),
            );

            // 컨트롤러 초기화 및 재생 시작
            await newController.initialize();

            // 위젯이 아직 마운트 상태인지 확인
            if (!isScreenActive.value) {
              newController.dispose();
              return;
            }

            await newController.play();

            if (isScreenActive.value) {
              controller.value = newController;
              isLoading.value = false;
            } else {
              newController.dispose();
            }
          } catch (e) {
            debugPrint('비디오 컨트롤러 초기화 오류: $e');
            if (isScreenActive.value) {
              errorMessage.value = '동영상을 로드할 수 없습니다: $e';
              isLoading.value = false;
            }
          }
        }
      }

      // 비디오 초기화 실행
      initializePlayer();

      // 화면이 언마운트될 때 실행되는 정리 작업
      return () {
        debugPrint('VideoPlayerScreen dispose 호출됨');
        isScreenActive.value = false;

        // 비디오 리소스 정리
        final currentController = controller.value;
        if (currentController != null) {
          currentController.pause();
          currentController.dispose();
        }

        // 전역 비디오 상태 관리에 화면 비활성화 알림
        ref.read(videoPlayerLifecycleProvider.notifier).releaseResources();

        // 화면 방향 제한 해제
        SystemChrome.setPreferredOrientations([]);

        // 시스템 UI 원래대로 복원
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      };
    }, []);

    // 관련 비디오 선택 처리 함수
    void handleRelatedVideoTap(Video selectedVideo) {
      // 비디오 재생 중지 및 컨트롤러 해제
      controller.value?.pause();

      // 비디오 상태 정리
      ref.read(videoPlayerLifecycleProvider.notifier).releaseResources();

      // 선택된 비디오로 화면 전환 (독립 화면으로 이동)
      SubscriptionHelpers.handleVideoSelection(context, ref, selectedVideo);
    }

    // WillPopScope 대체 - 뒤로가기 이벤트 처리
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          debugPrint('VideoPlayerScreen - 뒤로 가기 감지, 리소스 정리 중');
          // 비디오 재생 중지 및 컨트롤러 해제
          controller.value?.pause();

          // 비디오 리소스 정리
          ref.read(videoPlayerLifecycleProvider.notifier).releaseResources();

          // 화면 방향 제한 해제
          SystemChrome.setPreferredOrientations([]);
        }
      },
      child: Scaffold(
        appBar: isLandscape
            ? null
            : AppBar(
                title: Text(
                  video.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    // 컨트롤러 중지
                    controller.value?.pause();
                    // 비디오 리소스 정리
                    ref.read(videoPlayerLifecycleProvider.notifier).releaseResources();
                    // 뒤로가기
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
                actions: [
                  BookmarkButton(videoId: video.id),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _shareVideo(context),
                  ),
                ],
              ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // 비디오 플레이어 영역
              isYouTubeVideo
                  ? YouTubePlayerWidget(
                      youtubeUrl: video.videoUrl,
                      platformId: video.platformId,
                      onFullScreenToggle: (isFullscreen) {
                        isFullScreen.value = isFullscreen;
                      },
                    )
                  : AspectRatio(
                      aspectRatio: controller.value?.value.aspectRatio ?? 16 / 9,
                      child: errorMessage.value != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error, color: Colors.red, size: 48),
                                  const SizedBox(height: 16),
                                  Text(
                                    errorMessage.value!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : isLoading.value
                              ? const Center(child: CircularProgressIndicator())
                              : controller.value != null
                                  ? VideoPlayer(controller.value!)
                                  : const Center(
                                      child: Text('비디오를 찾을 수 없습니다.'),
                                    ),
                    ),

              // 비디오 정보 영역 (가로 모드에서는 숨김)
              if (!isLandscape && !isFullScreen.value)
                Container(
                  child: shouldShowSubscriptionPrompt.value
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock,
                                size: 48,
                                color: Colors.amber,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '이 콘텐츠를 시청하려면\n구독이 필요합니다',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: showSubscriptionPrompt,
                                child: const Text('구독 정보 보기'),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 비디오 정보 카드
                            VideoInfoCard(video: video),

                            // 관련 비디오 목록
                            RatingPanel(videoId: video.id),

                            // 관련 비디오 목록
                            relatedVideosAsync.when(
                              data: (videos) => RelatedVideosList(
                                videos: videos,
                                onVideoTap: handleRelatedVideoTap,
                              ),
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (error, _) => Center(
                                child: Text('관련 비디오를 불러올 수 없습니다: $error'),
                              ),
                            ),
                          ],
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
