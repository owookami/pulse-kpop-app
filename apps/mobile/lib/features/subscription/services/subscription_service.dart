// 구독 서비스 구현
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mobile/features/subscription/model/subscription_product.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* 
 * # 팬캠 서비스 구독 시스템 구현
 * 
 * 이 모듈은 모바일 앱에서 인앱 결제를 통한 구독 시스템을 구현합니다.
 * 
 * ## 구조
 * 
 * 1. 모델 (model/)
 *    - `subscription_product.dart`: 구독 상품 및 구독 상태 모델
 *    - SubscriptionPlanType, SubscriptionPeriod, SubscriptionTier 등의 열거형
 * 
 * 2. 서비스 (services/)
 *    - `subscription_service.dart`: 구독 서비스 인터페이스 및 구현체
 *    - MockSubscriptionService는 테스트용으로 실제 결제 없이 구독 기능 테스트 가능
 * 
 * 3. 프로바이더 (provider/)
 *    - `subscription_notifier.dart`: Riverpod 프로바이더 및 노티파이어
 *    - subscriptionServiceProvider, subscriptionStatusProvider, isPremiumUserProvider 등
 * 
 * 4. 화면 (view/)
 *    - `subscription_screen.dart`: 구독 상품 선택 및 구매 화면
 * 
 * ## 사용 방법
 * 
 * 1. 구독 상태 확인
 *    ```dart
 *    final isPremium = ref.watch(isPremiumUserProvider);
 *    ```
 * 
 * 2. 구독 화면으로 이동
 *    ```dart
 *    context.go(AppRoutes.subscriptionPlans);
 *    ```
 * 
 * 3. 특정 기능에 프리미엄 제한 추가
 *    ```dart
 *    if (!ref.read(isPremiumUserProvider)) {
 *      // 프리미엄 기능 제한 처리
 *      showPremiumFeatureDialog(context);
 *      return;
 *    }
 *    ```
 *
 * ## 구독 시스템 구현 요약
 *
 * 1. 필요한 패키지 의존성:
 *    - in_app_purchase: 인앱 결제 처리
 *    - in_app_purchase_android: 안드로이드 결제 처리
 *    - in_app_purchase_storekit: iOS 결제 처리
 *    - shared_preferences: 구독 상태 저장
 *
 * 2. 앱에 다음 사항 추가:
 *    - 안드로이드: `AndroidManifest.xml`에 결제 권한 추가
 *    - iOS: `Info.plist`에 인앱 결제 관련 설정 추가
 *    - 스토어에 구독 상품 등록 및 설정
 *
 * 3. 주의 사항:
 *    - 서버 측 영수증 검증 로직 구현 필요
 *    - 멀티 플랫폼 지원을 위한 조건부 로직 사용
 *    - 보안 이슈 방지를 위한 서버 통신 구현
 */

/// 구독 서비스 인터페이스
abstract class SubscriptionService {
  /// 현재 구독 상태
  SubscriptionStatus get currentStatus;

  /// 이용 가능한 구독 상품 목록
  List<SubscriptionProduct> get availableProducts;

  /// 구매 업데이트 스트림
  Stream<SubscriptionPurchaseResult> get purchaseUpdated;

  /// 서비스 초기화
  Future<void> initialize();

  /// 상품 구매
  Future<bool> purchase(SubscriptionProduct product);

  /// 이전 구매 복원
  Future<bool> restorePurchases();

  /// 구독 상태 확인
  Future<SubscriptionStatus> checkSubscriptionStatus();

  /// 영수증 검증
  Future<bool> verifyReceipt(String receiptData);

  /// 리소스 해제
  void dispose();
}

/// 모의 구독 서비스 (실제 결제 없이 테스트 가능)
class MockSubscriptionService implements SubscriptionService {
  /// 생성자
  MockSubscriptionService() {
    _initialize();
  }

