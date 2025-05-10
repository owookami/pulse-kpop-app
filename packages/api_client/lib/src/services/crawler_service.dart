import 'dart:convert';

import 'package:api_client/src/config/env.dart';
import 'package:dio/dio.dart';

/// 크롤러 API 서비스
class CrawlerService {
  /// 서비스 생성자
  CrawlerService({Dio? client}) : _client = client ?? Dio();

  final Dio _client;

  /// Supabase Edge Function을 통해 YouTube 동영상 크롤링
  Future<Map<String, dynamic>> crawlYouTubeVideos({
    String? query,
    String? artist,
    String? groupName,
    String? event,
    int limit = 20,
  }) async {
    try {
      // Supabase URL과 Anon Key 확인
      final supabaseUrl = Env.supabaseUrl;
      final supabaseAnonKey = Env.supabaseAnonKey;

      if (supabaseUrl.isEmpty) {
        throw Exception('Supabase URL이 설정되지 않았습니다.');
      }

      if (supabaseAnonKey.isEmpty) {
        throw Exception('Supabase Anon Key가 설정되지 않았습니다.');
      }

      // Edge Function URL 구성
      final functionUrl = '$supabaseUrl/functions/v1/crawler';

      // 요청 파라미터 구성
      final requestData = {
        'query': query,
        'artist': artist,
        'group_name': groupName,
        'event': event,
        'limit': limit,
      };

      // Supabase 인증 헤더 구성
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $supabaseAnonKey',
      };

      // 요청 보내기
      final response = await _client.post(
        functionUrl,
        data: json.encode(requestData),
        options: Options(headers: headers),
      );

      // 응답 확인
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('API 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('크롤러 서비스 오류: $e');
    }
  }

  /// 최근 크롤링 작업 목록 가져오기
  Future<List<Map<String, dynamic>>> getRecentCrawlerJobs({int limit = 10}) async {
    try {
      // 이 부분은 Supabase 데이터베이스에서 직접 쿼리하는 방식으로 구현해야 합니다.
      // 여기서는 예시로 더미 데이터를 반환합니다.
      return [
        {
          'id': 'job-1',
          'status': 'completed',
          'start_time': DateTime.now().toIso8601String(),
          'end_time': DateTime.now().toIso8601String(),
          'params': {'query': 'kpop fancam'},
        }
      ];
    } catch (e) {
      throw Exception('작업 목록 가져오기 오류: $e');
    }
  }

  /// 일일 리포트 생성 요청
  Future<Map<String, dynamic>> generateDailyReport() async {
    try {
      // Supabase URL과 Anon Key 확인
      final supabaseUrl = Env.supabaseUrl;
      final supabaseAnonKey = Env.supabaseAnonKey;

      if (supabaseUrl.isEmpty) {
        throw Exception('Supabase URL이 설정되지 않았습니다.');
      }

      if (supabaseAnonKey.isEmpty) {
        throw Exception('Supabase Anon Key가 설정되지 않았습니다.');
      }

      // Edge Function URL 구성
      final functionUrl = '$supabaseUrl/functions/v1/scheduler?action=dailyReport';

      // Supabase 인증 헤더 구성
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $supabaseAnonKey',
      };

      // 요청 보내기
      final response = await _client.get(
        functionUrl,
        options: Options(headers: headers),
      );

      // 응답 확인
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('API 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('일일 리포트 생성 오류: $e');
    }
  }
}
