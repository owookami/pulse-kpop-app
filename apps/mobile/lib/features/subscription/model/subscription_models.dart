// 구독 시스템 모델 - 상품, 플랜, 상태 등 모든 구독 관련 모델 정의
import 'package:equatable/equatable.dart';

/// 구독 플랜 타입
enum SubscriptionPlanType {
  /// 무료
  free,

  /// 베이직 월간
  basicMonthly,

  /// 베이직 연간
  basicYearly,

  /// 프리미엄 월간
  premiumMonthly,

  /// 프리미엄 연간
  premiumYearly
}

/// 구독 플랜 기간 (무료, 월간, 연간)
enum SubscriptionPeriod { free, monthly, yearly }

/// 구독 플랜 등급 (무료, 베이직, 프리미엄)
enum SubscriptionTier { free, basic, premium }

/// 결제 플랫폼
enum PaymentPlatform { none, appStore, googlePlay, web }

/// 구독 상태
enum SubscriptionState { active, expired, canceled, pending, onHold, paused, unknown }

/// 구독 플랜 타입 확장 메서드
extension SubscriptionPlanTypeExtension on SubscriptionPlanType {
  /// 구독 기간 반환
  SubscriptionPeriod get period {
    switch (this) {
      case SubscriptionPlanType.free:
        return SubscriptionPeriod.free;
      case SubscriptionPlanType.basicMonthly:
      case SubscriptionPlanType.premiumMonthly:
        return SubscriptionPeriod.monthly;
      case SubscriptionPlanType.basicYearly:
      case SubscriptionPlanType.premiumYearly:
        return SubscriptionPeriod.yearly;
    }
  }

  /// 구독 등급 반환
  SubscriptionTier get tier {
    switch (this) {
      case SubscriptionPlanType.free:
        return SubscriptionTier.free;
      case SubscriptionPlanType.basicMonthly:
      case SubscriptionPlanType.basicYearly:
        return SubscriptionTier.basic;
      case SubscriptionPlanType.premiumMonthly:
      case SubscriptionPlanType.premiumYearly:
        return SubscriptionTier.premium;
    }
  }

  /// 플랜의 스토어 상품 ID 반환
  String get productId {
    switch (this) {
      case SubscriptionPlanType.free:
        return 'free';
      case SubscriptionPlanType.basicMonthly:
        return 'com.zan.pulse.basic.monthly';
      case SubscriptionPlanType.basicYearly:
        return 'com.zan.pulse.basic.yearly';
      case SubscriptionPlanType.premiumMonthly:
        return 'com.zan.pulse.premium.monthly';
      case SubscriptionPlanType.premiumYearly:
        return 'com.zan.pulse.premium.yearly';
    }
  }

  /// 플랜 이름 반환
  String get name {
    switch (this) {
      case SubscriptionPlanType.free:
        return '무료';
      case SubscriptionPlanType.basicMonthly:
        return '베이직 월간';
      case SubscriptionPlanType.basicYearly:
        return '베이직 연간';
      case SubscriptionPlanType.premiumMonthly:
        return '프리미엄 월간';
      case SubscriptionPlanType.premiumYearly:
        return '프리미엄 연간';
    }
  }

  /// 문자열에서 플랜 타입 변환
  static SubscriptionPlanType fromString(String value) {
    switch (value) {
      case 'basicMonthly':
        return SubscriptionPlanType.basicMonthly;
      case 'basicYearly':
        return SubscriptionPlanType.basicYearly;
      case 'premiumMonthly':
        return SubscriptionPlanType.premiumMonthly;
      case 'premiumYearly':
        return SubscriptionPlanType.premiumYearly;
      case 'free':
      default:
        return SubscriptionPlanType.free;
    }
  }
}

/// 구독 상품 정보 모델
class SubscriptionProduct extends Equatable {
  /// 구독 상품 생성자
  const SubscriptionProduct({
    required this.planType,
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.period,
    required this.tier,
    this.rawDetails,
    this.isMostPopular = false,
    this.isBestValue = false,
    this.features = const [],
    this.countryCode,
  });

  /// 구독 플랜 타입
  final SubscriptionPlanType planType;

  /// 상품 ID (스토어에 등록된 ID)
  final String productId;

  /// 상품 제목
  final String title;

  /// 상품 설명
  final String description;

  /// 가격 문자열 (형식: '$1.99')
  final String price;

  /// 가격 (로컬 통화 기준)
  final double rawPrice;

