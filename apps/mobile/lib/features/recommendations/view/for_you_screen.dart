import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/bookmarks/provider/bookmark_provider.dart';
import 'package:mobile/features/recommendations/model/recommendation_state.dart';
import 'package:mobile/features/recommendations/provider/recommendation_provider.dart';
import 'package:mobile/routes/routes.dart';

/// 'For You' 화면
class ForYouScreen extends ConsumerWidget {
  /// 생성자
  const ForYouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationState = ref.watch(recommendationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('For You'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(recommendationProvider.notifier).refreshRecommendations(),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: recommendationState.when(
        data: (state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildContent(context, ref, state);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '추천을 불러오는 중 오류가 발생했습니다.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (error is ApiError)
                Text(
                  error.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(recommendationProvider.notifier).refreshRecommendations(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 추천 콘텐츠 구현
  Widget _buildContent(BuildContext context, WidgetRef ref, RecommendationState state) {
    // 추천 비디오가 없는 경우
    if (state.forYouVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '아직 추천할 비디오가 없습니다.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '관심 있는 비디오를 북마크하면\n맞춤형 추천을 받을 수 있습니다.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.home),
              label: const Text('홈으로 이동'),
            ),
          ],
        ),
      );
    }

    // 추천 콘텐츠 표시
    return ListView(
      children: [
        // 'For You' 섹션
        _buildVideoSection(
          context,
          ref,
          '당신을 위한 추천',
          state.forYouVideos,
          'For You 알고리즘에 맞춤 제작된 비디오입니다.',
        ),

        // 인기 비디오 섹션
        if (state.trendingVideos.isNotEmpty)
          _buildVideoSection(
            context,
            ref,
            '인기 비디오',
            state.trendingVideos,
            '인기 있는 비디오를 확인해보세요.',
          ),

        // 시청 기록 기반 추천 섹션
        if (state.basedOnHistoryVideos.isNotEmpty)
          _buildVideoSection(
            context,
            ref,
            '시청 기록 기반 추천',
            state.basedOnHistoryVideos,
            '최근에 시청한 비디오와 비슷한 콘텐츠입니다.',
          ),

        // 비슷한 아티스트 비디오 섹션
        if (state.similarArtistsVideos.isNotEmpty)
          _buildVideoSection(
            context,
            ref,
            '비슷한 아티스트 콘텐츠',
            state.similarArtistsVideos,
            '좋아하는 아티스트의 다른 콘텐츠를 확인해보세요.',
          ),
      ],
    );
  }

  /// 비디오 섹션 구현
  Widget _buildVideoSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<Video> videos,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return _VideoCard(video: video, ref: ref);
            },
          ),
        ),
      ],
    );
  }
}

/// 비디오 카드 위젯
class _VideoCard extends StatelessWidget {
  /// 생성자
  const _VideoCard({
    required this.video,
    required this.ref,
  });

  /// 비디오 정보
  final Video video;

  /// 위젯 참조
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          AppRoutes.videoPlayer,
          extra: {
            'video': video,
          },
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  video.thumbnailUrl ?? 'https://via.placeholder.com/300x169?text=No+Thumbnail',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),

            // 북마크 상태와 비디오 정보
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 비디오 제목
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),

                    const SizedBox(height: 4),

                    // 비디오 정보 (아티스트, 조회수)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '알 수 없는 아티스트',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ),

                        // 북마크 버튼
                        _BookmarkButton(video: video),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 북마크 버튼 위젯
class _BookmarkButton extends ConsumerWidget {
  /// 생성자
  const _BookmarkButton({
    required this.video,
  });

  /// 비디오 정보
  final Video video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkState = ref.watch(bookmarkProvider);

    return bookmarkState.when(
      data: (state) {
        final isBookmarked = state.bookmarkedVideos.any((v) => v.id == video.id);

        return IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            size: 18,
          ),
          color: isBookmarked ? Theme.of(context).primaryColor : Colors.grey,
          onPressed: () {
            // 북마크 토글
            if (isBookmarked) {
              ref.read(bookmarkProvider.notifier).removeBookmark(video.id);
            } else {
              ref.read(bookmarkProvider.notifier).addBookmark(video.id);
            }
          },
          tooltip: isBookmarked ? '북마크 해제' : '북마크 추가',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        );
      },
      loading: () => const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(Icons.bookmark_border, size: 18, color: Colors.grey),
    );
  }
}
