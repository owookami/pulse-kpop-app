import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/bookmark/provider/bookmark_provider.dart';
import 'package:mobile/features/vote/provider/vote_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 비디오 정보 카드 위젯
class VideoInfoCard extends ConsumerWidget {
  /// 생성자
  const VideoInfoCard({
    super.key,
    required this.video,
  });

  /// 표시할 비디오 정보
  final Video video;

  /// 비디오 공유 함수
  Future<void> _shareVideo(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      // 간단한 메시지와 YouTube URL만 포함하도록 수정
      final String shareText = l10n.video_player_share_message(video.title, video.videoUrl);
      final String subject = l10n.video_player_share_subject(video.title);

      // 공유 대화상자 표시
      await Share.share(
        shareText,
        subject: subject,
      );

      debugPrint('비디오 공유 성공: ${video.title}');
    } catch (e) {
      debugPrint('비디오 공유 중 오류 발생: $e');
      // 공유 실패 시 스낵바 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.video_player_share_error(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
                      _formatCount(video.viewCount, l10n),
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
                      _formatCount(voteState.likeCount, l10n),
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
                  label: l10n.video_player_bookmark,
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
                  label: l10n.video_player_share,
                  onTap: () => _shareVideo(context),
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

            // 동적 변수를 사용한 복합 문자열 표시 예제
            _buildDynamicExample(context, l10n, video),
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
  String _formatCount(int count, AppLocalizations l10n) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}${l10n.count_thousand_suffix}';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}${l10n.count_million_suffix}';
    }
  }

  // 동적 변수를 활용한 국제화 예제
  Widget _buildDynamicExample(BuildContext context, AppLocalizations localizations, Video video) {
    // 현재 날짜 포맷팅
    final now = DateTime.now();
    final formattedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 임의의 조회수와 좋아요 수 (실제로는 API에서 받아오겠지만 예제로 하드코딩)
    final viewCount = (1000 + (video.hashCode % 9000)).toString();
    final likeCount = (100 + (video.hashCode % 900)).toString();

    // 동적 변수를 포함한 문자열 생성
    final dynamicMessage = localizations.formatMessage(
      'dynamic_complex',
      {
        'artist': video.channelTitle ?? 'Unknown Artist',
        'title': video.title,
        'uploadDate': video.createdAt != null
            ? '${video.createdAt.year}-${video.createdAt.month.toString().padLeft(2, '0')}-${video.createdAt.day.toString().padLeft(2, '0')}'
            : formattedDate,
        'viewCount': viewCount,
        'category': video.eventName ?? 'General',
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          '동적 국제화 예제:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          dynamicMessage,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }
}
