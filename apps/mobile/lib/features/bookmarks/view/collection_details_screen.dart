import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/bookmarks/provider/bookmark_provider.dart';

/// 북마크 컬렉션 세부 화면
class CollectionDetailsScreen extends ConsumerWidget {
  /// 생성자
  const CollectionDetailsScreen({
    super.key,
    required this.collection,
  });

  /// 컬렉션 정보
  final BookmarkCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkState = ref.watch(bookmarkProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditCollectionDialog(context, ref, collection),
            tooltip: '컬렉션 편집',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteCollectionConfirmation(context, ref, collection),
            tooltip: '컬렉션 삭제',
          ),
        ],
      ),
      body: bookmarkState.when(
        data: (state) {
          // 컬렉션 정보 가져오기
          final currentCollection = state.collections.firstWhere(
            (c) => c.id == collection.id,
            orElse: () => collection,
          );

          // 컬렉션 내 비디오 ID 목록 가져오기
          // 실제 구현에서는 BookmarkService를 통해 컬렉션의 아이템 목록을 가져오는 것이 바람직
          final collectionVideos = <Video>[];

          // 예시 데이터 - 실제 구현에서는 API를 통해 가져온 BookmarkItem 목록을 사용
          final bookmarkItems = <BookmarkItem>[];

          // 북마크된 비디오 중 이 컬렉션에 속한 비디오 찾기
          // 여기서는 임시로 모든 북마크된 비디오를 컬렉션의 일부로 표시
          for (final video in state.bookmarkedVideos) {
            // 실제로는 bookmarkItems에서 collectionId와 videoId를 확인하여 필터링해야 함
            collectionVideos.add(video);
          }

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 컬렉션에 비디오가 없는 경우
          if (collectionVideos.isEmpty) {
            return _buildEmptyState(context);
          }

          // 컬렉션 비디오 표시
          return _buildCollectionContent(context, ref, currentCollection, collectionVideos);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                '오류가 발생했습니다',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(bookmarkProvider.notifier).refreshBookmarks(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVideoDialog(context, ref),
        tooltip: '비디오 추가',
        child: const Icon(Icons.video_library),
      ),
    );
  }

  /// 비디오 추가 다이얼로그
  void _showAddVideoDialog(BuildContext context, WidgetRef ref) {
    // TODO: 컬렉션에 추가할 비디오 검색 및 선택 UI 구현
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('컬렉션에 비디오 추가'),
          content: const Text('이 기능은 아직 구현되지 않았습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  /// 빈 상태 표시 위젯
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '컬렉션이 비어 있습니다',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '아래 버튼을 눌러 비디오를 추가하세요',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  /// 컬렉션 내용 표시 위젯
  Widget _buildCollectionContent(
    BuildContext context,
    WidgetRef ref,
    BookmarkCollection collection,
    List<Video> videos,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 컬렉션 정보 카드
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (collection.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      collection.description!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        collection.isPublic ? Icons.public : Icons.lock,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        collection.isPublic ? '공개' : '비공개',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.video_library,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${collection.bookmarkCount}개 비디오',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 비디오 목록 헤더
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '비디오 (${videos.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () {
                  // TODO: 정렬 기능 구현
                },
                tooltip: '정렬',
              ),
            ],
          ),
        ),

        // 비디오 그리드 목록
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return _buildVideoCard(context, ref, video, collection);
            },
          ),
        ),
      ],
    );
  }

  // 비디오 카드 위젯
  Widget _buildVideoCard(
    BuildContext context,
    WidgetRef ref,
    Video video,
    BookmarkCollection collection,
  ) {
    return GestureDetector(
      onTap: () {
        // 비디오 플레이어 화면으로 이동
        context.push('/video/${video.id}', extra: video);
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일
            AspectRatio(
              aspectRatio: 16 / 9,
              child: video.thumbnailUrl != null
                  ? Image.network(
                      video.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.error),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.videocam),
                      ),
                    ),
            ),

            // 비디오 정보
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.artistId,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 액션 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    onPressed: () {
                      // TODO: 비디오 공유 기능 구현
                    },
                    tooltip: '공유',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () {
                      _showRemoveVideoConfirmation(context, ref, video, collection);
                    },
                    tooltip: '컬렉션에서 제거',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 비디오를 컬렉션에서 제거
  void _removeVideoFromCollection(BuildContext context, WidgetRef ref, Video video) {
    // 확인 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비디오 제거'),
        content: const Text('이 비디오를 컬렉션에서 제거하시겠습니까?\n(북마크 목록에서는 유지됩니다)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 컬렉션에서 비디오 제거 구현
              // ref.read(bookmarkProvider.notifier).removeVideoFromCollection(
              //   collectionId: collection.id,
              //   videoId: video.id,
              // );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('컬렉션에서 비디오가 제거되었습니다.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('제거'),
          ),
        ],
      ),
    );
  }

  /// 컬렉션 편집 다이얼로그
  void _showEditCollectionDialog(
    BuildContext context,
    WidgetRef ref,
    BookmarkCollection collection,
  ) {
    final nameController = TextEditingController(text: collection.name);
    final descriptionController = TextEditingController(text: collection.description);
    bool isPublic = collection.isPublic;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('컬렉션 편집'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '컬렉션 이름',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: '설명 (선택사항)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('공개 컬렉션'),
                      subtitle: const Text('다른 사용자가 이 컬렉션을 볼 수 있도록 허용'),
                      value: isPublic,
                      onChanged: (value) {
                        setState(() {
                          isPublic = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('컬렉션 이름을 입력하세요')),
                      );
                      return;
                    }

                    Navigator.of(context).pop();

                    // 컬렉션 업데이트
                    ref.read(bookmarkProvider.notifier).updateCollection(
                          collectionId: collection.id,
                          name: nameController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 컬렉션 삭제 확인 다이얼로그
  void _showDeleteCollectionConfirmation(
    BuildContext context,
    WidgetRef ref,
    BookmarkCollection collection,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('컬렉션 삭제'),
          content: Text('정말 "${collection.name}" 컬렉션을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                // 컬렉션 삭제
                ref.read(bookmarkProvider.notifier).deleteCollection(collection.id).then((_) {
                  // 삭제 후 북마크 화면으로 돌아가기
                  context.go('/bookmarks');
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  // 비디오 제거 확인 다이얼로그
  void _showRemoveVideoConfirmation(
    BuildContext context,
    WidgetRef ref,
    Video video,
    BookmarkCollection collection,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('비디오 제거'),
          content: Text('정말 이 비디오를 "${collection.name}" 컬렉션에서 제거하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                // 비디오 제거
                ref.read(bookmarkProvider.notifier).removeVideoFromCollection(
                      video.id,
                      collection.id,
                    );
              },
              child: const Text('제거'),
            ),
          ],
        );
      },
    );
  }
}
