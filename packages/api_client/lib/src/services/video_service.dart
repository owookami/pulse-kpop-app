import 'dart:async'; // TimeoutException을 위한 import 추가

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/video_cache.dart';
import '../clients/supabase_client.dart';
import '../models/api_error.dart';
import '../models/api_response.dart';
import '../models/artist.dart';
import '../models/video.dart';
import '../providers/cache_providers.dart' as cache_providers;

/// 비디오 서비스 프로바이더
final videoServiceProvider = Provider<VideoService>((ref) {
  final supabaseClient = ref.watch(supabaseClientImplProvider);
  final videoCache = ref.watch(cache_providers.videoCacheProvider);
  return VideoService(supabaseClient, videoCache);
});

/// 네트워크 연결 상태 프로바이더
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  final connectivity = Connectivity();
  return connectivity.checkConnectivity().asStream().map((results) => results.first);
});

/// 오프라인 모드 상태 프로바이더
final isOfflineModeProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.maybeWhen(
    data: (result) => result == ConnectivityResult.none,
    orElse: () => false,
  );
});

/// 비디오 서비스 클래스
class VideoService {
  /// 생성자
  VideoService(this._client, this._cache) {
    // 캐시 초기화
    _initializeCache();
  }

  final ISupabaseClient _client;
  final VideoCache _cache;

  /// 네트워크 상태
  bool _isOffline = false;

  /// 캐시 초기화 메서드
  Future<void> _initializeCache() async {
    await _cache.initialize();
  }

  /// 네트워크 상태 설정
  void setNetworkStatus(bool isOffline) {
    _isOffline = isOffline;
  }

  /// 오프라인 여부 확인
  Future<bool> isOffline() async {
    if (_isOffline) return true;

    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    return result.first == ConnectivityResult.none;
  }