  /// 통화 코드
  final String currencyCode;

  /// 구독 기간 (월별, 연별)
  final SubscriptionPeriod period;

  /// 구독 티어 (베이직, 프리미엄)
  final SubscriptionTier tier;

  /// 스토어 제공 상품 상세 정보 (JSON 문자열)
  final String? rawDetails;

  /// 가장 인기 있는 상품 여부
  final bool isMostPopular;

  /// 가장 가성비 좋은 상품 여부
  final bool isBestValue;

  /// 구독 상품 기능 목록
  final List<String> features;

  /// 국가 코드 (지역별 가격 책정용)
  final String? countryCode;

  /// 국가 코드에 해당하는 국가명 반환
  String get countryName {
    if (countryCode == null) return '전 세계';

    final countryNames = {
      // 아시아 국가들
      'KR': '대한민국',
      'JP': '일본',
      'CN': '중국',
      'TW': '대만',
      'HK': '홍콩',
      'SG': '싱가포르',
      'MY': '말레이시아',
      'ID': '인도네시아',
      'TH': '태국',
      'PH': '필리핀',
      'VN': '베트남',

      // 북미/유럽 국가들
      'US': '미국',
      'CA': '캐나다',
      'GB': '영국',
      'DE': '독일',
      'FR': '프랑스',
      'IT': '이탈리아',
      'ES': '스페인',
      'AU': '호주',

      // 기타 지역 국가들
      'BR': '브라질',
      'MX': '멕시코',
      'AR': '아르헨티나',
      'IN': '인도',
      'ZA': '남아프리카공화국',
    };

    return countryNames[countryCode] ?? countryCode!;
  }

  /// 기본 무료 플랜 생성
  factory SubscriptionProduct.free() => const SubscriptionProduct(
        planType: SubscriptionPlanType.free,
        productId: 'free_plan',
        title: '무료 플랜',
        description: '기본 기능 이용 가능',
        price: r'$0.00',
        rawPrice: 0.0,
        currencyCode: 'USD',
        period: SubscriptionPeriod.free,
        tier: SubscriptionTier.free,
        features: [
          '팬캠 시청 10회',
          '일부 영상 제한',
          '표준 화질',
          '광고 포함',
        ],
      );

  /// 월간 프리미엄 플랜 생성 팩토리 메서드
  factory SubscriptionProduct.monthlyPremium({String? countryCode}) {
    // 기본 가격 및 통화 (미국 기준)
    double rawPrice = 1.99;
    String formattedPrice = r'$1.99';
    String currencyCode = 'USD';

    // 국가별 가격 및 통화 설정
    if (countryCode != null) {
      // 아시아 지역 국가별 세부 가격
      switch (countryCode) {
        case 'KR': // 한국
          rawPrice = 2400;
          formattedPrice = '₩2,400';
          currencyCode = 'KRW';
          break;
        case 'JP': // 일본
          rawPrice = 250;
          formattedPrice = '¥250';
          currencyCode = 'JPY';
          break;
        case 'CN': // 중국
          rawPrice = 12.9;
          formattedPrice = '¥12.9';
          currencyCode = 'CNY';
          break;
        case 'SG': // 싱가포르
          rawPrice = 2.98;
          formattedPrice = 'S\$2.98';
          currencyCode = 'SGD';
          break;
        // 다른 동남아시아 국가들 (태국, 말레이시아, 인도네시아, 필리핀, 베트남)
        case 'TH':
        case 'MY':
        case 'ID':
        case 'PH':
        case 'VN':
          rawPrice = 0.99;
          formattedPrice = r'$0.99';
          currencyCode = 'USD';
          break;
        // 북미/유럽 국가들
        case 'US':
        case 'CA':
        case 'GB':
        case 'DE':
        case 'FR':
        case 'IT':
        case 'ES':
        case 'AU':
          rawPrice = 1.99;
          formattedPrice = r'$1.99';
          currencyCode = 'USD';
          break;
        // 남미, 인도, 아프리카 지역
        case 'BR':
        case 'MX':
        case 'AR':
        case 'IN':
        case 'ZA':
          rawPrice = 0.79;
          formattedPrice = r'$0.79';
          currencyCode = 'USD';
          break;
        default:
          // 기본 가격 유지
          break;
      }
    }

    return SubscriptionProduct(
      planType: SubscriptionPlanType.premiumMonthly,
      productId: 'premium_monthly',
      title: '월간 프리미엄',
      description: '모든 프리미엄 기능 매월 이용',
      price: formattedPrice,
      rawPrice: rawPrice,
      currencyCode: currencyCode,
      period: SubscriptionPeriod.monthly,
      tier: SubscriptionTier.premium,
      isMostPopular: true,
      countryCode: countryCode,
      features: const [
        '무제한 팬캠 시청',
        '모든 영상 이용 가능',
        '720p HD 화질',
        '광고 제거',
        '투표 2배 가중치',
      ],
    );
  }

