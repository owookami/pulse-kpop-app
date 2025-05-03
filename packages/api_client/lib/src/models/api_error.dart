import 'package:meta/meta.dart';

/// API 에러 모델
///
/// 애플리케이션 에러를 나타내는 클래스입니다.
@immutable
class ApiError {
  /// API 에러 생성자
  const ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  /// 에러 코드
  final String code;

  /// 에러 메시지
  final String message;

  /// 추가 정보
  final Map<String, dynamic>? details;

  /// 네트워크 에러 팩토리 생성자
  factory ApiError.network(String message) {
    return ApiError(
      code: 'network_error',
      message: message,
    );
  }

  /// 인증 에러 팩토리 생성자
  factory ApiError.auth(String message) {
    return ApiError(
      code: 'auth_error',
      message: message,
    );
  }

  /// 서버 에러 팩토리 생성자
  factory ApiError.server(String message) {
    return ApiError(
      code: 'server_error',
      message: message,
    );
  }

  /// 데이터 에러 팩토리 생성자
  factory ApiError.data(String message, [Map<String, dynamic>? details]) {
    return ApiError(
      code: 'data_error',
      message: message,
      details: details,
    );
  }

  /// JSON으로부터 에러 객체 생성
  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String,
      message: json['message'] as String,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  /// 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'details': details,
    };
  }

  /// 복사본 생성
  ApiError copyWith({
    String? code,
    String? message,
    Map<String, dynamic>? details,
  }) {
    return ApiError(
      code: code ?? this.code,
      message: message ?? this.message,
      details: details ?? this.details,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiError &&
        other.code == code &&
        other.message == message &&
        _mapsEqual(other.details, details);
  }

  @override
  int get hashCode => Object.hash(code, message, details);

  @override
  String toString() {
    return 'ApiError(code: $code, message: $message)';
  }

  /// 두 맵이 동일한지 비교
  bool _mapsEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }

    return true;
  }
}
