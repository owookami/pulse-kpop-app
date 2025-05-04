import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/bookmark_provider.dart';

/// 북마크 버튼 위젯
class BookmarkButton extends ConsumerStatefulWidget {
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
  ConsumerState<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends ConsumerState<BookmarkButton> {
  String? _previousVideoId;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    _previousVideoId = widget.videoId;

    // 위젯이 처음 마운트된 후 북마크 상태를 새로고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      debugPrint('북마크 버튼 초기화: videoId=${widget.videoId}');
      ref.read(bookmarkProvider(widget.videoId).notifier).refresh();
    });
  }

  @override
  void didUpdateWidget(BookmarkButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // videoId가 변경된 경우 상태 새로고침
    if (widget.videoId != oldWidget.videoId) {
      debugPrint('북마크 버튼 videoId 변경: ${oldWidget.videoId} -> ${widget.videoId}');
      _previousVideoId = widget.videoId;

      // 새 videoId에 대한 상태 로드
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(bookmarkProvider(widget.videoId).notifier).refresh();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 북마크 상태와 노티파이어 가져오기
    final state = ref.watch(bookmarkProvider(widget.videoId));
    final notifier = ref.read(bookmarkProvider(widget.videoId).notifier);

    // 첫 빌드이거나 ID가 변경된 경우 로그 출력
    if (_isFirstBuild || widget.videoId != _previousVideoId) {
      debugPrint(
          '북마크 버튼 빌드: videoId=${widget.videoId}, isBookmarked=${state.isBookmarked}, isFirstBuild=$_isFirstBuild');
      _isFirstBuild = false;
      _previousVideoId = widget.videoId;
    }

    return IconButton(
      onPressed: state.isLoading
          ? null
          : () async {
              debugPrint('북마크 버튼 클릭: videoId=${widget.videoId}');
              await notifier.toggleBookmark();
            },
      icon: state.isLoading
          ? SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.color ?? Theme.of(context).colorScheme.primary,
              ),
            )
          : Icon(
              state.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: state.isBookmarked ? Theme.of(context).colorScheme.primary : widget.color,
              size: widget.size,
            ),
      tooltip: state.isBookmarked ? '북마크 해제' : '북마크 추가',
    );
  }
}
