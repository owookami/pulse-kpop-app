import 'package:api_client/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/bookmarks/model/bookmark_state.dart';

/// 북마크 프로바이더
final bookmarkProvider = AsyncNotifierProvider<BookmarkNotifier, BookmarkState>(() {
  return BookmarkNotifier();
});

/// 북마크 상태 관리 노티파이어
class BookmarkNotifier extends AsyncNotifier<BookmarkState> {
  late BookmarkService _bookmarkService;

  @override
  Future<BookmarkState> build() async {
    _bookmarkService = ref.watch(bookmarkServiceProvider);

    return _fetchInitialState();
  }

  /// 초기 북마크 상태 불러오기
  Future<BookmarkState> _fetchInitialState() async {
    // 북마크된 비디오 가져오기
    final bookmarkedVideosResponse = await _bookmarkService.getBookmarkedVideos(
      limit: 100, // 초기 로드에는 충분한 수의 비디오 가져오기
    );

    // 컬렉션 가져오기
    final collectionsResponse = await _bookmarkService.getUserCollections(
      limit: 20, // 컬렉션은 많지 않을 것으로 가정
    );

    // API 응답 처리
    final videos = bookmarkedVideosResponse.fold(
      onSuccess: (videos) => videos.map((data) => Video.fromJson(data)).toList(),
      onFailure: (_) => <Video>[],
    );

    final collections = collectionsResponse.fold(
      onSuccess: (collections) => collections,
      onFailure: (_) => <BookmarkCollection>[],
    );

    return BookmarkState(
      bookmarkedVideos: videos,
      collections: collections,
      isLoading: false,
      error: null,
    );
  }

  /// 비디오 북마크 추가
  Future<void> addBookmark(String videoId) async {
    // 낙관적 업데이트: 북마크 추가가 성공할 것으로 가정하고 UI 즉시 업데이트
    state.whenData((currentState) {
      // 이미 북마크된 경우
      if (currentState.bookmarkedVideos.any((video) => video.id == videoId)) {
        return;
      }

      // 비디오 정보 가져오기 (임시 비디오 객체 생성)
      // 실제 앱에서는 비디오 정보를 캐시나 인자로 전달받아 사용할 수 있음
      final tempVideo = Video(
        id: videoId,
        title: '', // 임시 빈 값
        artistId: '',
        thumbnailUrl: '',
        videoUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: 0,
        platform: 'youtube',
        platformId: videoId,
      );

      // 낙관적 업데이트 적용
      state = AsyncValue.data(
        currentState.copyWith(
          bookmarkedVideos: [...currentState.bookmarkedVideos, tempVideo],
        ),
      );
    });

    // 실제 API 호출
    final response = await _bookmarkService.addBookmark(
      videoId: videoId,
    );

    // 응답 처리
    response.fold(
      onSuccess: (_) {
        // 북마크 추가 성공 - 이미 낙관적 업데이트를 했으므로 추가 작업 불필요
        // 필요하다면 여기서 최신 비디오 정보를 가져와서 상태 업데이트 가능
      },
      onFailure: (error) {
        // 북마크 추가 실패 - 상태 롤백
        state.whenData((currentState) {
          state = AsyncValue.data(
            currentState.copyWith(
              bookmarkedVideos:
                  currentState.bookmarkedVideos.where((video) => video.id != videoId).toList(),
              error: error,
            ),
          );
        });
      },
    );
  }

