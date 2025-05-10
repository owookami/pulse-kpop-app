import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/subscription/model/subscription_models.dart';
import 'package:mobile/features/subscription/service/subscription_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 클라이언트 프로바이더
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// 구독 서비스 프로바이더
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  // 개발 환경에서는 MockSubscriptionService를 사용
  return MockSubscriptionService();
});

/// 구독 상태 프로바이더
final subscriptionStatusProvider = FutureProvider<SubscriptionStatus>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.checkSubscriptionStatus();
});

/// 구독 상품 목록 프로바이더
final subscriptionProductsProvider = FutureProvider<List<SubscriptionProduct>>((ref) async {
  final service = ref.watch(subscriptionServiceProvider);
  return service.getSubscriptionProducts();
});

/// 사용자 프리미엄 여부 프로바이더
final isPremiumUserProvider = FutureProvider<bool>((ref) async {
  final status = await ref.watch(subscriptionStatusProvider.future);
  return status.isActive && status.planType != SubscriptionPlanType.free;
});

/// 특정 기능 사용 가능 여부 확인 프로바이더
final canUseFeatureProvider = Provider.family<bool, String>((ref, featureId) {
  final premiumState = ref.watch(isPremiumUserProvider);
  final isPremium = premiumState.maybeWhen(
    data: (value) => value,
    orElse: () => false,
  );

  // 기본 기능들 (무료 플랜에서도 사용 가능)
  const basicFeatures = [
    'basic_videos',
    'standard_quality',
    'limited_search',
  ];

  // 프리미엄 기능들 (구독 필요)
  const premiumFeatures = [
    'hd_videos',
    'unlimited_search',
    'offline_downloads',
    'exclusive_content',
  ];

  // 해당 기능이 무료 플랜에서 사용 가능한지 확인
  if (basicFeatures.contains(featureId)) {
    return true;
  }

  // 프리미엄 기능은 구독자만 사용 가능
  if (premiumFeatures.contains(featureId)) {
    return isPremium;
  }

  // 알 수 없는 기능은 기본적으로 허용하지 않음
  return false;
});

/// 관리자 권한 확인 프로바이더
final isAdminProvider = FutureProvider<bool>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final session = supabase.auth.currentSession;

  // 세션이 없거나 유저 ID가 없으면 관리자 아님
  if (session == null || session.user.id.isEmpty) {
    debugPrint('관리자 권한 없음: 세션이 없거나 유저 ID가 없음');
    return false;
  }

  try {
    // 사용자 메타데이터에서 admin 역할 확인
    final user = supabase.auth.currentUser;
    final appMetadata = user?.appMetadata;
    final email = user?.email;
    final role = appMetadata?['role'];

    // 디버깅을 위한 로그 추가
    debugPrint('사용자 권한 확인: 이메일=$email, 역할=$role, 앱메타데이터=$appMetadata');

    // 특정 이메일은 항상 관리자로 인식
    if (email == 'loupslim@gmail.com') {
      debugPrint('관리자 권한 부여: loupslim@gmail.com');
      return true;
    }

    // 일반적인 역할 확인
    final isAdmin = role == 'admin';
    debugPrint('관리자 권한 확인 결과: $isAdmin');
    return isAdmin;
  } catch (e) {
    debugPrint('관리자 권한 확인 오류: $e');
    return false;
  }
});
