import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 광고 서비스 제공자
final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});

/// 광고 서비스
class AdService {
  /// 인스턴스 생성
  AdService() {
    _init();
  }

  /// 전면 광고 인스턴스
  InterstitialAd? _interstitialAd;

  /// 광고 로딩 상태
  bool _isAdLoading = false;

  /// 광고 초기화 완료 여부
  bool _isInitialized = false;

  /// 테스트 광고 ID (개발용)
  final String _testAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712' // 안드로이드 테스트 ID
      : 'ca-app-pub-3940256099942544/4411468910'; // iOS 테스트 ID

  /// 실제 광고 ID (배포용)
  final String _productionAdUnitId = Platform.isAndroid
      ? 'YOUR_ANDROID_AD_UNIT_ID' // TODO: 실제 광고 ID로 교체 필요
      : 'YOUR_IOS_AD_UNIT_ID'; // TODO: 실제 광고 ID로 교체 필요

  /// 현재 사용할 광고 ID
  String get _adUnitId => kDebugMode ? _testAdUnitId : _productionAdUnitId;

  /// 광고 서비스 초기화
  Future<void> _init() async {
    if (_isInitialized) return;

    // AdMob SDK 초기화
    await MobileAds.instance.initialize();
    _isInitialized = true;

    // 첫 광고 미리 로드
    loadInterstitialAd();
  }

  /// 전면 광고 로드
  Future<void> loadInterstitialAd() async {
    if (_isAdLoading || _interstitialAd != null) {
      debugPrint('전면 광고가 이미 로드 중이거나 로드되어 있습니다.');
      return;
    }

    _isAdLoading = true;

    try {
      await InterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isAdLoading = false;
            debugPrint('전면 광고 로드 성공');
          },
          onAdFailedToLoad: (error) {
            debugPrint('광고 로드 실패: ${error.message}');
            _interstitialAd = null;
            _isAdLoading = false;

            // 잠시 후 다시 로드 시도
            Future.delayed(const Duration(minutes: 1), loadInterstitialAd);
          },
        ),
      );
    } catch (e) {
      debugPrint('광고 로드 중 오류 발생: $e');
      _isAdLoading = false;
    }
  }

  /// 전면 광고 표시
  ///
  /// 광고가 표시되면 true 반환, 실패하면 false 반환
  Future<bool> showInterstitialAd({
    VoidCallback? onAdDismissed,
    VoidCallback? onAdFailedToShow,
  }) async {
    if (_interstitialAd == null) {
      // 광고가 로드되지 않았으면 로드 시도
      debugPrint('표시할 광고가 없어 새로 로드합니다.');
      await loadInterstitialAd();

      // 로드 후에도 광고가 없으면 false 반환
      if (_interstitialAd == null) {
        debugPrint('광고 로드 실패: 표시할 광고가 없습니다.');
        onAdFailedToShow?.call();
        return false;
      }
    }

    try {
      // 콜백 설정
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('광고가 닫혔습니다.');
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd(); // 다음 광고 미리 로드
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('광고 표시 실패: $error');
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd(); // 다시 로드 시도
          onAdFailedToShow?.call();
        },
      );

      // 광고 표시
      await _interstitialAd?.show();
      return true;
    } catch (e) {
      debugPrint('광고 표시 중 오류: $e');
      _interstitialAd = null;
      // 다음을 위해 광고 다시 로드
      loadInterstitialAd();
      onAdFailedToShow?.call();
      return false;
    }
  }

  /// 리소스 해제
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