  /// 연간 프리미엄 플랜 생성 팩토리 메서드
  factory SubscriptionProduct.yearlyPremium({String? countryCode}) {
    // 기본 가격 및 통화 (미국 기준)
    double rawPrice = 19.99;
    String formattedPrice = r'$19.99';
    String currencyCode = 'USD';

    // 국가별 가격 및 통화 설정
    if (countryCode != null) {
      // 아시아 지역 국가별 세부 가격
      switch (countryCode) {
        case 'KR': // 한국
          rawPrice = 24000;
          formattedPrice = '₩24,000';
          currencyCode = 'KRW';
          break;
        case 'JP': // 일본
          rawPrice = 2500;
          formattedPrice = '¥2,500';
          currencyCode = 'JPY';
          break;
        case 'CN': // 중국
          rawPrice = 129;
          formattedPrice = '¥129';
          currencyCode = 'CNY';
          break;
        case 'SG': // 싱가포르
          rawPrice = 29.98;
          formattedPrice = 'S\$29.98';
          currencyCode = 'SGD';
          break;
        // 다른 동남아시아 국가들 (태국, 말레이시아, 인도네시아, 필리핀, 베트남)
        case 'TH':
        case 'MY':
        case 'ID':
        case 'PH':
        case 'VN':
          rawPrice = 9.99;
          formattedPrice = r'$9.99';
          currencyCode = 'USD';
          break;
        // 북미/유럽 국가들
        case 'US':
        case 'CA':
        case 'GB':
        case 'DE':
        case 'FR':
        case 'IT':
        case 'ES':
        case 'AU':
          rawPrice = 19.99;
          formattedPrice = r'$19.99';
          currencyCode = 'USD';
          break;
        // 남미, 인도, 아프리카 지역
        case 'BR':
        case 'MX':
        case 'AR':
        case 'IN':
        case 'ZA':
          rawPrice = 7.99;
          formattedPrice = r'$7.99';
          currencyCode = 'USD';
          break;
        default:
          // 기본 가격 유지
          break;
      }
    }

    return SubscriptionProduct(
      planType: SubscriptionPlanType.premiumYearly,
      productId: 'premium_yearly',
      title: '연간 프리미엄',
      description: '월간 대비 2개월 무료 혜택',
      price: formattedPrice,
      rawPrice: rawPrice,
      currencyCode: currencyCode,
      period: SubscriptionPeriod.yearly,
      tier: SubscriptionTier.premium,
      isBestValue: true,
      countryCode: countryCode,
      features: const [
        '무제한 팬캠 시청',
        '모든 영상 이용 가능',
        '720p HD 화질',
        '광고 제거',
        '투표 2배 가중치',
        '월간 대비 17% 할인',
      ],
    );
  }

  /// JSON에서 변환
  factory SubscriptionProduct.fromJson(Map<String, dynamic> json) {
    return SubscriptionProduct(
      planType: SubscriptionPlanTypeExtension.fromString(json['plan_type'] as String? ?? 'free'),
      productId: json['product_id'] as String? ?? 'free',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] as String? ?? '',
      rawPrice: (json['raw_price'] as num?)?.toDouble() ?? 0.0,
      currencyCode: json['currency_code'] as String? ?? 'KRW',
      period: _periodFromString(json['period'] as String? ?? 'free'),
      tier: _tierFromString(json['tier'] as String? ?? 'free'),
      rawDetails: json['raw_details'] as String?,
      isMostPopular: json['is_most_popular'] as bool? ?? false,
      isBestValue: json['is_best_value'] as bool? ?? false,
      features: json['features'] as List<String>? ?? [],
      countryCode: json['country_code'] as String?,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'plan_type': planType.toString().split('.').last,
      'product_id': productId,
      'title': title,
      'description': description,
      'price': price,
      'raw_price': rawPrice,
      'currency_code': currencyCode,
      'period': period.toString().split('.').last,
      'tier': tier.toString().split('.').last,
      'raw_details': rawDetails,
      'is_most_popular': isMostPopular,
      'is_best_value': isBestValue,
      'features': features,
      'country_code': countryCode,
    };
  }

  /// 기간 문자열 변환
  static SubscriptionPeriod _periodFromString(String period) {
    switch (period) {
      case 'monthly':
        return SubscriptionPeriod.monthly;
      case 'yearly':
        return SubscriptionPeriod.yearly;
      case 'free':
      default:
        return SubscriptionPeriod.free;
    }
  }

  /// 티어 문자열 변환
  static SubscriptionTier _tierFromString(String tier) {
    switch (tier) {
      case 'basic':
        return SubscriptionTier.basic;
      case 'premium':
        return SubscriptionTier.premium;
      case 'free':
      default:
        return SubscriptionTier.free;
    }
  }

  @override
  List<Object?> get props => [
        planType,
        productId,
        title,
        description,
        price,
        rawPrice,
        currencyCode,
        period,
        tier,
      ];
}

