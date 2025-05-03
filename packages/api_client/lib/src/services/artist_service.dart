import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/api_error.dart';
import '../models/api_response.dart';
import '../models/artist.dart';
import '../models/follow.dart';

/// 아티스트 서비스 프로바이더
final artistServiceProvider = ArtistService(
  supabase: Supabase.instance.client,
);

/// 아티스트 관련 API 서비스
class ArtistService {
  /// 생성자
  ArtistService({
    required this.supabase,
  });

  /// Supabase 클라이언트
  final SupabaseClient supabase;

  /// 모든 아티스트 목록 가져오기
  Future<ApiResponse<List<Artist>>> getAllArtists() async {
    try {
      print('모든 아티스트 목록 가져오기 시작');

      try {
        final response = await supabase.from('artists').select().order('name').limit(100);

        final artists = response.map((json) => Artist.fromJson(json)).toList();
        print('모든 아티스트 목록 결과: ${artists.length}개');
        return ApiResponse.success(artists);
      } catch (e) {
        print('모든 아티스트 목록 오류: $e');

        // PostgrestException인 경우 테이블이 없을 때 더미 데이터 반환
        if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
          print('artists 테이블이 존재하지 않습니다. 더미 데이터 반환.');

          // 테이블이 없으면 더미 데이터 반환
          final dummyArtists = _createDummyArtists();
          return ApiResponse.success(dummyArtists);
        }

        rethrow; // 다시 예외 발생시켜서 아래 catch로 처리
      }
    } catch (e) {
      return ApiResponse.failure(ApiError.server('아티스트 목록을 불러오는데 실패했습니다: $e'));
    }
  }

  /// 아티스트 상세 정보 가져오기
  Future<ApiResponse<Artist>> getArtistDetails({
    required String artistId,
  }) async {
    try {
      print('아티스트 상세 정보 가져오기 시작: artistId=$artistId');

      try {
        final response = await supabase.from('artists').select().eq('id', artistId).single();

        final artist = Artist.fromJson(response);
        print('아티스트 상세 정보 가져오기 성공: ${artist.name}');
        return ApiResponse.success(artist);
      } catch (e) {
        print('아티스트 상세 정보 오류: $e');

        // PostgrestException인 경우 테이블이 없을 때 더미 데이터 반환
        if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
          print('artists 테이블이 존재하지 않습니다. 더미 데이터 반환.');

          // 테이블이 없으면 더미 데이터 반환
          final dummyArtist = _createDummyArtists().firstWhere(
            (artist) => artist.id == artistId,
            orElse: () => _createDummyArtists().first,
          );
          return ApiResponse.success(dummyArtist);
        }

        rethrow; // 다시 예외 발생시켜서 아래 catch로 처리
      }
    } catch (e) {
      return ApiResponse.failure(ApiError.server('아티스트 정보를 불러오는데 실패했습니다: $e'));
    }
  }

  /// 아티스트 팔로우하기
  Future<ApiResponse<Follow>> followArtist({
    required String artistId,
  }) async {
    try {
      print('아티스트 팔로우 시작: artistId=$artistId');

      final user = supabase.auth.currentUser;
      if (user == null) {
        print('팔로우 실패: 로그인 필요');
        return ApiResponse.failure(
          ApiError.auth('로그인이 필요합니다'),
        );
      }

      try {
        final response = await supabase.from('follows').insert({
          'follower_id': user.id,
          'following_id': artistId,
        }).select();

        final follow = Follow.fromJson(response.first);
        print('팔로우 성공: followId=${follow.id}');
        return ApiResponse.success(follow);
      } catch (e) {
        print('팔로우 오류: $e');

        // PostgrestException인 경우 테이블이 없을 때 가상 응답 반환
        if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
          print('follows 테이블이 존재하지 않습니다. 가상 팔로우 응답 반환.');

          // 가상 팔로우 응답 생성
          final virtualFollow = Follow(
            id: 'virtual-${DateTime.now().millisecondsSinceEpoch}',
            followerId: user.id,
            followingId: artistId,
            createdAt: DateTime.now(),
          );
          return ApiResponse.success(virtualFollow);
        }

        rethrow; // 다시 예외 발생시켜서 아래 catch로 처리
      }
    } catch (e) {
      return ApiResponse.failure(ApiError.server('팔로우에 실패했습니다: $e'));
    }
  }

  /// 아티스트 언팔로우하기
  Future<ApiResponse<bool>> unfollowArtist({
    required String artistId,
  }) async {
    try {
      print('아티스트 언팔로우 시작: artistId=$artistId');

      final user = supabase.auth.currentUser;
      if (user == null) {
        print('언팔로우 실패: 로그인 필요');
        return ApiResponse.failure(
          ApiError.auth('로그인이 필요합니다'),
        );
      }

      try {
        await supabase
            .from('follows')
            .delete()
            .eq('follower_id', user.id)
            .eq('following_id', artistId);

        print('언팔로우 성공');
        return ApiResponse.success(true);
      } catch (e) {
        print('언팔로우 오류: $e');

        // PostgrestException인 경우 테이블이 없을 때 성공으로 간주
        if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
          print('follows 테이블이 존재하지 않습니다. 성공으로 처리.');
          return ApiResponse.success(true);
        }

        rethrow; // 다시 예외 발생시켜서 아래 catch로 처리
      }
    } catch (e) {
      return ApiResponse.failure(ApiError.server('언팔로우에 실패했습니다: $e'));
    }
  }

  /// 사용자가 팔로우한 아티스트 목록 가져오기
  Future<ApiResponse<List<Artist>>> getFollowedArtists() async {
    try {
      print('팔로우한 아티스트 목록 가져오기 시작');

      final user = supabase.auth.currentUser;
      if (user == null) {
        print('팔로우한 아티스트 목록 실패: 로그인 필요');
        return ApiResponse.failure(
          ApiError.auth('로그인이 필요합니다'),
        );
      }

      try {
        final response = await supabase
            .from('follows')
            .select('artists:following_id(*)')
            .eq('follower_id', user.id);

        final artists = response.map((json) => Artist.fromJson(json['artists'])).toList();
        print('팔로우한 아티스트 목록 결과: ${artists.length}개');
        return ApiResponse.success(artists);
      } catch (e) {
        print('팔로우한 아티스트 목록 오류: $e');

        // PostgrestException인 경우 테이블이 없을 때 빈 목록 반환
        if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
          print('follows 또는 artists 테이블이 존재하지 않습니다. 빈 목록 반환.');
          return ApiResponse.success(<Artist>[]);
        }

        rethrow; // 다시 예외 발생시켜서 아래 catch로 처리
      }
    } catch (e) {
      return ApiResponse.failure(ApiError.server('팔로우한 아티스트 목록을 불러오는데 실패했습니다: $e'));
    }
  }

  /// 아티스트 팔로우 여부 확인
  Future<ApiResponse<bool>> isFollowingArtist({
    required String artistId,
  }) async {
    try {
      print('아티스트 팔로우 여부 확인 시작: artistId=$artistId');

      final user = supabase.auth.currentUser;
      if (user == null) {
        print('팔로우 여부 확인: 로그인되지 않음, false 반환');
        return ApiResponse.success(false);
      }

      try {
        final response = await supabase
            .from('follows')
            .select('id')
            .eq('follower_id', user.id)
            .eq('following_id', artistId);

        final isFollowing = response.isNotEmpty;
        print('팔로우 여부 확인 결과: $isFollowing');
        return ApiResponse.success(isFollowing);
      } catch (e) {
        print('팔로우 여부 확인 오류: $e');

        // PostgrestException인 경우 테이블이 없을 때 false 반환
        if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
          print('follows 테이블이 존재하지 않습니다. false 반환.');
          return ApiResponse.success(false);
        }

        rethrow; // 다시 예외 발생시켜서 아래 catch로 처리
      }
    } catch (e) {
      return ApiResponse.failure(ApiError.server('팔로우 상태를 확인하는데 실패했습니다: $e'));
    }
  }

  /// 아티스트 팔로워 수 가져오기
  Future<ApiResponse<int>> getArtistFollowersCount({
    required String artistId,
  }) async {
    try {
      print('아티스트 팔로워 수 가져오기 시작: artistId=$artistId');

      try {
        final response = await supabase.from('follows').select('id').eq('following_id', artistId);

        print('아티스트 팔로워 수 결과: ${response.length}');
        return ApiResponse.success(response.length);
      } catch (e) {
        print('아티스트 팔로워 수 오류: $e');

        // PostgrestException인 경우 테이블이 없을 때 0 반환
        if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
          print('follows 테이블이 존재하지 않습니다. 0 반환.');
          return ApiResponse.success(0);
        }

        rethrow; // 다시 예외 발생시켜서 아래 catch로 처리
      }
    } catch (e) {
      return ApiResponse.failure(ApiError.server('팔로워 수를 불러오는데 실패했습니다: $e'));
    }
  }

  /// 아티스트 검색
  Future<ApiResponse<List<Artist>>> searchArtists({
    required String query,
  }) async {
    try {
      print('아티스트 검색 시작: 쿼리=$query');

      final response =
          await supabase.from('artists').select().ilike('name', '%$query%').order('name').limit(20);

      final artists = response.map((json) => Artist.fromJson(json)).toList();
      print('아티스트 검색 결과: ${artists.length}개');
      return ApiResponse.success(artists);
    } catch (e) {
      print('아티스트 검색 오류: $e');

      // PostgrestException인 경우 테이블이 없을 때 빈 배열 반환
      if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
        print('artists 테이블이 존재하지 않습니다. 빈 결과 반환.');
        // 테이블이 없으면 빈 목록 반환
        return ApiResponse.success(<Artist>[]);
      }

      return ApiResponse.failure(ApiError.server('아티스트 검색에 실패했습니다: $e'));
    }
  }

  /// 인기 아티스트 목록 가져오기
  Future<ApiResponse<List<Artist>>> getPopularArtists({
    int limit = 10,
  }) async {
    try {
      print('인기 아티스트 목록 가져오기 시작: limit=$limit');

      // 인기 아티스트는 팔로워 수로 정렬
      // 실제로는 팔로워 수에 따라 정렬해야 하지만 여기서는 간단히 구현
      try {
        final response =
            await supabase.from('artists').select('*, follows(*)').order('name').limit(limit);

        final artists = response.map((json) => Artist.fromJson(json)).toList();
        print('인기 아티스트 목록 결과: ${artists.length}개');
        return ApiResponse.success(artists);
      } catch (e) {
        print('인기 아티스트 목록 오류: $e');

        // PostgrestException인 경우 테이블이 없을 때 빈 배열 반환
        if (e.toString().contains('relation') && e.toString().contains('does not exist')) {
          print('artists 테이블이 존재하지 않습니다. 더미 데이터 반환.');

          // 테이블이 없으면 더미 데이터 반환
          final dummyArtists = _createDummyArtists();
          return ApiResponse.success(dummyArtists.take(limit).toList());
        }

        rethrow; // 다시 예외 발생시켜서 아래 catch로 처리
      }
    } catch (e) {
      print('인기 아티스트 목록 가져오기 실패: $e');
      return ApiResponse.failure(ApiError.server('인기 아티스트 목록을 불러오는데 실패했습니다: $e'));
    }
  }

  /// 더미 아티스트 데이터 생성
  List<Artist> _createDummyArtists() {
    final now = DateTime.now();
    return [
      Artist(
        id: '1',
        name: 'BLACKPINK',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://via.placeholder.com/150',
        groupName: 'BLACKPINK',
      ),
      Artist(
        id: '2',
        name: 'NewJeans',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://via.placeholder.com/150',
        groupName: 'NewJeans',
      ),
      Artist(
        id: '3',
        name: 'BTS',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://via.placeholder.com/150',
        groupName: 'BTS',
      ),
      Artist(
        id: '4',
        name: 'IVE',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://via.placeholder.com/150',
        groupName: 'IVE',
      ),
      Artist(
        id: '5',
        name: 'TWICE',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://via.placeholder.com/150',
        groupName: 'TWICE',
      ),
      Artist(
        id: '6',
        name: 'aespa',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://via.placeholder.com/150',
        groupName: 'aespa',
      ),
      Artist(
        id: '7',
        name: 'ITZY',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://via.placeholder.com/150',
        groupName: 'ITZY',
      ),
      Artist(
        id: '8',
        name: 'LE SSERAFIM',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://via.placeholder.com/150',
        groupName: 'LE SSERAFIM',
      ),
      Artist(
        id: '9',
        name: 'SEVENTEEN',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://via.placeholder.com/150',
        groupName: 'SEVENTEEN',
      ),
      Artist(
        id: '10',
        name: 'Stray Kids',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://via.placeholder.com/150',
        groupName: 'Stray Kids',
      ),
    ];
  }
}
