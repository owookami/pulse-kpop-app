import 'package:api_client/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 랭킹 서비스
class RankingService {
  /// 생성자
  RankingService();

  /// 베이지안 평균을 계산하여 비디오 정렬
  ///
  /// 베이지안 평균은 다음 공식을 사용합니다:
  /// (C × m + R × v) / (C + v)
  ///
  /// C = 최소 투표 수 (사전 가중치)
  /// m = 기본 평균 평점 (3.0)
  /// R = 실제 평균 평점
  /// v = 실제 투표 수
  Future<List<Video>> rankVideosByBayesianAverage(
    List<Video> videos, {
    double defaultRating = 3.0,
    int minimumVotes = 10,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rankedVideos = List<Video>.from(videos);

    // 각 비디오의 현재 평점을 캐시에서 로드
    final Map<String, double> bayesianScores = {};

    for (final video in videos) {
      // API가 구현되면 서버에서 평점 정보를 가져올 수 있음
      // 임시로 SharedPreferences에서 가져옴
      final votes = prefs.getInt('votes_count_${video.id}') ?? 0;
      final averageRating = prefs.getDouble('average_rating_${video.id}') ?? defaultRating;
      final likes = prefs.getInt('likes_count_${video.id}') ?? 0;
      final dislikes = prefs.getInt('dislikes_count_${video.id}') ?? 0;

      // 좋아요/싫어요 비율 (0.0-1.0)
      final likeRatio = likes + dislikes > 0 ? likes / (likes + dislikes) : 0.5; // 기본값

      // 평점에 좋아요/싫어요 비율 반영 (가중치: 0.7/0.3)
      final combinedRating = (averageRating * 0.7) + (likeRatio * 5 * 0.3);

      // 베이지안 평균 계산
      final bayesianScore =
          ((minimumVotes * defaultRating) + (votes * combinedRating)) / (minimumVotes + votes);

      // 최근성 가중치 (최근 비디오에 약간의 가산점)
      final daysOld = DateTime.now().difference(video.createdAt).inDays;
      final recencyBonus = daysOld < 14 ? 0.3 * (1 - (daysOld / 14)) : 0.0;

      // 최종 점수
      final finalScore = bayesianScore + recencyBonus;

      bayesianScores[video.id] = finalScore;
    }

    // 점수 기준으로 정렬
    rankedVideos.sort((a, b) {
      final scoreA = bayesianScores[a.id] ?? defaultRating;
      final scoreB = bayesianScores[b.id] ?? defaultRating;
      return scoreB.compareTo(scoreA); // 내림차순
    });

    return rankedVideos;
  }

  /// 트렌딩 점수 계산 (최근 좋아요, 조회수 기반)
  Future<List<Video>> rankVideosByTrendingScore(
    List<Video> videos, {
    int recentDays = 7,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rankedVideos = List<Video>.from(videos);
    final now = DateTime.now();

    // 각 비디오의 트렌딩 점수 계산
    final Map<String, double> trendingScores = {};

    for (final video in videos) {
      // 최근성 계수 (최근 영상일수록 더 높은 점수)
      final daysSinceRelease = now.difference(video.createdAt).inDays;
      final recencyFactor =
          daysSinceRelease < recentDays ? 1.0 - (daysSinceRelease / recentDays) : 0.0;

      // 최근 좋아요 및 조회수 (실제로는 API에서 가져와야 함)
      final recentLikes = prefs.getInt('recent_likes_${video.id}') ?? 0;
      final recentViews = prefs.getInt('recent_views_${video.id}') ?? 0;

      // 트렌딩 점수 계산 (좋아요 가중치 3배)
      final trendingScore = ((recentLikes * 3) + recentViews) * (1 + recencyFactor);
      trendingScores[video.id] = trendingScore;
    }

    // 트렌딩 점수 기준으로 정렬
    rankedVideos.sort((a, b) {
      final scoreA = trendingScores[a.id] ?? 0;
      final scoreB = trendingScores[b.id] ?? 0;
      return scoreB.compareTo(scoreA); // 내림차순
    });

    return rankedVideos;
  }
}
