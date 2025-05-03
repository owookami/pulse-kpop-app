import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// YouTube 동영상 플레이어 위젯
class YouTubePlayerWidget extends StatefulWidget {
  /// YouTube URL을 받아서 플레이어를 생성하는 생성자
  const YouTubePlayerWidget({
    super.key,
    required this.youtubeUrl,
    this.onFullScreenToggle,
  });

  /// YouTube 동영상 URL
  final String youtubeUrl;

  /// 전체화면 토글 콜백
  final ValueChanged<bool>? onFullScreenToggle;

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> {
  bool _isFullScreen = false;
  bool _isError = false;
  String _errorMessage = '';
  bool _isLoading = true;
  String _videoId = '';
  late YoutubePlayerController _controller;
  bool _playerInitialized = false;

  @override
  void initState() {
    super.initState();
    debugPrint('YouTubePlayerWidget initState 실행');

    // 웹에서 실행 중인지 확인
    if (kIsWeb) {
      debugPrint('웹 플랫폼에서 실행 중입니다. 웹 플레이어로 대체합니다.');
      _initializeWebPlayer();
      return;
    }

    _initializePlayer();
  }

  void _initializeWebPlayer() {
    // 웹 환경에서는 제한된 기능 제공
    setState(() {
      _isLoading = false;
      _videoId = _extractVideoId(widget.youtubeUrl);
      if (_videoId.isEmpty) {
        _isError = true;
        _errorMessage = '유효한 YouTube ID를 추출할 수 없습니다.\n${widget.youtubeUrl}';
      }
    });
  }

  void _initializePlayer() {
    try {
      debugPrint('YouTube URL 처리 시작: ${widget.youtubeUrl}');
      _videoId = _extractVideoId(widget.youtubeUrl);

      if (_videoId.isEmpty) {
        setState(() {
          _isError = true;
          _errorMessage = '유효한 YouTube ID를 추출할 수 없습니다.\n${widget.youtubeUrl}';
          _isLoading = false;
        });
        debugPrint('YouTube ID 추출 실패: ${widget.youtubeUrl}');
        return;
      }

      debugPrint('YouTube ID 추출 성공: $_videoId, URL: ${widget.youtubeUrl}');

      // YoutubePlayerController 초기화
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
      _controller.addListener(() {
        if (_controller.value.isFullScreen != _isFullScreen) {
          _isFullScreen = _controller.value.isFullScreen;
          widget.onFullScreenToggle?.call(_isFullScreen);
        }
      });

      setState(() {
        _isLoading = false;
        _playerInitialized = true;
      });

      debugPrint('YouTube 플레이어 컨트롤러 초기화 성공');
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = '유튜브 플레이어 초기화 실패: $e';
        _isLoading = false;
      });
      debugPrint('YouTube 플레이어 컨트롤러 초기화 실패: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('YouTubePlayerWidget dispose 호출됨');

    // 전체화면 모드인 경우 원래 상태로 복원
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    // 컨트롤러 리소스 해제
    if (_playerInitialized) {
      _controller.dispose();
    }

    super.dispose();
  }

  /// YouTube URL에서 Video ID 추출
  String _extractVideoId(String url) {
    // URL이 빈 문자열인 경우
    if (url.isEmpty) {
      debugPrint('URL이 비어있습니다.');
      return '';
    }

    try {
      // YoutubePlayerController의 convertUrlToId 메서드 사용
      final id = YoutubePlayer.convertUrlToId(url);
      if (id != null) {
        return id;
      }

      // 유튜브 ID가 직접 입력된 경우(비디오 URL이 아닌 ID만 입력된 경우)
      if (_isValidYouTubeVideoId(url)) {
        debugPrint('입력된 텍스트가 유효한 유튜브 ID로 판단됨: $url');
        return url;
      }

      debugPrint('지원되지 않는 YouTube URL 형식: $url');
      return '';
    } catch (e) {
      debugPrint('YouTube ID 추출 중 오류: $e');
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
    final youtubeAppUrl = 'youtube://$_videoId';
    final youtubeWebUrl = 'https://www.youtube.com/watch?v=$_videoId';

    try {
      // 먼저 YouTube 앱 열기 시도
      final appUri = Uri.parse(youtubeAppUrl);
      if (await canLaunchUrl(appUri)) {
        debugPrint('YouTube 앱으로 동영상 여는 중: $_videoId');
        await launchUrl(appUri);
      } else {
        // 안되면 웹 브라우저로 열기
        final webUri = Uri.parse(youtubeWebUrl);
        debugPrint('웹 브라우저로 YouTube 여는 중: $_videoId');
        await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('YouTube 열기 오류: $e');
      // 마지막 시도 - 기본 모드로 열기
      try {
        final webUri = Uri.parse(youtubeWebUrl);
        await launchUrl(webUri);
      } catch (e) {
        debugPrint('최종 YouTube 열기 시도 오류: $e');
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
      debugPrint('동영상 제목: ${video.title}, 길이: ${video.duration}');
      yt.close();
    } catch (e) {
      debugPrint('메타데이터 가져오기 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Container(
        color: Colors.black,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Video ID: $_videoId\nURL: ${widget.youtubeUrl}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isError = false;
                        _isLoading = true;
                        _playerInitialized = false;
                      });
                      _initializePlayer();
                    },
                    child: const Text('재시도'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _openYouTubeVideo,
                    child: const Text('YouTube에서 보기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '유튜브 동영상을 불러오는 중...',
              style: TextStyle(color: Colors.white),
            ),
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
                  const Icon(
                    Icons.play_circle_outline,
                    size: 72,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '웹 환경에서는 외부 YouTube 플레이어로 재생해야 합니다.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _openYouTubeVideo,
                    child: const Text('YouTube에서 보기'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 네이티브 환경에서 유튜브 플레이어 표시
    if (_playerInitialized) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
          progressColors: const ProgressBarColors(
            playedColor: Colors.red,
            handleColor: Colors.redAccent,
          ),
          onReady: () {
            debugPrint('YouTube 플레이어 준비 완료');
            _fetchVideoMetadata();
          },
          onEnded: (data) {
            debugPrint('YouTube 동영상 재생 종료');
          },
          topActions: [
            IconButton(
              icon: const Icon(
                Icons.open_in_browser,
                color: Colors.white,
              ),
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
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              '플레이어 초기화 실패',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openYouTubeVideo,
              child: const Text('YouTube에서 보기'),
            ),
          ],
        ),
      ),
    );
  }
}
