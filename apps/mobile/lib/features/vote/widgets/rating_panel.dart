import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/vote/provider/vote_provider.dart';
import 'package:mobile/features/vote/widgets/like_dislike_buttons.dart';
import 'package:mobile/features/vote/widgets/star_rating.dart';

/// 비디오 평점 패널 위젯
class RatingPanel extends ConsumerWidget {
  /// 생성자
  const RatingPanel({
    super.key,
    required this.videoId,
    this.showDetailedRating = true,
  });

  /// 비디오 ID
  final String videoId;

  /// 상세 평점 표시 여부
  final bool showDetailedRating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voteState = ref.watch(voteProvider(videoId));
    final voteNotifier = ref.watch(voteProvider(videoId).notifier);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '이 팬캠은 어떤가요?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (voteState.error != null)
                  Tooltip(
                    message: voteState.error,
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (showDetailedRating) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '별점',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      StarRating(
                        rating: voteState.userRating,
                        onRatingChanged: (rating) {
                          voteNotifier.rateVideo(rating ?? 0);
                        },
                        size: 32,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            '평균:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 4),
                          ReadOnlyStarRating(
                            rating: voteState.averageRating,
                            size: 16,
                            showRatingText: true,
                          ),
                        ],
                      ),
                      Text(
                        '총 ${voteState.totalVotes}명 참여',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LikeDislikeButtons(
                  isLiked: voteState.isLiked,
                  isDisliked: voteState.isDisliked,
                  likeCount: voteState.likeCount,
                  dislikeCount: voteState.dislikeCount,
                  isLoading: voteState.isLoading,
                  onLikePressed: () => voteNotifier.toggleLike(true),
                  onDislikePressed: () => voteNotifier.toggleLike(false),
                  iconSize: 28,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
