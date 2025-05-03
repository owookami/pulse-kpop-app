import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/bookmark_provider.dart';

/// 북마크 버튼 위젯
class BookmarkButton extends ConsumerWidget {
  /// 생성자
  const BookmarkButton({
    super.key,
    required this.videoId,
    this.size = 24.0,
    this.color,
  });

  /// 비디오 ID
  final String videoId;

  /// 아이콘 크기
  final double size;

  /// 아이콘 컬러 (기본값: 현재 테마 컬러)
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookmarkProvider(videoId));
    final notifier = ref.read(bookmarkProvider(videoId).notifier);

    return IconButton(
      onPressed: state.isLoading ? null : notifier.toggleBookmark,
      icon: state.isLoading
          ? SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color ?? Theme.of(context).colorScheme.primary,
              ),
            )
          : Icon(
              state.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: state.isBookmarked ? Theme.of(context).colorScheme.primary : color,
              size: size,
            ),
      tooltip: state.isBookmarked ? '북마크 해제' : '북마크 추가',
    );
  }
}
