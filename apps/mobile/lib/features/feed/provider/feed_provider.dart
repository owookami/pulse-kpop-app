import 'dart:async';
import 'dart:math';

import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/feed/model/feed_state.dart';

/// 피드 스크롤 위치 저장용 프로바이더
final feedScrollPositionProvider = StateProvider<Map<FeedTab, double>>((ref) {
  return {
    FeedTab.trending: 0,
    FeedTab.rising: 0,
  };
});

/// 현재 선택된 피드 뷰 타입 프로바이더
final feedViewTypeProvider = StateProvider<FeedViewType>((ref) {
  return FeedViewType.popular;
});

/// 비디오 선택 프로바이더
final selectedVideoProvider = StateProvider<Video?>((ref) => null);

/// 현재 선택된 탭 프로바이더
final selectedFeedTabProvider = StateProvider<FeedTab>((ref) {
  return FeedTab.trending;
});

/// 페이지당 로드할 비디오 수
const int videosPerPage = 50;

/// 마지막 비디오 ID 저장용 프로바이더 (탭별로 관리)
final lastVideoIdProvider = StateProvider.family<String?, FeedViewType>((ref, viewType) => null);

/// 비디오 로딩 상태 프로바이더 - 중복 로드 방지를 위한 플래그
final videoLoadingStateProvider = StateProvider.family<bool, FeedViewType>((ref, _) => false);

/// 피드 비디오 프로바이더
final feedVideosProvider = AsyncNotifierProvider<FeedVideosNotifier, List<Video>>(() {
  return FeedVideosNotifier();
});

/// 피드 비디오 상태 관리 노티파이어
class FeedVideosNotifier extends AsyncNotifier<List<Video>> {
  late VideoService _videoService;

  // 페이징 관련 상태 변수 (탭별로 관리)
  final Map<FeedViewType, String?> _lastVideoIds = {};
  final Map<FeedViewType, int> _offsets = {
    FeedViewType.popular: 0,
    FeedViewType.latest: 0,
    FeedViewType.favorites: 0,
  };

  final Map<FeedViewType, bool> _hasMoreData = {
    FeedViewType.popular: true,
    FeedViewType.latest: true,
    FeedViewType.favorites: true,
  };

  // 각 탭 별로 비디오 캐시
  final Map<FeedViewType, List<Video>> _videoCache = {
    FeedViewType.popular: [],
    FeedViewType.latest: [],
    FeedViewType.favorites: [],
  };

  // 페이지 카운터 관리 - 오프셋 기반 페이징 사용
  final Map<FeedViewType, int> _pageCounters = {
    FeedViewType.popular: 0,
    FeedViewType.latest: 0,
    FeedViewType.favorites: 0,
  };

  // 총 로드된 항목 수 추적 (디버깅용)
  final Map<FeedViewType, int> _totalLoaded = {
    FeedViewType.popular: 0,
    FeedViewType.latest: 0,
    FeedViewType.favorites: 0,
  };

  // 페이지당 항목 수 - 20개로 수정 (이전 값: 10)
  static const int pageSize = 20;

  @override
  Future<List<Video>> build() async {
    _videoService = ref.read(videoServiceProvider);
    return _loadVideos(FeedViewType.popular);
  }

  /// 비디오 선택
  void selectVideo(Video video) {
    ref.read(selectedVideoProvider.notifier).state = video;
  }

