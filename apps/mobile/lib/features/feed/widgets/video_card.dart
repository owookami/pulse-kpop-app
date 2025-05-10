import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';

/// 비디오 카드 위젯
class VideoCard extends StatelessWidget {
  /// 비디오 카드 생성자
  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.isAdmin = false,
    this.onDelete,
    this.lightweightMode = false, // 경량화 모드 추가
  });

  /// 비디오 데이터
  final Video video;

  /// 탭 콜백
  final VoidCallback onTap;

  /// 관리자 여부
  final bool isAdmin;

  /// 삭제 콜백
  final VoidCallback? onDelete;

  /// 경량화 모드 여부 (화면 밖 항목을 최적화하기 위한 플래그)
  final bool lightweightMode;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 썸네일 이미지
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildThumbnail(video.thumbnailUrl),
                  ),
                ),

                // 메타데이터 (제목, 조회수 등)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildMetadata(context),
                ),
              ],
            ),

            // 관리자용 삭제 버튼
            if (isAdmin && onDelete != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

            // 뱃지 (인기, 신규 등)
            Positioned(
              top: 8,
              left: 8,
              child: _buildBadge(context),
            ),
          ],
        ),
      ),
    );
  }

  // 썸네일 위젯 - 최적화 버전
  Widget _buildThumbnail(String? url) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: lightweightMode
                ? _buildLightweightImage(url ?? '')
                : Image.network(
                    url ?? '',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // 재생 시간 표시
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              // duration이 null이거나 int로 변환할 수 없는 경우 0으로 처리
              _formatDuration(video.duration is int ? video.duration as int : 0),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 경량화된 이미지 로딩 (화면 밖 항목용)
  Widget _buildLightweightImage(String url) {
    // 화면 밖 항목은 저해상도로 로드하거나 지연 로드
    return Image.network(
      url,
      fit: BoxFit.cover,
      // 메모리 효율을 위한 설정
      cacheWidth: 300, // 절반 해상도
      cacheHeight: 170,
      gaplessPlayback: true,
      // 로딩 우선순위 낮춤
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.photo, color: Colors.grey),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      },
    );
  }

  // 메타데이터 위젯 (일반 모드)
  Widget _buildMetadata(BuildContext context) {
    final theme = Theme.of(context);
    final views = _formatNumber(video.viewCount);
    final likes = _formatNumber(video.likeCount ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          video.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        // 작성자 및 조회수
        Row(
          children: [
            // 아티스트 이름 (실제 API에서는 아티스트 정보 사용 필요)
            Text(
              '아티스트 ${video.artistId.split('_').last}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),

            const SizedBox(width: 8),

            // 구분자
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: theme.hintColor,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 8),

            // 조회수
            Text(
              '조회수 $views회',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),

            const SizedBox(width: 8),

            // 좋아요 수
            Row(
              children: [
                Icon(
                  Icons.thumb_up_outlined,
                  size: 14,
                  color: theme.hintColor,
                ),
                const SizedBox(width: 2),
                Text(
                  likes,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 4),

        // 생성일 표시
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 12,
              color: theme.hintColor,
            ),
            const SizedBox(width: 4),
            Text(
              _formatCreatedDate(video.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 경량화된 메타데이터 위젯 (간소화 버전)
  Widget _buildLightweightMetadata(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목만 표시 (간소화)
        Text(
          video.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        // 최소한의 정보만 표시
        Row(
          children: [
            Text(
              '조회수 ${_formatNumber(video.viewCount)}회',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.calendar_today,
              size: 12,
              color: theme.hintColor,
            ),
            const SizedBox(width: 4),
            Text(
              _formatCreatedDate(video.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 뱃지 위젯
  Widget _buildBadge(BuildContext context) {
    // 인기 콘텐츠 뱃지 (조회수 기준) - 삭제 요청에 따라 비활성화
    /*
    if (video.viewCount > 1000) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '인기',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    */

    // 신규 콘텐츠 뱃지 (1주일 이내)
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    if (video.createdAt.isAfter(oneWeekAgo)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '신규',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // 기본적으로는 빈 컨테이너 반환
    return const SizedBox();
  }

  // 유틸리티 메서드 - 숫자 포맷팅
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  // 생성일 포맷팅
  String _formatCreatedDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // 날짜 형식으로 포맷팅 - yyyy.MM.dd 형식
    return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
  }

  // 유틸리티 메서드 - 동영상 길이 포맷팅
  String _formatDuration(int seconds) {
    if (seconds <= 0) return '00:00';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
