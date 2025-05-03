import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cache/video_cache.dart';

/// SharedPreferences 프로바이더
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider는 메인에서 초기화해야 합니다');
});

/// VideoCache 프로바이더
final videoCacheProvider = Provider<VideoCache>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return VideoCache(sharedPreferences: sharedPreferences);
});