/// 구독 상태 모델
class SubscriptionStatus extends Equatable {
  /// 구독 상태 생성자
  const SubscriptionStatus({
    required this.planType,
    required this.isActive,
    required this.state,
    this.expiryDate,
    this.willRenew = false,
    this.receiptData,
    this.purchaseDate,
    this.subscriptionId,
    this.platform = PaymentPlatform.none,
    this.additionalData = const {},
  });

  /// 구독한 플랜 타입
  final SubscriptionPlanType planType;

  /// 구독 활성화 여부
  final bool isActive;

  /// 구독 상태
  final SubscriptionState state;

  /// 구독 만료일
  final DateTime? expiryDate;

  /// 자동 갱신 여부
  final bool willRenew;

  /// 영수증 데이터 (검증 및 복원용, JSON 문자열)
  final String? receiptData;

  /// 최초 구독일
  final DateTime? purchaseDate;

  /// 구독 ID (스토어 제공)
  final String? subscriptionId;

  /// 결제 플랫폼
  final PaymentPlatform platform;

  /// 추가 데이터
  final Map<String, dynamic> additionalData;

  /// JSON에서 변환
  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      planType: SubscriptionPlanTypeExtension.fromString(json['plan_type'] as String? ?? 'free'),
      isActive: json['is_active'] as bool? ?? false,
      state: _stateFromString(json['state'] as String? ?? 'unknown'),
      expiryDate:
          json['expiry_date'] != null ? DateTime.parse(json['expiry_date'] as String) : null,
      willRenew: json['will_renew'] as bool? ?? false,
      receiptData: json['receipt_data'] as String?,
      purchaseDate:
          json['purchase_date'] != null ? DateTime.parse(json['purchase_date'] as String) : null,
      subscriptionId: json['subscription_id'] as String?,
      platform: _platformFromString(json['platform'] as String? ?? 'none'),
      additionalData: json['additional_data'] as Map<String, dynamic>? ?? {},
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'plan_type': planType.toString().split('.').last,
      'is_active': isActive,
      'state': state.toString().split('.').last,
      'expiry_date': expiryDate?.toIso8601String(),
      'will_renew': willRenew,
      'receipt_data': receiptData,
      'purchase_date': purchaseDate?.toIso8601String(),
      'subscription_id': subscriptionId,
      'platform': platform.toString().split('.').last,
      'additional_data': additionalData,
    };
  }

  /// 무료 플랜 상태 생성
  factory SubscriptionStatus.free() => SubscriptionStatus(
        planType: SubscriptionPlanType.free,
        isActive: true,
        state: SubscriptionState.active,
        willRenew: true,
        purchaseDate: DateTime.now(),
      );

  /// 상태 문자열 변환
  static SubscriptionState _stateFromString(String state) {
    switch (state) {
      case 'active':
        return SubscriptionState.active;
      case 'expired':
        return SubscriptionState.expired;
      case 'canceled':
        return SubscriptionState.canceled;
      case 'pending':
        return SubscriptionState.pending;
      case 'onHold':
        return SubscriptionState.onHold;
      case 'paused':
        return SubscriptionState.paused;
      case 'unknown':
      default:
        return SubscriptionState.unknown;
    }
  }

  /// 플랫폼 문자열 변환
  static PaymentPlatform _platformFromString(String platform) {
    switch (platform) {
      case 'appStore':
        return PaymentPlatform.appStore;
      case 'googlePlay':
        return PaymentPlatform.googlePlay;
      case 'web':
        return PaymentPlatform.web;
      case 'none':
      default:
        return PaymentPlatform.none;
    }
  }

  @override
  List<Object?> get props => [
        planType,
        isActive,
        state,
        expiryDate,
        willRenew,
        subscriptionId,
        platform,
      ];
}

