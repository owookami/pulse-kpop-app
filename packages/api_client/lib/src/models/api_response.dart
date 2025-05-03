import 'api_error.dart';

/// API 응답 모델
///
/// API 호출 결과를 담는 클래스로, 성공 또는 실패 상태를 포함합니다.
sealed class ApiResponse<T> {
  /// 기본 생성자
  const ApiResponse();

  /// 성공 응답 팩토리 생성자
  factory ApiResponse.success(T data) => ApiResponseSuccess<T>(data: data);

  /// 실패 응답 팩토리 생성자
  factory ApiResponse.failure(ApiError error) => ApiResponseFailure<T>(error: error);

  /// 응답이 성공인지 확인
  bool get isSuccess => this is ApiResponseSuccess<T>;

  /// 응답이 실패인지 확인
  bool get isFailure => this is ApiResponseFailure<T>;

  /// 성공 데이터 반환 (실패인 경우 null)
  T? get dataOrNull {
    if (this is ApiResponseSuccess<T>) {
      return (this as ApiResponseSuccess<T>).data;
    }
    return null;
  }

  /// 에러 반환 (성공인 경우 null)
  ApiError? get errorOrNull {
    if (this is ApiResponseFailure<T>) {
      return (this as ApiResponseFailure<T>).error;
    }
    return null;
  }

  /// 성공인 경우 콜백 실행
  void whenSuccess(void Function(T data) onSuccess) {
    if (this is ApiResponseSuccess<T>) {
      onSuccess((this as ApiResponseSuccess<T>).data);
    }
  }

  /// 실패인 경우 콜백 실행
  void whenFailure(void Function(ApiError error) onFailure) {
    if (this is ApiResponseFailure<T>) {
      onFailure((this as ApiResponseFailure<T>).error);
    }
  }

  /// 성공/실패에 따라 다른 콜백 실행
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(ApiError error) onFailure,
  }) {
    if (this is ApiResponseSuccess<T>) {
      return onSuccess((this as ApiResponseSuccess<T>).data);
    } else {
      return onFailure((this as ApiResponseFailure<T>).error);
    }
  }
}

/// 성공 응답
final class ApiResponseSuccess<T> extends ApiResponse<T> {
  /// 성공 응답 생성자
  const ApiResponseSuccess({required this.data});

  /// 응답 데이터
  final T data;
}

/// 실패 응답
final class ApiResponseFailure<T> extends ApiResponse<T> {
  /// 실패 응답 생성자
  const ApiResponseFailure({required this.error});

  /// 에러 정보
  final ApiError error;
}
