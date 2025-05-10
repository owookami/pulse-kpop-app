import 'dart:async';
import 'dart:io';

import 'package:api_client/api_client.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/ads/service/ad_service.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/subscription/provider/new_subscription_provider.dart';
import 'package:mobile/features/video_player/view/video_player_screen.dart';
import 'package:mobile/routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 비회원 시청 횟수 추적 프로바이더
final guestViewCountProvider = StateProvider<int>((ref) {
  return 0;
});

/// 구독 관련 도우미 함수들
class SubscriptionHelpers {
  /// SharedPreferences 기본 키
  static const String _guestViewCountBaseKey = 'guest_view_count';

  /// 현재 기기용 SharedPreferences 키 생성
  static Future<String> _getDeviceViewCountKey() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      }

      // deviceId가 비어있으면 _guestViewCountBaseKey 사용
      if (deviceId.isEmpty) {
        return _guestViewCountBaseKey;
      }

      // deviceId에서 특수문자 제거하고 마지막 8자리만 사용
      deviceId = deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final shortId = deviceId.length > 8 ? deviceId.substring(deviceId.length - 8) : deviceId;

      return '${_guestViewCountBaseKey}_$shortId';
    } catch (e) {
      debugPrint('기기 ID 가져오기 오류: $e');
      return _guestViewCountBaseKey;
    }
  }

  /// 비회원 시청 횟수 불러오기 (추적 기능은 유지)
  static Future<int> loadGuestViewCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getDeviceViewCountKey();
      return prefs.getInt(key) ?? 0;
    } catch (e) {
      debugPrint('시청 횟수 로드 오류: $e');
      return 0;
    }
  }

  /// 비회원 시청 횟수 증가 및 저장 (추적 기능은 유지)
  static Future<int> incrementGuestViewCount(WidgetRef ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getDeviceViewCountKey();
      final currentCount = prefs.getInt(key) ?? 0;
      final newCount = currentCount + 1;

      await prefs.setInt(key, newCount);
      ref.read(guestViewCountProvider.notifier).state = newCount;

      return newCount;
    } catch (e) {
      debugPrint('시청 횟수 증가 오류: $e');
      return -1;
    }
  }

  /// 비회원 시청 횟수 초기화 (추적 기능은 유지)
  static Future<void> resetGuestViewCount(WidgetRef ref) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getDeviceViewCountKey();
      await prefs.setInt(key, 0);
      ref.read(guestViewCountProvider.notifier).state = 0;
    } catch (e) {
      debugPrint('시청 횟수 초기화 오류: $e');
    }
  }

  /// 비디오 접근 가능 여부 확인
  ///
  /// 프리미엄 사용자는 즉시 접근 가능
  /// 비회원이나 무료 회원은 광고 후 접근 가능
  /// 접근 가능한 경우 true 반환
  static Future<bool> checkVideoAccess(
    BuildContext context,
    WidgetRef ref,
    Video video,
  ) async {
    final isAuthenticated = ref.read(authControllerProvider).isAuthenticated;
    final premiumState = ref.read(isPremiumUserProvider);
    final isPremium = premiumState.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );

    // 프리미엄 구독자는 모든 비디오 접근 가능
    if (isPremium) return true;

    // 무료 시청 횟수 확인 (비구독자용)
    final freeViewsUsed = await _getFreeViewsCount(ref);
    const maxFreeViews = 10; // 최대 무료 시청 가능 수

    if (freeViewsUsed < maxFreeViews) {
      // 무료 시청 카운트 증가
      await _incrementFreeViewsCount(ref);
      return true;
    }

    // 무료 시청 한도 초과 시 광고 시청 또는 구독 안내 다이얼로그 표시
    if (context.mounted) {
      return await _showLimitReachedDialog(context, ref);
    }

    return false;
  }

  /// 무료 시청 횟수 가져오기
  static Future<int> _getFreeViewsCount(WidgetRef ref) async {
    // 실제 구현에서는 로컬 저장소나 API에서 값을 가져와야 함
    // 예시 구현: SharedPreferences 사용

    // 임시 구현: 하드코딩된 값 반환
    return 9; // 예시: 9회 사용함
  }

  /// 무료 시청 횟수 증가
  static Future<void> _incrementFreeViewsCount(WidgetRef ref) async {
    // 실제 구현에서는 로컬 저장소나 API에 값을 저장해야 함
    // 예시 구현: SharedPreferences 사용

    // 임시 구현: 로그만 출력
    debugPrint('무료 시청 횟수 증가');
  }

  /// 무료 시청 한도 도달 다이얼로그 표시
  static Future<bool> _showLimitReachedDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final completer = Completer<bool>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.free_trial_limit_reached),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이 영상을 시청하려면 광고를 시청하거나 프리미엄으로 구독하세요.'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.premium_benefit_1, style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.premium_benefit_2, style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.premium_benefit_3, style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAdvertisement(context).then((success) {
                completer.complete(success);
              });
            },
            child: Text(l10n.watch_ad_to_continue),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToSubscription(context);
              completer.complete(false); // 구독 화면으로 이동하므로 접근 허용 안함
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.subscribe_to_continue),
          ),
        ],
      ),
    );

    return completer.future;
  }

  /// 광고 표시
  static Future<bool> _showAdvertisement(BuildContext context) async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // 광고 로드 및 표시 (실제 구현에서는 광고 SDK 사용)
    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      // 광고 시청 완료 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).ad_watch_completed),
          duration: const Duration(seconds: 3),
        ),
      );

      return true; // 광고 시청 완료, 비디오 접근 허용
    }

    return false;
  }

  /// 구독 화면으로 이동
  static void _navigateToSubscription(BuildContext context) {
    context.push(AppRoutes.subscription);
  }

  /// 구독 안내 다이얼로그 표시
  static void showSubscriptionDialog(
    BuildContext context,
    bool isAuthenticated,
    bool isPremium,
  ) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isAuthenticated ? l10n.subscription_title : l10n.subscription_signup_required),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isAuthenticated) ...[
              Text(l10n.subscription_limit_message_guest),
            ] else if (isAuthenticated && !isPremium) ...[
              Text(l10n.subscription_limit_message_user),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.subscription_later),
          ),
          if (!isAuthenticated)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // 회원가입 화면으로 직접 이동
                context.push(AppRoutes.signup);
              },
              child: Text(l10n.subscription_signup),
            ),
          if (isAuthenticated && !isPremium)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.subscription);
              },
              child: Text(l10n.subscription_subscribe),
            ),
        ],
      ),
    );
  }

  /// 동영상 선택 핸들러
  ///
  /// 동영상 목록에서 동영상 클릭 시 호출되는 공통 핸들러 함수
  /// 로그인/구독 상태를 확인하고 동영상 화면으로 이동하거나 광고 표시
  static Future<void> handleVideoSelection(
    BuildContext context,
    WidgetRef ref,
    Video video,
  ) async {
    final authState = ref.read(authControllerProvider);
    final isPremiumState = ref.read(isPremiumUserProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isPremium = isPremiumState.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );

    // 비디오 플레이어 화면 위젯 생성
    Widget videoPlayerScreen;
    try {
      videoPlayerScreen = VideoPlayerScreen(video: video);
    } catch (e) {
      debugPrint('VideoPlayerScreen 생성 오류: $e');
      // ID 기반 생성자 사용 시도
      videoPlayerScreen = VideoPlayerScreen.fromId(videoId: video.id);
    }

    // 프리미엄 사용자는 광고 없이 바로 시청 가능
    if (isAuthenticated && isPremium) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => videoPlayerScreen,
          fullscreenDialog: true,
        ),
      );
      return;
    }

    // 비프리미엄 회원과 비회원은 광고 시청 후 동영상 재생
    await incrementGuestViewCount(ref); // 추적을 위해 카운트는 계속 증가시킴

    // 광고 표시
    try {
      final adService = ref.read(adServiceProvider);
      final adShown = await adService.showInterstitialAd();

      // 광고 표시 결과와 상관없이 동영상 재생 (광고 표시 실패해도 시청 가능)
      if (adShown) {
        debugPrint('광고 표시 성공 후 동영상 재생');
      } else {
        debugPrint('광고 표시 실패, 동영상 바로 재생');
      }
    } catch (e) {
      debugPrint('광고 표시 중 오류: $e');
    }

    // 광고 표시 후 (또는 광고 표시 실패 후) 동영상 재생
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => videoPlayerScreen,
          fullscreenDialog: true,
        ),
      );
    }
  }

  /// 동영상 클릭 시 사용자 인증 상태에 따라 적절한 화면으로 이동
  /// 회원가입 후 자동 로그인 및 구독 화면 이동을 처리하는 라우터 리다이렉트에서 사용
  static void handleAfterSignup(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authControllerProvider);
    final isPremiumState = ref.read(isPremiumUserProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isPremium = isPremiumState.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );

    // 로그인 완료 후 구독 상태에 따라 이동
    if (isAuthenticated) {
      // 로그인 성공 시 시청 횟수 초기화
      resetGuestViewCount(ref);

      if (isPremium) {
        // 이미 프리미엄 구독 중이면 홈으로 이동
        context.go(AppRoutes.home);
      } else {
        // 구독이 안 되어 있으면 구독 상품 화면으로 이동
        context.push(AppRoutes.subscriptionPlans);
      }
    }
  }

  /// 광고 시청 후 비디오 재생 시작
  static void _startVideoAfterAd(BuildContext context) {
    // 스낵바로 안내 메시지 표시
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.ad_watch_completed),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 프리미엄 사용자 여부 확인
  static bool isPremiumUser(WidgetRef ref) {
    final premiumState = ref.read(isPremiumUserProvider);
    return premiumState.maybeWhen(
      data: (value) => value,
      orElse: () => false,
    );
  }
}
