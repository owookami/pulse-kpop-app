import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/video.dart';
import 'cache.dart';

/// 비디오 캐시 프로바이더
final videoCacheProvider = Provider<VideoCache>((ref) {
  return VideoCache();
});

/// 비디오 캐시 클래스
///
/// 비디오 데이터의 로컬 캐싱을 담당하는 클래스입니다.
class VideoCache implements Cache {
  /// 생성자
  VideoCache({SharedPreferences? sharedPreferences}) {
    if (sharedPreferences != null) {
      _prefs = sharedPreferences;
      _initialized = true;
    } else {
      initialize();
    }
  }

  late SharedPreferences _prefs;
  bool _initialized = false;

  // 캐시 키 (접두사)
  static const String _trendingVideosKey = 'video_cache_trending';
  static const String _risingVideosKey = 'video_cache_rising';
  static const String _videoDetailsKey = 'video_cache_details_';
  static const String _voteInfoKey = 'video_cache_vote_';
  static const String _bookmarksKey = 'video_cache_bookmarks_';
  static const String _artistVideosKey = 'video_cache_artist_';

  // 캐시 유효 기간 (시간 단위)
  static const int _cacheDurationHours = 24;
  static const int _artistVideosCacheDurationHours = 12;

  @override
  Future<void> initialize() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  @override
  bool isValidCache(String key) {
    if (!_initialized) return false;

    // 캐시 데이터 존재 여부 확인
    final cacheData = _prefs.getString(key);
    if (cacheData == null) return false;

    // 캐시 타임스탬프 확인
    final timestampKey = '${key}_timestamp';
    final timestamp = _prefs.getInt(timestampKey);
    if (timestamp == null) return false;

    // 현재 시간과 비교하여 유효기간 확인
    final now = DateTime.now().millisecondsSinceEpoch;

    // 캐시 기간 결정 (아티스트 비디오는 더 짧은 캐시 기간 적용)
    final cacheDurationMillis = key.startsWith(_artistVideosKey)
        ? _artistVideosCacheDurationHours * 60 * 60 * 1000
        : _cacheDurationHours * 60 * 60 * 1000;

    return (now - timestamp) < cacheDurationMillis;
  }

  @override
  SharedPreferences getPreferences() {
    return _prefs;
  }

  @override
  Future<void> invalidateCache(String key) async {
    if (!_initialized) await initialize();

    await _prefs.remove(key);
    await _prefs.remove('${key}_timestamp');
  }

  @override
  Future<void> clearAll() async {
    if (!_initialized) await initialize();

    // 비디오 관련 캐시만 삭제
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('video_cache_')) {
        await _prefs.remove(key);
      }
    }
  }

  /// 인기 비디오 캐싱
  Future<void> cacheTrendingVideos(List<Video> videos) async {
    if (!_initialized) await initialize();

    final jsonData = json.encode(videos.map((video) => video.toJson()).toList());
    await _prefs.setString(_trendingVideosKey, jsonData);
    await _prefs.setInt('${_trendingVideosKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// 인기 비디오 조회
  List<Video>? getTrendingVideos() {
    if (!isValidCache(_trendingVideosKey)) return null;

    final jsonData = _prefs.getString(_trendingVideosKey);
    if (jsonData == null) return null;

    try {
      final List<dynamic> videoList = json.decode(jsonData);
      return videoList.map((data) => Video.fromJson(data as Map<String, dynamic>)).toList();
    } catch (e) {
      // 캐시 파싱 실패 시 캐시 삭제
      invalidateCache(_trendingVideosKey);
      return null;
    }
  }

  /// 최신 비디오 캐싱
  Future<void> cacheRisingVideos(List<Video> videos) async {
    if (!_initialized) await initialize();

    final jsonData = json.encode(videos.map((video) => video.toJson()).toList());
    await _prefs.setString(_risingVideosKey, jsonData);
    await _prefs.setInt('${_risingVideosKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// 최신 비디오 조회
  List<Video>? getRisingVideos() {
    if (!isValidCache(_risingVideosKey)) return null;

    final jsonData = _prefs.getString(_risingVideosKey);
    if (jsonData == null) return null;

    try {
      final List<dynamic> videoList = json.decode(jsonData);
      return videoList.map((data) => Video.fromJson(data as Map<String, dynamic>)).toList();
    } catch (e) {
      // 캐시 파싱 실패 시 캐시 삭제
      invalidateCache(_risingVideosKey);
      return null;
    }
  }

  /// 비디오 상세정보 캐싱
  Future<void> cacheVideoDetails(Video video) async {
    if (!_initialized) await initialize();

    final key = '$_videoDetailsKey${video.id}';
    final jsonData = json.encode(video.toJson());
    await _prefs.setString(key, jsonData);
    await _prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// 비디오 상세정보 조회
  Video? getVideoDetails(String videoId) {
    final key = '$_videoDetailsKey$videoId';
    if (!isValidCache(key)) return null;

    final jsonData = _prefs.getString(key);
    if (jsonData == null) return null;

    try {
      final Map<String, dynamic> videoData = json.decode(jsonData);
      return Video.fromJson(videoData);
    } catch (e) {
      // 캐시 파싱 실패 시 캐시 삭제
      invalidateCache(key);
      return null;
    }
  }

  /// 투표 정보 캐싱
  Future<void> cacheVoteInfo(String videoId, Map<String, dynamic> voteInfo) async {
    if (!_initialized) await initialize();

    final key = '$_voteInfoKey$videoId';
    final jsonData = json.encode(voteInfo);
    await _prefs.setString(key, jsonData);
    await _prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// 투표 정보 조회
  Map<String, dynamic>? getVoteInfo(String videoId) {
    final key = '$_voteInfoKey$videoId';
    if (!isValidCache(key)) return null;

    final jsonData = _prefs.getString(key);
    if (jsonData == null) return null;

    try {
      return json.decode(jsonData);
    } catch (e) {
      // 캐시 파싱 실패 시 캐시 삭제
      invalidateCache(key);
      return null;
    }
  }

  /// 아티스트 비디오 캐싱
  Future<void> cacheArtistVideos(String artistId, List<Video> videos) async {
    if (!_initialized) await initialize();

    debugPrint('아티스트 비디오 캐싱: $artistId, ${videos.length}개');

    final key = '$_artistVideosKey$artistId';
    final jsonData = json.encode(videos.map((video) => video.toJson()).toList());
    await _prefs.setString(key, jsonData);
    await _prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// 아티스트 비디오 조회
  List<Video>? getArtistVideos(String artistId) {
    final key = '$_artistVideosKey$artistId';
    if (!isValidCache(key)) return null;

    final jsonData = _prefs.getString(key);
    if (jsonData == null) return null;

    try {
      final List<dynamic> videoList = json.decode(jsonData);
      return videoList.map((data) => Video.fromJson(data as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('아티스트 비디오 캐시 파싱 실패: $e');
      // 캐시 파싱 실패 시 캐시 삭제
      invalidateCache(key);
      return null;
    }
  }
}
