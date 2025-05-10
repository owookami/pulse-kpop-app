import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/bookmarks/provider/bookmark_provider.dart';
import 'package:mobile/routes/routes.dart';

/// 북마크 컬렉션 관리 화면
class CollectionManagementScreen extends ConsumerWidget {
  /// 생성자
  const CollectionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarkState = ref.watch(bookmarkProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.collection_management_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateCollectionDialog(context, ref),
            tooltip: l10n.collection_management_new,
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
                l10n.collection_management_error,
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
                child: Text(l10n.common_retry),
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
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.collections_bookmark_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            l10n.collection_management_empty,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.collection_management_empty_description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateCollectionDialog(context, ref),
            icon: const Icon(Icons.add),
            label: Text(l10n.collection_management_create),
          ),
        ],
      ),
    );
  }

  // 컬렉션 생성 다이얼로그
  void _showCreateCollectionDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.collection_management_create_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.collection_management_name,
                hintText: l10n.collection_management_name_hint,
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: l10n.collection_management_description,
                hintText: l10n.collection_management_description_hint,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.collection_management_cancel),
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
            child: Text(l10n.collection_management_create_button),
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
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(collection.name),
        subtitle: collection.description != null ? Text(collection.description!) : null,
        leading: const Icon(Icons.folder),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _showDeleteDialog(context, ref),
          tooltip: l10n.common_delete,
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
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.collection_management_delete_title),
        content: Text(l10n.collection_management_delete_message(collection.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.collection_management_cancel),
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
            child: Text(l10n.collection_management_delete_button),
          ),
        ],
      ),
    );
  }
}
