import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/subscription/model/subscription_model.dart';
import 'package:mobile/features/subscription/service/subscription_service.dart';

/// 구독 서비스 프로바이더
final subscriptionServiceProvider = Provider<MockSubscriptionService>((ref) {
  return MockSubscriptionService();
});

/// 구독 상태 프로바이더
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return SubscriptionNotifier(service);
});

/// 구독 상품 프로바이더
final subscriptionProductsProvider = FutureProvider<List<SubscriptionProduct>>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getSubscriptionProducts();
});

/// 프리미엄 여부 프로바이더
final isPremiumProvider = Provider<bool>((ref) {
  final state = ref.watch(subscriptionProvider);
  return state.isPremium;
});

/// 구독 상태 Notifier
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  /// 생성자
  SubscriptionNotifier(this._service) : super(const SubscriptionState()) {
    _initialize();
  }

  final MockSubscriptionService _service;

  /// 초기화
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);
      final status = await _service.checkSubscriptionStatus();
      state = status;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '구독 상태를 확인하는 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 구독 구매
  Future<bool> purchase(SubscriptionProduct product) async {
    try {
      state = state.toLoading();
      final result = await _service.purchaseSubscription(product);
      if (result) {
        // 구독 상태 갱신
        final status = await _service.checkSubscriptionStatus();
        state = status;
        return true;
      } else {
        state = state.toError('구독 구매에 실패했습니다.');
        return false;
      }
    } catch (e) {
      state = state.toError('구독 구매 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 구독 복원
  Future<bool> restore() async {
    try {
      state = state.toLoading();
      final result = await _service.restorePurchases();
      if (result) {
        // 구독 상태 갱신
        final status = await _service.checkSubscriptionStatus();
        state = status;
        return true;
      } else {
        state = state.toError('구독 복원에 실패했습니다.');
        return false;
      }
    } catch (e) {
      state = state.toError('구독 복원 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 구독 해지 설정 페이지 열기
  Future<bool> openManageSubscriptions() async {
    try {
      return await _service.openManageSubscriptions();
    } catch (e) {
      state = state.toError('구독 관리 페이지를 열 수 없습니다: $e');
      return false;
    }
  }

  /// 구독 취소
  Future<bool> cancelSubscription() async {
    try {
      state = state.toLoading();
      final result = await _service.cancelSubscription();

      if (result) {
        // 구독 상태 갱신 (구독은 기간 만료 시까지 유지됨)
        final status = await _service.checkSubscriptionStatus();
        state = status.copyWith(isCancelled: true);
        return true;
      } else {
        state = state.toError('구독 취소에 실패했습니다.');
        return false;
      }
    } catch (e) {
      state = state.toError('구독 취소 중 오류가 발생했습니다: $e');
      return false;
    }
  }

  /// 구독 상태 새로고침
  Future<void> refreshSubscription() async {
    await _initialize();
  }
}
