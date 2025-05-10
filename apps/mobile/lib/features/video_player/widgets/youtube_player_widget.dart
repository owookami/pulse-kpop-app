import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// YouTube 동영상 플레이어 위젯
class YouTubePlayerWidget extends StatefulWidget {
  /// YouTube URL을 받아서 플레이어를 생성하는 생성자
  const YouTubePlayerWidget(
      {super.key, required this.youtubeUrl, this.platformId, this.onFullScreenToggle});

  /// YouTube 동영상 URL
  final String youtubeUrl;

  /// 플랫폼 ID (YouTube 비디오 ID)
  final String? platformId;

  /// 전체화면 토글 콜백
  final ValueChanged<bool>? onFullScreenToggle;

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> with WidgetsBindingObserver {
  bool _isFullScreen = false;
  bool _isError = false;
  String _errorMessage = '';
  bool _isLoading = true;
  String _videoId = '';
  YoutubePlayerController? _controller;
  bool _playerInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    developer.log('YouTubePlayerWidget initState 실행', name: 'YouTubePlayer');
    _isDisposed = false;

    // 앱 생명주기 이벤트 리스너 등록
    WidgetsBinding.instance.addObserver(this);

    // 초기화 과정을 비동기로 안전하게 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      _initializePlayerSafely();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱의 생명주기 상태가 변경될 때 호출
    if (_isDisposed) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // 앱이 백그라운드로 갔을 때 비디오 일시정지
        if (_controller != null && _playerInitialized) {
          developer.log('앱 백그라운드 진입: YouTube 일시정지', name: 'YouTubePlayer');
          _controller?.pause();
        }
        break;
      case AppLifecycleState.detached:
        // 앱이 종료될 때 리소스 해제
        _cleanupResources();
        break;
      default:
        break;
    }
  }

  void _cleanupResources() {
    if (_isDisposed) return;

    try {
      if (_playerInitialized && _controller != null) {
        developer.log('유튜브 플레이어 리소스 정리 시작', name: 'YouTubePlayer');
        _controller?.pause();
        _controller?.removeListener(() {});
        _controller?.dispose();
        _controller = null;
        _playerInitialized = false;
        developer.log('유튜브 플레이어 리소스 정리 완료', name: 'YouTubePlayer');
      }
    } catch (e) {
      developer.log('유튜브 리소스 정리 오류: $e', name: 'YouTubePlayer');
    }
  }

  // 안전하게 플레이어 초기화
  Future<void> _initializePlayerSafely() async {
    try {
      if (!mounted || _isDisposed) return;

      // 웹에서 실행 중인지 확인
      if (kIsWeb) {
        developer.log('웹 플랫폼에서 실행 중입니다. 웹 플레이어로 대체합니다.', name: 'YouTubePlayer');
        _initializeWebPlayer();
        return;
      }

      // 네이티브 플랫폼 초기화
      await _initializePlayer();
    } catch (e) {
      developer.log('플레이어 초기화 중 예상치 못한 오류: $e', name: 'YouTubePlayer');
      if (mounted && !_isDisposed) {
        setState(() {
          _isError = true;
          _errorMessage = '플레이어 초기화 오류: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _initializeWebPlayer() {
    // 웹 환경에서는 제한된 기능 제공
    if (!mounted || _isDisposed) return;

    setState(() {
      _isLoading = false;
      _videoId = _getVideoId();
      if (_videoId.isEmpty) {
        _isError = true;
        _errorMessage = '유효한 YouTube ID를 추출할 수 없습니다.\n${widget.youtubeUrl}';
      }
    });
  }

  String _getVideoId() {
    try {
      // 1. platformId가 제공된 경우 먼저 사용
      if (widget.platformId != null && widget.platformId!.isNotEmpty) {
        developer.log('platformId 검사 중: ${widget.platformId}', name: 'YouTubePlayer');

        // platformId가 직접 ID인 경우
        if (_isValidYouTubeVideoId(widget.platformId!)) {
          developer.log('유효한 플랫폼 ID 사용: ${widget.platformId}', name: 'YouTubePlayer');
          return widget.platformId!;
        }

        // platformId에서 ID 추출 시도 (URL이나 다른 형식인 경우)
        final extractedFromPlatformId = _extractVideoId(widget.platformId!);
        if (extractedFromPlatformId.isNotEmpty) {
          developer.log('platformId에서 추출한 ID: $extractedFromPlatformId', name: 'YouTubePlayer');
          return extractedFromPlatformId;
        }
      }

      // 2. URL에서 ID 추출
      final extractedId = _extractVideoId(widget.youtubeUrl);
      if (extractedId.isNotEmpty) {
        developer.log('URL에서 추출한 ID: $extractedId', name: 'YouTubePlayer');
        return extractedId;
      }

      // 3. URL 자체가 ID인지 확인
      if (_isValidYouTubeVideoId(widget.youtubeUrl)) {
        developer.log('입력된 URL이 유효한 YouTube ID: ${widget.youtubeUrl}', name: 'YouTubePlayer');
        return widget.youtubeUrl;
      }

      // 4. 모든 방법 실패 시 빈 문자열 반환
      developer.log(
          '유효한 YouTube ID를 찾을 수 없음: URL=${widget.youtubeUrl}, platformId=${widget.platformId}',
          name: 'YouTubePlayer');
      return '';
    } catch (e) {
      developer.log('ID 추출 중 오류 발생: $e', name: 'YouTubePlayer');
      return '';
    }
  }

  Future<void> _initializePlayer() async {
    try {
      if (!mounted || _isDisposed) return;

      developer.log('YouTube URL 처리 시작: ${widget.youtubeUrl}', name: 'YouTubePlayer');
      _videoId = _getVideoId();

      if (_videoId.isEmpty) {
        if (!mounted || _isDisposed) return;
        setState(() {
          _isError = true;
          _errorMessage = '유효한 YouTube ID를 추출할 수 없습니다.\n${widget.youtubeUrl}';
          _isLoading = false;
        });
        developer.log('YouTube ID 추출 실패: ${widget.youtubeUrl}, platformId: ${widget.platformId}',
            name: 'YouTubePlayer');
        return;
      }

      developer.log('YouTube ID 추출 성공: $_videoId, URL: ${widget.youtubeUrl}',
          name: 'YouTubePlayer');

      // 동기화 문제 방지를 위한 딜레이 추가
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted || _isDisposed) return;

      // YoutubePlayerController 초기화 시도
      try {
        _controller = YoutubePlayerController(
          initialVideoId: _videoId,
          flags: const YoutubePlayerFlags(
            mute: false,
            autoPlay: true,
            disableDragSeek: false,
            loop: false,
            isLive: false,
            forceHD: false,
            enableCaption: true,
          ),
        );

        // 전체화면 토글 리스너 등록
        _controller?.addListener(() {
          if (_isDisposed) return;
          if (_controller?.value.isFullScreen != _isFullScreen) {
            _isFullScreen = _controller?.value.isFullScreen ?? false;
            widget.onFullScreenToggle?.call(_isFullScreen);
          }
        });

        if (mounted && !_isDisposed) {
          setState(() {
            _isLoading = false;
            _playerInitialized = true;
          });
        }

        developer.log('YouTube 플레이어 컨트롤러 초기화 성공', name: 'YouTubePlayer');
      } catch (e) {
        developer.log('YouTube 플레이어 컨트롤러 초기화 실패: $e', name: 'YouTubePlayer');
        if (mounted && !_isDisposed) {
          setState(() {
            _isError = true;
            _errorMessage = '유튜브 플레이어 초기화 실패: $e';
            _isLoading = false;
            _playerInitialized = false;
          });
        }
      }
    } catch (e) {
      developer.log('_initializePlayer 메서드 오류: $e', name: 'YouTubePlayer');
      if (mounted && !_isDisposed) {
        setState(() {
          _isError = true;
          _errorMessage = '유튜브 플레이어 초기화 실패: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    developer.log('YouTubePlayerWidget dispose 호출됨', name: 'YouTubePlayer');
    _isDisposed = true;

    // WidgetsBinding 옵저버 해제
    WidgetsBinding.instance.removeObserver(this);

    // 전체화면 모드인 경우 원래 상태로 복원
    if (_isFullScreen) {
      try {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        _isFullScreen = false;
      } catch (e) {
        developer.log('전체화면 모드 해제 오류: $e', name: 'YouTubePlayer');
      }
    }

    // 컨트롤러 리소스 해제
    _cleanupResources();

    super.dispose();
  }

  /// YouTube URL에서 Video ID 추출
  String _extractVideoId(String url) {
    // URL이 빈 문자열인 경우
    if (url.isEmpty) {
      developer.log('URL이 비어있습니다.', name: 'YouTubePlayer');
      return '';
    }

    try {
      // 1. YoutubePlayer.convertUrlToId 메서드로 추출 시도 (가장 안정적인 방법)
      final id = YoutubePlayer.convertUrlToId(url);
      if (id != null && _isValidYouTubeVideoId(id)) {
        developer.log('YoutubePlayer.convertUrlToId로 추출한 ID: $id', name: 'YouTubePlayer');
        return id;
      }

      // 2. 유튜브 표준 URL 패턴 확인
      const String pattern =
          r'^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))([^#&?]*)(?:.*)$';
      RegExp regExp = RegExp(pattern);
      var match = regExp.firstMatch(url);

      if (match != null && match.groupCount >= 1) {
        String id = match.group(1)!;
        if (_isValidYouTubeVideoId(id)) {
          developer.log('정규식으로 추출한 YouTube ID: $id', name: 'YouTubePlayer');
          return id;
        }
      }

      // 3. URL에서 직접 ID 추출 - 단순 패턴 확인
      if (url.contains('youtu.be/')) {
        final parts = url.split('youtu.be/');
        if (parts.length > 1) {
          final id = parts[1].split('?').first.split('&').first;
          if (_isValidYouTubeVideoId(id)) {
            developer.log('youtu.be/ 패턴에서 추출한 ID: $id', name: 'YouTubePlayer');
            return id;
          }
        }
      }

      if (url.contains('youtube.com/watch')) {
        final uri = Uri.parse(url);
        final videoId = uri.queryParameters['v'];
        if (videoId != null && _isValidYouTubeVideoId(videoId)) {
          developer.log('URI 쿼리 파라미터에서 추출한 ID: $videoId', name: 'YouTubePlayer');
          return videoId;
        }
      }

      // 모든 방법 실패시 빈 문자열 반환
      developer.log('지원되지 않는 YouTube URL 형식: $url', name: 'YouTubePlayer');
      return '';
    } catch (e) {
      developer.log('YouTube ID 추출 중 오류: $e', name: 'YouTubePlayer');
      return '';
    }
  }

  /// 유효한 YouTube 비디오 ID인지 확인
  bool _isValidYouTubeVideoId(String id) {
    // YouTube 비디오 ID는 일반적으로 11자리 영숫자와 특수문자(-_)로 구성됨
    final RegExp regex = RegExp(r'^[A-Za-z0-9_-]{11}$');
    return regex.hasMatch(id);
  }

  /// YouTube 앱 또는 브라우저에서 열기
  Future<void> _openYouTubeVideo() async {
    if (_videoId.isEmpty) {
      developer.log('YouTube ID가 비어있어 외부에서 열 수 없습니다.', name: 'YouTubePlayer');
      return;
    }

    final youtubeAppUrl = 'youtube://watch?v=$_videoId';
    final youtubeWebUrl = 'https://www.youtube.com/watch?v=$_videoId';

    try {
      // 먼저 YouTube 앱 열기 시도
      final appUri = Uri.parse(youtubeAppUrl);
      if (await canLaunchUrl(appUri)) {
        developer.log('YouTube 앱으로 동영상 여는 중: $_videoId', name: 'YouTubePlayer');
        await launchUrl(appUri);
      } else {
        // 안되면 웹 브라우저로 열기
        final webUri = Uri.parse(youtubeWebUrl);
        developer.log('웹 브라우저로 YouTube 여는 중: $_videoId', name: 'YouTubePlayer');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      developer.log('YouTube 열기 오류: $e', name: 'YouTubePlayer');
      // 마지막 시도 - 기본 모드로 열기
      try {
        final webUri = Uri.parse(youtubeWebUrl);
        await launchUrl(webUri);
      } catch (e) {
        developer.log('최종 YouTube 열기 시도 오류: $e', name: 'YouTubePlayer');
        if (mounted) {
          setState(() {
            _isError = true;
            _errorMessage = 'YouTube 동영상을 열 수 없습니다: $e';
          });
        }
      }
    }
  }

  /// 동영상 메타데이터 가져오기
  Future<void> _fetchVideoMetadata() async {
    try {
      final yt = YoutubeExplode();
      final video = await yt.videos.get(_videoId);
      developer.log('동영상 제목: ${video.title}, 길이: ${video.duration}', name: 'YouTubePlayer');
      yt.close();
    } catch (e) {
      developer.log('메타데이터 가져오기 실패: $e', name: 'YouTubePlayer');
    }
  }

  /// 에러 상태 표시
  Widget _buildErrorWidget(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error,
              color: Colors.red, size: 48, semanticLabel: l10n.video_player_error_icon),
          const SizedBox(height: 8),
          Text(
            l10n.video_player_youtube_error(error),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          // 외부 YouTube 앱으로 열기 버튼
          if (widget.platformId != null)
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.video_player_open_youtube),
              onPressed: () async {
                final url = 'https://www.youtube.com/watch?v=${widget.platformId}';
                try {
                  await launchUrl(Uri.parse(url));
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.app_error_launching_url}: $e')),
                    );
                  }
                }
              },
            ),
          const SizedBox(height: 8),
          // 재시도 버튼
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(l10n.video_player_retry),
            onPressed: () {
              _initializePlayerSafely();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isError) {
      return _buildErrorWidget(context, _errorMessage);
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.video_player_youtube_loading, style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    // 웹 환경에서는 임베드 플레이어 링크 표시
    if (kIsWeb) {
      return Stack(
        children: [
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_outline, size: 72, color: Colors.white70),
                  const SizedBox(height: 16),
                  Text(
                    l10n.video_player_web_player_message,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _openYouTubeVideo, child: Text(l10n.video_player_open_youtube)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 네이티브 환경에서 유튜브 플레이어 표시
    if (_playerInitialized && _controller != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
          progressColors: const ProgressBarColors(
            playedColor: Colors.red,
            handleColor: Colors.redAccent,
          ),
          onReady: () {
            developer.log('YouTube 플레이어 준비 완료', name: 'YouTubePlayer');
            _fetchVideoMetadata();
          },
          onEnded: (data) {
            developer.log('YouTube 동영상 재생 종료', name: 'YouTubePlayer');
          },
          topActions: [
            IconButton(
              icon: const Icon(Icons.open_in_browser, color: Colors.white),
              onPressed: _openYouTubeVideo,
            ),
          ],
        ),
        builder: (context, player) {
          return player;
        },
      );
    }

    // 초기화 실패 시 대체 UI
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.video_player_player_init_failed,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _openYouTubeVideo, child: Text(l10n.video_player_open_youtube)),
          ],
        ),
      ),
    );
  }
}
