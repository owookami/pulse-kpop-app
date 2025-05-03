import 'package:flutter/material.dart';

/// 커스텀 비디오 플레이어 컨트롤
class CustomPlayerControls extends StatelessWidget {
  /// 생성자
  const CustomPlayerControls({
    super.key,
    required this.isPlaying,
    required this.isMuted,
    required this.isFullScreen,
    required this.currentPosition,
    required this.duration,
    required this.onPlayPause,
    required this.onMuteToggle,
    required this.onFullScreenToggle,
    required this.onSeek,
    this.playbackSpeed = 1.0,
    required this.onSpeedChange,
  });

  /// 재생 중인지 여부
  final bool isPlaying;

  /// 음소거 여부
  final bool isMuted;

  /// 전체화면 모드 여부
  final bool isFullScreen;

  /// 현재 재생 위치 (초)
  final int currentPosition;

  /// 총 영상 길이 (초)
  final int duration;

  /// 재생 속도
  final double playbackSpeed;

  /// 재생/일시정지 토글 콜백
  final VoidCallback onPlayPause;

  /// 음소거 토글 콜백
  final VoidCallback onMuteToggle;

  /// 전체화면 토글 콜백
  final VoidCallback onFullScreenToggle;

  /// 시간 이동 콜백
  final void Function(int position) onSeek;

  /// 재생 속도 변경 콜백
  final void Function(double speed) onSpeedChange;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder를 사용하여 사용 가능한 공간을 확인
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          // 영역 탭 시 컨트롤 숨김처리 등을 위해 빈 함수 지정
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withOpacity(0.4),
            // 컨테이너의 크기를 제한
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight,
              maxWidth: constraints.maxWidth,
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 상단 컨트롤
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 음소거 버튼
                        IconButton(
                          icon: Icon(
                            isMuted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white,
                          ),
                          onPressed: onMuteToggle,
                        ),

                        // 재생 속도 설정 버튼
                        _buildPlaybackSpeedButton(context),
                      ],
                    ),
                  ),

                  // 중앙 빈 공간과 재생 버튼 (Expanded로 남은 공간 차지)
                  Expanded(
                    child: Center(
                      child: IconButton(
                        iconSize: 48,
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        onPressed: onPlayPause,
                      ),
                    ),
                  ),

                  // 하단 컨트롤 (진행바, 시간, 전체화면)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 진행 슬라이더
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            trackHeight: 4,
                            trackShape: const RoundedRectSliderTrackShape(),
                            activeTrackColor: Theme.of(context).colorScheme.primary,
                            inactiveTrackColor: Colors.grey[300],
                            thumbColor: Theme.of(context).colorScheme.primary,
                            overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                          child: Slider(
                            value: currentPosition.toDouble(),
                            min: 0,
                            max: duration.toDouble() > 0 ? duration.toDouble() : 1,
                            onChanged: (value) => onSeek(value.toInt()),
                          ),
                        ),

                        // 하단 시간 표시 및 전체화면 버튼
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 시간 표시
                            Text(
                              '${_formatDuration(currentPosition)} / ${_formatDuration(duration)}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),

                            // 전체화면 버튼
                            IconButton(
                              icon: Icon(
                                isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                color: Colors.white,
                              ),
                              onPressed: onFullScreenToggle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 재생 속도 설정 버튼 구성
  Widget _buildPlaybackSpeedButton(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: '재생 속도',
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${playbackSpeed}x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      color: Colors.black.withOpacity(0.8),
      onSelected: onSpeedChange,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 0.5,
          child: Text('0.5x', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 0.75,
          child: Text('0.75x', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 1.0,
          child: Text('1.0x (기본)', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 1.25,
          child: Text('1.25x', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 1.5,
          child: Text('1.5x', style: TextStyle(color: Colors.white)),
        ),
        const PopupMenuItem(
          value: 2.0,
          child: Text('2.0x', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  /// 시간을 MM:SS 형식으로 포맷
  String _formatDuration(int seconds) {
    if (seconds <= 0) return '00:00';

    final Duration duration = Duration(seconds: seconds);
    final int minutes = duration.inMinutes;
    final int remainingSeconds = duration.inSeconds - minutes * 60;

    final String minutesStr = minutes.toString().padLeft(2, '0');
    final String secondsStr = remainingSeconds.toString().padLeft(2, '0');

    return '$minutesStr:$secondsStr';
  }
}
