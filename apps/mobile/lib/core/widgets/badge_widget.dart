import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// 배지 위젯 - VIP, PREMIUM, SPECIAL 등의 상태를 표시
class BadgeWidget extends StatelessWidget {
  final String type;
  final double fontSize;

  const BadgeWidget({
    Key? key,
    required this.type,
    this.fontSize = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color badgeColor;

    switch (type.toUpperCase()) {
      case 'PREMIUM':
        badgeColor = AppTheme.premiumBadge;
        break;
      case 'VIP':
        badgeColor = AppTheme.vipBadge;
        break;
      case 'SPECIAL':
        badgeColor = AppTheme.specialBadge;
        break;
      default:
        badgeColor = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }
}
