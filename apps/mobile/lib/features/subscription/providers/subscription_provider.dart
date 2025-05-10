import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/subscription/model/subscription_models.dart';
import 'package:mobile/features/subscription/service/subscription_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 구독 상태 프로바이더
final subscriptionStateProvider =
    StateNotifierProvider<SubscriptionStateNotifier, AsyncValue<SubscriptionStatus>>((ref) {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return SubscriptionStateNotifier(subscriptionService);
});

/// 구독 상품 목록 프로바이더
final subscriptionProductsProvider = FutureProvider<List<SubscriptionProduct>>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return subscriptionService.getSubscriptionProducts();
});

/// 현재 구독 활성화 여부 프로바이더
final hasActiveSubscriptionProvider = Provider<bool>((ref) {
  // 현재 사용자 확인
  final currentUser = Supabase.instance.client.auth.currentUser;

  // loupslim@gmail.com 계정인 경우 항상 구독 활성화로 처리
  if (currentUser != null && currentUser.email == 'loupslim@gmail.com') {
    return true;
  }

  final subscriptionState = ref.watch(subscriptionStateProvider);
  return subscriptionState.valueOrNull?.isActive ?? false;
});

/// 무료 시청 가능 여부 판단 프로바이더
final canWatchFreeVideosProvider = Provider<bool>((ref) {
  // 현재 사용자 확인
  final currentUser = Supabase.instance.client.auth.currentUser;

  // loupslim@gmail.com 계정인 경우 항상 무료 시청 가능으로 처리
  if (currentUser != null && currentUser.email == 'loupslim@gmail.com') {
    return true;
  }

  // 실제 구현에서는 남은 무료 시청 횟수에 따라 판단
  final freeWatchCount = ref.watch(freeVideoWatchCountProvider);
  return freeWatchCount > 0;
});

/// 남은 무료 시청 횟수 프로바이더 (예시)
final freeVideoWatchCountProvider = StateProvider<int>((ref) {
  // 현재 사용자 확인
  final currentUser = Supabase.instance.client.auth.currentUser;

  // loupslim@gmail.com 계정인 경우 무제한 시청 가능(큰 값 사용)
  if (currentUser != null && currentUser.email == 'loupslim@gmail.com') {
    return 9999;
  }

  // 일반적으로 한 달에 10회 정도로 설정
  return 10;
});

/// 구독 상태 관리 노티파이어
class SubscriptionStateNotifier extends StateNotifier<AsyncValue<SubscriptionStatus>> {
  final SubscriptionService _subscriptionService;

  SubscriptionStateNotifier(this._subscriptionService) : super(const AsyncValue.loading()) {
    _init();
  }

  /// 초기화
  Future<void> _init() async {
    await _checkSubscriptionStatus();
  }

  /// 구독 상태 확인
  Future<void> _checkSubscriptionStatus() async {
    state = const AsyncValue.loading();
    try {
      final subscriptionState = await _subscriptionService.checkSubscriptionStatus();
      state = AsyncValue.data(subscriptionState);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 구독 구매
  Future<bool> purchase(SubscriptionProduct product) async {
    state = const AsyncValue.loading();
    try {
      final success = await _subscriptionService.purchaseSubscription(product);
      if (success) {
        await _checkSubscriptionStatus();
      }
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// 구매 복원
  Future<bool> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      final success = await _subscriptionService.restorePurchases();
      await _checkSubscriptionStatus();
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// 구독 취소
  Future<bool> cancelSubscription() async {
    try {
      return await _subscriptionService.cancelSubscription();
    } catch (e) {
      return false;
    }
  }

  /// 구독 관리 페이지 열기
  Future<bool> openManageSubscriptions() async {
    try {
      return await _subscriptionService.openManageSubscriptions();
    } catch (e) {
      return false;
    }
  }

  /// 구독 상태 새로고침
  Future<void> refresh() async {
    await _checkSubscriptionStatus();
  }

  /// 무료 영상 시청 시 카운트 감소
  void decreaseFreeWatchCount(Ref ref) {
    // 현재 사용자 확인
    final currentUser = Supabase.instance.client.auth.currentUser;

    // loupslim@gmail.com 계정인 경우 무료 시청 횟수를 감소시키지 않음
    if (currentUser != null && currentUser.email == 'loupslim@gmail.com') {
      return;
    }

    // 이미 구독 중이면 무료 시청 횟수를 감소시키지 않음
    if (state.valueOrNull?.isActive ?? false) return;

    final currentCount = ref.read(freeVideoWatchCountProvider);
    if (currentCount > 0) {
      ref.read(freeVideoWatchCountProvider.notifier).state = currentCount - 1;
    }
  }
}