  /// 비디오 로드 - 초기 로드 또는 새로고침
  Future<List<Video>> loadVideos(FeedViewType viewType, {bool forceRefresh = false}) async {
    // 현재 뷰 타입 설정
    ref.read(feedViewTypeProvider.notifier).state = viewType;

    // 이미 로딩 중인지 확인
    final isLoading = ref.read(videoLoadingStateProvider(viewType));
    if (isLoading && !forceRefresh) {
      debugPrint('이미 로딩 중: $viewType');
      return _videoCache[viewType] ?? [];
    }

    // 로딩 상태 설정
    ref.read(videoLoadingStateProvider(viewType).notifier).state = true;

    try {
      // 강제 새로고침인 경우 상태 초기화
      if (forceRefresh) {
        _lastVideoIds[viewType] = null;
        _offsets[viewType] = 0;
        _hasMoreData[viewType] = true;
        _videoCache[viewType] = [];
        _pageCounters[viewType] = 0;
        _totalLoaded[viewType] = 0; // 총 로드된 항목 수 초기화
      }

      // 상태 업데이트
      state = const AsyncLoading();

      // 비디오 로드 - 초기 로드는 lastId 없이 진행
      final videos = await _loadVideosWithLastId(viewType, null, pageSize);
      debugPrint('초기 로드된 비디오 수: ${videos.length}');

      // 마지막 ID 저장 (다음 페이지 로드에 사용)
      if (videos.isNotEmpty) {
        _lastVideoIds[viewType] = videos.last.id;
        debugPrint('마지막 비디오 ID 저장: ${videos.last.id}, 비디오 수: ${videos.length}');
      }

      // 비디오 정렬 - 각 탭에 맞게
      final sortedVideos = _sortVideos(videos, viewType);

      // 캐시 업데이트
      _videoCache[viewType] = sortedVideos;

      // 다음 페이지 존재 여부 설정 - 데이터가 있으면 true
      _hasMoreData[viewType] = videos.isNotEmpty;

      // 오프셋 업데이트
      _offsets[viewType] = sortedVideos.length;

      // 페이지 카운터 업데이트
      _pageCounters[viewType] = 1;

      // 총 로드된 항목 수 업데이트
      _totalLoaded[viewType] = sortedVideos.length;
      debugPrint('총 로드된 비디오: ${_totalLoaded[viewType]}개, 이 로드에서: ${sortedVideos.length}개');

      state = AsyncData(sortedVideos);
      return sortedVideos;
    } catch (error, stackTrace) {
      debugPrint('비디오 로드 오류: $error');
      state = AsyncError('비디오를 불러오는 중 오류가 발생했습니다.', stackTrace);
      return [];
    } finally {
      // 로딩 상태 해제
      ref.read(videoLoadingStateProvider(viewType).notifier).state = false;
    }
  }

  /// 추가 비디오 로드 (페이징)
  Future<List<Video>> loadMoreVideos(FeedViewType viewType) async {
    debugPrint('loadMoreVideos 호출: viewType=$viewType');

    // 더 이상 데이터가 없으면 현재 상태 유지
    if (!_hasMoreData[viewType]!) {
      debugPrint('더 이상 로드할 데이터가 없음: viewType=$viewType');
      return _videoCache[viewType] ?? [];
    }

    try {
      // 현재 상태 확인
      final currentVideos = _videoCache[viewType] ?? [];

      // 마지막 비디오 ID 가져오기
      String? lastId;
      if (currentVideos.isNotEmpty) {
        lastId = currentVideos.last.id;
        debugPrint('마지막 비디오 ID: $lastId (currentVideos.last.id)');
      } else {
        lastId = _lastVideoIds[viewType];
        debugPrint('마지막 비디오 ID: $lastId (_lastVideoIds[viewType])');
      }

      debugPrint(
          '무한 스크롤 시작: viewType=$viewType, lastId=$lastId, 현재 비디오 수=${currentVideos.length}, 총 로드된 비디오 수=${_totalLoaded[viewType]}');

      if (currentVideos.isEmpty) {
        // 현재 목록이 비어있으면 초기 로드 수행
        debugPrint('현재 비디오 목록이 비어 있어 초기 로드 수행');
        return loadVideos(viewType);
      }

      // 추가 비디오 로드 - 명확한 lastId 사용
      final newVideos = await _loadVideosWithLastId(viewType, lastId, pageSize);
      debugPrint('추가 로드된 비디오 수: ${newVideos.length}');

      // 데이터가 없으면 더 이상 데이터 없음으로 설정
      if (newVideos.isEmpty) {
        _hasMoreData[viewType] = false;
        debugPrint('더 이상 데이터가 없습니다: viewType=$viewType');
        return currentVideos;
      }

      // 중복 제거 - ID 기준으로 필터링
      final currentIds = currentVideos.map((v) => v.id).toSet();
      final uniqueNewVideos = newVideos.where((v) => !currentIds.contains(v.id)).toList();

      debugPrint(
          '중복 제거 후 새 비디오 수: ${uniqueNewVideos.length} (제외된 비디오: ${newVideos.length - uniqueNewVideos.length}개)');

      // 새로운 비디오가 없으면 더 이상 데이터 없음
      if (uniqueNewVideos.isEmpty) {
        _hasMoreData[viewType] = false;
        debugPrint('중복 제거 후 새 비디오가 없음, 더 이상 데이터 없음으로 설정');
        return currentVideos;
      }

      // 결합된 비디오 리스트
      final combinedVideos = [...currentVideos, ...uniqueNewVideos];
      debugPrint('결합된 비디오 총 수: ${combinedVideos.length}');

      // 마지막 ID 업데이트 - 새로 로드된 비디오 중 마지막 ID
      if (uniqueNewVideos.isNotEmpty) {
        _lastVideoIds[viewType] = uniqueNewVideos.last.id;
        debugPrint('마지막 ID 업데이트: ${uniqueNewVideos.last.id} (다음 페이징용)');
      }

      // 다음 페이지 존재 여부 - 새 비디오가 있으면 더 있을 가능성이 있음
      // 서버에서 최소 1개 이상 데이터를 반환했으면 더 있을 가능성이 있음
      _hasMoreData[viewType] = uniqueNewVideos.isNotEmpty;

      // 디버깅 목적으로 총 로드된 항목 수와 예상되는 DB의 총 항목 수(150) 비교
      if ((_totalLoaded[viewType] ?? 0) + uniqueNewVideos.length >= 150) {
        debugPrint('DB의 총 비디오 수(약 150개)에 근접함, 데이터가 거의 다 로드됨');
      }

      debugPrint('다음 페이지 존재: ${_hasMoreData[viewType]} (새 비디오 수: ${uniqueNewVideos.length})');

      // 총 로드된 항목 수 업데이트
      _totalLoaded[viewType] = combinedVideos.length;
      debugPrint('총 로드된 비디오 수: ${_totalLoaded[viewType]}개');

      // 캐시 업데이트
      _videoCache[viewType] = combinedVideos;

      // 상태 업데이트 (UI 갱신용)
      state = AsyncData(combinedVideos);

      debugPrint('무한 스크롤 완료: 총 ${combinedVideos.length}개 비디오, 전체 DB 데이터 약 150개');
      return combinedVideos;
    } catch (error, stackTrace) {
      // 오류 발생 시 기존 데이터 유지
      debugPrint('무한 스크롤 오류: $error');
      debugPrint('스택 트레이스: $stackTrace');

      // 오류 발생 시에도 상태는 기존 데이터 유지
      return _videoCache[viewType] ?? [];
    }
  }

