/// API 구성 및 초기화
///
/// API 클라이언트 초기화 및 구성에 관련된 유틸리티를 제공합니다.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

/// API 클라이언트 초기화를 담당하는 클래스
class ApiClientInitializer {
  /// Supabase 초기화
  static Future<void> initSupabase({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  /// Dio HTTP 클라이언트 생성
  static Dio createDioClient({
    String? baseUrl,
    Map<String, dynamic>? headers,
    List<Interceptor>? interceptors,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        headers: headers,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // 디버그 모드에서만 로그 표시
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        responseBody: true,
        requestBody: true,
      ));
    }

    // 추가 인터셉터 등록
    if (interceptors != null) {
      dio.interceptors.addAll(interceptors);
    }

    return dio;
  }
}

/// Global Supabase 클라이언트 프로바이더
final supabaseClientProvider = riverpod.Provider<SupabaseClient>(
  (ref) {
    return Supabase.instance.client;
  },
);

/// Global Dio 클라이언트 프로바이더
final dioProvider = riverpod.Provider<Dio>((ref) {
  return ApiClientInitializer.createDioClient();
});

/// API 클라이언트 설정
class ApiConfig {
  /// Supabase URL
  static const String supabaseUrl = 'https://mdqfbcoexjdhuweziwff.supabase.co';

  /// Supabase 익명 키
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kcWZiY29leGpkaHV3ZXppd2ZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYxOTEwMTcsImV4cCI6MjA2MTc2NzAxN30.f-byX2tW8K8fsWJJoD3UeohvNiFMoBC73f_cKeSZjeA';

  /// API 기본 URL
  static const String apiBaseUrl = supabaseUrl;

  /// 기본 페이지 크기
  static const int defaultPageSize = 10;
}
