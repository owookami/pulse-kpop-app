import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/bookmarks/provider/bookmark_provider.dart';
import 'package:mobile/routes/routes.dart';

/// 북마크 컬렉션 관리 화면
class CollectionManagementScreen extends ConsumerWidget {
  /// 생성자
  const CollectionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkState = ref.watch(bookmarkProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('컬렉션 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateCollectionDialog(context, ref),
            tooltip: '새 컬렉션',
          ),
        ],
      ),
      body: bookmarkState.when(
        data: (state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.collections.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          return _buildCollectionList(context, ref, state.collections);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '컬렉션을 불러오는 중 오류가 발생했습니다.',
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
                onPressed: () => ref.read(bookmarkProvider.notifier).refreshBookmarks(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 컬렉션 목록 빌드
  Widget _buildCollectionList(
    BuildContext context,
    WidgetRef ref,
    List<BookmarkCollection> collections,
  ) {
    return ListView.builder(
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final collection = collections[index];
        return _CollectionListItem(collection: collection);
      },
    );
  }

  // 빈 상태 위젯
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.collections_bookmark_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '컬렉션이 없습니다.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '북마크한 비디오를 컬렉션으로 관리해보세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateCollectionDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('컬렉션 만들기'),
          ),
        ],
      ),
    );
  }

  // 컬렉션 생성 다이얼로그
  void _showCreateCollectionDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 컬렉션 만들기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '컬렉션 이름',
                hintText: '새 컬렉션 이름을 입력하세요.',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '설명 (선택사항)',
                hintText: '컬렉션에 대한 설명을 입력하세요.',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref.read(bookmarkProvider.notifier).createCollection(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                Navigator.of(context).pop();
              }
            },
            child: const Text('만들기'),
          ),
        ],
      ),
    );
  }
}

/// 컬렉션 목록 아이템
class _CollectionListItem extends ConsumerWidget {
  /// 생성자
  const _CollectionListItem({
    required this.collection,
  });

  /// 컬렉션 정보
  final BookmarkCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(collection.name),
        subtitle: collection.description != null ? Text(collection.description!) : null,
        leading: const Icon(Icons.folder),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _showDeleteDialog(context, ref),
          tooltip: '컬렉션 삭제',
        ),
        onTap: () {
          context.push(
            '${AppRoutes.bookmarks}/${AppRoutes.collection.replaceAll(':id', collection.id)}',
            extra: collection,
          );
        },
      ),
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('컬렉션 삭제'),
        content: Text('\'${collection.name}\' 컬렉션을 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(bookmarkProvider.notifier).deleteCollection(collection.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
