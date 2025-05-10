import 'package:api_client/api_client.dart' as api_client;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobile/core/services/locale_service.dart';
import 'package:mobile/features/subscription/provider/subscription_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app.dart';

/// 앱의 기본 언어 설정을 위한 프로바이더
final localeProvider = StateProvider<Locale>((ref) => LocaleService.defaultLocale);

/// SharedPreferences 제공자
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider는 runApp 전에 초기화되어야 합니다.');
});

/// 앱이 로드되었는지 확인하는 프로바이더
final appInitializedProvider = StateProvider<bool>((ref) => false);

// 전역 변수
late SharedPreferences _sharedPrefs;
late Locale _userLocale;

/// 앱의 시작점
void main() async {
  // 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 앱 시작 전 초기화 함수
  await _initialize();

  // 앱 시작
  runApp(
    ProviderScope(
      overrides: [
        // 앱의 SharedPreferences 제공자 초기화
        sharedPreferencesProvider.overrideWithValue(_sharedPrefs),
        // api_client 패키지의 SharedPreferences 제공자도 초기화
        api_client.sharedPreferencesProvider.overrideWithValue(_sharedPrefs),
        // 언어 설정 초기화 - 사용자 설정된 언어 사용
        localeProvider.overrideWith((ref) => _userLocale),
      ],
      // 앱 초기화 후 리스너 등록
      observers: [AppInitObserver()],
      child: const MyApp(),
    ),
  );
}

/// 앱 초기화 Observer - 앱이 시작될 때 필요한 서비스 초기화
class AppInitObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    // 앱 초기화가 완료되면 구독 서비스 초기화
    if (!container.read(appInitializedProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        container.read(subscriptionServiceProvider);
        container.read(appInitializedProvider.notifier).state = true;
      });
    }
  }
}

/// 앱 시작 전 초기화 함수
Future<void> _initialize() async {
  // 환경 변수 로드
  await dotenv.load();

  // 구글 모바일 광고 초기화
  await MobileAds.instance.initialize();

  // Supabase 초기화
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // API 클라이언트 초기화
  try {
    // 다음 부분은 api_client 패키지의 구현에 따라 달라질 수 있음
    // 참고: api_client 패키지의 정확한 초기화 방법 확인 필요
    // 현재는 주석 처리하여 빌드 오류를 방지
    /*
    api_client.initialize(
      supabaseUrl: dotenv.env['SUPABASE_URL'] ?? '',
      supabaseKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );
    */
    debugPrint('api_client 초기화는 패키지 구현에 따라 별도로 설정해야 합니다.');
  } catch (e) {
    debugPrint('API 클라이언트 초기화 중 오류: $e');
  }

  // SharedPreferences 초기화 및 제공자 설정
  final prefs = await SharedPreferences.getInstance();
  _sharedPrefs = prefs;

  // 사용자 국가 감지 및 저장 (지역 기반 가격 표시용)
  final userCountry = await LocaleService.detectAndSaveUserCountry();
  debugPrint('감지된 국가: $userCountry');

  // 앱 최초 실행 여부 확인 및 국가에 맞는 언어 설정
  final isFirstLaunch = await LocaleService.isFirstLaunch();
  if (isFirstLaunch) {
    // 첫 실행 시 국가에 맞는 언어 자동 설정
    _userLocale = await LocaleService.setDefaultLocaleForCountry();
    debugPrint('최초 실행: 언어 자동 설정 -> ${_userLocale.languageCode}_${_userLocale.countryCode}');

    // 최초 실행 완료 플래그 설정
    await LocaleService.completeFirstLaunch();
  } else {
    // 이미 설정된 언어 로드
    _userLocale = await LocaleService.getUserLocale();
    debugPrint('저장된 언어 로드: ${_userLocale.languageCode}_${_userLocale.countryCode}');
  }
}