  /// 내부 비디오 로드 구현 - 초기 로드용
  Future<List<Video>> _loadVideos(FeedViewType viewType) async {
    return _loadVideosWithLastId(viewType, null, pageSize);
  }

  /// 각 탭에 맞게 비디오 정렬
  List<Video> _sortVideos(List<Video> videos, FeedViewType viewType) {
    switch (viewType) {
      case FeedViewType.popular:
        // 인기 탭은 서버에서 가져온 순서 그대로 사용
        return videos;
      case FeedViewType.latest:
        // 최신 탭은 생성일 기준 내림차순 정렬 (현재 사용 안함)
        /*
        return List.from(videos)
          ..sort((a, b) {
            // null 안전하게 비교
            if (a.createdAt == null && b.createdAt == null) return 0;
            return b.createdAt.compareTo(a.createdAt);
          });
        */
        // 빈 리스트 반환 - 사용하지 않음
        return [];
      case FeedViewType.favorites:
        // 즐겨찾기는 기본 정렬 유지
        return videos;
    }
  }

  /// lastId 기반으로 비디오 로드 (백엔드 API와 호환)
  Future<List<Video>> _loadVideosWithLastId(
      FeedViewType viewType, String? lastId, int limit) async {
    try {
      List<Video> videos = [];
      debugPrint('_loadVideosWithLastId 호출: viewType=$viewType, lastId=$lastId, limit=$limit');

      // limit 값 확인 - 명시적으로 pageSize 값 사용
      if (limit != pageSize) {
        debugPrint('요청된 limit($limit)이 pageSize($pageSize)와 다릅니다. pageSize 값으로 변경합니다.');
        limit = pageSize;
      }

      switch (viewType) {
        case FeedViewType.popular:
          // 인기 탭 - videos 테이블에서 최신순으로 데이터 가져오기
          debugPrint('인기 탭 비디오 로드 시작 - 최신순으로 가져오기: limit=$limit, lastId=$lastId');

          // 비디오 가져오기 - lastId가 있으면 id.lt.lastId 필터 사용
          final response = await _videoService.getTrendingVideos(
            limit: limit * 4, // 더 많은 데이터를 요청하여 빈 결과 방지 (40개씩 요청)
            lastId: lastId, // lastId가 null이면 처음부터, 있으면 해당 ID 이후 데이터
            forceRefresh: true, // 캐시 무시하고 항상 새로 로드 (무한 스크롤에서 중요)
          );

          debugPrint('인기 탭 API 호출 결과: ${response.isSuccess}, lastId=$lastId, limit=${limit * 4}');

          // 결과 처리
          videos = response.fold(
            onSuccess: (data) {
              debugPrint('인기 탭 비디오 로드 성공: ${data.length}개 항목, lastId=$lastId');
              if (data.isEmpty) {
                debugPrint('API에서 반환된 데이터가 없음 (더 이상 데이터 없음)');
              } else {
                debugPrint('첫 번째 비디오 ID: ${data.first.id}, 마지막 비디오 ID: ${data.last.id}');

                // 서버에서 반환한 모든 데이터 사용 (제한 없음)
                return data;
              }
              return data;
            },
            onFailure: (error) {
              debugPrint('인기 탭 비디오 로드 실패: ${error.message}');
              return [];
            },
          );
          break;

        case FeedViewType.latest:
          // 최신 탭 - 사용 안함 (주석 처리)
          debugPrint('최신 탭은 비활성화됨');
          videos = [];
          break;

        case FeedViewType.favorites:
          // 데모 목적으로 임시 구현 (실제 API 연동 필요)
          videos = await _generateDummyVideos(lastId, limit, prefix: '즐겨찾기_');
          break;
      }

      debugPrint('${viewType.name} 비디오 로드 완료: ${videos.length}개 (요청 limit=$limit)');
      return videos;
    } catch (error, stackTrace) {
      // 오류 로깅
      debugPrint('비디오 로드 오류: $error');
      debugPrint(stackTrace.toString());
      // 실패 시 빈 목록 반환
      return [];
    }
  }

