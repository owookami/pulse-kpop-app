import 'package:api_client/api_client.dart';
import "package:flutter/material.dart";
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/features/video_player/view/video_player_screen.dart';

import '../provider/artist_provider.dart';
import '../widgets/follow_button.dart';

/// 아티스트 프로필 화면
class ArtistProfileScreen extends HookConsumerWidget {
  /// 생성자
  const ArtistProfileScreen({
    required this.artistId,
    super.key,
  });

  /// 아티스트 ID
  final String artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistState = ref.watch(artistProvider);
    final artist = artistState.selectedArtist;
    final isLoading = artistState.isLoading;
    final error = artistState.error;
    final videos = artistState.artistVideos;
    final followersCount = artistState.followedArtistsCount;

    // 탭 컨트롤러
    final tabController = useTabController(initialLength: 2);

    // 필터링 및 정렬 상태
    final sortBy = useState<String>('latest');
    final filterType = useState<String>('all');

    // 필터링된 비디오 목록 계산
    final filteredVideos = useState<List<Video>>(videos);

    // 비디오 목록이 변경되면 필터링 및 정렬 적용
    useEffect(() {
      if (videos.isEmpty) {
        filteredVideos.value = [];
        return null;
      }

      // 필터링
      List<Video> filtered = List.from(videos);

      // 타입별 필터링
      if (filterType.value != 'all') {
        filtered = filtered.where((video) {
          // 비디오 제목이나 설명에서 타입 확인
          final titleContainsType =
              video.title.toLowerCase().contains(filterType.value.toLowerCase());
          final descContainsType =
              video.description?.toLowerCase().contains(filterType.value.toLowerCase()) ?? false;

          return titleContainsType || descContainsType;
        }).toList();
      }

      // 정렬
      switch (sortBy.value) {
        case 'latest':
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'oldest':
          filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
        case 'popular':
          filtered.sort((a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0));
          break;
      }

      filteredVideos.value = filtered;
      return null;
    }, [videos, sortBy.value, filterType.value]);

