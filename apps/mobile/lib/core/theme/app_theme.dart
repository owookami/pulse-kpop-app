import 'package:flutter/material.dart';

/// 앱 테마 정의
class AppTheme {
  // 메인 색상
  static const Color primary = Color(0xFFFF5349);
  static const Color secondary = Color(0xFF222222);
  static const Color background = Colors.white;
  static const Color cardBackground = Color(0xFFF8F9FA);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF555555);

  // 배지 색상
  static const Color premiumBadge = Color(0xFFFF5349);
  static const Color vipBadge = Color(0xFFE02020);
  static const Color specialBadge = Color(0xFFFF5349);

  // 텍스트 스타일
  static const TextStyle headingLarge = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 14,
    color: textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 12,
    color: textSecondary,
  );

  // 테마 데이터
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      fontFamily: 'Pretendard',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: secondary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pretendard',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
      ),
      textTheme: const TextTheme(
        displayLarge: headingLarge,
        titleLarge: heading,
        titleMedium: subheading,
        bodyMedium: body,
        bodySmall: caption,
      ),
      cardTheme: CardTheme(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
      ),
    );
  }
}
