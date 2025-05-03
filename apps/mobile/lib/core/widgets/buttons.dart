import 'package:flutter/material.dart';

/// 기본 버튼 위젯
/// 앱 전체에서 일관된 디자인의 버튼을 제공합니다.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryButton({
    required this.text,
    required this.onPressed,
    Key? key,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = 48.0,
    this.icon,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.primary,
          foregroundColor: textColor ?? theme.colorScheme.onPrimary,
          disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.5),
          disabledForegroundColor: theme.colorScheme.onPrimary.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        child: _buildButtonContent(theme),
      ),
    );
  }

  Widget _buildButtonContent(ThemeData theme) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: theme.colorScheme.onPrimary,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}

/// 아웃라인 버튼 위젯
class OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;

  const OutlineButton({
    required this.text,
    required this.onPressed,
    Key? key,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = 48.0,
    this.icon,
    this.borderColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = borderColor ?? theme.colorScheme.primary;

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          foregroundColor: textColor ?? color,
          disabledForegroundColor: color.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        child: _buildButtonContent(theme, color),
      ),
    );
  }

  Widget _buildButtonContent(ThemeData theme, Color color) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}

/// 텍스트 버튼 위젯
class TextBtn extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? textColor;
  final IconData? icon;
  final bool iconLeading;

  const TextBtn({
    required this.text,
    required this.onPressed,
    Key? key,
    this.isLoading = false,
    this.textColor,
    this.icon,
    this.iconLeading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = textColor ?? theme.colorScheme.primary;

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: color.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      child: _buildButtonContent(theme, color),
    );
  }

  Widget _buildButtonContent(ThemeData theme, Color color) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          color: color,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: iconLeading
            ? [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(text),
              ]
            : [
                Text(text),
                const SizedBox(width: 8),
                Icon(icon, size: 18),
              ],
      );
    }

    return Text(text);
  }
}

/// 소셜 로그인 버튼 위젯
class SocialLoginButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String iconAsset;
  final Color backgroundColor;
  final Color textColor;

  const SocialLoginButton({
    required this.text,
    required this.onPressed,
    required this.iconAsset,
    Key? key,
    this.isLoading = false,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 1,
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.grey,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(iconAsset, fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: textColor)),
      ],
    );
  }
}
