/// 캐시 인터페이스
///
/// 앱 데이터의 로컬 캐싱을 위한 기본 인터페이스입니다.
/// 이 인터페이스를 구현하는 클래스는 캐시 저장, 조회, 삭제 등의 기능을 제공해야 합니다.

import 'package:shared_preferences/shared_preferences.dart';

/// 공통 캐시 인터페이스
abstract class Cache {
  /// 캐시 초기화
  Future<void> initialize();

  /// 캐시 유효성 확인
  bool isValidCache(String key);

  /// SharedPreferences 인스턴스 반환
  SharedPreferences getPreferences();

  /// 캐시 무효화
  Future<void> invalidateCache(String key);

  /// 모든 캐시 삭제
  Future<void> clearAll();
}