  /// 비디오 북마크 삭제
  Future<void> removeBookmark(String videoId) async {
    // 현재 상태에서 북마크 ID 찾기
    String? bookmarkId;
    Video? removedVideo;

    state.whenData((currentState) {
      // 북마크된 비디오 찾기
      for (final video in currentState.bookmarkedVideos) {
        if (video.id == videoId) {
          removedVideo = video;
          break;
        }
      }

      // 북마크 ID는 실제로 사용되는 앱에서는 비디오 객체에 포함되거나
      // 별도의 맵으로 관리될 수 있음 (현재는 임시 구현)
      bookmarkId = 'bookmark_$videoId';

      // 낙관적 업데이트: 북마크 삭제가 성공할 것으로 가정하고 UI 즉시 업데이트
      if (removedVideo != null) {
        state = AsyncValue.data(
          currentState.copyWith(
            bookmarkedVideos:
                currentState.bookmarkedVideos.where((video) => video.id != videoId).toList(),
          ),
        );
      }
    });

    if (bookmarkId == null) return;

    // 실제 API 호출
    final response = await _bookmarkService.removeBookmark(
      bookmarkId: bookmarkId!,
    );

    // 응답 처리
    response.fold(
      onSuccess: (_) {
        // 북마크 삭제 성공 - 이미 낙관적 업데이트를 했으므로 추가 작업 불필요
      },
      onFailure: (error) {
        // 북마크 삭제 실패 - 상태 롤백
        if (removedVideo != null) {
          state.whenData((currentState) {
            state = AsyncValue.data(
              currentState.copyWith(
                bookmarkedVideos: [...currentState.bookmarkedVideos, removedVideo!],
                error: error,
              ),
            );
          });
        }
      },
    );
  }

