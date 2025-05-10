import 'package:flutter/material.dart';
import 'package:mobile/config/theme/app_colors.dart';

/// 앱 전체에서 사용할 공통 버튼 위젯
class AppButton extends StatelessWidget {
  /// 기본 생성자
  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.width,
    this.height = 48.0,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 12.0,
    this.icon,
    this.iconPosition = IconPosition.left,
  });

  /// 전체 너비 버튼
  factory AppButton.fullWidth({
    Key? key,
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
    bool isOutlined = false,
    Color? backgroundColor,
    Color? foregroundColor,
    double height = 48.0,
    IconData? icon,
    IconPosition iconPosition = IconPosition.left,
  }) {
    return AppButton(
      key: key,
      onPressed: onPressed,
      text: text,
      width: double.infinity,
      height: height,
      isLoading: isLoading,
      isOutlined: isOutlined,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      icon: icon,
      iconPosition: iconPosition,
    );
  }

  /// 아웃라인 버튼
  factory AppButton.outlined({
    Key? key,
    required VoidCallback? onPressed,
    required String text,
    double? width,
    double height = 48.0,
    bool isLoading = false,
    Color? foregroundColor,
    IconData? icon,
    IconPosition iconPosition = IconPosition.left,
  }) {
    return AppButton(
      key: key,
      onPressed: onPressed,
      text: text,
      width: width,
      height: height,
      isLoading: isLoading,
      isOutlined: true,
      foregroundColor: foregroundColor ?? AppColors.primary,
      icon: icon,
      iconPosition: iconPosition,
    );
  }

  /// 버튼 클릭 콜백
  final VoidCallback? onPressed;

  /// 버튼 텍스트
  final String text;

  /// 버튼 너비
  final double? width;

  /// 버튼 높이
  final double height;

  /// 로딩 상태 여부
  final bool isLoading;

  /// 아웃라인 스타일 여부
  final bool isOutlined;

  /// 배경 색상
  final Color? backgroundColor;

  /// 텍스트 및 테두리 색상
  final Color? foregroundColor;

  /// 테두리 둥글기
  final double borderRadius;

  /// 아이콘 (선택적)
  final IconData? icon;

  /// 아이콘 위치
  final IconPosition iconPosition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 배경색 및 전경색 결정
    final bgColor = backgroundColor ?? AppColors.primary;
    final fgColor = foregroundColor ?? Colors.white;

    // 아웃라인 버튼인 경우 스타일 변경
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: fgColor,
            side: BorderSide(color: fgColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          );

    // 로딩 인디케이터
    if (isLoading) {
      return SizedBox(
        width: width,
        height: height,
        child: isOutlined
            ? OutlinedButton(
                onPressed: null,
                style: buttonStyle,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: null,
                style: buttonStyle,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                  ),
                ),
              ),
      );
    }

    // 아이콘 및 텍스트 위젯
    final textWidget = Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    final iconWidget = icon != null ? Icon(icon, size: 20) : null;

    // 아이콘 및 텍스트 레이아웃
    Widget childWidget;

    if (icon == null) {
      childWidget = textWidget;
    } else {
      childWidget = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconPosition == IconPosition.left) ...[
            iconWidget!,
            const SizedBox(width: 8),
          ],
          textWidget,
          if (iconPosition == IconPosition.right) ...[
            const SizedBox(width: 8),
            iconWidget!,
          ],
        ],
      );
    }

    // 최종 버튼 위젯
    return SizedBox(
      width: width,
      height: height,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: childWidget,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: childWidget,
            ),
    );
  }
}

/// 아이콘 위치 열거형
enum IconPosition {
  /// 왼쪽
  left,

  /// 오른쪽
  right,
}
