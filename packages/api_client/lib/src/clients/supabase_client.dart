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

  /// Supabase 테이블에 접근
  dynamic from(String table);

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
  dynamic from(String table) => _client.from(table);

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

      // 필터 적용 (or 대신 정확한 필터를 위해 수정)
      dynamic filteredQuery = query;
      if (filter != null && filter.isNotEmpty) {
        print('필터 적용: $filter');
        // 여러 필터 조건이 있는 경우 (쉼표로 구분된)
        if (filter.contains(',')) {
          // 쉼표로 구분된 필터 조건을 개별 조건으로 분리
          final conditions = filter.split(',');
          for (final condition in conditions) {
            print('개별 필터 조건 적용: $condition');
            // 조건이 eq, neq, gt, lt 등의 형식인지 확인
            if (condition.contains('.eq.')) {
              final parts = condition.split('.eq.');
              if (parts.length == 2) {
                filteredQuery = filteredQuery.eq(parts[0], parts[1]);
              }
            } else if (condition.contains('.in.')) {
              final parts = condition.split('.in.');
              if (parts.length == 2) {
                // in 조건은 괄호 안에 쉼표로 구분된 값들을 포함
                final values = parts[1].replaceAll('(', '').replaceAll(')', '').split(',');
                filteredQuery = filteredQuery.in_(parts[0], values);
              }
            } else if (condition.startsWith('or(') && condition.endsWith(')')) {
              // or 조건인 경우 괄호 내용을 추출하여 처리
              try {
                final orContent = condition.substring(3, condition.length - 1);
                final orParts = orContent.split(',');

                String orConditions = '';
                for (final orPart in orParts) {
                  if (orConditions.isNotEmpty) {
                    orConditions += ',';
                  }
                  orConditions += orPart;
                }

                if (orConditions.isNotEmpty) {
                  filteredQuery = filteredQuery.or(orConditions);
                }
              } catch (e) {
                print('or 조건 처리 중 오류: $e');
                // 오류 발생 시 안전하게 진행
                continue;
              }
            } else {
              // 기타 필터 조건은 그대로 or로 처리
              try {
                filteredQuery = filteredQuery.or(condition);
              } catch (e) {
                print('필터 조건 적용 중 오류: $e, 조건: $condition');
                // 오류 발생 시 안전하게 진행
                continue;
              }
            }
          }
        } else if (filter.startsWith('or(') && filter.endsWith(')')) {
          // 단일 or 필터인 경우
          try {
            // or 괄호 안의 내용 추출
            final orContent = filter.substring(3, filter.length - 1);

            // 쉼표로 구분된 필터 조건 처리
            final conditions = orContent.split(',');

            if (conditions.length >= 2) {
              // 첫 번째 조건 적용
              String field1 = '', value1 = '';
              if (conditions[0].contains('.ilike.')) {
                final parts = conditions[0].split('.ilike.');
                if (parts.length == 2) {
                  field1 = parts[0];
                  value1 = parts[1];
                  filteredQuery = filteredQuery.ilike(field1, value1);
                }
              }

              // 두 번째 조건 적용 (or 조건)
              for (int i = 1; i < conditions.length; i++) {
                String condition = conditions[i];
                if (condition.contains('.ilike.')) {
                  final parts = condition.split('.ilike.');
                  if (parts.length == 2) {
                    String field = parts[0];
                    String value = parts[1];
                    filteredQuery = filteredQuery.or('$field.ilike.$value');
                  }
                }
              }
            } else {
              // 단일 조건인 경우 or 없이 적용
              filteredQuery = filteredQuery.or(orContent);
            }
          } catch (e) {
            print('or 필터 처리 중 오류: $e');
            // 실패 시 그대로 적용 시도
            try {
              filteredQuery = filteredQuery.or(filter);
            } catch (_) {
              print('필터 적용 실패, 필터링 없이 진행');
            }
          }
        } else {
          // 단일 필터 조건
          try {
            filteredQuery = filteredQuery.or(filter);
          } catch (e) {
            print('단일 필터 적용 오류: $e, 필터: $filter');
          }
        }
      }

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
            nullsFirst: false, // nulls last 설정
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
        // 먼저 limit 적용
        orderedQuery = orderedQuery.limit(limit);
        print('Limit 설정: $limit');
      }

      if (offset != null) {
        // offset이 있을 때만 range 메서드 적용
        // range 메서드는 start와 end 인덱스를 지정 (0부터 시작)
        // orderedQuery = orderedQuery.range(offset, offset + (limit ?? 20) - 1);
        // range 메서드 대신 offset 메서드 사용 (RangeError 해결)
        orderedQuery = orderedQuery.offset(offset);
        print('Offset 설정: $offset, Limit: ${limit ?? 20}');
      } else {
        // offset이 없는 경우 range 사용 안함 (처음부터 limit 개수만큼 가져옴)
        print('첫 페이지 로드: offset 사용 안함, limit만 사용: $limit');
      }

      // 쿼리 실행 전 로깅
      print(
          '쿼리 실행 전 최종 구성: table=$table, filter=$filter, orderBy=$orderBy, limit=$limit, offset=$offset');

      // 최대 3회 재시도 로직 추가
      int retryCount = 0;
      final maxRetries = 3;
      while (true) {
        try {
          final response = await orderedQuery.timeout(const Duration(seconds: 10));
          final List<dynamic> data = response as List<dynamic>;
          print('쿼리 결과 수: ${data.length}');

          // 타입 안전성 향상을 위한 변환 로직
          final List<T> items = [];

          for (final dynamic item in data) {
            try {
              // Supabase에서 반환된 데이터를 안전하게 Map<String, dynamic>으로 변환
              Map<String, dynamic> safeMap;

              if (item is Map<String, dynamic>) {
                // 이미 정확한 타입인 경우
                safeMap = item;
              } else if (item is Map) {
                // 다른 Map 타입(예: _Map<String, dynamic>)인 경우 명시적으로 변환
                safeMap = Map<String, dynamic>.from(item);
              } else {
                // Map이 아닌 경우 건너뛰기
                print('예상치 못한 데이터 타입 건너뛰기: ${item.runtimeType}');
                continue;
              }

              // fromJson 변환 시도
              final T convertedItem = fromJson(safeMap);
              items.add(convertedItem);
            } catch (e) {
              print('데이터 변환 실패: $e, 데이터: $item, 타입: ${item.runtimeType}');
              // 변환 실패 시 이 항목은 건너뛰기
            }
          }

          return ApiResponse<List<T>>.success(items);
        } catch (e) {
          retryCount++;
          print('Supabase 쿼리 오류 ($retryCount/$maxRetries): $e');

          if (retryCount >= maxRetries) {
            // 최대 재시도 횟수 초과
            return ApiResponse<List<T>>.failure(ApiError(
              code: 'network_error',
              message: '서버에 연결할 수 없습니다. 네트워크 연결을 확인하고 다시 시도해주세요.',
            ));
          }

          // 지수 백오프 적용 (1초, 2초, 4초...)
          final delay = Duration(milliseconds: 1000 * (1 << (retryCount - 1)));
          print('${delay.inMilliseconds}ms 후 재시도');
          await Future.delayed(delay);
        }
      }
    } catch (e) {
      print('Supabase 쿼리 오류: $e');
      return ApiResponse<List<T>>.failure(ApiError(
        code: 'supabase_error',
        message: '데이터를 가져오는 중 오류가 발생했습니다. 네트워크 연결 상태를 확인해주세요.',
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
      // 최대 3회 재시도 로직 추가
      int retryCount = 0;
      final maxRetries = 3;

      while (true) {
        try {
          final data = await _client
              .from(table)
              .select(columns?.join(',') ?? '*')
              .eq('id', id)
              .maybeSingle()
              .timeout(const Duration(seconds: 8));

          if (data == null) {
            return ApiResponse.success(null);
          }

          try {
            // 안전한 타입 변환
            Map<String, dynamic> safeMap;

            // 이미 정확한 타입인 경우
            safeMap = data;

            // fromJson 변환 시도
            try {
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
          retryCount++;
          print('Supabase getRecord 오류 ($retryCount/$maxRetries): $e');

          if (retryCount >= maxRetries) {
            // 최대 재시도 횟수 초과
            return ApiResponse.failure(
              ApiError(
                code: 'network_error',
                message: '서버에 연결할 수 없습니다. 네트워크 연결을 확인하고 다시 시도해주세요.',
              ),
            );
          }

          // 지수 백오프 적용 (1초, 2초, 4초...)
          final delay = Duration(milliseconds: 1000 * (1 << (retryCount - 1)));
          print('${delay.inMilliseconds}ms 후 재시도');
          await Future.delayed(delay);
        }
      }
    } catch (e) {
      print('레코드 조회 중 예외 발생: $e');
      return ApiResponse.failure(
        ApiError(
          code: 'db/get-error',
          message: '데이터를 조회할 수 없습니다. 네트워크 연결을 확인하고 다시 시도해주세요.',
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
        Map<String, dynamic> safeMap;

        safeMap = response;

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
        Map<String, dynamic> safeMap;

        safeMap = response;

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
