import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/locale_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/subscription_models.dart';

/// 구독 서비스 프로바이더
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  // 실제 환경에서는 실제 구현 사용, 개발 환경에서는 Mock 사용
  if (kReleaseMode) {
    return InAppSubscriptionService();
  }
  return MockSubscriptionService();
});

/// 구독 서비스 인터페이스
abstract class SubscriptionService {
  /// 구독 상태 확인
  Future<SubscriptionStatus> checkSubscriptionStatus();

  /// 구독 상품 목록 가져오기
  Future<List<SubscriptionProduct>> getSubscriptionProducts();

  /// 구독 구매
  Future<bool> purchaseSubscription(SubscriptionProduct product);

  /// 구매 복원
  Future<bool> restorePurchases();

  /// 구독 관리 페이지 열기
  Future<bool> openManageSubscriptions();

  /// 구독 취소
  Future<bool> cancelSubscription();
}

/// Mock 구독 서비스 구현
class MockSubscriptionService implements SubscriptionService {
  bool _isPremium = false;
  DateTime? _expiryDate;

  @override
  Future<SubscriptionStatus> checkSubscriptionStatus() async {
    // 실제 구현에서는 인앱 결제 API 통신을 수행
    await Future.delayed(const Duration(milliseconds: 500));

    // Supabase 클라이언트에서 현재 사용자 확인
    final currentUser = Supabase.instance.client.auth.currentUser;

    // 관리자 이메일인 경우 무조건 프리미엄 상태로 반환
    if (currentUser != null && currentUser.email == 'loupslim@gmail.com') {
      return SubscriptionStatus(
        planType: SubscriptionPlanType.premiumYearly,
        isActive: true,
        state: SubscriptionState.active,
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
      );
    }

    return SubscriptionStatus(
      planType: _isPremium ? SubscriptionPlanType.premiumMonthly : SubscriptionPlanType.free,
      isActive: _isPremium,
      state: SubscriptionState.active,
      expiryDate: _expiryDate,
      purchaseDate: _isPremium ? DateTime.now().subtract(const Duration(days: 5)) : null,
    );
  }

  @override
  Future<List<SubscriptionProduct>> getSubscriptionProducts() async {
    // 목업 데이터 반환
    await Future.delayed(const Duration(milliseconds: 300));

    // LocaleService에서 사용자 지역 정보 가져오기
    final userRegion = await LocaleService.getUserRegion();

    // 지역별 국가 코드 매핑
    String? countryCode;

    switch (userRegion) {
      case LocaleService.regionNaEu:
        // 북미/유럽 지역은 기본 가격 사용 (미국 기준)
        countryCode = 'US';
        break;
      case LocaleService.regionAsia:
        // 아시아 지역 가격 사용 (한국 기준)
        countryCode = 'KR';
        break;
      case LocaleService.regionOthers:
        // 기타 지역 가격 사용 (인도 기준)
        countryCode = 'IN';
        break;
      default:
        countryCode = 'US';
    }

    debugPrint('Mock 서비스 - 사용자 지역: $userRegion, 국가 코드: $countryCode');

    return [
      SubscriptionProduct.free(),
      SubscriptionProduct.monthlyPremium(countryCode: countryCode),
      SubscriptionProduct.yearlyPremium(countryCode: countryCode),
    ];
  }

