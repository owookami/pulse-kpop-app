import 'package:flutter/material.dart';

/// 좋아요/싫어요 버튼 위젯
class LikeDislikeButtons extends StatelessWidget {
  /// 생성자
  const LikeDislikeButtons({
    super.key,
    required this.isLiked,
    required this.isDisliked,
    required this.likeCount,
    required this.dislikeCount,
    required this.onLikePressed,
    required this.onDislikePressed,
    this.iconSize = 24.0,
    this.spacing = 16.0,
    this.likeColor = Colors.blue,
    this.dislikeColor = Colors.red,
    this.inactiveColor = Colors.grey,
    this.showCounts = true,
    this.countTextStyle,
    this.isLoading = false,
  });

  /// 좋아요 상태
  final bool isLiked;

  /// 싫어요 상태
  final bool isDisliked;

  /// 좋아요 수
  final int likeCount;

  /// 싫어요 수
  final int dislikeCount;

  /// 좋아요 버튼 콜백
  final VoidCallback onLikePressed;

  /// 싫어요 버튼 콜백
  final VoidCallback onDislikePressed;

  /// 아이콘 크기
  final double iconSize;

  /// 버튼 간 간격
  final double spacing;

  /// 좋아요 활성화 색상
  final Color likeColor;

  /// 싫어요 활성화 색상
  final Color dislikeColor;

  /// 비활성화 색상
  final Color inactiveColor;

  /// 카운트 표시 여부
  final bool showCounts;

  /// 카운트 텍스트 스타일
  final TextStyle? countTextStyle;

  /// 로딩 중 여부
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLikeButton(),
        SizedBox(width: spacing),
        _buildDislikeButton(),
      ],
    );
  }

  /// 좋아요 버튼 구현
  Widget _buildLikeButton() {
    return InkWell(
      onTap: isLoading ? null : onLikePressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            isLoading
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLiked ? likeColor : inactiveColor,
                      ),
                    ),
                  )
                : Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: isLiked ? likeColor : inactiveColor,
                    size: iconSize,
                  ),
            if (showCounts) ...[
              const SizedBox(width: 4),
              Text(
                '$likeCount',
                style: countTextStyle ??
                    TextStyle(
                      fontSize: 14,
                      fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                      color: isLiked ? likeColor : inactiveColor,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 싫어요 버튼 구현
  Widget _buildDislikeButton() {
    return InkWell(
      onTap: isLoading ? null : onDislikePressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            isLoading
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDisliked ? dislikeColor : inactiveColor,
                      ),
                    ),
                  )
                : Icon(
                    isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                    color: isDisliked ? dislikeColor : inactiveColor,
                    size: iconSize,
                  ),
            if (showCounts) ...[
              const SizedBox(width: 4),
              Text(
                '$dislikeCount',
                style: countTextStyle ??
                    TextStyle(
                      fontSize: 14,
                      fontWeight: isDisliked ? FontWeight.bold : FontWeight.normal,
                      color: isDisliked ? dislikeColor : inactiveColor,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
