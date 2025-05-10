import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// 날짜 사이드바 위젯 - 이벤트/비디오 날짜를 표시
class DateSidebar extends StatelessWidget {
  final String day;
  final String month;

  const DateSidebar({
    Key? key,
    required this.day,
    required this.month,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          day,
          style: AppTheme.heading,
        ),
        Text(
          month.toUpperCase(),
          style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// int 월을 영문 약자로 변환
  static String getMonthAbbr(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[month - 1];
  }
}
