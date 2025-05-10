import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/subscription/model/subscription_models.dart';
import 'package:mobile/features/subscription/services/subscription_service.dart';
import 'package:mobile/features/subscription/services/subscription_service_impl.dart';

/// 구독 서비스 프로바이더
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final service = InAppPurchaseService();

  // 서비스 초기화
  service.initialize();

  // 서비스 dispose 처리
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// 구독 상태 프로바이더
final subscriptionStatusProvider = Provider<SubscriptionStatus>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.currentStatus;
});

/// 구독 상품 목록 프로바이더
final subscriptionProductsProvider = Provider<List<SubscriptionProduct>>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return [
    SubscriptionProduct.free(),
    ...service.availableProducts,
  ];
});

/// 사용자 프리미엄 여부 프로바이더
final isPremiumUserProvider = Provider<bool>((ref) {
  final status = ref.watch(subscriptionStatusProvider);
  return status.isActive && status.planType != SubscriptionPlanType.free;
});

/// 구독 등급 프로바이더
final subscriptionTierProvider = Provider<SubscriptionTier>((ref) {
  final status = ref.watch(subscriptionStatusProvider);
  return status.planType.tier;
});

/// 특정 기능 사용 가능 여부 확인 프로바이더
final canUseFeatureProvider = Provider.family<bool, String>((ref, featureId) {
  final isPremium = ref.watch(isPremiumUserProvider);
  final tier = ref.watch(subscriptionTierProvider);

  // 기본 기능들 (무료 플랜에서도 사용 가능)
  const basicFeatures = [
    'basic_videos',
    'standard_quality',
    'limited_search',
  ];

  // 베이직 플랜 기능
  const basicPlanFeatures = [
    'ad_free',
    'hd_videos',
    'unlimited_search',
  ];

  // 프리미엄 전용 기능
  const premiumOnlyFeatures = [
    'offline_downloads',
    'exclusive_content',
    '4k_videos',
  ];

  // 해당 기능이 무료 플랜에서 사용 가능한지 확인
  if (basicFeatures.contains(featureId)) {
    return true;
  }

  // 베이직 플랜 이상에서 사용 가능한 기능
  if (basicPlanFeatures.contains(featureId)) {
    return isPremium; // 베이직 또는 프리미엄
  }

  // 프리미엄 전용 기능
  if (premiumOnlyFeatures.contains(featureId)) {
    return tier == SubscriptionTier.premium;
  }

  // 알 수 없는 기능은 기본적으로 허용하지 않음
  return false;
});

/// 구독 관리 Notifier
class SubscriptionNotifier extends StateNotifier<SubscriptionStatus> {
  /// 생성자
  SubscriptionNotifier(this._service) : super(SubscriptionStatus.free()) {
    _initialize();
  }

  final SubscriptionService _service;
  bool _isLoading = false;
  String? _error;

  /// 로딩 상태 getter
  bool get isLoading => _isLoading;

  /// 오류 메시지 getter
  String? get error => _error;

  /// 초기화
  Future<void> _initialize() async {
    try {
      _isLoading = true;
      final status = await _service.checkSubscriptionStatus();
      state = status;
      _error = null;
    } catch (e) {
      _error = '구독 상태를 확인하는 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
    }
  }

  /// 구독 구매
  Future<bool> purchase(SubscriptionProduct product) async {
    try {
      _isLoading = true;
      _error = null;

      final result = await _service.purchase(product);
      if (result) {
        // 구독 상태 갱신
        final status = await _service.checkSubscriptionStatus();
        state = status;
        return true;
      } else {
        _error = '구독 구매에 실패했습니다.';
        return false;
      }
    } catch (e) {
      _error = '구독 구매 중 오류가 발생했습니다: $e';
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// 구독 복원
  Future<bool> restore() async {
    try {
      _isLoading = true;
      _error = null;

      final result = await _service.restorePurchases();
      if (result) {
        // 구독 상태 갱신
        final status = await _service.checkSubscriptionStatus();
        state = status;
        return true;
      } else {
        _error = '구독 복원에 실패했습니다.';
        return false;
      }
    } catch (e) {
      _error = '구독 복원 중 오류가 발생했습니다: $e';
      return false;
    } finally {
      _isLoading = false;
    }
  }

  /// 구독 상태 새로고침
  Future<void> refresh() async {
    await _initialize();
  }
}

/// 구독 Notifier 프로바이더
final subscriptionNotifierProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionStatus>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return SubscriptionNotifier(service);
});
