import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 사용자 국가 및 언어 설정을 관리하는 서비스
class LocaleService {
  static const String _userCountryKey = 'user_country';
  static const String _userLocaleKey = 'user_locale';
  static const String _isFirstLaunchKey = 'is_first_launch';

  // 지역 상수 (하위 호환성 유지)
  static const String regionNaEu = 'NA_EU';
  static const String regionAsia = 'ASIA';
  static const String regionOthers = 'OTHERS';

  // 기본 국가 및 언어
  static const String defaultCountry = 'KR';
  static const Locale defaultLocale = Locale('en', 'US');

  // 국가별 기본 언어 매핑
  static final Map<String, Locale> _countryToDefaultLocale = {
    // 아시아 국가
    'KR': const Locale('ko', 'KR'), // 한국
    'JP': const Locale('ja', 'JP'), // 일본
    'CN': const Locale('zh', 'CN'), // 중국
    'TW': const Locale('zh', 'TW'), // 대만
    'HK': const Locale('zh', 'HK'), // 홍콩
    'SG': const Locale('en', 'SG'), // 싱가포르
    'MY': const Locale('ms', 'MY'), // 말레이시아
    'ID': const Locale('id', 'ID'), // 인도네시아
    'TH': const Locale('th', 'TH'), // 태국
    'VN': const Locale('vi', 'VN'), // 베트남
    'PH': const Locale('en', 'PH'), // 필리핀

    // 북미/유럽 국가
    'US': const Locale('en', 'US'), // 미국
    'CA': const Locale('en', 'CA'), // 캐나다
    'GB': const Locale('en', 'GB'), // 영국
    'DE': const Locale('de', 'DE'), // 독일
    'FR': const Locale('fr', 'FR'), // 프랑스
    'IT': const Locale('it', 'IT'), // 이탈리아
    'ES': const Locale('es', 'ES'), // 스페인
    'AU': const Locale('en', 'AU'), // 호주

    // 기타 지역 국가
    'BR': const Locale('pt', 'BR'), // 브라질
    'MX': const Locale('es', 'MX'), // 멕시코
    'AR': const Locale('es', 'AR'), // 아르헨티나
    'IN': const Locale('hi', 'IN'), // 인도
    'ZA': const Locale('en', 'ZA'), // 남아프리카공화국
  };

  // 국가별 영어 국가명
  static final Map<String, String> _countryNames = {
    // 아시아 국가들
    'KR': 'South Korea',
    'JP': 'Japan',
    'CN': 'China',
    'TW': 'Taiwan',
    'HK': 'Hong Kong',
    'SG': 'Singapore',
    'MY': 'Malaysia',
    'ID': 'Indonesia',
    'TH': 'Thailand',
    'PH': 'Philippines',
    'VN': 'Vietnam',

    // 북미/유럽 국가들
    'US': 'United States',
    'CA': 'Canada',
    'GB': 'United Kingdom',
    'DE': 'Germany',
    'FR': 'France',
    'IT': 'Italy',
    'ES': 'Spain',
    'AU': 'Australia',

    // 기타 지역 국가들
    'BR': 'Brazil',
    'MX': 'Mexico',
    'AR': 'Argentina',
    'IN': 'India',
    'ZA': 'South Africa',
  };

  // 국가별 현지어 국가명
  static final Map<String, String> _countryLocalNames = {
    // 아시아 국가들
    'KR': '대한민국',
    'JP': '日本',
    'CN': '中国',
    'TW': '台灣',
    'HK': '香港',
    'SG': 'Singapore',
    'MY': 'Malaysia',
    'ID': 'Indonesia',
    'TH': 'ประเทศไทย',
    'PH': 'Philippines',
    'VN': 'Việt Nam',

    // 북미/유럽 국가들
    'US': 'United States',
    'CA': 'Canada',
    'GB': 'United Kingdom',
    'DE': 'Deutschland',
    'FR': 'France',
    'IT': 'Italia',
    'ES': 'España',
    'AU': 'Australia',

    // 기타 지역 국가들
    'BR': 'Brasil',
    'MX': 'México',
    'AR': 'Argentina',
    'IN': 'भारत',
    'ZA': 'South Africa',
  };

  // 지원되는 언어 목록
  static final List<Locale> supportedLocales = [
    const Locale('en', 'US'), // 영어
    const Locale('ko', 'KR'), // 한국어
    const Locale('ja', 'JP'), // 일본어
    const Locale('zh', 'CN'), // 중국어 (간체)
    const Locale('zh', 'TW'), // 중국어 (번체)
    const Locale('de', 'DE'), // 독일어
    const Locale('fr', 'FR'), // 프랑스어
    const Locale('es', 'ES'), // 스페인어
  ];

