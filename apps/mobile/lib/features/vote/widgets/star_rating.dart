import 'package:flutter/material.dart';

/// 별점 위젯 (선택 가능)
class StarRating extends StatelessWidget {
  /// 생성자
  const StarRating({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.size = 24.0,
    this.color = Colors.amber,
    this.borderColor = Colors.grey,
    this.spacing = 0.0,
    this.allowHalfRating = true,
    this.allowClear = true,
  });

  /// 현재 별점 (0.0-5.0, null은 평가하지 않음)
  final double? rating;

  /// 별점 변경 콜백
  final ValueChanged<double?>? onRatingChanged;

  /// 별 크기
  final double size;

  /// 별 색상
  final Color color;

  /// 별 테두리 색상
  final Color borderColor;

  /// 별 간격
  final double spacing;

  /// 반 별점 허용 여부
  final bool allowHalfRating;

  /// 별점 취소 허용 여부
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: GestureDetector(
            onTap: onRatingChanged != null
                ? () {
                    final newRating = index + 1.0;
                    // 같은 별점 다시 탭하면 취소
                    if (allowClear && rating == newRating) {
                      onRatingChanged!(null);
                    } else {
                      onRatingChanged!(newRating);
                    }
                  }
                : null,
            onHorizontalDragUpdate: onRatingChanged != null && allowHalfRating
                ? (details) {
                    // 드래그로 반 별점 선택
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    final localPosition = box.globalToLocal(details.globalPosition);
                    final totalWidth = box.size.width;
                    final starWidth = totalWidth / 5;
                    final position = localPosition.dx.clamp(0, totalWidth);

                    final starPosition = position / starWidth;
                    final starIndex = starPosition.floor();
                    final starDecimal = starPosition - starIndex;

                    double newRating;
                    if (starDecimal < 0.5) {
                      newRating = starIndex + 0.5;
                    } else {
                      newRating = starIndex + 1.0;
                    }

                    // 경계값 처리
                    newRating = newRating.clamp(0.5, 5.0);

                    if (rating != newRating) {
                      onRatingChanged!(newRating);
                    }
                  }
                : null,
            child: _buildStar(index),
          ),
        );
      }),
    );
  }

  /// 별 구현
  Widget _buildStar(int index) {
    IconData icon;
    double fillPercent = 0;

    if (rating == null) {
      icon = Icons.star_border;
    } else {
      final difference = rating! - index;

      if (difference >= 1) {
        // 꽉 찬 별
        icon = Icons.star;
        fillPercent = 1.0;
      } else if (difference > 0 && difference < 1) {
        // 반 별
        if (allowHalfRating && difference >= 0.5) {
          icon = Icons.star_half;
          fillPercent = 0.5;
        } else {
          icon = Icons.star_border;
        }
      } else {
        // 빈 별
        icon = Icons.star_border;
      }
    }

    return Icon(
      icon,
      color: fillPercent > 0 ? color : borderColor,
      size: size,
    );
  }
}

/// 읽기 전용 별점 위젯
class ReadOnlyStarRating extends StatelessWidget {
  /// 생성자
  const ReadOnlyStarRating({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.color = Colors.amber,
    this.borderColor = Colors.grey,
    this.spacing = 0.0,
    this.showRatingText = true,
    this.ratingTextStyle,
  });

  /// 현재 별점 (0.0-5.0)
  final double rating;

  /// 별 크기
  final double size;

  /// 별 색상
  final Color color;

  /// 별 테두리 색상
  final Color borderColor;

  /// 별 간격
  final double spacing;

  /// 별점 텍스트 표시 여부
  final bool showRatingText;

  /// 별점 텍스트 스타일
  final TextStyle? ratingTextStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final difference = rating - index;
            IconData icon;

            if (difference >= 1) {
              // 꽉 찬 별
              icon = Icons.star;
            } else if (difference > 0) {
              // 반 별
              icon = difference >= 0.5 ? Icons.star_half : Icons.star_border;
            } else {
              // 빈 별
              icon = Icons.star_border;
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Icon(
                icon,
                color: difference > 0 ? color : borderColor,
                size: size,
              ),
            );
          }),
        ),
        if (showRatingText) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: ratingTextStyle ??
                TextStyle(
                  fontSize: size * 0.75,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
        ],
      ],
    );
  }
}
