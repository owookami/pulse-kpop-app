import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models/api_error.dart';
import '../models/api_response.dart';

/// Supabase 클라이언트 인터페이스
abstract class ISupabaseClient {
  /// 현재 로그인된 사용자 ID
  String? get currentUserId;

  /// 사용자 로그인 상태 확인
  bool get isAuthenticated;

  /// 이메일/비밀번호로 회원가입
  Future<ApiResponse<User>> signUp({
    required String email,
    required String password,
  });

  /// 이메일/비밀번호로 로그인
  Future<ApiResponse<User>> signIn({
    required String email,
    required String password,
  });

  /// 로그아웃
  Future<ApiResponse<void>> signOut();

  /// 데이터베이스 쿼리 수행
  Future<ApiResponse<List<T>>> query<T>({
    required String table,
    required T Function(Map<String, dynamic>) fromJson,
    List<String>? columns,
    String? filter,
    String? orderBy,
    int? limit,
    int? offset,
  });

  /// 단일 레코드 조회
  Future<ApiResponse<T?>> getRecord<T>({
    required String table,
    required String id,
    required T Function(Map<String, dynamic>) fromJson,
    List<String>? columns,
  });

  /// 레코드 생성
  Future<ApiResponse<T>> createRecord<T>({
    required String table,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
  });

  /// 레코드 수정
  Future<ApiResponse<T>> updateRecord<T>({
    required String table,
    required String id,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
  });

  /// 레코드 삭제
  Future<ApiResponse<void>> deleteRecord({
    required String table,
    required String id,
  });
}

/// Supabase 클라이언트 구현
class SupabaseClientImpl implements ISupabaseClient {
  /// 생성자
  SupabaseClientImpl(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  bool get isAuthenticated => _client.auth.currentUser != null;

  @override
  Future<ApiResponse<User>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return ApiResponse.failure(
          const ApiError(
            code: 'auth/signup-failed',
            message: '회원가입에 실패했습니다.',
          ),
        );
      }