  /// 인기 비디오 목록 조회
  Future<ApiResponse<List<Video>>> getTrendingVideos({
    int limit = 50,
    String? lastId,
    bool forceRefresh = false,
  }) async {
    try {
      // 캐시 조회 로직
      final cacheKey = _trendingVideosKey;

      // 네트워크 상태 확인 (오프라인 또는 강제 캐시 사용 시)
      final offline = await isOffline();
      if (offline) {
        _isOffline = true;
      }

      // 네트워크가 없거나 캐시를 강제로 사용해야 하는 경우
      if (_isOffline || (!forceRefresh && _cache.isValidCache(cacheKey))) {
        final cachedVideos = _cache.getTrendingVideos();
        if (cachedVideos != null && cachedVideos.isNotEmpty) {
          final result = _applyPagination(cachedVideos, lastId, limit);
          return ApiResponse<List<Video>>.success(result);
        }
      }

      // 오프라인이면서 캐시도 없는 경우
      if (_isOffline) {
        return ApiResponse<List<Video>>.failure(ApiError(
          code: 'offline',
          message: '오프라인 모드입니다. 네트워크 연결을 확인하고 다시 시도해주세요.',
        ));
      }

      // 최적화된 재시도 로직 - 중복 보호 및 타임아웃 시간 증가
      int retryCount = 0;
      final maxRetries = 2; // 재시도 횟수 감소

      while (true) {
        try {
          // 온라인 API 호출 - 최신순 정렬로 변경 및 타임아웃 시간 증가
          print('인기 비디오 호출 시작: 제한=$limit, 마지막ID=$lastId');

          // 더 정확한 필터 로직 구현 - ID 기반 페이징
          String? filterCondition;
          if (lastId != null && lastId.isNotEmpty) {
            // ID 값이 문자열인 경우 "id.lt." 방식으로 필터링
            filterCondition = 'id.lt.$lastId';
            print('페이징 필터 적용: $filterCondition');
          } else {
            print('페이징 필터 없음: 첫 페이지 로드');
          }

          // Supabase 요청 준비 및 디버깅
          print(
              '쿼리 구성: table=videos, filter=$filterCondition, orderBy=created_at.desc, limit=$limit');

          final response = await _client
              .query<Video>(
                table: 'videos',
                fromJson: Video.fromJson,
                orderBy: 'created_at.desc', // 최신순 - 생성일 기준 내림차순 정렬
                limit: limit * 2, // 더 많은 데이터 요청하여 빈 결과 방지
                filter: filterCondition, // ID 기준 페이징
              )
              .timeout(const Duration(seconds: 15)); // 타임아웃 증가

          // 응답 로깅 강화
          final itemCount = response.isSuccess ? (response.dataOrNull?.length ?? 0) : 0;
          print('인기 비디오 API 응답: ${response.isSuccess ? '성공' : '실패'}, $itemCount개 항목');

          if (response.isSuccess && itemCount > 0) {
            final firstId = response.dataOrNull?.first.id;
            final lastItemId = response.dataOrNull?.last.id;
            print('첫 번째 ID: $firstId, 마지막 ID: $lastItemId');

            // ID 연속성 확인
            if (lastId != null && firstId == lastId) {
              print('경고: 첫 번째 ID가 마지막 ID와 같음 - 페이징 오류 가능성');
            }
          } else if (response.isSuccess && itemCount == 0) {
            print('경고: 성공적인 응답이지만 데이터 없음, lastId=$lastId');
          }

          // 성공 시 캐시 저장
          return response.fold(
            onSuccess: (videos) async {
              if (videos.isEmpty) {
                // 캐시에 저장된 비디오가 있는지 확인
                final cachedVideos = _cache.getTrendingVideos();
                if (cachedVideos != null && cachedVideos.isNotEmpty) {
                  return ApiResponse<List<Video>>.success(
                      _applyPagination(cachedVideos, lastId, limit));
                }
                return ApiResponse<List<Video>>.success([]);
              }

              // 캐시 저장 (백그라운드로 처리하여 UI 응답성 향상)
              _cache.cacheTrendingVideos(videos).catchError((e) {
                // 캐시 저장 실패해도 응답에는 영향 없음
              });

              final result = lastId == null ? videos : _applyPagination(videos, lastId, limit);
              return ApiResponse<List<Video>>.success(result);
            },
            onFailure: (error) {
              // 오류 발생 시 캐시 확인
              final cachedVideos = _cache.getTrendingVideos();
              if (cachedVideos != null && cachedVideos.isNotEmpty) {
                return ApiResponse<List<Video>>.success(
                    _applyPagination(cachedVideos, lastId, limit));
              }

              return ApiResponse<List<Video>>.failure(error);
            },
          );
        } catch (e) {
          retryCount++;

          if (retryCount >= maxRetries) {
            // 최대 재시도 횟수 초과, 캐시 확인
            final cachedVideos = _cache.getTrendingVideos();
            if (cachedVideos != null && cachedVideos.isNotEmpty) {
              return ApiResponse<List<Video>>.success(
                  _applyPagination(cachedVideos, lastId, limit));
            }

            // 캐시도 없으면 오류 반환
            return ApiResponse<List<Video>>.failure(ApiError(
              code: 'video_service/network-error',
              message: '서버에 연결할 수 없습니다. 네트워크 연결을 확인하고 다시 시도해주세요.',
            ));
          }

          // 지수 백오프 적용 (0.5초, 1초)
          final delay = Duration(milliseconds: 500 * (1 << (retryCount - 1)));
          await Future.delayed(delay);
        }
      }
    } catch (e) {
      // 예외 발생 시 캐시 확인
      final cachedVideos = _cache.getTrendingVideos();
      if (cachedVideos != null && cachedVideos.isNotEmpty) {
        return ApiResponse<List<Video>>.success(_applyPagination(cachedVideos, lastId, limit));
      }

      return ApiResponse<List<Video>>.failure(ApiError(
        code: 'video_service/trending-videos-error',
        message: '데이터를 불러올 수 없습니다. 네트워크 연결을 확인하고 다시 시도해주세요.',
      ));
    }
  }

