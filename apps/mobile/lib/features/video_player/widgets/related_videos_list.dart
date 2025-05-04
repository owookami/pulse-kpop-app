import 'package:api_client/api_client.dart';
import "package:flutter/material.dart";
import 'package:intl/intl.dart';

/// 관련 비디오 목록 위젯
class RelatedVideosList extends StatelessWidget {
  /// 생성자
  const RelatedVideosList({
    super.key,
    required this.videos,
    required this.onVideoTap,
  });

  /// 관련 비디오 목록
  final List<Video> videos;

  /// 비디오 탭 이벤트 콜백
  final Function(Video video) onVideoTap;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                '관련 영상',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '현재 관련 영상이 없습니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '관련 영상',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        // ListView.builder 대신 모든 항목을 직접 생성
        ...videos.map((video) => _RelatedVideoItem(
              video: video,
              onTap: () => onVideoTap(video),
            )),
      ],
    );
  }
}

/// 관련 비디오 아이템 위젯
class _RelatedVideoItem extends StatefulWidget {
  /// 생성자
  const _RelatedVideoItem({
    required this.video,
    required this.onTap,
  });

  /// 비디오 정보
  final Video video;

  /// 탭 이벤트 콜백
  final VoidCallback onTap;

  @override
  State<_RelatedVideoItem> createState() => _RelatedVideoItemState();
}

class _RelatedVideoItemState extends State<_RelatedVideoItem> {
  bool _isProcessingTap = false;
  DateTime? _lastTapTime;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _handleTap() {
    // 이미 처리 중이면 무시
    if (_isProcessingTap) {
      debugPrint('이미 탭 처리 중입니다, 무시합니다');
      return;
    }

    // 마지막 탭 시간으로부터 1.5초 이내의 탭은 무시 (디바운싱)
    final now = DateTime.now();
    if (_lastTapTime != null) {
      final difference = now.difference(_lastTapTime!);
      if (difference.inMilliseconds < 1500) {
        debugPrint('너무 빠른 탭 시도, 무시합니다: ${difference.inMilliseconds}ms');
        return;
      }
    }

    _lastTapTime = now;

    // 상태 업데이트하여 즉시 UI에 처리중임을 표시
    setState(() {
      _isProcessingTap = true;
    });

    debugPrint('관련 비디오 탭 처리 시작: ${widget.video.id}');

    // 콜백 호출
    widget.onTap();

    // 중복 탭 방지를 위해 잠시 후 상태 복원
    // (화면 전환이 제대로 이루어지도록 충분한 시간 부여)
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!_isDisposed && mounted) {
        setState(() {
          _isProcessingTap = false;
        });
        debugPrint('탭 상태 복원 완료');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _handleTap,
      child: Opacity(
        opacity: _isProcessingTap ? 0.5 : 1.0, // 탭 처리 중이면 더 명확하게 투명하게
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 썸네일
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 120,
                  height: 68,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.video.thumbnailUrl != null &&
                          widget.video.thumbnailUrl!.isNotEmpty)
                        Image.network(
                          widget.video.thumbnailUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.videocam,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Positioned(
                        right: 5,
                        bottom: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '3:45', // 임시 하드코딩 값으로 대체
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 비디오 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 비디오 제목
                    Text(
                      widget.video.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // 이벤트 정보 (있는 경우)
                    if (widget.video.eventName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          widget.video.eventName!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // 조회수 및 날짜 정보
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(widget.video.viewCount),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        if (widget.video.recordedDate != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('yyyy.MM.dd').format(widget.video.recordedDate!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
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
  }

  /// 시간 포맷
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// 숫자 포맷팅 (예: 1,200, 5.2K, 1.3M)
  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}
