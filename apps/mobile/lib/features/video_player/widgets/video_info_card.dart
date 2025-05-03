import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/bookmark/provider/bookmark_provider.dart';
import 'package:mobile/features/vote/provider/vote_provider.dart';

/// 비디오 정보 카드 위젯
class VideoInfoCard extends ConsumerWidget {
  /// 생성자
  const VideoInfoCard({
    super.key,
    required this.video,
  });

  /// 표시할 비디오 정보
  final Video video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 투표 상태 조회
    final voteState = ref.watch(voteProvider(video.id));

    // 북마크 상태 조회
    final bookmarkState = ref.watch(bookmarkProvider(video.id));

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 비디오 정보 (제목 또는 설명)
            // description이 없는 경우 제목을 표시, 있는 경우 설명을 표시
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                (video.description != null && video.description!.isNotEmpty)
                    ? video.description!
                    : video.title, // 설명이 없으면 제목 표시
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 6, // 설명이 충분히 보이도록 라인 수 설정
              ),
            ),

            // 이벤트 정보 및 날짜
            if (video.eventName != null || video.recordedDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    if (video.eventName != null)
                      Chip(
                        label: Text(video.eventName!),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      ),
                    if (video.eventName != null && video.recordedDate != null)
                      const SizedBox(width: 8),
                    if (video.recordedDate != null)
                      Text(
                        DateFormat('yyyy.MM.dd').format(video.recordedDate!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // 조회수, 좋아요 정보
            Row(
              children: [
                // 조회수
                Row(
                  children: [
                    const Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(video.viewCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // 좋아요 수 (voteState에서 가져온 최신 데이터 사용)
                Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(voteState.likeCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 액션 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 좋아요 버튼 주석 처리 (중복 기능)
                /*
                _buildActionButton(
                  context,
                  icon: voteState.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '좋아요',
                  color: voteState.isLiked ? Colors.red : null,
                  isLoading: voteState.isLoading,
                  onTap: () {
                    ref.read(voteProvider(video.id).notifier).toggleLike(true);
                  },
                ),
                */
                _buildActionButton(
                  context,
                  icon: bookmarkState.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  label: '북마크',
                  color: bookmarkState.isBookmarked ? Theme.of(context).colorScheme.primary : null,
                  isLoading: bookmarkState.isLoading,
                  onTap: () {
                    // 북마크 토글 실행
                    ref.read(bookmarkProvider(video.id).notifier).toggleBookmark();
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.share,
                  label: '공유',
                  onTap: () {
                    // TODO: 공유 기능 구현
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('공유 기능이 구현될 예정입니다.')),
                    );
                  },
                ),
              ],
            ),

            // 에러 메시지가 있으면 표시 (좋아요 또는 북마크 에러)
            if (voteState.error != null || bookmarkState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  bookmarkState.error ?? voteState.error ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 액션 버튼 위젯 생성
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap, // 로딩 중에는 비활성화
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
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
