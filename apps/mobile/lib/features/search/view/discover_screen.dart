import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/feed/widgets/video_card.dart';
import 'package:mobile/features/search/model/discover_state.dart';
import 'package:mobile/features/search/provider/discover_provider.dart';
import 'package:mobile/features/shared/error_view.dart';
import 'package:mobile/routes/routes.dart';

/// 발견 화면
class DiscoverScreen extends ConsumerWidget {
  /// 생성자
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverState = ref.watch(discoverProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discover_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(discoverProvider.notifier).refresh(),
          ),
        ],
      ),
      body: discoverState.isLoading && !discoverState.hasData
          ? const Center(child: CircularProgressIndicator())
          : discoverState.error != null && !discoverState.hasData
              ? ErrorView(
                  message: discoverState.error!,
                  onRetry: () => ref.read(discoverProvider.notifier).refresh(),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(discoverProvider.notifier).refresh(),
                  child: _buildContent(context, discoverState),
                ),
    );
  }

  /// 발견 화면 컨텐츠
  Widget _buildContent(BuildContext context, DiscoverState state) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 인기 아티스트 섹션
        if (state.popularArtists.isNotEmpty) ...[
          _buildSectionHeader(context, l10n.discover_popular_artists),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.popularArtists.length,
              itemBuilder: (context, index) {
                final artist = state.popularArtists[index];
                return _buildArtistItem(context, artist);
              },
            ),
          ),
          const Divider(height: 32.0),
        ],

        // 트렌딩 비디오 섹션
        if (state.trendingVideos.isNotEmpty) ...[
          _buildSectionHeader(context, l10n.discover_trending_fancams),
          ...state.trendingVideos.take(3).map((video) => VideoCard(
                video: video,
                onTap: () => Navigator.of(context).pushNamed('/video/${video.id}'),
              )),
          TextButton(
            onPressed: () {
              // 더 많은 인기 비디오 화면으로 이동
              context.push(AppRoutes.feed);
            },
            child: Text(l10n.discover_view_more),
          ),
          const Divider(height: 32.0),
        ],

        // 최신 비디오 섹션
        if (state.recentVideos.isNotEmpty) ...[
          _buildSectionHeader(context, l10n.discover_recent_fancams),
          ...state.recentVideos.take(3).map((video) => VideoCard(
                video: video,
                onTap: () => Navigator.of(context).pushNamed('/video/${video.id}'),
              )),
          TextButton(
            onPressed: () {
              // 더 많은 최신 비디오 화면으로 이동
              context.push(AppRoutes.feed);
            },
            child: Text(l10n.discover_view_more),
          ),
          const Divider(height: 32.0),
        ],

        // 인기 그룹별 영상
        if (state.groupVideos.isNotEmpty) ...[
          _buildSectionHeader(context, l10n.discover_popular_by_group),
          Column(
            children: state.groupVideos.entries.take(3).map((entry) {
              final groupName = entry.key;
              final videos = entry.value;
              return _buildGroupSection(context, groupName, videos);
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// 섹션 헤더
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  /// 아티스트 아이템
  Widget _buildArtistItem(BuildContext context, Artist artist) {
    return InkWell(
      onTap: () => context.push('${AppRoutes.artistBase}/${artist.id}'),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: artist.imageUrl != null ? NetworkImage(artist.imageUrl!) : null,
              child: artist.imageUrl == null
                  ? Text(
                      artist.name.substring(0, 1),
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
            const SizedBox(height: 8.0),
            Text(
              artist.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.0),
            ),
          ],
        ),
      ),
    );
  }

  /// 그룹 섹션
  Widget _buildGroupSection(BuildContext context, String groupName, List<Video> videos) {
    final l10n = AppLocalizations.of(context);

    if (videos.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            groupName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (videos.isNotEmpty)
          VideoCard(
            video: videos.first,
            onTap: () => Navigator.of(context).pushNamed('/video/${videos.first.id}'),
          ),
        if (videos.length > 1)
          TextButton(
            onPressed: () {
              // 그룹 비디오 더 보기
              context.push('${AppRoutes.search}?group=$groupName');
            },
            child: Text(l10n.discover_view_more),
          ),
        const SizedBox(height: 16.0),
      ],
    );
  }
}
