import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// 앱 환경 설정 (개발/스테이징/프로덕션)
enum AppEnvironment {
  /// 개발 환경
  development,

  /// 스테이징 환경
  staging,

  /// 프로덕션 환경
  production,
}

/// API 클라이언트 환경 변수 관리
class Env {
  /// 환경 변수를 초기화합니다.
  static void init() {
    if (kIsWeb || _isInitialized) return;
    _loadEnvVariables();
    _isInitialized = true;
  }

  static bool _isInitialized = false;

  static void _loadEnvVariables() {
    try {
      final envMap = Platform.environment;
      _supabaseUrl = envMap['SUPABASE_URL'] ?? _supabaseUrl;
      _supabaseAnonKey = envMap['SUPABASE_ANON_KEY'] ?? _supabaseAnonKey;
      _youtubeApiKey = envMap['YOUTUBE_API_KEY'] ?? _youtubeApiKey;
      _crawlerApiUrl = envMap['CRAWLER_API_URL'] ?? _crawlerApiUrl;
      _appEnvString = envMap['APP_ENV'] ?? _appEnvString;
    } catch (e) {
      debugPrint('환경 변수 로드 중 오류 발생: $e');
    }
  }

  /// 프로덕션 빌드에서 사용할 기본 값들입니다.
  /// 실제 앱에서는 빌드 시점에 환경변수로 대체되어야 합니다.
  static String _supabaseUrl = 'https://your-project.supabase.co';
  static String _supabaseAnonKey = 'your-anon-key';
  static String _youtubeApiKey = '';
  static String _crawlerApiUrl = '';
  static String _appEnvString = 'development';

  /// Supabase 프로젝트 URL
  static String get supabaseUrl => _supabaseUrl;

  /// Supabase 익명(public) API 키
  static String get supabaseAnonKey => _supabaseAnonKey;

  /// YouTube Data API 키
  static String get youtubeApiKey => _youtubeApiKey;

  /// 크롤러 API URL
  static String get crawlerApiUrl => _crawlerApiUrl;

  /// 앱 환경 열거형 값
  static AppEnvironment get appEnvironment {
    switch (_appEnvString) {
      case 'production':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      case 'development':
      default:
        return AppEnvironment.development;
    }
  }

  /// 개발 환경인지 확인
  static bool get isDevelopment => appEnvironment == AppEnvironment.development;

  /// 스테이징 환경인지 확인
  static bool get isStaging => appEnvironment == AppEnvironment.staging;

  /// 프로덕션 환경인지 확인
  static bool get isProduction => appEnvironment == AppEnvironment.production;
}