/// 구독 트랜잭션 정보
class SubscriptionTransaction extends Equatable {
  /// 구독 트랜잭션 생성자
  const SubscriptionTransaction({
    required this.transactionId,
    required this.purchaseDate,
    required this.planType,
    required this.productId,
    required this.price,
    required this.currencyCode,
    required this.platform,
    this.receipt,
    this.orderId,
    this.packageName,
    this.userId,
    this.status,
  });

  /// 트랜잭션 ID
  final String transactionId;

  /// 구매일
  final DateTime purchaseDate;

  /// 구독 플랜 타입
  final SubscriptionPlanType planType;

  /// 상품 ID
  final String productId;

  /// 가격
  final double price;

  /// 통화 코드
  final String currencyCode;

  /// 결제 플랫폼
  final PaymentPlatform platform;

  /// 영수증 데이터
  final String? receipt;

  /// 주문 ID
  final String? orderId;

  /// 패키지명
  final String? packageName;

  /// 사용자 ID
  final String? userId;

  /// 구독 상태
  final SubscriptionStatus? status;

  /// JSON에서 변환
  factory SubscriptionTransaction.fromJson(Map<String, dynamic> json) {
    return SubscriptionTransaction(
      transactionId: json['transaction_id'] as String,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      planType: SubscriptionPlanTypeExtension.fromString(json['plan_type'] as String? ?? 'free'),
      productId: json['product_id'] as String,
      price: (json['price'] as num).toDouble(),
      currencyCode: json['currency_code'] as String,
      platform: SubscriptionStatus._platformFromString(json['platform'] as String? ?? 'none'),
      receipt: json['receipt'] as String?,
      orderId: json['order_id'] as String?,
      packageName: json['package_name'] as String?,
      userId: json['user_id'] as String?,
      status: json['status'] != null
          ? SubscriptionStatus.fromJson(json['status'] as Map<String, dynamic>)
          : null,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'purchase_date': purchaseDate.toIso8601String(),
      'plan_type': planType.toString().split('.').last,
      'product_id': productId,
      'price': price,
      'currency_code': currencyCode,
      'platform': platform.toString().split('.').last,
      'receipt': receipt,
      'order_id': orderId,
      'package_name': packageName,
      'user_id': userId,
      'status': status?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        transactionId,
        purchaseDate,
        planType,
        productId,
        price,
        currencyCode,
        platform,
      ];
}

/// 구독 결제 결과
abstract class SubscriptionPurchaseResult extends Equatable {
  /// 구독 결제 결과 생성자
  const SubscriptionPurchaseResult();

  /// 성공 결과
  const factory SubscriptionPurchaseResult.success({
    required SubscriptionTransaction transaction,
    required SubscriptionStatus status,
  }) = SubscriptionPurchaseSuccess;

  /// 취소 결과
  const factory SubscriptionPurchaseResult.canceled() = SubscriptionPurchaseCanceled;

  /// 오류 결과
  const factory SubscriptionPurchaseResult.error({
    required String code,
    required String message,
    dynamic details,
  }) = SubscriptionPurchaseError;

  /// JSON에서 변환
  factory SubscriptionPurchaseResult.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'success':
        return SubscriptionPurchaseSuccess(
          transaction:
              SubscriptionTransaction.fromJson(json['transaction'] as Map<String, dynamic>),
          status: SubscriptionStatus.fromJson(json['status'] as Map<String, dynamic>),
        );
      case 'canceled':
        return const SubscriptionPurchaseCanceled();
      case 'error':
      default:
        return SubscriptionPurchaseError(
          code: json['code'] as String? ?? 'unknown_error',
          message: json['message'] as String? ?? '알 수 없는 오류가 발생했습니다.',
          details: json['details'],
        );
    }
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson();
}

/// 구독 구매 성공 결과
class SubscriptionPurchaseSuccess extends SubscriptionPurchaseResult {
  /// 구독 구매 성공 결과 생성자
  const SubscriptionPurchaseSuccess({
    required this.transaction,
    required this.status,
  });

  /// 트랜잭션 정보
  final SubscriptionTransaction transaction;