    // 화면이 처음 로드될 때 실행되는 효과
    useEffect(() {
      // 아티스트 정보 로드
      ref.read(artistProvider.notifier).getArtistDetails(artistId);
      return null;
    }, [artistId]);

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              : artist == null
                  ? const Center(child: Text('아티스트 정보를 찾을 수 없습니다'))
                  : NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) => [
                        SliverAppBar(
                          expandedHeight: 240,
                          pinned: true,
                          flexibleSpace: FlexibleSpaceBar(
                            background: _buildProfileHeader(context, artist, followersCount),
                          ),
                        ),
                        SliverPersistentHeader(
                          delegate: _SliverTabBarDelegate(
                            TabBar(
                              controller: tabController,
                              labelColor: Theme.of(context).primaryColor,
                              unselectedLabelColor: Colors.grey,
                              tabs: const [
                                Tab(text: '팬캠'),
                                Tab(text: '소개'),
                              ],
                            ),
                          ),
                          pinned: true,
                        ),
                      ],
                      body: TabBarView(
                        controller: tabController,
                        children: [
                          // 팬캠 탭
                          filteredVideos.value.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.videocam_off,
                                          size: 60, color: Colors.grey.shade400),
                                      const SizedBox(height: 16),
                                      Text(
                                        '등록된 팬캠이 없습니다',
                                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                              color: Colors.grey.shade700,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => ref
                                            .read(artistProvider.notifier)
                                            .getArtistDetails(artistId),
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('새로고침'),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.all(16.0),
                                  children: [
                                    // 필터링 및 정렬 UI
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: Row(
                                        children: [
                                          // 필터 드롭다운
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: filterType.value,
                                                  isExpanded: true,
                                                  icon: const Icon(Icons.filter_list),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: 'all',
                                                      child: Text('전체'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: '무대',
                                                      child: Text('무대'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: '연습',
                                                      child: Text('연습영상'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: '비하인드',
                                                      child: Text('비하인드'),
                                                    ),
                                                  ],
                                                  onChanged: (value) {
                                                    if (value != null) {
                                                      filterType.value = value;
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // 정렬 드롭다운
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: sortBy.value,
                                                  isExpanded: true,
                                                  icon: const Icon(Icons.sort),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: 'latest',
                                                      child: Text('최신순'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'oldest',
                                                      child: Text('오래된순'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'popular',
                                                      child: Text('인기순'),
                                                    ),
                                                  ],
                                                  onChanged: (value) {
                                                    if (value != null) {
                                                      sortBy.value = value;
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 팬캠 그리드 뷰
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.8,
                                        crossAxisSpacing: 8.0,
                                        mainAxisSpacing: 8.0,
                                      ),
                                      itemCount: filteredVideos.value.length,
                                      itemBuilder: (context, index) {
                                        final video = filteredVideos.value[index];
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context, rootNavigator: true).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VideoPlayerScreen.fromId(videoId: video.id),
                                                fullscreenDialog: true,
                                              ),
                                            );
                                          },
                                          child: Card(
                                            clipBehavior: Clip.antiAlias,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                            elevation: 2.0,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                // 썸네일
                                                Stack(
                                                  children: [
                                                    AspectRatio(
                                                      aspectRatio: 16 / 9,
                                                      child: video.thumbnailUrl != null
                                                          ? Image.network(
                                                              video.thumbnailUrl!,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (_, __, ___) =>
                                                                  Container(
                                                                color: Colors.grey.shade200,
                                                                child: const Icon(
                                                                  Icons.image_not_supported,
                                                                  color: Colors.grey,
                                                                ),
                                                              ),
                                                            )
                                                          : Container(
                                                              color: Colors.grey.shade200,
                                                              child: const Icon(
                                                                Icons.videocam,
                                                                color: Colors.grey,
                                                              ),
                                                            ),
                                                    ),
                                                    // 플레이 아이콘
                                                    Positioned.fill(
                                                      child: Center(
                                                        child: Icon(
                                                          Icons.play_circle_filled,
                                                          size: 40,
                                                          color: Colors.white.withOpacity(0.8),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // 비디오 정보
                                                Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        video.title,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          const Icon(Icons.visibility,
                                                              size: 14, color: Colors.grey),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            _formatNumber(video.viewCount ?? 0),
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey.shade700),
                                                          ),
                                                          const Spacer(),
                                                          Text(
                                                            _formatDate(video.createdAt),
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey.shade700),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),

                          // 소개 탭
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 프로필 정보
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 아티스트 이름
                                        Row(
                                          children: [
                                            const Icon(Icons.person, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(
                                              '이름',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              artist.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24),

                                        // 그룹 이름 (있을 경우)
                                        if (artist.groupName != null &&
                                            artist.groupName!.isNotEmpty) ...[
                                          Row(
                                            children: [
                                              const Icon(Icons.group, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(
                                                '그룹',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                artist.groupName!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 24),
                                        ],

                                        // 팔로워
                                        Row(
                                          children: [
                                            const Icon(Icons.people, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(
                                              '팔로워',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '$followersCount명',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // 팬캠 통계
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '팬캠 통계',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // 전체 팬캠 수
                                        Row(
                                          children: [
                                            const Icon(Icons.videocam, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(
                                              '전체 영상',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${videos.length}개',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24),

                                        // 총 조회수
                                        Row(
                                          children: [
                                            const Icon(Icons.visibility, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(
                                              '총 조회수',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              _formatNumber(videos.fold<int>(
                                                  0, (sum, video) => sum + (video.viewCount ?? 0))),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24),

                                        // 최근 업로드
                                        Row(
                                          children: [
                                            const Icon(Icons.date_range, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            Text(
                                              '최신 영상',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              videos.isNotEmpty
                                                  ? _formatDate(videos
                                                      .map((v) => v.createdAt)
                                                      .reduce((a, b) => a.isAfter(b) ? a : b))
                                                  : '없음',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Artist artist, int followersCount) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 아티스트 프로필 이미지
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: artist.imageUrl != null
                        ? Image.network(
                            artist.imageUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, error, _) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey.shade300,
                              child: Center(
                                child: Text(
                                  artist.name.substring(0, 1),
                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade300,
                            child: Center(
                              child: Text(
                                artist.name.substring(0, 1),
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  // 아티스트 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '팔로워 ${followersCount.toString()}명',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                        ),
                        const SizedBox(height: 8),
                        // 팔로우 버튼
                        SizedBox(
                          width: 120,
                          child: FollowButton(artistId: artist.id),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 설명이 있을 수 있으므로 대비하지만, 현재 모델에 없음
              // 그룹 정보가 있다면 표시
              if (artist.groupName != null && artist.groupName!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '${artist.groupName} 소속',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 날짜 형식화
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 숫자 형식화
  String _formatNumber(int number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(1)}천만';
    } else if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}만';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}천';
    } else {
      return number.toString();
    }
  }
}

/// TabBar를 고정하기 위한 SliverPersistentHeaderDelegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
