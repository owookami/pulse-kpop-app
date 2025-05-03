import 'package:api_client/api_client.dart';
import "package:flutter/material.dart";

/// 비디오 카드 위젯
class VideoCard extends StatelessWidget {
  /// 비디오 카드 생성자
  const VideoCard({
    required this.video,
    super.key,
    this.onTap,
    this.showBorder = true,
  });

  /// 비디오 데이터
  final Video video;

  /// 탭 이벤트 콜백
  final VoidCallback? onTap;

  /// 경계선 표시 여부
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ??
          () {
            // TODO: 비디오 상세 페이지로 이동
          },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: showBorder ? 16 : 0,
          vertical: showBorder ? 8 : 0,
        ),
        decoration: showBorder
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일
            _buildThumbnail(context),

            // 비디오 정보
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    video.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // 이벤트 정보
                  if (video.eventName != null)
                    Text(
                      video.eventName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  // 조회수 및 업로드 날짜
                  Row(
                    children: [
                      _buildStatItem(
                        icon: Icons.visibility_outlined,
                        label: _formatViewCount(video.viewCount),
                      ),
                      const SizedBox(width: 12),
                      _buildStatItem(
                        icon: Icons.favorite_outline,
                        label: _formatLikeCount(video.likeCount),
                      ),
                      const SizedBox(width: 12),
                      _buildStatItem(
                        icon: Icons.access_time,
                        label: _formatTimestamp(video.createdAt),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 썸네일 빌드
  Widget _buildThumbnail(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty)
              Image.network(
                video.thumbnailUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.black26,
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
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('썸네일 로드 오류: ${video.thumbnailUrl}, 에러: $error');
                  // 에러 발생시 YouTube ID로 기본 썸네일 시도
                  if (video.platform == 'YouTube' && video.platformId.isNotEmpty) {
                    return Image.network(
                      'https://i.ytimg.com/vi/${video.platformId}/hqdefault.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('기본 YouTube 썸네일도 로드 실패: ${video.platformId}, 에러: $error');
                        return Container(
                          color: Colors.black26,
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white54,
                          ),
                        );
                      },
                    );
                  }
                  return Container(
                    color: Colors.black26,
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.white54,
                    ),
                  );
                },
              )
            else
              Container(
                color: Colors.black26,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 4),
                    if (video.thumbnailUrl == null)
                      const Text('썸네일 없음 (null)',
                          style: TextStyle(color: Colors.white54, fontSize: 10))
                    else if (video.thumbnailUrl!.isEmpty)
                      const Text('썸네일 없음 (empty)',
                          style: TextStyle(color: Colors.white54, fontSize: 10)),
                    const SizedBox(height: 4),
                    Text('ID: ${video.id.substring(0, 8)}...',
                        style: const TextStyle(color: Colors.white54, fontSize: 8)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 통계 항목 빌드 (아이콘 + 텍스트)
  Widget _buildStatItem({required IconData icon, required String label}) {
    return _StatItem(icon: icon, label: label);
  }

  /// 타임스탬프 표시 형식 지정
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  /// 조회수 표시 형식 지정
  String _formatViewCount(int viewCount) {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    } else {
      return viewCount.toString();
    }
  }

  /// 좋아요 포맷
  String _formatLikeCount(int likeCount) {
    if (likeCount >= 1000000) {
      return '${(likeCount / 1000000).toStringAsFixed(1)}M';
    } else if (likeCount >= 1000) {
      return '${(likeCount / 1000).toStringAsFixed(1)}K';
    } else {
      return likeCount.toString();
    }
  }
}

/// 통계 항목 위젯
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