  @override
  Future<bool> purchaseSubscription(SubscriptionProduct product) async {
    // 플랫폼 확인
    if (Platform.isIOS) {
      // iOS 플랫폼에서의 구독 처리
      debugPrint('iOS 플랫폼에서 구독 구매 시작: ${product.productId}');

      // 실제 구현에서는 StoreKit 통합 구현
      await Future.delayed(const Duration(seconds: 1));

      // 구매 성공 시뮬레이션 (iOS용 로그 추가)
      _isPremium = true;

      if (product.planType == SubscriptionPlanType.premiumMonthly) {
        _expiryDate = DateTime.now().add(const Duration(days: 30));
      } else if (product.planType == SubscriptionPlanType.premiumYearly) {
        _expiryDate = DateTime.now().add(const Duration(days: 365));
      }

      debugPrint('iOS 앱스토어 구독 성공: ${product.productId}');
      return true;
    } else if (Platform.isAndroid) {
      // Android 플랫폼에서의 구독 처리
      debugPrint('Android 플랫폼에서 구독 구매 시작: ${product.productId}');

      // 실제 구현에서는 Google Play Billing 통합 구현
      await Future.delayed(const Duration(seconds: 1));

      // 구매 성공 시뮬레이션 (Android용 로그 추가)
      _isPremium = true;

      if (product.planType == SubscriptionPlanType.premiumMonthly) {
        _expiryDate = DateTime.now().add(const Duration(days: 30));
      } else if (product.planType == SubscriptionPlanType.premiumYearly) {
        _expiryDate = DateTime.now().add(const Duration(days: 365));
      }

      debugPrint('Google Play 구독 성공: ${product.productId}');
      return true;
    } else {
      // 웹이나 기타 플랫폼에서의 처리
      debugPrint('지원되지 않는 플랫폼에서 구독 구매 시도: ${product.productId}');

      // 테스트를 위한 간단한 구현
      await Future.delayed(const Duration(seconds: 1));

      // 구매 성공 시뮬레이션
      _isPremium = true;

      if (product.planType == SubscriptionPlanType.premiumMonthly) {
        _expiryDate = DateTime.now().add(const Duration(days: 30));
      } else if (product.planType == SubscriptionPlanType.premiumYearly) {
        _expiryDate = DateTime.now().add(const Duration(days: 365));
      }

      return true;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    // 실제 구현에서는 인앱 결제 API 통신을 수행
    await Future.delayed(const Duration(seconds: 1));

    // 복원 성공 시뮬레이션 (랜덤)
    final success = DateTime.now().millisecond % 2 == 0;

    if (success) {
      _isPremium = true;
      _expiryDate = DateTime.now().add(const Duration(days: 30));
    }

    return success;
  }

  @override
  Future<bool> cancelSubscription() async {
    // 실제 구현에서는 구독 취소 API 호출
    await Future.delayed(const Duration(seconds: 1));

    // 취소 성공 시뮬레이션
    // 구독이 즉시 취소되지 않고 만료일까지 유지되는 것이 일반적이므로
    // _isPremium은 변경하지 않고 취소 처리 여부만 반환
    return true;
  }

  @override
  Future<bool> openManageSubscriptions() async {
    // 실제 구현에서는 앱스토어나 구글플레이 구독 관리 페이지로 이동
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // 플랫폼별 스토어 URL
      final Uri storeUrl;

      if (Platform.isIOS) {
        // iOS: 앱스토어 구독 관리 페이지
        storeUrl = Uri.parse('https://apps.apple.com/account/subscriptions');
      } else if (Platform.isAndroid) {
        // Android: 구글 플레이 구독 관리 페이지
        storeUrl = Uri.parse('https://play.google.com/store/account/subscriptions');
      } else {
        // 웹이나 다른 플랫폼은 지원하지 않음
        return false;
      }

      // URL 열기
      final result = await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
      return result;
    } catch (e) {
      // 실패한 경우 false 반환
      return false;
    }
  }
}

/// 인앱 결제 기반 구독 서비스 (실제 구현)
class InAppSubscriptionService implements SubscriptionService {
  // 싱글톤 패턴
  static final InAppSubscriptionService _instance = InAppSubscriptionService._internal();
  factory InAppSubscriptionService() => _instance;
  InAppSubscriptionService._internal();

  // 여기에 실제 인앱 결제 관련 구현을 추가
  // 현재는 Mock과 동일하게 작동하는 기본 구현만 제공

  @override
  Future<SubscriptionStatus> checkSubscriptionStatus() async {
    // 실제 구현에서는 인앱 결제 상태 확인 로직 구현
    await Future.delayed(const Duration(milliseconds: 500));

    return SubscriptionStatus.free();
  }

  @override
  Future<bool> cancelSubscription() async {
    // 실제 구현에서는 구독 취소 처리
    return openManageSubscriptions();
  }

