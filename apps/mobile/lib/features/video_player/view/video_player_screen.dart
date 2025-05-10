import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../auth/controller/auth_controller.dart';
import '../../bookmark/widgets/bookmark_button.dart';
import '../../subscription/helpers/subscription_helpers.dart';
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
        final l10n = AppLocalizations.of(context);

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
              child: Text(l10n.video_player_load_error(error.toString())),
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
    final l10n = AppLocalizations.of(context);
    Share.share(
      l10n.video_player_share_message(video.title, video.videoUrl),
      subject: l10n.video_player_share_subject(video.title),
    );
  }

  // 비디오 정보 표시
  void _showVideoInfoDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.video_player_info_dialog_title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.video_title_prefix}${video.title}'),
              const SizedBox(height: 8),
              Text('${l10n.video_id_prefix}${video.id}'),
              const SizedBox(height: 8),
              Text('${l10n.video_platform_prefix}${video.platform}'),
              const SizedBox(height: 8),
              Text('${l10n.video_platform_id_prefix}${video.platformId}'),
              const SizedBox(height: 8),
              Text('${l10n.video_url_prefix}${video.videoUrl}'),
              const SizedBox(height: 8),
              Text(
                  '${l10n.video_description_prefix}${video.description ?? l10n.video_player_no_description}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
    final isPremium = SubscriptionHelpers.isPremiumUser(ref);
    final isAuthenticated = authState.isAuthenticated;

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
        SubscriptionHelpers.isPremiumUser(ref),
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

      // 무료 시청 한도 확인 (이전 _checkFreeViewsLimit 로직 통합)
      Future<void> checkFreeViewsLimit() async {
        if (!isScreenActive.value) return;

        final isPremium = SubscriptionHelpers.isPremiumUser(ref);

        // 프리미엄 사용자는 제한 없음
        if (isPremium) return;

        // 무료 시청 한도에 도달했는지 확인 (실제 구현에서는 서비스에서 가져와야 함)
        // 예시: 최대 10회 중 9회 사용, 현재 영상이 10회차
        const viewsUsed = 9; // 예시 값
        const maxViews = 10;

        if (viewsUsed >= maxViews && isScreenActive.value) {
          // 무료 시청 한도 도달 시 안내 다이얼로그 표시
          showSubscriptionPrompt();
        }
      }

      // 무료 시청 한도 확인 실행
      checkFreeViewsLimit();

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
            errorMessage.value = l10n.video_player_load_error(l10n.video_player_youtube_id_error);
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
              errorMessage.value = l10n.video_player_load_error(e.toString());
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
                  icon: Icon(Icons.arrow_back, semanticLabel: l10n.video_player_back),
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
                                  Icon(Icons.error,
                                      color: Colors.red,
                                      size: 48,
                                      semanticLabel: l10n.video_player_error_icon),
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
                              ? Center(
                                  child: CircularProgressIndicator(
                                    semanticsLabel: l10n.video_player_loading,
                                  ),
                                )
                              : controller.value != null
                                  ? VideoPlayer(controller.value!)
                                  : Center(
                                      child: Text(l10n.video_player_no_video),
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
                              Text(
                                l10n.video_player_need_subscription,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: showSubscriptionPrompt,
                                child: Text(l10n.video_player_view_subscription),
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
                                child:
                                    Text(l10n.video_player_related_videos_error(error.toString())),
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