  /// 최근 비디오 목록 조회
  Future<ApiResponse<List<Video>>> getRisingVideos({
    int limit = 50,
    String? lastId,
    bool forceRefresh = false,
  }) async {
    try {
      // 캐시 조회 로직
      final cacheKey = _risingVideosKey;

      // 네트워크 상태 확인 (오프라인 또는 강제 캐시 사용 시)
      final offline = await isOffline();
      if (offline) {
        _isOffline = true;
      }

      // 네트워크가 없거나 캐시를 강제로 사용해야 하는 경우
      if (_isOffline || (!forceRefresh && _cache.isValidCache(cacheKey))) {
        final cachedVideos = _cache.getRisingVideos();
        if (cachedVideos != null && cachedVideos.isNotEmpty) {
          final result = _applyPagination(cachedVideos, lastId, limit);
          return ApiResponse<List<Video>>.success(result);
        }
      }

      // 오프라인이면서 캐시도 없는 경우
      if (_isOffline) {
        return ApiResponse<List<Video>>.failure(ApiError(
          code: 'offline',
          message: '오프라인 모드입니다. 네트워크 연결을 확인하고 다시 시도해주세요.',
        ));
      }

      // 최적화된 재시도 로직
      int retryCount = 0;
      final maxRetries = 2; // 재시도 횟수 감소

      while (true) {
        try {
          // 온라인 API 호출 - 최신 비디오 순으로 정렬
          print('최신 비디오 호출 시작: 제한=$limit, 마지막ID=$lastId');
          final response = await _client
              .query<Video>(
                table: 'videos',
                fromJson: Video.fromJson,
                orderBy: 'created_at.desc', // 최신순 - 생성일 기준 내림차순 정렬
                limit: limit, // 명시적으로 limit 값 사용 (기본값 50)
                filter: lastId != null ? 'id.lt.$lastId' : null,
              )
              .timeout(const Duration(seconds: 15)); // 타임아웃 증가
          print(
              '최신 비디오 API 응답: ${response.isSuccess ? '성공' : '실패'}, ${response.isSuccess ? (response.dataOrNull?.length ?? 0) : 0}개 항목');

          // 성공 시 캐시 저장
          return response.fold(
            onSuccess: (videos) async {
              if (videos.isEmpty) {
                // 캐시에 저장된 비디오가 있는지 확인
                final cachedVideos = _cache.getRisingVideos();
                if (cachedVideos != null && cachedVideos.isNotEmpty) {
                  return ApiResponse<List<Video>>.success(
                      _applyPagination(cachedVideos, lastId, limit));
                }
                return ApiResponse<List<Video>>.success([]);
              }

              // 캐시 저장 (백그라운드로 처리하여 UI 응답성 향상)
              _cache.cacheRisingVideos(videos).catchError((e) {
                // 캐시 저장 실패해도 응답에는 영향 없음
              });

              final result = lastId == null ? videos : _applyPagination(videos, lastId, limit);
              return ApiResponse<List<Video>>.success(result);
            },
            onFailure: (error) {
              // 오류 발생 시 캐시 확인
              final cachedVideos = _cache.getRisingVideos();
              if (cachedVideos != null && cachedVideos.isNotEmpty) {
                return ApiResponse<List<Video>>.success(
                    _applyPagination(cachedVideos, lastId, limit));
              }

              return ApiResponse<List<Video>>.failure(error);
            },
          );
        } catch (e) {
          retryCount++;

          if (retryCount >= maxRetries) {
            // 최대 재시도 횟수 초과, 캐시 확인
            final cachedVideos = _cache.getRisingVideos();
            if (cachedVideos != null && cachedVideos.isNotEmpty) {
              return ApiResponse<List<Video>>.success(
                  _applyPagination(cachedVideos, lastId, limit));
            }

            // 캐시도 없으면 오류 반환
            return ApiResponse<List<Video>>.failure(ApiError(
              code: 'video_service/network-error',
              message: '서버에 연결할 수 없습니다. 네트워크 연결을 확인하고 다시 시도해주세요.',
            ));
          }

          // 지수 백오프 적용 (0.5초, 1초)
          final delay = Duration(milliseconds: 500 * (1 << (retryCount - 1)));
          await Future.delayed(delay);
        }
      }
    } catch (e) {
      // 예외 발생 시 캐시 확인
      final cachedVideos = _cache.getRisingVideos();
      if (cachedVideos != null && cachedVideos.isNotEmpty) {
        return ApiResponse<List<Video>>.success(_applyPagination(cachedVideos, lastId, limit));
      }

      return ApiResponse<List<Video>>.failure(ApiError(
        code: 'video_service/rising-videos-error',
        message: '데이터를 불러올 수 없습니다. 네트워크 연결을 확인하고 다시 시도해주세요.',
      ));
    }
  }

  /// 비디오 상세 정보 조회
  Future<ApiResponse<Video>> getVideoDetails({
    required String videoId,
    bool forceRefresh = false,
  }) async {
    try {
      // 캐시 조회 로직
      final cacheKey = '$_videoDetailsKey$videoId';

      // 네트워크가 없거나 캐시를 강제로 사용해야 하는 경우
      if (_isOffline || (!forceRefresh && _cache.isValidCache(cacheKey))) {
        final cachedVideo = _cache.getVideoDetails(videoId);
        if (cachedVideo != null) {
          return ApiResponse<Video>.success(cachedVideo);
        }
      }

      // 오프라인이면서 캐시도 없는 경우
      if (_isOffline) {
        return ApiResponse<Video>.failure(ApiError(
          code: 'offline',
          message: '오프라인 모드에서는 사용할 수 없습니다.',
        ));
      }

      // 온라인 API 호출
      final response = await _client.getRecord<Video>(
        table: 'videos',
        id: videoId,
        fromJson: Video.fromJson,
      );

      // 성공 시 캐시 저장
      return response.fold(
        onSuccess: (video) async {
          if (video != null) {
            await _cache.cacheVideoDetails(video);
          }
          return ApiResponse<Video>.success(video!);
        },
        onFailure: (error) => ApiResponse<Video>.failure(error),
      );
    } catch (e) {
      return ApiResponse<Video>.failure(ApiError(
        code: 'video_service/video-details-error',
        message: e.toString(),
      ));
    }
  }

