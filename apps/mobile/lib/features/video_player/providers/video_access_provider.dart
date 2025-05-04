import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/subscription/providers/subscription_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 비디오 접근 결과 타입
enum VideoAccessResult {
  /// 접근 가능
  allowed,

  /// 구독 필요
  requiresSubscription,

  /// 무료 시청 횟수 초과
  noFreeViews,
}

/// 비디오 접근 확인 서비스 프로바이더
final videoAccessProvider = Provider.family<VideoAccessResult, String>((ref, videoId) {
  // 현재 사용자 확인
  final currentUser = Supabase.instance.client.auth.currentUser;

  // loupslim@gmail.com 계정인 경우 항상 접근 허용
  if (currentUser != null && currentUser.email == 'loupslim@gmail.com') {
    return VideoAccessResult.allowed;
  }

  // 구독 상태 확인
  final hasSubscription = ref.watch(hasActiveSubscriptionProvider);

  // 구독 중이면 항상 접근 허용
  if (hasSubscription) {
    return VideoAccessResult.allowed;
  }

  // 무료 시청 가능 여부 확인
  final canWatchFree = ref.watch(canWatchFreeVideosProvider);

  if (canWatchFree) {
    return VideoAccessResult.allowed;
  }

  // 무료 시청 횟수 초과
  return VideoAccessResult.noFreeViews;
});

/// 비디오 접근 확인 함수 (접근 사용 시 카운트 감소)
Future<VideoAccessResult> checkVideoAccess(String videoId, WidgetRef ref) async {
  // 현재 사용자 확인
  final currentUser = Supabase.instance.client.auth.currentUser;

  // loupslim@gmail.com 계정인 경우 카운트 감소 없이 접근 허용
  if (currentUser != null && currentUser.email == 'loupslim@gmail.com') {
    return VideoAccessResult.allowed;
  }

  // 현재 접근 가능 여부 확인
  final accessResult = ref.read(videoAccessProvider(videoId));

  // 접근 가능한 경우에만 무료 시청 횟수 차감
  if (accessResult == VideoAccessResult.allowed && !ref.read(hasActiveSubscriptionProvider)) {
    // 무료 시청 횟수 차감
    final notifier = ref.read(subscriptionStateProvider.notifier);
    // Ref 타입 충돌 해결: 직접 카운트 감소 로직 구현
    final currentCount = ref.read(freeVideoWatchCountProvider);
    if (currentCount > 0) {
      ref.read(freeVideoWatchCountProvider.notifier).state = currentCount - 1;
    }
  }

  return accessResult;
}
