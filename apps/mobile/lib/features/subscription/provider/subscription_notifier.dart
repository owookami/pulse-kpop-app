import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/subscription/model/subscription_models.dart';
import 'package:mobile/features/subscription/services/subscription_service.dart';

/// 구독 서비스 프로바이더
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  // 실제 환경에서는 적절한 SubscriptionService 구현체를 사용
  // 테스트용으로 MockSubscriptionService 사용
  final service = MockSubscriptionService();

  // 서비스 초기화
  service.initialize();

  // 서비스 객체가 해제될 때 정리 작업 수행
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
  return service.availableProducts;
});

/// 프리미엄 사용자 여부 프로바이더
final isPremiumUserProvider = Provider<bool>((ref) {
  final status = ref.watch(subscriptionStatusProvider);
  return status.isActive &&
      status.planType != SubscriptionPlanType.free &&
      (status.expiryDate == null || status.expiryDate!.isAfter(DateTime.now()));
});

/// 구독 액션 상태
class SubscriptionAction {
  const SubscriptionAction({
    this.isLoading = false,
    this.isSuccess = false,
    this.isError = false,
    this.errorMessage,
  });

  /// 로딩 중 여부
  final bool isLoading;

  /// 성공 여부
  final bool isSuccess;

  /// 오류 발생 여부
  final bool isError;

  /// 오류 메시지
  final String? errorMessage;

  /// 상태 복사
  SubscriptionAction copyWith({
    bool? isLoading,
    bool? isSuccess,
    bool? isError,
    String? errorMessage,
  }) {
    return SubscriptionAction(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 초기 상태
  static const initial = SubscriptionAction();
}

/// 구독 액션 노티파이어
class SubscriptionNotifier extends StateNotifier<SubscriptionAction> {
  /// 생성자
  SubscriptionNotifier(this._subscriptionService) : super(SubscriptionAction.initial);

  /// 구독 서비스 인스턴스
  final SubscriptionService _subscriptionService;

  /// 상품 구매
  Future<void> purchase(SubscriptionProduct product) async {
    // 이미 처리 중이면 무시
    if (state.isLoading) return;

    // 로딩 상태로 변경
    state = state.copyWith(isLoading: true, isError: false, isSuccess: false);

    try {
      // 구매 처리
      final success = await _subscriptionService.purchase(product);

      if (success) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          isError: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: '구매에 실패했습니다. 다시 시도해 주세요.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: '구매 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  /// 구매 내역 복원
  Future<void> restorePurchases() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, isError: false, isSuccess: false);

    try {
      final success = await _subscriptionService.restorePurchases();

      if (success) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          isError: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: '구매 내역을 복원할 수 없습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: '구매 내역 복원 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }

  /// 상태 초기화
  void resetState() {
    state = SubscriptionAction.initial;
  }
}

/// 구독 노티파이어 프로바이더
final subscriptionNotifierProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionAction>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return SubscriptionNotifier(service);
});
