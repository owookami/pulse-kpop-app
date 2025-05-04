import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/video_cache.dart';
import '../clients/supabase_client.dart';
import '../models/api_error.dart';
import '../models/api_response.dart';
import '../models/bookmark.dart';
import '../models/bookmark_collection.dart';
import '../models/bookmark_item.dart';
import '../models/video.dart';

/// 북마크 서비스 프로바이더
final bookmarkServiceProvider = Provider<BookmarkService>((ref) {
  final supabaseClient = ref.watch(supabaseClientImplProvider);
  final videoCache = ref.watch(videoCacheProvider);
  return BookmarkService(
    client: supabaseClient,
    videoCache: videoCache,
  );
});

/// 북마크 서비스 클래스
class BookmarkService {
  /// 생성자
  BookmarkService({
    required ISupabaseClient client,
    required VideoCache videoCache,
  })  : _client = client,
        _videoCache = videoCache;

  final ISupabaseClient _client;
  final VideoCache _videoCache;

  // 캐시 키
  static const String _bookmarksKey = 'bookmark_cache_user_';

  /// 오프라인 상태 확인
  Future<bool> isOffline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.none;
  }

  /// 사용자의 북마크 목록 조회
  Future<ApiResponse<List<Bookmark>>> getUserBookmarks({
    bool forceRefresh = false,
  }) async {
    try {
      // 오프라인 체크
      final offline = await isOffline();
      if (offline) {
        return ApiResponse<List<Bookmark>>.failure(ApiError(
          code: 'offline',
          message: '오프라인 모드에서는 북마크 목록을 조회할 수 없습니다.',
        ));
      }

      // 로그인 상태 체크
      if (!_client.isAuthenticated) {
        return ApiResponse<List<Bookmark>>.failure(ApiError(
          code: 'auth/not-authenticated',
          message: '로그인이 필요한 기능입니다.',
        ));
      }

      final userId = _client.currentUserId;
      if (userId == null) {
        return ApiResponse<List<Bookmark>>.failure(ApiError(
          code: 'auth/invalid-user',
          message: '사용자 정보를 확인할 수 없습니다.',
        ));
      }

      final cacheKey = '$_bookmarksKey$userId';

      // 캐시에서 가져오기 (네트워크 없거나 강제 새로고침 아닌 경우)
      if (!forceRefresh) {
        final cachedData = _videoCache.getPreferences().getString(cacheKey);
        if (cachedData != null) {
          try {
            final List<dynamic> bookmarksList = json.decode(cachedData);
            final bookmarks = bookmarksList
                .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
                .toList();
            return ApiResponse<List<Bookmark>>.success(bookmarks);
          } catch (e) {
            // 캐시 데이터 파싱 오류 시 삭제
            await _videoCache.getPreferences().remove(cacheKey);
          }
        }
      }

      // API 호출
      debugPrint('북마크 목록 API 호출: userId=$userId');

      // 북마크 테이블에서 사용자의 북마크 목록 조회
      final response = await _client.query<Bookmark>(
        table: 'bookmarks',
        fromJson: Bookmark.fromJson,
        filter: 'user_id.eq.$userId',
      );

      // 캐싱
      if (response.isSuccess && response.dataOrNull != null) {
        final jsonData = json.encode(
          response.dataOrNull!.map((bookmark) => bookmark.toJson()).toList(),
        );
        await _videoCache.getPreferences().setString(cacheKey, jsonData);
      }

      return response;
    } catch (e, stackTrace) {
      debugPrint('북마크 목록 조회 실패: $e\n$stackTrace');
      return ApiResponse<List<Bookmark>>.failure(ApiError(
        code: 'unknown',
        message: '북마크 목록을 조회하는 중 오류가 발생했습니다.',
        details: {'error': e.toString()},
      ));
    }
  }

  /// 비디오에 대한 북마크 상태 확인
  Future<ApiResponse<bool>> isBookmarked({
    required String videoId,
  }) async {
    try {
      // 오프라인 체크
      final offline = await isOffline();
      if (offline) {
        return ApiResponse<bool>.failure(ApiError(
          code: 'offline',
          message: '오프라인 모드에서는 북마크 상태를 확인할 수 없습니다.',
        ));
      }

      // 로그인 상태 체크
      if (!_client.isAuthenticated) {
        return ApiResponse<bool>.failure(ApiError(
          code: 'auth/not-authenticated',
          message: '로그인이 필요한 기능입니다.',
        ));
      }

      final userId = _client.currentUserId;
      if (userId == null) {
        return ApiResponse<bool>.failure(ApiError(
          code: 'auth/invalid-user',
          message: '사용자 정보를 확인할 수 없습니다.',
        ));
      }

      // 북마크 정보 조회
      debugPrint('북마크 상태 확인 API 호출: userId=$userId, videoId=$videoId');

      final List<String> columns = ['id'];
      final filter = 'user_id.eq.$userId,video_id.eq.$videoId';
      debugPrint('북마크 필터: $filter');

      final response = await _client.query<Map<String, dynamic>>(
        table: 'bookmarks',
        fromJson: (data) => data,
        columns: columns,
        filter: filter,
      );

      // 북마크 여부 확인
      if (response.isSuccess && response.dataOrNull != null) {
        final isBookmarked = response.dataOrNull!.isNotEmpty;
        debugPrint(
            '북마크 결과: $isBookmarked, 결과 개수: ${response.dataOrNull!.length}, 데이터: ${response.dataOrNull}');
        return ApiResponse<bool>.success(isBookmarked);
      }

      debugPrint('북마크 조회 실패: ${response.errorOrNull?.message}');
      return ApiResponse<bool>.failure(ApiError(
        code: 'query_error',
        message: '북마크 상태를 확인하는 중 오류가 발생했습니다.',
      ));
    } catch (e, stackTrace) {
      debugPrint('북마크 상태 확인 실패: $e\n$stackTrace');
      return ApiResponse<bool>.failure(ApiError(
        code: 'unknown',
        message: '북마크 상태를 확인하는 중 오류가 발생했습니다.',
        details: {'error': e.toString()},
      ));
    }
  }

  /// 북마크 추가/제거
  Future<ApiResponse<bool>> toggleBookmark({
    required String videoId,
  }) async {
    try {
      // 오프라인 체크
      final offline = await isOffline();
      if (offline) {
        return ApiResponse<bool>.failure(ApiError(
          code: 'offline',
          message: '오프라인 모드에서는 북마크 기능을 사용할 수 없습니다.',
        ));
      }

      // 로그인 상태 체크
      if (!_client.isAuthenticated) {
        return ApiResponse<bool>.failure(ApiError(
          code: 'auth/not-authenticated',
          message: '로그인이 필요한 기능입니다.',
        ));
      }

      final userId = _client.currentUserId;
      if (userId == null) {
        return ApiResponse<bool>.failure(ApiError(
          code: 'auth/invalid-user',
          message: '사용자 정보를 확인할 수 없습니다.',
        ));
      }

      // 현재 북마크 상태 확인
      final bookmarkStateResponse = await isBookmarked(videoId: videoId);
      if (!bookmarkStateResponse.isSuccess) {
        return bookmarkStateResponse;
      }

      final isCurrentlyBookmarked = bookmarkStateResponse.dataOrNull ?? false;
      debugPrint('현재 북마크 상태: $isCurrentlyBookmarked, videoId=$videoId');

      ApiResponse<dynamic> actionResponse;

      if (isCurrentlyBookmarked) {
        // 북마크 제거
        final bookmarkResponse = await _client.query<Map<String, dynamic>>(
          table: 'bookmarks',
          fromJson: (data) => data,
          filter: 'user_id.eq.$userId,video_id.eq.$videoId',
        );

        if (bookmarkResponse.isSuccess &&
            bookmarkResponse.dataOrNull != null &&
            bookmarkResponse.dataOrNull!.isNotEmpty) {
          final bookmarkId = bookmarkResponse.dataOrNull![0]['id'] as String;

          actionResponse = await _client.deleteRecord(
            table: 'bookmarks',
            id: bookmarkId,
          );
        } else {
          return ApiResponse<bool>.failure(ApiError(
            code: 'bookmark_not_found',
            message: '북마크를 찾을 수 없습니다.',
          ));
        }
      } else {
        // 북마크 추가
        final bookmarkData = {
          'user_id': userId,
          'video_id': videoId,
        };

        actionResponse = await _client.createRecord<Map<String, dynamic>>(
          table: 'bookmarks',
          data: bookmarkData,
          fromJson: (data) => data,
        );
      }

      if (!actionResponse.isSuccess) {
        return ApiResponse<bool>.failure(ApiError(
          code: 'action_error',
          message: '북마크를 처리하는 중 오류가 발생했습니다.',
        ));
      }

      // 캐시 무효화
      final cacheKey = '$_bookmarksKey$userId';
      await _videoCache.getPreferences().remove(cacheKey);

      // 최종 상태 반환 (이전 상태의 반대)
      return ApiResponse<bool>.success(!isCurrentlyBookmarked);
    } catch (e, stackTrace) {
      debugPrint('북마크 토글 실패: $e\n$stackTrace');
      return ApiResponse<bool>.failure(ApiError(
        code: 'unknown',
        message: '북마크를 처리하는 중 오류가 발생했습니다.',
        details: {'error': e.toString()},
      ));
    }
  }

  /// 북마크된 비디오 목록 가져오기
  Future<ApiResponse<List<Map<String, dynamic>>>> getBookmarkedVideos({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // 오프라인 체크
      final offline = await isOffline();
      if (offline) {
        return ApiResponse<List<Map<String, dynamic>>>.failure(
          ApiError(code: 'offline', message: '오프라인 모드에서는 북마크된 비디오 목록을 조회할 수 없습니다.'),
        );
      }

      // 로그인 상태 체크
      if (!_client.isAuthenticated) {
        return ApiResponse<List<Map<String, dynamic>>>.failure(
          ApiError(code: 'auth/not-authenticated', message: '로그인이 필요한 기능입니다.'),
        );
      }

      final userId = _client.currentUserId;
      if (userId == null) {
        return ApiResponse<List<Map<String, dynamic>>>.failure(
          ApiError(code: 'auth/invalid-user', message: '사용자 정보를 확인할 수 없습니다.'),
        );
      }

      // 북마크 목록 가져오기
      final bookmarksResponse = await getUserBookmarks(forceRefresh: false);

      if (!bookmarksResponse.isSuccess || bookmarksResponse.dataOrNull == null) {
        return ApiResponse<List<Map<String, dynamic>>>.failure(ApiError(
          code: 'bookmark_fetch_error',
          message: '북마크 목록을 가져오는데 실패했습니다.',
        ));
      }

      final bookmarks = bookmarksResponse.dataOrNull!;
      if (bookmarks.isEmpty) {
        return ApiResponse<List<Map<String, dynamic>>>.success([]);
      }

      // 북마크된 비디오 ID 목록
      final videoIds = bookmarks.map((bookmark) => bookmark.videoId).toList();
      if (videoIds.isEmpty) {
        return ApiResponse<List<Map<String, dynamic>>>.success([]);
      }

      // videoId IN 필터 생성 (예: id.in.(id1,id2,id3))
      final videoIdsStr = videoIds.join(',');
      final filter = 'id.in.($videoIdsStr)';

      // 비디오 가져오기
      final response = await _client.query<Map<String, dynamic>>(
        table: 'videos',
        fromJson: (data) => data,
        filter: filter,
        orderBy: 'created_at.desc',
        limit: limit,
        offset: offset,
      );

      if (!response.isSuccess) {
        return ApiResponse<List<Map<String, dynamic>>>.failure(ApiError(
          code: 'video_fetch_error',
          message: '북마크된 비디오 정보를 가져오는데 실패했습니다.',
        ));
      }

      return response;
    } catch (e, stackTrace) {
      debugPrint('북마크된 비디오 목록 조회 실패: $e\n$stackTrace');
      return ApiResponse<List<Map<String, dynamic>>>.failure(
        ApiError(
          code: 'unknown',
          message: '북마크된 비디오 목록을 조회하는 중 오류가 발생했습니다.',
          details: {'error': e.toString()},
        ),
      );
    }
  }

  /// 북마크 추가
  Future<ApiResponse<Bookmark>> addBookmark({
    String? userId,
    required String videoId,
  }) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse<Bookmark>.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 북마크를 추가할 수 없습니다.',
        ),
      );
    }

    // userId가 제공되지 않으면 현재 로그인된 사용자의 ID 사용
    final currentUserId = userId ?? _client.currentUserId;
    if (currentUserId == null) {
      return ApiResponse<Bookmark>.failure(
        ApiError(
          code: 'auth/invalid-user',
          message: '사용자 정보를 확인할 수 없습니다.',
        ),
      );
    }

    final data = {
      'user_id': currentUserId,
      'video_id': videoId,
    };

    return _client.createRecord<Bookmark>(
      table: 'bookmarks',
      data: data,
      fromJson: Bookmark.fromJson,
    );
  }

  /// 북마크 삭제
  Future<ApiResponse<void>> removeBookmark({
    required String bookmarkId,
  }) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse<void>.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 북마크 삭제를 사용할 수 없습니다.',
        ),
      );
    }

    return _client.deleteRecord(
      table: 'bookmarks',
      id: bookmarkId,
    );
  }

  /// 비디오의 북마크 상태 확인
  Future<ApiResponse<bool>> isVideoBookmarked({
    String? userId,
    required String videoId,
  }) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse<bool>.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 북마크 상태를 확인할 수 없습니다.',
        ),
      );
    }

    // userId가 제공되지 않으면 현재 로그인된 사용자의 ID 사용
    final currentUserId = userId ?? _client.currentUserId;
    if (currentUserId == null) {
      return ApiResponse<bool>.failure(
        ApiError(
          code: 'auth/invalid-user',
          message: '사용자 정보를 확인할 수 없습니다.',
        ),
      );
    }

    final filter = 'user_id.eq.$currentUserId,video_id.eq.$videoId';

    final response = await _client.query<Bookmark>(
      table: 'bookmarks',
      fromJson: Bookmark.fromJson,
      filter: filter,
      limit: 1,
    );

    return response.fold(
      onSuccess: (bookmarks) => ApiResponse<bool>.success(bookmarks.isNotEmpty),
      onFailure: (error) => ApiResponse<bool>.failure(error),
    );
  }

  /// 컬렉션 생성
  Future<ApiResponse<BookmarkCollection>> createCollection({
    String? userId,
    required String name,
    String? description,
    String? coverImageUrl,
    bool isPublic = false,
  }) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse<BookmarkCollection>.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 컬렉션을 생성할 수 없습니다.',
        ),
      );
    }

    // userId가 제공되지 않으면 현재 로그인된 사용자의 ID 사용
    final currentUserId = userId ?? _client.currentUserId;
    if (currentUserId == null) {
      return ApiResponse<BookmarkCollection>.failure(
        ApiError(
          code: 'auth/invalid-user',
          message: '사용자 정보를 확인할 수 없습니다.',
        ),
      );
    }

    final now = DateTime.now().toIso8601String();
    final data = {
      'user_id': currentUserId,
      'name': name,
      'description': description,
      'created_at': now,
      'updated_at': now,
      'cover_image_url': coverImageUrl,
      'is_public': isPublic ? 'true' : 'false',
      'bookmark_count': 0,
    };

    return _client.createRecord<BookmarkCollection>(
      table: 'bookmark_collections',
      data: data,
      fromJson: BookmarkCollection.fromJson,
    );
  }

  /// 컬렉션 수정
  Future<ApiResponse<BookmarkCollection>> updateCollection({
    required String collectionId,
    String? name,
    String? description,
    String? coverImageUrl,
    bool? isPublic,
  }) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse<BookmarkCollection>.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 컬렉션을 수정할 수 없습니다.',
        ),
      );
    }

    final data = {
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (coverImageUrl != null) data['cover_image_url'] = coverImageUrl;
    if (isPublic != null) data['is_public'] = isPublic ? 'true' : 'false';

    return _client.updateRecord<BookmarkCollection>(
      table: 'bookmark_collections',
      id: collectionId,
      data: data,
      fromJson: BookmarkCollection.fromJson,
    );
  }

  /// 컬렉션 삭제
  Future<ApiResponse<void>> deleteCollection({
    required String collectionId,
  }) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse<void>.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 컬렉션을 삭제할 수 없습니다.',
        ),
      );
    }

    return _client.deleteRecord(
      table: 'bookmark_collections',
      id: collectionId,
    );
  }

  /// 사용자의 컬렉션 목록 가져오기
  Future<ApiResponse<List<BookmarkCollection>>> getUserCollections({
    String? userId,
    int limit = 20,
    String? lastId,
  }) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse<List<BookmarkCollection>>.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 컬렉션 목록을 가져올 수 없습니다.',
        ),
      );
    }

    // userId가 제공되지 않으면 현재 로그인된 사용자의 ID 사용
    final currentUserId = userId ?? _client.currentUserId;
    if (currentUserId == null) {
      return ApiResponse<List<BookmarkCollection>>.failure(
        ApiError(
          code: 'auth/invalid-user',
          message: '사용자 정보를 확인할 수 없습니다.',
        ),
      );
    }

    // 사용자 ID 필터
    final userFilter = 'user_id.eq.$currentUserId';

    // lastId가 있으면 해당 ID 이후의 데이터 조회
    final idFilter = lastId != null ? 'and(id.lt.$lastId)' : '';

    // 최종 필터 생성
    final filter = lastId != null ? '$userFilter,$idFilter' : userFilter;

    return _client.query<BookmarkCollection>(
      table: 'bookmark_collections',
      fromJson: BookmarkCollection.fromJson,
      orderBy: 'updated_at.desc', // 최신 업데이트순
      limit: limit,
      filter: filter,
    );
  }

  /// 컬렉션에 북마크 추가
  Future<ApiResponse<BookmarkItem>> addBookmarkToCollection({
    String? userId,
    required String videoId,
    required String collectionId,
  }) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse<BookmarkItem>.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 컬렉션에 북마크를 추가할 수 없습니다.',
        ),
      );
    }

    // userId가 제공되지 않으면 현재 로그인된 사용자의 ID 사용
    final currentUserId = userId ?? _client.currentUserId;
    if (currentUserId == null) {
      return ApiResponse<BookmarkItem>.failure(
        ApiError(
          code: 'auth/invalid-user',
          message: '사용자 정보를 확인할 수 없습니다.',
        ),
      );
    }

    final data = {
      'user_id': currentUserId,
      'video_id': videoId,
      'collection_id': collectionId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _client.createRecord<BookmarkItem>(
      table: 'bookmark_items',
      data: data,
      fromJson: BookmarkItem.fromJson,
    );

    // 북마크 추가 성공 시 컬렉션의 북마크 수 업데이트
    return response.fold(
      onSuccess: (bookmarkItem) async {
        // 컬렉션 정보 조회
        final collectionResponse = await _client.getRecord<BookmarkCollection>(
          table: 'bookmark_collections',
          id: collectionId,
          fromJson: BookmarkCollection.fromJson,
        );

        return collectionResponse.fold(
          onSuccess: (collection) async {
            if (collection == null) {
              return ApiResponse<BookmarkItem>.success(bookmarkItem);
            }

            // 북마크 수 증가
            final updatedCount = collection.bookmarkCount + 1;
            final updateData = {
              'bookmark_count': updatedCount,
              'updated_at': DateTime.now().toIso8601String(),
            };

            // 컬렉션 업데이트
            await _client.updateRecord<BookmarkCollection>(
              table: 'bookmark_collections',
              id: collectionId,
              data: updateData,
              fromJson: BookmarkCollection.fromJson,
            );

            return ApiResponse<BookmarkItem>.success(bookmarkItem);
          },
          onFailure: (_) => ApiResponse<BookmarkItem>.success(bookmarkItem),
        );
      },
      onFailure: (error) => ApiResponse<BookmarkItem>.failure(error),
    );
  }

  /// 컬렉션에서 북마크 제거
  Future<ApiResponse<void>> removeBookmarkFromCollection({
    required String bookmarkItemId,
    required String collectionId,
  }) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse<void>.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 컬렉션에서 북마크를 제거할 수 없습니다.',
        ),
      );
    }

    final response = await _client.deleteRecord(
      table: 'bookmark_items',
      id: bookmarkItemId,
    );

    // 북마크 제거 성공 시 컬렉션의 북마크 수 업데이트
    return response.fold(
      onSuccess: (_) async {
        // 컬렉션 정보 조회
        final collectionResponse = await _client.getRecord<BookmarkCollection>(
          table: 'bookmark_collections',
          id: collectionId,
          fromJson: BookmarkCollection.fromJson,
        );

        return collectionResponse.fold(
          onSuccess: (collection) async {
            if (collection == null) {
              return ApiResponse<void>.success(null);
            }

            // 북마크 수 감소 (최소 0)
            final updatedCount = (collection.bookmarkCount - 1).clamp(0, double.infinity).toInt();
            final updateData = {
              'bookmark_count': updatedCount,
              'updated_at': DateTime.now().toIso8601String(),
            };

            // 컬렉션 업데이트
            await _client.updateRecord<BookmarkCollection>(
              table: 'bookmark_collections',
              id: collectionId,
              data: updateData,
              fromJson: BookmarkCollection.fromJson,
            );

            return ApiResponse<void>.success(null);
          },
          onFailure: (_) => ApiResponse<void>.success(null),
        );
      },
      onFailure: (error) => ApiResponse<void>.failure(error),
    );
  }

  /// 컬렉션의 북마크 목록 가져오기
  Future<ApiResponse<List<Video>>> getCollectionVideos({
    required String collectionId,
    int limit = 20,
    String? lastId,
  }) async {
    // 오프라인 상태 확인
    final offline = await isOffline();
    if (offline) {
      return ApiResponse<List<Video>>.failure(
        ApiError(
          code: 'network-error',
          message: '오프라인 상태에서는 컬렉션 비디오를 가져올 수 없습니다.',
        ),
      );
    }

    // 컬렉션 ID 필터
    final collectionFilter = 'collection_id.eq.$collectionId';

    // lastId가 있으면 해당 ID 이후의 데이터 조회
    final idFilter = lastId != null ? 'and(id.lt.$lastId)' : '';

    // 최종 필터 생성
    final filter = lastId != null ? '$collectionFilter,$idFilter' : collectionFilter;

    // 북마크 아이템 조회
    final bookmarkItemsResponse = await _client.query<BookmarkItem>(
      table: 'bookmark_items',
      fromJson: BookmarkItem.fromJson,
      orderBy: 'created_at.desc', // 최신순
      limit: limit,
      filter: filter,
    );

    return bookmarkItemsResponse.fold(
      onSuccess: (bookmarkItems) async {
        if (bookmarkItems.isEmpty) {
          return ApiResponse<List<Video>>.success([]);
        }

        // 북마크된 비디오 ID 목록
        final videoIds = bookmarkItems.map((item) => item.videoId).toList();

        // 비디오 ID 목록으로 비디오 정보 가져오기
        final videoIdFilter = 'id.in.(${videoIds.join(',')})';

        return _client.query<Video>(
          table: 'videos',
          fromJson: Video.fromJson,
          filter: videoIdFilter,
          limit: limit,
        );
      },
      onFailure: (error) => ApiResponse<List<Video>>.failure(error),
    );
  }
}