  /// 아티스트별 비디오 목록 조회
  Future<ApiResponse<List<Video>>> getArtistVideos({
    required String artistId,
    int limit = 20,
    String? lastId,
    bool forceRefresh = false,
  }) async {
    try {
      // 캐시 조회 로직
      final cacheKey = '$_artistVideosKey$artistId';

      // 네트워크가 없거나 캐시를 강제로 사용해야 하는 경우
      if (_isOffline || (!forceRefresh && _cache.isValidCache(cacheKey))) {
        final cachedVideos = _cache.getArtistVideos(artistId);
        if (cachedVideos != null) {
          return ApiResponse<List<Video>>.success(_applyPagination(cachedVideos, lastId, limit));
        }
      }

      // 오프라인이면서 캐시도 없는 경우
      if (_isOffline) {
        return ApiResponse<List<Video>>.failure(ApiError(
          code: 'offline',
          message: '오프라인 모드에서는 사용할 수 없습니다.',
        ));
      }

      // 온라인 API 호출
      final filter =
          lastId != null ? 'artist_id.eq.$artistId,id.lt.$lastId' : 'artist_id.eq.$artistId';

      final response = await _client.query<Video>(
        table: 'videos',
        fromJson: Video.fromJson,
        orderBy: 'created_at.desc', // 최신순
        limit: limit,
        filter: filter,
      );

      // 성공 시 캐시 저장
      return response.fold(
        onSuccess: (videos) async {
          await _cache.cacheArtistVideos(artistId, videos);
          return ApiResponse<List<Video>>.success(
              lastId == null ? videos : _applyPagination(videos, lastId, limit));
        },
        onFailure: (error) => ApiResponse<List<Video>>.failure(error),
      );
    } catch (e) {
      return ApiResponse<List<Video>>.failure(ApiError(
        code: 'video_service/artist-videos-error',
        message: e.toString(),
      ));
    }
  }