  /// 최초 실행 여부 확인
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  /// 최초 실행 완료 설정
  static Future<void> completeFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }

  /// 사용자 국가 감지 및 저장
  static Future<String> detectAndSaveUserCountry() async {
    final prefs = await SharedPreferences.getInstance();

    // 이미 저장된 국가가 있는지 확인
    final savedCountry = prefs.getString(_userCountryKey);
    if (savedCountry != null) {
      return savedCountry;
    }

    // 현재 시스템 로케일 가져오기
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final countryCode = systemLocale.countryCode ?? 'US';
    final detectedCountry = _validateCountryCode(countryCode);

    // 감지된 국가 저장
    await prefs.setString(_userCountryKey, detectedCountry);

    // 국가에 맞는 언어 자동 설정
    if (!prefs.containsKey(_userLocaleKey)) {
      final defaultLocale = _countryToDefaultLocale[detectedCountry] ?? LocaleService.defaultLocale;
      await setUserLocale(defaultLocale);
    }

    return detectedCountry;
  }

  /// 사용자 국가 설정
  static Future<void> setUserCountry(String countryCode) async {
    final prefs = await SharedPreferences.getInstance();
    final validCountry = _validateCountryCode(countryCode);
    await prefs.setString(_userCountryKey, validCountry);
  }

  /// 사용자 국가 가져오기
  static Future<String> getUserCountry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userCountryKey) ?? defaultCountry;
  }

  /// 국가 코드 유효성 검사
  static String _validateCountryCode(String countryCode) {
    return _countryToDefaultLocale.containsKey(countryCode) ? countryCode : defaultCountry;
  }

  /// 국가에 대한 영어 이름 가져오기
  static String getCountryName(String countryCode) {
    return _countryNames[countryCode] ?? countryCode;
  }

  /// 국가에 대한 현지어 이름 가져오기
  static String getCountryLocalName(String countryCode) {
    return _countryLocalNames[countryCode] ?? countryCode;
  }

  /// 사용자 언어 설정
  static Future<void> setUserLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userLocaleKey, '${locale.languageCode}_${locale.countryCode}');
  }

  /// 사용자 언어 가져오기
  static Future<Locale> getUserLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeStr = prefs.getString(_userLocaleKey);

    if (localeStr != null) {
      final parts = localeStr.split('_');
      if (parts.length >= 2) {
        return Locale(parts[0], parts[1]);
      }
    }

    // 저장된 언어가 없으면 국가 기반 기본 언어 반환
    final country = await getUserCountry();
    return _countryToDefaultLocale[country] ?? defaultLocale;
  }

  /// 국가에 맞는 기본 언어 설정
  static Future<Locale> setDefaultLocaleForCountry() async {
    final country = await getUserCountry();
    final defaultLocale = _countryToDefaultLocale[country] ?? LocaleService.defaultLocale;

    // 언어 설정 저장
    await setUserLocale(defaultLocale);

    return defaultLocale;
  }

  /// 지역 정보를 국가 코드로 변환 (기존 코드 호환용)
  static Future<String> getUserRegion() async {
    final country = await getUserCountry();

    // 국가 코드를 지역으로 변환
    if (['US', 'CA', 'GB', 'DE', 'FR', 'IT', 'ES', 'AU'].contains(country)) {
      return regionNaEu;
    } else if (['KR', 'JP', 'CN', 'TW', 'HK', 'SG', 'MY', 'ID', 'TH', 'PH', 'VN']
        .contains(country)) {
      return regionAsia;
    } else {
      return regionOthers;
    }
  }

  /// 로케일 문자열에서 국가 코드 추출
  static String _getCountryFromLocale(String locale) {
    if (locale.isEmpty) return defaultCountry;

    // 형식이 'xx_YY'인 경우
    final parts = locale.split('_');
    if (parts.length >= 2 && parts[1].length == 2) {
      return parts[1].toUpperCase();
    }

    // 형식이 'xx-YY'인 경우
    final hyphenParts = locale.split('-');
    if (hyphenParts.length >= 2 && hyphenParts[1].length == 2) {
      return hyphenParts[1].toUpperCase();
    }

    // 국가 코드를 추출할 수 없는 경우
    return defaultCountry;
  }
}

/// 현재 선택된 국가 제공자
final userCountryProvider = FutureProvider<String>((ref) async {
  return LocaleService.getUserCountry();
});

/// 현재 선택된 언어 제공자
final userLocaleProvider = FutureProvider<Locale>((ref) async {
  return LocaleService.getUserLocale();
});
