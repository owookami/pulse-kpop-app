import 'package:flutter/material.dart';

/// 앱 전체에서 사용할 색상 정의
class AppColors {
  /// 기본 생성자 - 인스턴스화 방지
  const AppColors._();

  /// 기본 프라이머리 색상
  static const Color primary = Color(0xFF7D59FF);

  /// 세컨더리 색상
  static const Color secondary = Color(0xFF59C1FF);

  /// 에러 색상
  static const Color error = Color(0xFFE53935);

  /// 배경 색상
  static const Color background = Color(0xFFF5F5F5);

  /// 텍스트 기본 색상
  static const Color textPrimary = Color(0xFF212121);

  /// 텍스트 보조 색상
  static const Color textSecondary = Color(0xFF757575);

  /// 텍스트 플레이스홀더 색상
  static const Color textPlaceholder = Color(0xFFBDBDBD);

  /// 구분선 색상
  static const Color divider = Color(0xFFE0E0E0);

  /// 카드 배경색
  static const Color cardBackground = Colors.white;

  /// 성공 색상
  static const Color success = Color(0xFF4CAF50);

  /// 경고 색상
  static const Color warning = Color(0xFFFFC107);
}