  @override
  Future<List<SubscriptionProduct>> getSubscriptionProducts() async {
    // 실제 구현에서는 스토어에서 상품 정보 조회
    await Future.delayed(const Duration(milliseconds: 500));

    // LocaleService에서 사용자 지역 정보 가져오기
    final userRegion = await LocaleService.getUserRegion();

    // 지역별 국가 코드 매핑
    String? countryCode;

    switch (userRegion) {
      case LocaleService.regionNaEu:
        // 북미/유럽 지역은 기본 가격 사용 (미국 기준)
        countryCode = 'US';
        break;
      case LocaleService.regionAsia:
        // 아시아 지역 가격 사용 (싱가포르 기준)
        countryCode = 'SG';
        break;
      case LocaleService.regionOthers:
        // 기타 지역 가격 사용 (인도 기준)
        countryCode = 'IN';
        break;
      default:
        // 로케일이나 플랫폼 기본 정보로 폴백
        if (Platform.isIOS || Platform.isAndroid) {
          countryCode = Platform.localeName.split('_').last;
        }
    }

    debugPrint('사용자 지역: $userRegion, 국가 코드: $countryCode');

    return [
      SubscriptionProduct.free(),
      SubscriptionProduct.monthlyPremium(countryCode: countryCode),
      SubscriptionProduct.yearlyPremium(countryCode: countryCode),
    ];
  }

  @override
  Future<bool> openManageSubscriptions() async {
    try {
      final Uri storeUrl;

      if (Platform.isIOS) {
        storeUrl = Uri.parse('https://apps.apple.com/account/subscriptions');
      } else if (Platform.isAndroid) {
        storeUrl = Uri.parse('https://play.google.com/store/account/subscriptions');
      } else {
        return false;
      }

      return await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('구독 관리 페이지 열기 실패: $e');
      return false;
    }
  }

  @override
  Future<bool> purchaseSubscription(SubscriptionProduct product) async {
    // 플랫폼 확인
    if (Platform.isIOS) {
      // iOS 플랫폼에서의 구독 처리
      debugPrint('iOS 플랫폼에서 인앱 결제 구독 구매 시작: ${product.productId}');

      try {
        // 실제 구현에서는 StoreKit API 호출
        // 구현 예시:
        // final productDetails = await InAppPurchase.instance.queryProductDetails({product.productId});
        // final purchaseParam = PurchaseParam(productDetails: productDetails.first);
        // await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);

        // 시뮬레이션을 위한 지연
        await Future.delayed(const Duration(seconds: 1));

        // 성공 시뮬레이션
        debugPrint('iOS 앱스토어 구독 성공 (시뮬레이션): ${product.productId}');
        return true;
      } catch (e) {
        debugPrint('iOS 인앱 결제 오류: $e');
        return false;
      }
    } else if (Platform.isAndroid) {
      // Android 플랫폼에서의 구독 처리
      debugPrint('Android 플랫폼에서 인앱 결제 구독 구매 시작: ${product.productId}');

      try {
        // 실제 구현에서는 Google Play Billing API 호출
        // 구현 예시:
        // final productDetails = await InAppPurchase.instance.queryProductDetails({product.productId});
        // final purchaseParam = PurchaseParam(productDetails: productDetails.first);
        // await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);

        // 시뮬레이션을 위한 지연
        await Future.delayed(const Duration(seconds: 1));

        // 성공 시뮬레이션
        debugPrint('Google Play 구독 성공 (시뮬레이션): ${product.productId}');
        return true;
      } catch (e) {
        debugPrint('Android 인앱 결제 오류: $e');
        return false;
      }
    } else {
      // 웹이나 기타 플랫폼에서의 처리
      debugPrint('지원되지 않는 플랫폼에서 구독 구매 시도: ${product.productId}');
      await Future.delayed(const Duration(seconds: 1));
      return false;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    // 실제 구현에서는 이전 구매 복원
    await Future.delayed(const Duration(seconds: 1));
    return false; // 실제 구현에서는 복원 결과에 따라 반환
  }
}