  /// 테스트용 상품 목록
  final List<SubscriptionProduct> _products = [
    SubscriptionProduct.free(),
    const SubscriptionProduct(
      planType: SubscriptionPlanType.basicMonthly,
      productId: 'com.zan.pulse.basic.monthly',
      title: '베이직 월간 구독',
      description: '기본 기능과 광고 제거',
      price: '₩4,900',
      rawPrice: 4900,
      currencyCode: 'KRW',
      period: SubscriptionPeriod.monthly,
      tier: SubscriptionTier.basic,
    ),
    const SubscriptionProduct(
      planType: SubscriptionPlanType.basicYearly,
      productId: 'com.zan.pulse.basic.yearly',
      title: '베이직 연간 구독',
      description: '기본 기능과 광고 제거 (16% 할인)',
      price: '₩49,000',
      rawPrice: 49000,
      currencyCode: 'KRW',
      period: SubscriptionPeriod.yearly,
      tier: SubscriptionTier.basic,
    ),
    const SubscriptionProduct(
      planType: SubscriptionPlanType.premiumMonthly,
      productId: 'com.zan.pulse.premium.monthly',
      title: '프리미엄 월간 구독',
      description: '모든 프리미엄 기능 이용 가능',
      price: '₩9,900',
      rawPrice: 9900,
      currencyCode: 'KRW',
      period: SubscriptionPeriod.monthly,
      tier: SubscriptionTier.premium,
    ),
    const SubscriptionProduct(
      planType: SubscriptionPlanType.premiumYearly,
      productId: 'com.zan.pulse.premium.yearly',
      title: '프리미엄 연간 구독',
      description: '모든 프리미엄 기능 이용 가능 (16% 할인)',
      price: '₩99,000',
      rawPrice: 99000,
      currencyCode: 'KRW',
      period: SubscriptionPeriod.yearly,
      tier: SubscriptionTier.premium,
    ),
  ];

  /// 현재 구독 상태
  SubscriptionStatus _currentStatus = SubscriptionStatus.free();
  @override
  SubscriptionStatus get currentStatus => _currentStatus;

  @override
  List<SubscriptionProduct> get availableProducts => _products;

  // 구매 업데이트 스트림 컨트롤러
  final _purchaseUpdatedController = StreamController<SubscriptionPurchaseResult>.broadcast();

  /// 구매 업데이트 스트림
  @override
  Stream<SubscriptionPurchaseResult> get purchaseUpdated => _purchaseUpdatedController.stream;

  /// 서비스 초기화
  void _initialize() {
    _loadSubscriptionStatus();
  }

  @override
  Future<void> initialize() async {
    await _loadSubscriptionStatus();
  }

  /// 저장된 구독 상태 로드
  Future<void> _loadSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString('subscription_status');

      if (statusJson != null) {
        final json = jsonDecode(statusJson) as Map<String, dynamic>;
        _currentStatus = SubscriptionStatus.fromJson(json);
        debugPrint('구독 상태 로드: ${_currentStatus.planType}');
      } else {
        _currentStatus = SubscriptionStatus.free();
      }
    } catch (e) {
      debugPrint('구독 상태 로드 오류: $e');
      _currentStatus = SubscriptionStatus.free();
    }
  }

  /// 구독 상태 저장
  Future<void> _saveSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = jsonEncode(_currentStatus.toJson());
      await prefs.setString('subscription_status', statusJson);
    } catch (e) {
      debugPrint('구독 상태 저장 오류: $e');
    }
  }

  @override
  Future<bool> purchase(SubscriptionProduct product) async {
    // 테스트용으로 항상 성공 반환
    final now = DateTime.now();
    DateTime expiryDate;

    // 만료일 계산
    if (product.period == SubscriptionPeriod.monthly) {
      expiryDate = DateTime(now.year, now.month + 1, now.day);
    } else if (product.period == SubscriptionPeriod.yearly) {
      expiryDate = DateTime(now.year + 1, now.month, now.day);
    } else {
      // 무료 플랜은 만료일 없음
      _currentStatus = SubscriptionStatus.free();
      await _saveSubscriptionStatus();
      return true;
    }

    // 새 구독 상태 설정
    _currentStatus = SubscriptionStatus(
      planType: product.planType,
      isActive: true,
      state: SubscriptionState.active,
      expiryDate: expiryDate,
      willRenew: true,
      receiptData: 'mock_receipt_data_${DateTime.now().millisecondsSinceEpoch}',
      purchaseDate: now,
      subscriptionId: 'mock_subscription_${DateTime.now().millisecondsSinceEpoch}',
    );

    // 구독 상태 저장
    await _saveSubscriptionStatus();
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    // 모의 구현에서는 현재 상태 유지
    return true;
  }

  @override
  Future<SubscriptionStatus> checkSubscriptionStatus() async {
    // 만료 여부 확인
    if (_currentStatus.expiryDate != null &&
        _currentStatus.expiryDate!.isBefore(DateTime.now()) &&
        _currentStatus.planType != SubscriptionPlanType.free) {
      _currentStatus = SubscriptionStatus.free();
      await _saveSubscriptionStatus();
    }
    return _currentStatus;
  }

  @override
  Future<bool> verifyReceipt(String receiptData) async {
    // 모의 구현에서는 항상 true 반환
    return true;
  }

  @override
  void dispose() {
    // 리소스 정리
    _purchaseUpdatedController.close();
  }
}
