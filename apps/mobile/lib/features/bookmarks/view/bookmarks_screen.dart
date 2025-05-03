import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/widgets/main_scaffold.dart';
import 'package:mobile/features/bookmarks/model/bookmark_state.dart';
import 'package:mobile/features/bookmarks/provider/bookmark_provider.dart';
import 'package:mobile/routes/routes.dart';

/// 북마크 화면
class BookmarksScreen extends ConsumerStatefulWidget {
  /// 생성자
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkState = ref.watch(bookmarkProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('북마크'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(bookmarkProvider.notifier).refreshBookmarks(),
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/bookmarks/manage'),
            tooltip: '컬렉션 관리',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '북마크된 비디오'),
            Tab(text: '컬렉션'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 북마크된 비디오 탭
          _BookmarkedVideosTab(bookmarkState: bookmarkState),

          // 컬렉션 탭
          _CollectionsTab(bookmarkState: bookmarkState),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 현재 탭에 따라 다른 액션 수행
          if (_tabController.index == 0) {
            // 홈 탭으로 이동
            final navigationShell = ref.read(activeNavigationShellProvider);

            if (navigationShell != null) {
              // 홈 탭(인덱스 0)으로 이동
              navigationShell.goBranch(
                0,
                initialLocation: true,
              );
            } else {
              // 네비게이션 셸을 찾을 수 없는 경우 기존 방식으로 이동
              print('네비게이션 셸을 찾을 수 없습니다. 기존 방식으로 이동합니다.');
              context.go(AppRoutes.home);
            }
          } else {
            // 컬렉션 탭에서는 새 컬렉션 생성 다이얼로그 표시
            _showCreateCollectionDialog(context);
          }
        },
        child: Icon(
          _tabController.index == 0 ? Icons.video_library : Icons.add,
        ),
      ),
    );
  }

  // 컬렉션 생성 다이얼로그
  void _showCreateCollectionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isPublic = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('새 컬렉션'),
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
                      autofocus: true,
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

                    // 컬렉션 생성
                    ref.read(bookmarkProvider.notifier).createCollection(
                          name: nameController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );
                  },
                  child: const Text('생성'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 북마크된 비디오 탭
class _BookmarkedVideosTab extends ConsumerWidget {
  /// 생성자
  const _BookmarkedVideosTab({
    required this.bookmarkState,
  });

  /// 북마크 상태
  final AsyncValue<BookmarkState> bookmarkState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return bookmarkState.when(
      data: (state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 북마크된 비디오가 없는 경우
        if (state.bookmarkedVideos.isEmpty) {
          return _buildEmptyState(context, ref);
        }

        // 북마크된 비디오 목록 표시
        return _buildVideoList(context, state.bookmarkedVideos);
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
    );
  }

  // 비디오 목록 위젯
  Widget _buildVideoList(BuildContext context, List<Video> videos) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _buildVideoCard(context, video);
      },
    );
  }

  // 비디오 카드 위젯
  Widget _buildVideoCard(BuildContext context, Video video) {
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

            // 비디오 제목 및 정보
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
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${video.viewCount}회',
                        style: Theme.of(context).textTheme.bodySmall,
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

  // 빈 상태 위젯
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '북마크가 없습니다',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '비디오를 시청하는 동안 북마크를 추가하세요',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(bookmarkProvider.notifier).refreshBookmarks(),
            icon: const Icon(Icons.home),
            label: const Text('홈으로 이동'),
          ),
        ],
      ),
    );
  }
}

/// 컬렉션 탭
class _CollectionsTab extends ConsumerWidget {
  /// 생성자
  const _CollectionsTab({
    required this.bookmarkState,
  });

  /// 북마크 상태
  final AsyncValue<BookmarkState> bookmarkState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return bookmarkState.when(
      data: (state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 컬렉션이 없는 경우
        if (state.collections.isEmpty) {
          return _buildEmptyState(context, ref);
        }

        // 컬렉션 목록 표시
        return _buildCollectionList(context, state.collections);
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
    );
  }

  // 컬렉션 목록 위젯
  Widget _buildCollectionList(BuildContext context, List<BookmarkCollection> collections) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final collection = collections[index];
        return _buildCollectionCard(context, collection);
      },
    );
  }

  // 컬렉션 카드 위젯
  Widget _buildCollectionCard(BuildContext context, BookmarkCollection collection) {
    return GestureDetector(
      onTap: () {
        // 컬렉션 세부 화면으로 이동
        context.push('/bookmarks/collection/${collection.id}', extra: collection);
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 컬렉션 커버
            AspectRatio(
              aspectRatio: 16 / 9,
              child: collection.coverImageUrl != null
                  ? Image.network(
                      collection.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.blueGrey[200],
                        child: const Center(
                          child: Icon(Icons.collections_bookmark),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.blueGrey[200],
                      child: const Center(
                        child: Icon(
                          Icons.collections_bookmark,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),

            // 컬렉션 정보
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          collection.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        collection.isPublic ? Icons.public : Icons.lock,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                  if (collection.description != null && collection.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      collection.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.video_library, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${collection.bookmarkCount}개',
                        style: Theme.of(context).textTheme.bodySmall,
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

  // 빈 상태 위젯
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections_bookmark_outlined,
            size: 72,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '컬렉션이 없습니다',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '컬렉션을 만들어 북마크를 정리하세요',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(bookmarkProvider.notifier).createCollection(
                  name: '나의 첫 컬렉션',
                  description: '북마크한 비디오를 모아두는 첫 컬렉션입니다.',
                ),
            icon: const Icon(Icons.add),
            label: const Text('컬렉션 만들기'),
          ),
        ],
      ),
    );
  }
}
