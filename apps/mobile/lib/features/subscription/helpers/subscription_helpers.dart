import 'dart:io';

import 'package:api_client/api_client.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/subscription/provider/subscription_provider.dart';
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

  /// 비회원의 시청 가능 최대 횟수
  static const int maxGuestViewCount = 10; // 3회에서 10회로 변경

  /// 비회원 시청 횟수 불러오기
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

  /// 비회원 시청 횟수 증가 및 저장
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

  /// 비회원 시청 횟수 초기화
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

  /// 비디오 접근 가능 여부 확인 및 필요시 구독 안내 다이얼로그 표시
  ///
  /// 비회원이거나 구독하지 않은 회원인 경우 10회까지 시청 허용하고, 그 이후에는 구독 안내 다이얼로그를 표시
  /// 접근 가능한 경우 true 반환
  static Future<bool> checkVideoAccess(BuildContext context, WidgetRef ref, Video? video) async {
    final authState = ref.read(authControllerProvider);
    final subscriptionState = ref.read(subscriptionProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isPremium = subscriptionState.isPremium;

    // 로그인한 프리미엄 사용자는 항상 접근 가능
    if (isAuthenticated && isPremium) {
      return true;
    }

    // 시청 횟수 확인 (로그인 여부와 관계없이)
    final currentCount = await loadGuestViewCount();
    ref.read(guestViewCountProvider.notifier).state = currentCount;

    // 10회 미만 시청 시 접근 허용 후 카운터 증가
    if (currentCount < maxGuestViewCount) {
      // 비디오 접근 허용 및 카운터 증가
      await incrementGuestViewCount(ref);
      return true;
    } else {
      // 10회 이상 시청 시 가입/구독 안내 다이얼로그 표시
      showSubscriptionDialog(context, isAuthenticated, isPremium);
      return false;
    }
  }

  /// 구독 안내 다이얼로그 표시
  static void showSubscriptionDialog(
    BuildContext context,
    bool isAuthenticated,
    bool isPremium,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isAuthenticated ? '무료 시청 한도 도달' : '무료 시청 한도 도달'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isAuthenticated) ...[
              const Text('무료로 시청할 수 있는 영상 수(10개)를 모두 사용하셨습니다.'),
              const SizedBox(height: 8),
              const Text('회원가입 후 구독하시면 모든 콘텐츠를 무제한으로 이용해보세요.'),
            ] else if (isAuthenticated && !isPremium) ...[
              const Text('무료로 시청할 수 있는 영상 수(10개)를 모두 사용하셨습니다.'),
              const SizedBox(height: 8),
              const Text('프리미엄에 가입하고 모든 영상을 무제한으로 시청하세요.'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('나중에'),
          ),
          if (!isAuthenticated)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // 회원가입 화면으로 직접 이동
                context.push(AppRoutes.signup);
              },
              child: const Text('회원가입하기'),
            ),
          if (isAuthenticated && !isPremium)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.subscription);
              },
              child: const Text('구독하기'),
            ),
        ],
      ),
    );
  }

  /// 동영상 선택 핸들러
  ///
  /// 동영상 목록에서 동영상 클릭 시 호출되는 공통 핸들러 함수
  /// 로그인/구독 상태를 확인하고 동영상 화면으로 이동하거나 구독 안내 다이얼로그를 표시
  static Future<void> handleVideoSelection(
    BuildContext context,
    WidgetRef ref,
    Video video,
  ) async {
    final authState = ref.read(authControllerProvider);
    final subscriptionState = ref.read(subscriptionProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isPremium = subscriptionState.isPremium;

    // 비디오 플레이어 화면 위젯 생성
    Widget videoPlayerScreen;
    try {
      // VideoPlayerScreen 클래스 import 필요
      videoPlayerScreen = VideoPlayerScreen(video: video);
    } catch (e) {
      debugPrint('VideoPlayerScreen 생성 오류: $e');
      // ID 기반 생성자 사용 시도
      videoPlayerScreen = VideoPlayerScreen.fromId(videoId: video.id);
    }

    // 프리미엄 사용자는 바로 시청 가능
    if (isAuthenticated && isPremium) {
      // rootNavigator: true를 사용하여 하단 네비게이션 바가 없는 루트 네비게이터에서 화면 표시
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => videoPlayerScreen,
          fullscreenDialog: true,
        ),
      );
      return;
    }

    // 비회원 및 비프리미엄 회원은 무료 시청 횟수 확인
    final currentCount = await loadGuestViewCount();

    // 무료 시청 횟수가 남아있으면 동영상 재생 및 카운터 증가
    if (currentCount < maxGuestViewCount) {
      await incrementGuestViewCount(ref);
      // rootNavigator: true를 사용하여 하단 네비게이션 바가 없는 루트 네비게이터에서 화면 표시
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => videoPlayerScreen,
          fullscreenDialog: true,
        ),
      );
      return;
    }

    // 무료 시청 횟수를 모두 사용한 경우
    showSubscriptionDialog(context, isAuthenticated, isPremium);
  }

  /// 동영상 클릭 시 사용자 인증 상태에 따라 적절한 화면으로 이동
  /// 회원가입 후 자동 로그인 및 구독 화면 이동을 처리하는 라우터 리다이렉트에서 사용
  static void handleAfterSignup(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authControllerProvider);
    final subscriptionState = ref.read(subscriptionProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isPremium = subscriptionState.isPremium;

    // 로그인 완료 후 구독 상태에 따라 이동
    if (isAuthenticated) {
      // 로그인 성공 시 시청 횟수 초기화
      resetGuestViewCount(ref);

      if (isPremium) {
        // 이미 프리미엄 구독 중이면 홈으로 이동
        context.go(AppRoutes.home);
      } else {
        // 구독이 안 되어 있으면 구독 화면으로 이동
        context.push(AppRoutes.subscription);
      }
    }
  }
}