  /// 구독 상태
  final SubscriptionStatus status;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'success',
      'transaction': transaction.toJson(),
      'status': status.toJson(),
    };
  }

  @override
  List<Object?> get props => [transaction, status];
}

/// 구독 구매 취소 결과
class SubscriptionPurchaseCanceled extends SubscriptionPurchaseResult {
  /// 구독 구매 취소 결과 생성자
  const SubscriptionPurchaseCanceled();

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'canceled',
    };
  }

  @override
  List<Object?> get props => [];
}

/// 구독 구매 오류 결과
class SubscriptionPurchaseError extends SubscriptionPurchaseResult {
  /// 구독 구매 오류 결과 생성자
  const SubscriptionPurchaseError({
    required this.code,
    required this.message,
    this.details,
  });

  /// 오류 코드
  final String code;

  /// 오류 메시지
  final String message;

  /// 오류 상세 정보
  final dynamic details;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'error',
      'code': code,
      'message': message,
      'details': details,
    };
  }

  @override
  List<Object?> get props => [code, message, details];
}

/// 구독 상품 혜택 모델
class SubscriptionBenefit extends Equatable {
  /// 구독 혜택 생성자
  const SubscriptionBenefit({
    required this.title,
    required this.description,
    required this.isAvailable,
    this.icon,
  });

  /// 혜택 제목
  final String title;

  /// 혜택 설명
  final String description;

  /// 제공 여부
  final bool isAvailable;

  /// 아이콘
  final String? icon;

  /// JSON에서 변환
  factory SubscriptionBenefit.fromJson(Map<String, dynamic> json) {
    return SubscriptionBenefit(
      title: json['title'] as String,
      description: json['description'] as String,
      isAvailable: json['is_available'] as bool,
      icon: json['icon'] as String?,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'is_available': isAvailable,
      'icon': icon,
    };
  }

  @override
  List<Object?> get props => [title, description, isAvailable, icon];
}

/// 구독 계획 (가격 정보 포함)
class SubscriptionPlan extends Equatable {
  /// 구독 계획 생성자
  const SubscriptionPlan({
    required this.type,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
    required this.period,
    required this.tier,
    this.benefits = const [],
    this.isMostPopular = false,
    this.isBestValue = false,
    this.trialDays = 0,
  });

  /// 플랜 타입
  final SubscriptionPlanType type;

  /// 제목
  final String title;

  /// 설명
  final String description;

  /// 가격 문자열 (형식: '₩7,900')
  final String price;

  /// 가격 (로컬 통화 기준)
  final double rawPrice;

  /// 통화 코드
  final String currencyCode;

  /// 구독 기간
  final SubscriptionPeriod period;

  /// 구독 등급
  final SubscriptionTier tier;

  /// 제공 혜택 목록
  final List<SubscriptionBenefit> benefits;

  /// 가장 인기 있는 플랜 여부
  final bool isMostPopular;

  /// 가장 가성비 좋은 플랜 여부
  final bool isBestValue;

  /// 무료 체험 기간 (일 수)
  final int trialDays;

  /// JSON에서 변환
  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      type: SubscriptionPlanTypeExtension.fromString(json['type'] as String? ?? 'free'),
      title: json['title'] as String,
      description: json['description'] as String,
      price: json['price'] as String,
      rawPrice: (json['raw_price'] as num).toDouble(),
      currencyCode: json['currency_code'] as String,
      period: SubscriptionProduct._periodFromString(json['period'] as String? ?? 'free'),
      tier: SubscriptionProduct._tierFromString(json['tier'] as String? ?? 'free'),
      benefits: (json['benefits'] as List<dynamic>?)
              ?.map((e) => SubscriptionBenefit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isMostPopular: json['is_most_popular'] as bool? ?? false,
      isBestValue: json['is_best_value'] as bool? ?? false,
      trialDays: json['trial_days'] as int? ?? 0,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'price': price,
      'raw_price': rawPrice,
      'currency_code': currencyCode,
      'period': period.toString().split('.').last,
      'tier': tier.toString().split('.').last,
      'benefits': benefits.map((e) => e.toJson()).toList(),
      'is_most_popular': isMostPopular,
      'is_best_value': isBestValue,
      'trial_days': trialDays,
    };
  }

  @override
  List<Object?> get props => [
        type,
        title,
        description,
        price,
        rawPrice,
        currencyCode,
        period,
        tier,
        benefits,
        isMostPopular,
        isBestValue,
        trialDays,
      ];
}