  /// 테스트용 더미 비디오 생성 메서드
  Future<List<Video>> _generateDummyVideos(String? lastId, int limit, {String prefix = ''}) async {
    // 1초 지연 (실제 네트워크 요청 시뮬레이션)
    await Future.delayed(const Duration(milliseconds: 500));

    List<Video> dummies = [];
    final now = DateTime.now();
    final random = Random();

    // lastId가 있으면 해당 ID 다음부터 생성
    int startId = 0;
    if (lastId != null) {
      try {
        final idString = lastId.replaceAll(prefix, '').replaceAll('dummy_', '');
        startId = int.parse(idString) + 1;
      } catch (e) {
        startId = 0;
      }
    }

    // 페이지가 너무 많으면 더 적은 데이터 반환 (페이지 끝 시뮬레이션)
    final actualCount = startId > 150 ? (200 - startId).clamp(0, limit) : limit;

    if (actualCount <= 0) {
      return []; // 더 이상 데이터 없음
    }

    for (int i = 0; i < actualCount; i++) {
      final index = startId + i;
      final id = '${prefix}dummy_$index';
      dummies.add(
        Video(
          id: id,
          title: '$prefix 테스트 비디오 $index번',
          description: '설명 $index',
          thumbnailUrl: 'https://picsum.photos/seed/$index/350/200', // 랜덤 이미지
          videoUrl: 'https://example.com/video/$id',
          artistId: 'artist_1',
          viewCount: 100 + index,
          publishedAt: now.subtract(Duration(days: index % 30)),
          platform: 'youtube',
          platformId: 'youtube_$id',
          likeCount: (index * 5) % 1000,
          createdAt: now.subtract(Duration(days: index % 30)),
          updatedAt: now,
        ),
      );
    }

    return dummies;
  }

  /// 해당 뷰 타입에 대해 추가 데이터가 있는지 확인
  bool hasMoreData(FeedViewType viewType) {
    return _hasMoreData[viewType] ?? false;
  }

  /// 전체 비디오 수 반환 (근사치)
  int getTotalVideoCount() {
    // 데이터베이스에 있는 총 비디오 수의 근사치 반환
    // 실제로는 API 응답에서 총 개수를 얻어와야 하지만,
    // 현재는 알려진 대략적인 개수인 150을 반환
    return 150;
  }
}
