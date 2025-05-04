import 'package:flutter/foundation.dart';

/// 구독 유형
enum SubscriptionType {
  /// 무료 (기본)
  free,

  /// 월간 프리미엄
  monthly,

  /// 연간 프리미엄
  yearly,
}

/// 구독 상태
@immutable
class SubscriptionState {
  /// 생성자
  const SubscriptionState({
    this.type = SubscriptionType.free,
    this.isActive = false,
    this.expiryDate,
    this.purchaseDate,
    this.isLoading = false,
    this.error,
    this.isCancelled = false,
  });

  /// 구독 유형
  final SubscriptionType type;

  /// 활성화 여부
  final bool isActive;

  /// 만료일
  final DateTime? expiryDate;

  /// 구매일
  final DateTime? purchaseDate;

  /// 로딩 중 여부
  final bool isLoading;

  /// 오류 메시지
  final String? error;

  /// 구독 취소 여부 (만료일까지 이용 가능)
  final bool isCancelled;

  /// 프리미엄 구독 여부
  bool get isPremium => isActive && type != SubscriptionType.free;

  /// 복사본 생성
  SubscriptionState copyWith({
    SubscriptionType? type,
    bool? isActive,
    DateTime? expiryDate,
    DateTime? purchaseDate,
    bool? isLoading,
    String? error,
    bool? isCancelled,
  }) {
    return SubscriptionState(
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      expiryDate: expiryDate ?? this.expiryDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  /// 로딩 상태로 변경
  SubscriptionState toLoading() {
    return copyWith(
      isLoading: true,
      error: null,
    );
  }

  /// 오류 상태로 변경
  SubscriptionState toError(String message) {
    return copyWith(
      isLoading: false,
      error: message,
    );
  }
}

/// 구독 상품 정보
class SubscriptionProduct {
  /// 생성자
  const SubscriptionProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    this.currencySymbol = '₩',
    this.currencyCode = 'KRW',
  });

  /// 상품 ID
  final String id;

  /// 상품명
  final String title;

  /// 상품 설명
  final String description;

  /// 가격
  final double price;

  /// 구독 유형
  final SubscriptionType type;

  /// 통화 기호
  final String currencySymbol;

  /// 통화 코드
  final String currencyCode;

  /// 가격 표시 (예: ₩9,900)
  String get priceDisplay {
    return '$currencySymbol${price.toStringAsFixed(0)}';
  }
}