  /// 북마크 컬렉션 생성
  Future<void> createCollection({
    required String name,
    String? description,
  }) async {
    // 로딩 상태로 변경
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(isLoading: true));
    });

    // API 호출
    final response = await _bookmarkService.createCollection(
      name: name,
      description: description,
    );

    // 응답 처리
    response.fold(
      onSuccess: (newCollection) {
        // 컬렉션 생성 성공
        state.whenData((currentState) {
          state = AsyncValue.data(
            currentState.copyWith(
              collections: [...currentState.collections, newCollection],
              isLoading: false,
            ),
          );
        });
      },
      onFailure: (error) {
        // 컬렉션 생성 실패
        state.whenData((currentState) {
          state = AsyncValue.data(
            currentState.copyWith(
              isLoading: false,
              error: error,
            ),
          );
        });
      },
    );
  }

  /// 북마크 컬렉션 삭제
  Future<void> deleteCollection(String collectionId) async {
    // 낙관적 업데이트: 컬렉션 삭제가 성공할 것으로 가정하고 UI 즉시 업데이트
    BookmarkCollection? removedCollection;
    state.whenData((currentState) {
      // 컬렉션 찾기
      for (final collection in currentState.collections) {
        if (collection.id == collectionId) {
          removedCollection = collection;
          break;
        }
      }

      if (removedCollection != null) {
        state = AsyncValue.data(
          currentState.copyWith(
            collections: currentState.collections
                .where((collection) => collection.id != collectionId)
                .toList(),
          ),
        );
      }
    });

    // 실제 API 호출
    final response = await _bookmarkService.deleteCollection(
      collectionId: collectionId,
    );

    // 응답 처리
    response.fold(
      onSuccess: (_) {
        // 컬렉션 삭제 성공 - 이미 낙관적 업데이트를 했으므로 추가 작업 불필요
      },
      onFailure: (error) {
        // 컬렉션 삭제 실패 - 상태 롤백
        if (removedCollection != null) {
          state.whenData((currentState) {
            state = AsyncValue.data(
              currentState.copyWith(
                collections: [...currentState.collections, removedCollection!],
                error: error,
              ),
            );
          });
        }
      },
    );
  }

  /// 컬렉션 정보 업데이트
  Future<void> updateCollection({
    required String collectionId,
    String? name,
    String? description,
  }) async {
    // 로딩 상태로 변경
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(isLoading: true));
    });

    // API 호출
    final response = await _bookmarkService.updateCollection(
      collectionId: collectionId,
      name: name,
      description: description,
    );

    // 응답 처리
    response.fold(
      onSuccess: (updatedCollection) {
        // 컬렉션 업데이트 성공
        state.whenData((currentState) {
          final updatedCollections = currentState.collections.map((collection) {
            return collection.id == collectionId ? updatedCollection : collection;
          }).toList();

          state = AsyncValue.data(
            currentState.copyWith(
              collections: updatedCollections,
              isLoading: false,
            ),
          );
        });
      },
      onFailure: (error) {
        // 컬렉션 업데이트 실패
        state.whenData((currentState) {
          state = AsyncValue.data(
            currentState.copyWith(
              isLoading: false,
              error: error,
            ),
          );
        });
      },
    );
  }

  /// 비디오를 컬렉션에 추가
  Future<void> addVideoToCollection({
    required String videoId,
    required String collectionId,
  }) async {
    // 로딩 상태로 변경
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(isLoading: true));
    });

    // API 호출
    final response = await _bookmarkService.addBookmarkToCollection(
      videoId: videoId,
      collectionId: collectionId,
    );

    // 응답 처리
    response.fold(
      onSuccess: (_) async {
        // 비디오 추가 성공, 컬렉션 목록 새로고침
        final collectionsResponse = await _bookmarkService.getUserCollections();

        collectionsResponse.fold(
          onSuccess: (updatedCollections) {
            state.whenData((currentState) {
              state = AsyncValue.data(
                currentState.copyWith(
                  collections: updatedCollections,
                  isLoading: false,
                ),
              );
            });
          },
          onFailure: (error) {
            state.whenData((currentState) {
              state = AsyncValue.data(
                currentState.copyWith(
                  isLoading: false,
                  error: error,
                ),
              );
            });
          },
        );
      },
      onFailure: (error) {
        // 비디오 추가 실패
        state.whenData((currentState) {
          state = AsyncValue.data(
            currentState.copyWith(
              isLoading: false,
              error: error,
            ),
          );
        });
      },
    );
  }

  /// 컬렉션 북마크 새로고침
  Future<void> refreshBookmarks() async {
    try {
      final newState = await _fetchInitialState();
      state = AsyncValue.data(newState);
    } catch (e, stackTrace) {
      state = AsyncValue.error(
        ApiError(
          code: 'bookmark/refresh-failed',
          message: '북마크 새로고침 실패: $e',
        ),
        stackTrace,
      );
    }
  }

  /// 북마크 여부 확인
  bool isBookmarked(String videoId) {
    return state.value?.bookmarkedVideos.any((video) => video.id == videoId) ?? false;
  }

  /// 북마크 토글
  Future<void> toggleBookmark(Video video) async {
    if (isBookmarked(video.id)) {
      await removeBookmark(video.id);
    } else {
      await addBookmark(video.id);
    }
  }

  /// 컬렉션에서 비디오 제거
  Future<void> removeVideoFromCollection(
    String videoId,
    String collectionId,
  ) async {
    // 로딩 상태로 변경
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(isLoading: true));
    });

    // BookmarkItem ID 검색은 실제 구현에서는 API를 통해 이루어져야 함
    // 여기서는 간단한 구현을 위해 임시 ID 생성
    final bookmarkItemId = 'bookmark_item_${videoId}_$collectionId';

    // API 호출
    final response = await _bookmarkService.removeBookmarkFromCollection(
      bookmarkItemId: bookmarkItemId,
      collectionId: collectionId,
    );

    // 응답 처리
    response.fold(
      onSuccess: (_) async {
        // 비디오 제거 성공, 컬렉션 목록 새로고침
        final collectionsResponse = await _bookmarkService.getUserCollections();

        collectionsResponse.fold(
          onSuccess: (updatedCollections) {
            state.whenData((currentState) {
              state = AsyncValue.data(
                currentState.copyWith(
                  collections: updatedCollections,
                  isLoading: false,
                ),
              );
            });
          },
          onFailure: (error) {
            state.whenData((currentState) {
              state = AsyncValue.data(
                currentState.copyWith(
                  isLoading: false,
                  error: error,
                ),
              );
            });
          },
        );
      },
      onFailure: (error) {
        // 비디오 제거 실패
        state.whenData((currentState) {
          state = AsyncValue.data(
            currentState.copyWith(
              isLoading: false,
              error: error,
            ),
          );
        });
      },
    );
  }
}