      return ApiResponse.success(response.user!);
    } on AuthException catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'auth/${e.statusCode}',
          message: e.message,
        ),
      );
    } catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'auth/unexpected-error',
          message: '예상치 못한 오류가 발생했습니다: $e',
        ),
      );
    }
  }

  @override
  Future<ApiResponse<User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return ApiResponse.failure(
          const ApiError(
            code: 'auth/signin-failed',
            message: '로그인에 실패했습니다.',
          ),
        );
      }

      return ApiResponse.success(response.user!);
    } on AuthException catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'auth/${e.statusCode}',
          message: e.message,
        ),
      );
    } catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'auth/unexpected-error',
          message: '예상치 못한 오류가 발생했습니다: $e',
        ),
      );
    }
  }

  @override
  Future<ApiResponse<void>> signOut() async {
    try {
      await _client.auth.signOut();
      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'auth/signout-failed',
          message: '로그아웃 중 오류가 발생했습니다: $e',
        ),
      );
    }
  }

  @override
  Future<ApiResponse<List<T>>> query<T>({
    required String table,
    required T Function(Map<String, dynamic>) fromJson,
    List<String>? columns,
    String? filter,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final selectQuery = columns?.join(',') ?? '*';
      final query = _client.from(table).select(selectQuery);

      // 필터 적용
      final filteredQuery = filter != null ? query.or(filter) : query;

      // 정렬 적용
      dynamic orderedQuery = filteredQuery;
      if (orderBy != null && orderBy.isNotEmpty) {
        try {
          print('Applying order by: $orderBy');

          // 복잡한 정렬 구문 간단하게 처리
          final fieldName = orderBy.split('.').first;
          final isDescending = orderBy.contains('.desc');

          print('Simplified to: field=$fieldName, isDescending=$isDescending');

          // 안전한 방식으로 order 메서드 호출
          orderedQuery = orderedQuery.order(
            fieldName,
            ascending: !isDescending,
          );

          print('Order applied successfully');
        } catch (orderError) {
          print('Error applying order: $orderError');
          // 정렬 오류 시 정렬 없이 진행
          orderedQuery = filteredQuery;
        }
      }

      // 페이지네이션 적용
      if (limit != null) {
        orderedQuery = orderedQuery.limit(limit);
      }
      if (offset != null) {
        orderedQuery = orderedQuery.range(offset, offset + (limit ?? 20) - 1);
      }

      // 쿼리 실행
      final response = await orderedQuery;
      final List<dynamic> data = response as List<dynamic>;

      // 타입 안전성 향상을 위한 변환 로직
      final items = data
          .map((dynamic item) {
            try {
              // Supabase에서 반환된 데이터가 Map 타입인지 확인하고 안전하게 변환
              Map<String, dynamic> safeMap;

              if (item is Map<String, dynamic>) {
                // 이미 정확한 타입인 경우
                safeMap = item;
              } else if (item is Map) {
                // 다른 Map 타입(예: _Map<String, dynamic>)인 경우 안전하게 변환
                safeMap = Map<String, dynamic>.from(item);
              } else {
                // Map이 아닌 경우 예외 발생
                throw FormatException('예상치 못한 데이터 타입: ${item.runtimeType}');
              }

              try {
                // fromJson 실행 및 예외 포착
                return fromJson(safeMap);
              } catch (conversionError) {
                print('fromJson 변환 오류: $conversionError, 데이터: $safeMap');
                throw FormatException('fromJson 변환 실패: $conversionError');
              }
            } catch (e) {
              print('데이터 변환 오류: $e, 데이터 타입: ${item.runtimeType}, 데이터: $item');
              // 비어있는 데이터로 판단되면 건너뛰기 (필터링을 위해 null 반환)
              return null;
            }
          })
          .whereType<T>()
          .toList(); // null 값 필터링

      return ApiResponse<List<T>>.success(items);
    } catch (e) {
      print('Supabase 쿼리 오류: $e');
      return ApiResponse<List<T>>.failure(ApiError(
        code: 'supabase_error',
        message: e.toString(),
      ));
    }
  }

  @override
  Future<ApiResponse<T?>> getRecord<T>({
    required String table,
    required String id,
    required T Function(Map<String, dynamic>) fromJson,
    List<String>? columns,
  }) async {
    try {
      final data =
          await _client.from(table).select(columns?.join(',') ?? '*').eq('id', id).maybeSingle();

      if (data == null) {
        return ApiResponse.success(null);
      }

      try {
        // 안전한 타입 변환
        Map<String, dynamic> safeMap;

        // 이미 정확한 타입인 경우
        safeMap = data;

        try {
          // fromJson 실행 및 예외 포착
          return ApiResponse.success(fromJson(safeMap));
        } catch (conversionError) {
          print('fromJson 변환 오류: $conversionError, 데이터: $safeMap');
          return ApiResponse.failure(
            ApiError(
              code: 'db/conversion-error',
              message: 'fromJson 변환 실패: $conversionError',
            ),
          );
        }
      } catch (conversionError) {
        print('데이터 변환 오류: $conversionError, 데이터 타입: ${data.runtimeType}, 데이터: $data');
        return ApiResponse.failure(
          ApiError(
            code: 'db/format-error',
            message: '잘못된 데이터 형식: $conversionError',
          ),
        );
      }
    } catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'db/get-error',
          message: '데이터 조회 중 오류가 발생했습니다: $e',
        ),
      );
    }
  }

  @override
  Future<ApiResponse<T>> createRecord<T>({
    required String table,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await _client.from(table).insert(data).select().single();

      try {
        // 안전한 타입 변환
        final Map<String, dynamic> safeMap = Map<String, dynamic>.from(response);
        return ApiResponse.success(fromJson(safeMap));
      } catch (conversionError) {
        print('레코드 생성 결과 변환 오류: $conversionError, 데이터: $response');
        return ApiResponse.failure(
          ApiError(
            code: 'db/conversion-error',
            message: '데이터 변환 오류: $conversionError',
          ),
        );
      }
    } on PostgrestException catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'db/${e.code}',
          message: e.message,
        ),
      );
    } catch (e) {
      print('레코드 생성 오류: $e');
      return ApiResponse.failure(
        ApiError(
          code: 'db/unexpected-error',
          message: '데이터 생성 중 오류가 발생했습니다: $e',
        ),
      );
    }
  }

  @override
  Future<ApiResponse<T>> updateRecord<T>({
    required String table,
    required String id,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final response = await _client.from(table).update(data).eq('id', id).select().single();

      try {
        // 안전한 타입 변환
        final Map<String, dynamic> safeMap = Map<String, dynamic>.from(response);
        return ApiResponse.success(fromJson(safeMap));
      } catch (conversionError) {
        print('레코드 업데이트 결과 변환 오류: $conversionError, 데이터: $response');
        return ApiResponse.failure(
          ApiError(
            code: 'db/conversion-error',
            message: '데이터 변환 오류: $conversionError',
          ),
        );
      }
    } on PostgrestException catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'db/${e.code}',
          message: e.message,
        ),
      );
    } catch (e) {
      print('레코드 업데이트 오류: $e');
      return ApiResponse.failure(
        ApiError(
          code: 'db/unexpected-error',
          message: '데이터 업데이트 중 오류가 발생했습니다: $e',
        ),
      );
    }
  }

  @override
  Future<ApiResponse<void>> deleteRecord({
    required String table,
    required String id,
  }) async {
    try {
      await _client.from(table).delete().eq('id', id);
      return ApiResponse.success(null);
    } on PostgrestException catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'db/${e.code}',
          message: e.message,
        ),
      );
    } catch (e) {
      return ApiResponse.failure(
        ApiError(
          code: 'db/unexpected-error',
          message: '데이터 삭제 중 오류가 발생했습니다: $e',
        ),
      );
    }
  }
}

/// Supabase 클라이언트 프로바이더
final supabaseClientImplProvider = riverpod.Provider<ISupabaseClient>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseClientImpl(client);
});
