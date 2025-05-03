import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 특정 ID의 비디오를 가져오는 프로바이더
final videoByIdProvider = FutureProvider.family<Video, String>((ref, videoId) async {
  final videoService = ref.watch(videoServiceProvider);
  final response = await videoService.getVideoDetails(videoId: videoId);

  return response.fold(
    onSuccess: (video) => video,
    onFailure: (error) => throw error,
  );
});

/// 관련 비디오를 가져오는 프로바이더
final relatedVideosProvider = FutureProvider.family<List<Video>, String>((ref, videoId) async {
  try {
    final video = await ref.watch(videoByIdProvider(videoId).future);
    final videoService = ref.watch(videoServiceProvider);

    // artist_id가 비어있거나 null인 경우 검증
    if (video.artistId.isEmpty) {
      debugPrint('관련 비디오를 artist_id 기반으로 불러올 수 없음: 비디오의 artist_id가 비어있습니다.');

      // 대체 방법: 인기 비디오 가져오기
      debugPrint('대신 인기 비디오를 가져옵니다.');

      final response = await videoService.getTrendingVideos(limit: 10);

      return response.fold(
        onSuccess: (videos) {
          // 타입 안전성 보장을 위한 변환 로직 개선
          final typeSafeVideos = videos
              .map((dynamic v) {
                if (v is Video) {
                  return v;
                } else if (v is Map) {
                  try {
                    // Map을 안전하게 Video로 변환하기 위해 Map<String, dynamic>으로 먼저 캐스팅
                    final Map<String, dynamic> videoMap = Map<String, dynamic>.from(v);
                    return Video.fromJson(videoMap);
                  } catch (e) {
                    debugPrint('Video 변환 오류: $e');
                    return null;
                  }
                } else {
                  debugPrint('지원되지 않는 데이터 타입: ${v.runtimeType}');
                  return null;
                }
              })
              .whereType<Video>()
              .where((v) => v.id != videoId)
              .toList();

          return typeSafeVideos;
        },
        onFailure: (error) {
          debugPrint('인기 비디오 로딩 오류: $error');
          return []; // 오류 발생시 빈 배열 반환
        },
      );
    }

    // UUID 형식 검증 (간단한 검증)
    final uuidRegExp = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
    if (!uuidRegExp.hasMatch(video.artistId)) {
      debugPrint('관련 비디오를 불러올 수 없음: 유효하지 않은 artist_id 형식: ${video.artistId}');

      // 대체 방법: 인기 비디오 가져오기
      debugPrint('대신 인기 비디오를 가져옵니다.');

      final response = await videoService.getTrendingVideos(limit: 10);

      return response.fold(
        onSuccess: (videos) {
          // 타입 안전성 보장을 위한 변환 로직 개선
          final typeSafeVideos = videos
              .map((dynamic v) {
                if (v is Video) {
                  return v;
                } else if (v is Map) {
                  try {
                    // Map을 안전하게 Video로 변환하기 위해 Map<String, dynamic>으로 먼저 캐스팅
                    final Map<String, dynamic> videoMap = Map<String, dynamic>.from(v);
                    return Video.fromJson(videoMap);
                  } catch (e) {
                    debugPrint('Video 변환 오류: $e');
                    return null;
                  }
                } else {
                  debugPrint('지원되지 않는 데이터 타입: ${v.runtimeType}');
                  return null;
                }
              })
              .whereType<Video>()
              .where((v) => v.id != videoId)
              .toList();

          return typeSafeVideos;
        },
        onFailure: (error) {
          debugPrint('인기 비디오 로딩 오류: $error');
          return []; // 오류 발생시 빈 배열 반환
        },
      );
    }

    // 아티스트 ID 기반으로 관련 비디오 가져오기
    final response = await videoService.getArtistVideos(
      artistId: video.artistId,
    );

    return response.fold(
      onSuccess: (videos) {
        // 타입 안전성 보장을 위한 변환 로직 개선
        final typeSafeVideos = videos
            .map((dynamic v) {
              if (v is Video) {
                return v;
              } else if (v is Map) {
                try {
                  // Map을 안전하게 Video로 변환하기 위해 Map<String, dynamic>으로 먼저 캐스팅
                  final Map<String, dynamic> videoMap = Map<String, dynamic>.from(v);
                  return Video.fromJson(videoMap);
                } catch (e) {
                  debugPrint('Video 변환 오류: $e');
                  return null;
                }
              } else {
                debugPrint('지원되지 않는 데이터 타입: ${v.runtimeType}');
                return null;
              }
            })
            .whereType<Video>()
            .where((v) => v.id != videoId)
            .toList();

        return typeSafeVideos;
      },
      onFailure: (error) {
        debugPrint('관련 비디오 로딩 오류: $error');
        return []; // 오류 발생시 빈 배열 반환
      },
    );
  } catch (e) {
    debugPrint('관련 비디오 로딩 중 예외 발생: $e');
    return []; // 예외 발생시 빈 배열 반환
  }
});