  /// 아티스트 정보 조회
  Future<ApiResponse<Artist?>> getArtistDetails(String artistId) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 아티스트 정보를 불러올 수 없습니다.',
        ),
      );
    }

    return _client.getRecord<Artist>(
      table: 'artists',
      id: artistId,
      fromJson: Artist.fromJson,
    );
  }

  /// 인기 아티스트 목록 조회
  Future<ApiResponse<List<Artist>>> getPopularArtists({
    int limit = 10,
  }) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 인기 아티스트를 불러올 수 없습니다.',
        ),
      );
    }

    return _client.query<Artist>(
      table: 'artists',
      fromJson: Artist.fromJson,
      // 실제로는, 인기도나 영상 개수 등의 기준으로 정렬해야 함
      orderBy: 'name', // .asc 제거
      limit: limit,
    );
  }

  /// 비디오 검색
  Future<ApiResponse<List<Video>>> searchVideos({
    required String query,
    int limit = 20,
    String? lastId,
  }) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 검색을 사용할 수 없습니다.',
        ),
      );
    }

    try {
      // Supabase 직접 쿼리 사용
      var queryBuilder = _client.from('videos').select('*');

      // 제목 검색 (ilike 사용)
      queryBuilder = queryBuilder.ilike('title', '%$query%');

      // ID 기준 페이지네이션
      if (lastId != null) {
        queryBuilder = queryBuilder.lt('id', lastId);
      }

      // 정렬 및 한도 설정
      queryBuilder = queryBuilder.order('created_at', ascending: false).limit(limit);

      // 쿼리 실행
      final response = await queryBuilder;

      // 결과를 Video 객체로 변환
      final List<Video> videos = [];
      for (final item in response) {
        try {
          // PostgreSQL 결과는 Map<String, dynamic> 형태
          if (item is Map<String, dynamic>) {
            videos.add(Video.fromJson(item));
          }
        } catch (e) {
          print('비디오 데이터 변환 오류: $e');
        }
      }

      return ApiResponse.success(videos);
    } catch (e) {
      print('비디오 검색 오류: $e');
      return ApiResponse.failure(
        ApiError(
          code: 'search_error',
          message: '검색 중 오류가 발생했습니다: $e',
        ),
      );
    }
  }

  /// 아티스트 검색
  Future<ApiResponse<List<Artist>>> searchArtists({
    required String query,
    int limit = 20,
  }) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 검색을 사용할 수 없습니다.',
        ),
      );
    }

    // 검색어가 포함된 아티스트 이름 또는 그룹 이름 검색
    final filter = 'or(name.ilike.%$query%,group_name.ilike.%$query%)';

    return _client.query<Artist>(
      table: 'artists',
      fromJson: Artist.fromJson,
      orderBy: 'name', // .asc 제거
      limit: limit,
      filter: filter,
    );
  }

  /// 전체 캐시 초기화
  Future<void> clearCache() async {
    await _cache.clearAll();
  }

  /// 페이징 적용 - lastId 기준으로 다음 비디오 반환
  List<Video> _applyPagination(List<Video> videos, String? lastId, int limit) {
    print('_applyPagination 호출: videos.length=${videos.length}, lastId=$lastId, limit=$limit');

    if (videos.isEmpty) {
      print('비디오 목록이 비어있어 빈 리스트 반환');
      return [];
    }

    // 원래 로직에서는 lastId 유무에 따라 limit 개수만큼 반환했지만,
    // 무한 스크롤이 제대로 동작하지 않는 문제가 있어
    // 모든 비디오를 반환하도록 수정합니다.
    print('수정된 로직: 항상 모든 비디오 데이터 반환 (${videos.length}개)');

    if (videos.isNotEmpty) {
      print('반환되는 첫 번째 비디오 ID: ${videos[0].id}, 마지막 비디오 ID: ${videos[videos.length - 1].id}');
    }

    // 모든 비디오 반환
    return videos;
  }

  /// 인기 비디오 가져오기
  Future<List<Video>> getPopularVideos({int limit = 50}) async {
    final response = await getTrendingVideos(limit: limit);
    return response.fold(
      onSuccess: (videos) => videos,
      onFailure: (_) => const [],
    );
  }

  /// 아티스트 ID 목록으로 비디오 가져오기
  Future<List<Video>> getVideosByArtistIds({
    required List<String> artistIds,
    int limit = 50,
  }) async {
    if (artistIds.isEmpty) {
      return const [];
    }

    try {
      // 아티스트별로 비디오를 가져와서 조합
      final allVideos = <Video>[];

      for (final artistId in artistIds) {
        final response = await getArtistVideos(
          artistId: artistId,
          limit: limit ~/ artistIds.length + 1, // 골고루 분배
        );

        response.fold(
          onSuccess: (videos) => allVideos.addAll(videos),
          onFailure: (_) => null,
        );
      }

      // 중복 제거 및 정렬
      final uniqueVideos = <Video>[];
      final addedIds = <String>{};

      for (final video in allVideos) {
        if (!addedIds.contains(video.id)) {
          uniqueVideos.add(video);
          addedIds.add(video.id);
        }
      }

      // 원하는 개수만큼 자르기
      return uniqueVideos.take(limit).toList();
    } catch (e) {
      return const [];
    }
  }

  /// 비디오 좋아요/싫어요
  Future<ApiResponse<bool>> likeVideo({
    required String videoId,
    required bool isLike,
    bool cancel = false,
  }) async {
    try {
      // 오프라인 체크
      if (_isOffline) {
        return ApiResponse<bool>.failure(ApiError(
          code: 'offline',
          message: '오프라인 모드에서는 좋아요 기능을 사용할 수 없습니다.',
        ));
      }

      // 로그인 상태 체크
      if (!_client.isAuthenticated) {
        return ApiResponse<bool>.failure(ApiError(
          code: 'auth/not-authenticated',
          message: '로그인이 필요한 기능입니다.',
        ));
      }

      // API 호출
      final response = await _client.query<dynamic>(
        table: 'reviews',
        fromJson: (data) => data,
        filter: 'user_id.eq.${_client.currentUserId},video_id.eq.$videoId',
      );

      return await response.fold(
        onSuccess: (data) async {
          if (data.isEmpty) {
            // 리뷰가 없으면 새로 생성
            final createResponse = await _client.createRecord(
              table: 'reviews',
              data: {
                'user_id': _client.currentUserId,
                'video_id': videoId,
                'liked': isLike ? !cancel : null, // 좋아요면 !cancel, 싫어요면 null
                'disliked': !isLike ? !cancel : null, // 싫어요면 !cancel, 좋아요면 null
              },
              fromJson: (data) => data,
            );

            // 좋아요/싫어요 개수 업데이트
            await _updateVideoLikesCount(videoId);

            // 캐시 무효화 (최신 데이터를 가져오도록)
            _cache.invalidateCache('$_voteInfoKey$videoId');

            return createResponse.fold(
              onSuccess: (_) => ApiResponse<bool>.success(true),
              onFailure: (error) => ApiResponse<bool>.failure(error),
            );
          } else {
            // 기존 리뷰 업데이트
            final reviewId = data[0]['id'];
            final updateResponse = await _client.updateRecord(
              table: 'reviews',
              id: reviewId,
              data: {
                'liked': isLike ? !cancel : null, // 좋아요면 !cancel, 싫어요면 null
                'disliked': !isLike ? !cancel : null, // 싫어요면 !cancel, 좋아요면 null
              },
              fromJson: (data) => data,
            );

            // 좋아요/싫어요 개수 업데이트
            await _updateVideoLikesCount(videoId);

            // 캐시 무효화 (최신 데이터를 가져오도록)
            _cache.invalidateCache('$_voteInfoKey$videoId');

            return updateResponse.fold(
              onSuccess: (_) => ApiResponse<bool>.success(true),
              onFailure: (error) => ApiResponse<bool>.failure(error),
            );
          }
        },
        onFailure: (error) => ApiResponse<bool>.failure(error),
      );
    } catch (e) {
      return ApiResponse<bool>.failure(ApiError(
        code: 'video_service/like-video-error',
        message: e.toString(),
      ));
    }
  }

  /// 비디오의 좋아요/싫어요 개수 업데이트
  Future<Map<String, int>> _updateVideoLikesCount(String videoId) async {
    try {
      // 좋아요/싫어요 개수 계산
      final likesResponse = await _client.query<dynamic>(
        table: 'reviews',
        fromJson: (data) => data,
        filter: 'video_id.eq.$videoId,liked.eq.true',
      );

      final dislikesResponse = await _client.query<dynamic>(
        table: 'reviews',
        fromJson: (data) => data,
        filter: 'video_id.eq.$videoId,disliked.eq.true',
      );

      final likes = likesResponse.isSuccess ? likesResponse.dataOrNull?.length ?? 0 : 0;
      final dislikes = dislikesResponse.isSuccess ? dislikesResponse.dataOrNull?.length ?? 0 : 0;

      print('비디오($videoId) 좋아요 개수: $likes, 싫어요 개수: $dislikes');

      // 비디오 테이블 업데이트
      final updateResponse = await _client.updateRecord(
        table: 'videos',
        id: videoId,
        data: {
          'like_count': likes,
          'dislike_count': dislikes,
        },
        fromJson: (data) => data,
      );

      if (updateResponse.isFailure) {
        print('비디오 좋아요/싫어요 개수 업데이트 실패: ${updateResponse.errorOrNull?.message}');
      } else {
        print('비디오 좋아요/싫어요 개수 업데이트 성공');
      }

      return {'likes': likes, 'dislikes': dislikes};
    } catch (e) {
      // 오류 로깅만 하고 실패해도 계속 진행
      print('비디오 좋아요 카운트 업데이트 실패: $e');
      return {'likes': 0, 'dislikes': 0};
    }
  }

  /// 비디오 별점 평가
  Future<ApiResponse<double>> rateVideo({
    required String videoId,
    required double rating,
  }) async {
    try {
      // 오프라인 체크
      if (_isOffline) {
        return ApiResponse<double>.failure(ApiError(
          code: 'offline',
          message: '오프라인 모드에서는 평가 기능을 사용할 수 없습니다.',
        ));
      }

      // 로그인 상태 체크
      if (!_client.isAuthenticated) {
        return ApiResponse<double>.failure(ApiError(
          code: 'auth/not-authenticated',
          message: '로그인이 필요한 기능입니다.',
        ));
      }

      // 기존 리뷰 확인
      final response = await _client.query<dynamic>(
        table: 'reviews',
        fromJson: (data) => data,
        filter: 'user_id.eq.${_client.currentUserId},video_id.eq.$videoId',
      );

      return await response.fold(
        onSuccess: (data) async {
          bool isNewRating = false;
          double? previousRating;

          if (data.isEmpty) {
            // 리뷰가 없으면 새로 생성
            isNewRating = true;
            print('새 별점 평가 생성: 비디오=$videoId, 별점=$rating');

            final createResponse = await _client.createRecord(
              table: 'reviews',
              data: {
                'user_id': _client.currentUserId,
                'video_id': videoId,
                'rating': rating,
              },
              fromJson: (data) => data,
            );

            if (createResponse.isFailure) {
              print('새 별점 평가 생성 실패: ${createResponse.errorOrNull?.message}');
              return ApiResponse<double>.failure(createResponse.errorOrNull!);
            }

            print('새 별점 평가 생성 성공');
          } else {
            // 기존 리뷰 업데이트
            final reviewId = data[0]['id'];
            previousRating = data[0]['rating']?.toDouble();
            isNewRating = previousRating == null;

            print('기존 별점 평가 업데이트: 비디오=$videoId, 이전별점=$previousRating, 새별점=$rating');

            final updateResponse = await _client.updateRecord(
              table: 'reviews',
              id: reviewId,
              data: {
                'rating': rating,
              },
              fromJson: (data) => data,
            );

            if (updateResponse.isFailure) {
              print('별점 평가 업데이트 실패: ${updateResponse.errorOrNull?.message}');
              return ApiResponse<double>.failure(updateResponse.errorOrNull!);
            }

            print('별점 평가 업데이트 성공');
          }

          // 먼저 캐시 무효화 (통계 업데이트 전에도 최신 정보를 보장하기 위해)
          _cache.invalidateCache('$_voteInfoKey$videoId');

          // 비디오의 평균 평점 및 투표 수 업데이트
          await _updateVideoRatingStats(videoId, isNewRating, rating, previousRating);

          return ApiResponse<double>.success(rating);
        },
        onFailure: (error) {
          print('별점 평가 쿼리 실패: ${error.message}');
          return ApiResponse<double>.failure(error);
        },
      );
    } catch (e) {
      print('별점 평가 예외 발생: $e');
      return ApiResponse<double>.failure(ApiError(
        code: 'video_service/rate-video-error',
        message: e.toString(),
      ));
    }
  }

  /// 비디오의 평균 평점 및 투표 수 업데이트
  Future<void> _updateVideoRatingStats(
      String videoId, bool isNewRating, double newRating, double? previousRating) async {
    try {
      // 별점 평가 정보 통계 계산
      final ratingsResponse = await _client.query<dynamic>(
        table: 'reviews',
        fromJson: (data) => data,
        filter: 'video_id.eq.$videoId,rating.not.is.null',
      );

      if (ratingsResponse.isFailure) {
        print('별점 통계 조회 실패: ${ratingsResponse.errorOrNull?.message}');
        return;
      }

      final ratings = ratingsResponse.dataOrNull ?? [];
      final ratingCount = ratings.length;

      // 별점이 없는 경우 통계를 업데이트하지 않음
      if (ratingCount == 0) {
        print('별점이 없어 통계 업데이트를 건너뜁니다: 비디오=$videoId');
        return;
      }

      // 실제 평균 평점 계산 (소수점 둘째자리까지)
      double totalRating = 0;
      for (var review in ratings) {
        double rating = (review['rating'] ?? 0).toDouble();
        totalRating += rating;
      }
      double averageRating = double.parse((totalRating / ratingCount).toStringAsFixed(2));

      print('별점 통계 계산 결과: 비디오=$videoId, 평균=$averageRating, 참여자수=$ratingCount');

      // 현재 비디오 정보 가져오기
      final videoResponse = await _client.getRecord<dynamic>(
        table: 'videos',
        id: videoId,
        fromJson: (data) => data,
      );

      if (videoResponse.isFailure || videoResponse.dataOrNull == null) {
        print('비디오 정보를 가져올 수 없어 평점 통계를 업데이트할 수 없습니다: 비디오=$videoId');
        return;
      }

      final videoData = videoResponse.dataOrNull!;
      final currentRatingCount = videoData['rating_count']?.toInt() ?? 0;
      final currentAverage = videoData['average_rating']?.toDouble() ?? 0.0;

      print(
          '비디오 현재 정보: 비디오=$videoId, DB평균=$currentAverage, DB참여자수=$currentRatingCount, 실제평균=$averageRating, 실제참여자수=$ratingCount');

      // 비디오 테이블 업데이트
      final updateResponse = await _client.updateRecord(
        table: 'videos',
        id: videoId,
        data: {
          'average_rating': averageRating,
          'rating_count': ratingCount,
        },
        fromJson: (data) => data,
      );

      if (updateResponse.isFailure) {
        print('별점 통계 업데이트 실패: ${updateResponse.errorOrNull?.message}');
        return;
      }

      print('별점 통계 업데이트 성공: 비디오=$videoId, 평균=$averageRating, 참여자수=$ratingCount');
    } catch (e) {
      print('별점 통계 업데이트 예외 발생: $e');
    }
  }

  /// 비디오 투표 정보 조회
  Future<ApiResponse<Map<String, dynamic>>> getVoteInfo({
    required String videoId,
    bool forceRefresh = false,
  }) async {
    try {
      // 캐시 조회 로직
      final cacheKey = '$_voteInfoKey$videoId';

      // 네트워크가 없거나 캐시를 강제로 사용해야 하는 경우
      if (_isOffline || (!forceRefresh && _cache.isValidCache(cacheKey))) {
        final cachedInfo = _cache.getVoteInfo(videoId);
        if (cachedInfo != null) {
          print('캐시에서 비디오 투표 정보 로드: $cachedInfo');
          return ApiResponse<Map<String, dynamic>>.success(cachedInfo);
        }
      }

      // 오프라인이면서 캐시도 없는 경우
      if (_isOffline) {
        return ApiResponse<Map<String, dynamic>>.failure(ApiError(
          code: 'offline',
          message: '오프라인 모드에서는 사용할 수 없습니다.',
        ));
      }

      print('서버에서 비디오 투표 정보 로드 시작: 비디오=$videoId');

      // 사용자가 로그인했는지 확인
      final String? userId = _client.isAuthenticated ? _client.currentUserId : null;

      // 1. 사용자의 평가 정보 로드 (로그인한 경우)
      double? userRating;
      bool isLiked = false;
      bool isDisliked = false;

      if (userId != null) {
        final userReviewResponse = await _client.query<dynamic>(
          table: 'reviews',
          fromJson: (data) => data,
          filter: 'user_id.eq.$userId,video_id.eq.$videoId',
        );

        if (userReviewResponse.isSuccess && userReviewResponse.dataOrNull?.isNotEmpty == true) {
          final userReview = userReviewResponse.dataOrNull![0];
          userRating = userReview['rating']?.toDouble();
          isLiked = userReview['liked'] == true;
          isDisliked = userReview['disliked'] == true;
        }
      }

      // 2. 좋아요/싫어요 개수 계산
      final likesCountResponse = await _client.query<dynamic>(
        table: 'reviews',
        fromJson: (data) => data,
        filter: 'video_id.eq.$videoId,liked.eq.true',
      );

      final dislikesCountResponse = await _client.query<dynamic>(
        table: 'reviews',
        fromJson: (data) => data,
        filter: 'video_id.eq.$videoId,disliked.eq.true',
      );

      final likeCount =
          likesCountResponse.isSuccess ? likesCountResponse.dataOrNull?.length ?? 0 : 0;
      final dislikeCount =
          dislikesCountResponse.isSuccess ? dislikesCountResponse.dataOrNull?.length ?? 0 : 0;

      // 3. 별점 정보 계산
      final ratingsResponse = await _client.query<dynamic>(
        table: 'reviews',
        fromJson: (data) => data,
        filter: 'video_id.eq.$videoId,rating.not.is.null',
      );

      int totalVotes = 0;
      double averageRating = 0.0;

      if (ratingsResponse.isSuccess) {
        final ratings = ratingsResponse.dataOrNull ?? [];
        totalVotes = ratings.length;

        if (totalVotes > 0) {
          double totalRating = 0;
          for (var review in ratings) {
            double rating = (review['rating'] ?? 0).toDouble();
            totalRating += rating;
          }
          averageRating = double.parse((totalRating / totalVotes).toStringAsFixed(2));
        }
      }

      // 4. 비디오 테이블의 정보 확인 (검증용)
      final videoResponse = await _client.getRecord<dynamic>(
        table: 'videos',
        id: videoId,
        fromJson: (data) => data,
      );

      if (videoResponse.isSuccess && videoResponse.dataOrNull != null) {
        final videoData = videoResponse.dataOrNull!;
        final dbRatingCount = videoData['rating_count']?.toInt() ?? 0;
        final dbAverage = videoData['average_rating']?.toDouble() ?? 0.0;

        // DB 통계와 실제 통계가 다르면 업데이트
        if (dbRatingCount != totalVotes || dbAverage != averageRating) {
          print(
              '비디오 테이블 통계 불일치 감지: DB(평균=$dbAverage, 참여자=$dbRatingCount), 실제(평균=$averageRating, 참여자=$totalVotes)');

          try {
            await _client.updateRecord(
              table: 'videos',
              id: videoId,
              data: {
                'average_rating': averageRating,
                'rating_count': totalVotes,
              },
              fromJson: (data) => data,
            );
            print('비디오 테이블 통계 자동 업데이트 성공');
          } catch (e) {
            print('비디오 테이블 통계 자동 업데이트 실패: $e');
          }
        }
      }

      // 결과 생성
      final result = {
        'userRating': userRating,
        'isLiked': isLiked,
        'isDisliked': isDisliked,
        'averageRating': averageRating,
        'totalVotes': totalVotes,
        'likeCount': likeCount,
        'dislikeCount': dislikeCount,
      };

      // 캐시에 저장
      _cache.cacheVoteInfo(videoId, result);

      print('서버에서 비디오 투표 정보 로드 완료: 비디오=$videoId, 정보=$result');

      return ApiResponse<Map<String, dynamic>>.success(result);
    } catch (e) {
      print('비디오 투표 정보 로드 예외: $e');
      return ApiResponse<Map<String, dynamic>>.failure(ApiError(
        code: 'video_service/get-vote-info-error',
        message: e.toString(),
      ));
    }
  }

  // 캐시 키
  static const String _trendingVideosKey = 'video_cache_trending';
  static const String _risingVideosKey = 'video_cache_rising';
  static const String _videoDetailsKey = 'video_cache_details_';
  static const String _artistVideosKey = 'video_cache_artist_';
  static const String _voteInfoKey = 'vote_info_';

  /// 최신 비디오 목록 조회 (래퍼 메서드)
  Future<List<Video>> getLatestVideos({
    int limit = 20,
    String? lastId,
    bool forceRefresh = false,
  }) async {
    final response = await getRisingVideos(
      limit: limit,
      lastId: lastId,
      forceRefresh: forceRefresh,
    );

    return response.fold(
      onSuccess: (videos) => videos,
      onFailure: (error) => [],
    );
  }

  /// 즐겨찾기 비디오 목록 조회
  Future<List<Video>> getFavoriteVideos({
    int limit = 20,
    String? lastId,
    bool forceRefresh = false,
  }) async {
    try {
      // 즐겨찾기 비디오는 캐시에서만 가져오기
      final cachedVideos = _cache.getFavoriteVideos() ?? [];
      return _applyPagination(cachedVideos, lastId, limit);
    } catch (e) {
      return [];
    }
  }
}
