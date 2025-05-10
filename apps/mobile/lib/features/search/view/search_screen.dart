import 'package:api_client/api_client.dart'; // Video 클래스에 대한 import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/ads/service/ad_service.dart';
import 'package:mobile/features/feed/provider/feed_provider.dart';
import 'package:mobile/features/feed/widgets/video_card.dart';
import 'package:mobile/features/search/model/search_state.dart';
import 'package:mobile/features/search/provider/search_provider.dart';
import 'package:mobile/features/shared/error_view.dart';
import 'package:mobile/features/subscription/provider/new_subscription_provider.dart';
import 'package:mobile/features/video_player/view/video_player_screen.dart';
import 'package:mobile/routes/routes.dart';

/// 검색 화면
class SearchScreen extends ConsumerStatefulWidget {
  /// 생성자
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  // AdService 인스턴스를 클래스 멤버 변수로 선언
  late final AdService _adService;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // AdService 초기화
    _adService = AdService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _adService.dispose(); // AdService 리소스 해제
    super.dispose();
  }

  // 스크롤 리스너 - 페이지네이션 처리
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // 스크롤이 하단에 가까워지면 추가 데이터 로드
      final state = ref.read(searchProvider);
      if (!state.isLoading && !state.isLoadingMore && state.hasMore) {
        ref.read(searchProvider.notifier).loadMore();
      }
    }
  }

  // 검색 수행
  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    ref.read(searchProvider.notifier).search(query);
    _focusNode.unfocus();
  }

  // 검색어 지우기
  void _clearSearch() {
    _searchController.clear();
    ref.read(searchProvider.notifier).onQueryChanged('');
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(searchProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.search_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore),
            tooltip: l10n.search_discover,
            onPressed: () => context.push(AppRoutes.discover),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: l10n.search_hint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _performSearch,
              onChanged: (value) {
                // 검색어 변경 시 제안 표시
                ref.read(searchProvider.notifier).onQueryChanged(value);
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 필터 패널
            if (state.query.isNotEmpty) _buildFilterPanel(state),

            // 검색 결과 또는 제안/최근 검색어
            Expanded(
              child:
                  state.query.isEmpty ? _buildSearchSuggestions(state) : _buildSearchResults(state),
            ),
          ],
        ),
      ),
    );
  }

  // 필터 패널
  Widget _buildFilterPanel(SearchState state) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // 필터 탭
          Row(
            children: [
              _filterChip(
                label: l10n.search_filter_all,
                selected: state.selectedFilter == SearchFilterType.all,
                onSelected: (_) =>
                    ref.read(searchProvider.notifier).setFilter(SearchFilterType.all),
              ),
              const SizedBox(width: 8.0),
              _filterChip(
                label: l10n.search_filter_video,
                selected: state.selectedFilter == SearchFilterType.video,
                onSelected: (_) =>
                    ref.read(searchProvider.notifier).setFilter(SearchFilterType.video),
              ),
              const SizedBox(width: 8.0),
              _filterChip(
                label: l10n.search_filter_artist,
                selected: state.selectedFilter == SearchFilterType.artist,
                onSelected: (_) =>
                    ref.read(searchProvider.notifier).setFilter(SearchFilterType.artist),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // 정렬 옵션
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _sortChip(
                  label: l10n.search_sort_relevance,
                  selected: state.sortOption == SearchSortOption.relevance,
                  onSelected: (_) =>
                      ref.read(searchProvider.notifier).setSortOption(SearchSortOption.relevance),
                ),
                const SizedBox(width: 8.0),
                _sortChip(
                  label: l10n.search_sort_latest,
                  selected: state.sortOption == SearchSortOption.latest,
                  onSelected: (_) =>
                      ref.read(searchProvider.notifier).setSortOption(SearchSortOption.latest),
                ),
                const SizedBox(width: 8.0),
                _sortChip(
                  label: l10n.search_sort_popularity,
                  selected: state.sortOption == SearchSortOption.popularity,
                  onSelected: (_) =>
                      ref.read(searchProvider.notifier).setSortOption(SearchSortOption.popularity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 필터 칩
  Widget _filterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  // 정렬 칩
  Widget _sortChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
    );
  }

  // 검색 제안 및 최근 검색어
  Widget _buildSearchSuggestions(SearchState state) {
    final l10n = AppLocalizations.of(context);

    if (state.suggestions.isNotEmpty) {
      // 실시간 검색어 제안 표시
      return ListView.builder(
        itemCount: state.suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = state.suggestions[index];
          return ListTile(
            leading: const Icon(Icons.search),
            title: Text(suggestion),
            onTap: () {
              _searchController.text = suggestion;
              _performSearch(suggestion);
            },
          );
        },
      );
    }

    // 최근 검색어와 인기 검색어 표시
    return CustomScrollView(
      slivers: [
        // 최근 검색어
        if (state.recentSearches.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.search_recent,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(searchProvider.notifier).clearRecentSearches(),
                    child: Text(l10n.search_clear_all),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final search = state.recentSearches[index];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(search),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => ref.read(searchProvider.notifier).removeRecentSearch(search),
                  ),
                  onTap: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                );
              },
              childCount: state.recentSearches.length,
            ),
          ),
          const SliverToBoxAdapter(
            child: Divider(height: 24.0),
          ),
        ],

        // 인기 검색어
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Text(
              l10n.search_popular,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.0,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final popular = ref.watch(popularSearchesProvider)[index];
              return Card(
                margin: const EdgeInsets.all(4.0),
                child: InkWell(
                  onTap: () {
                    _searchController.text = popular;
                    _performSearch(popular);
                  },
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Flexible(
                          child: Text(
                            popular,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            childCount: ref.watch(popularSearchesProvider).length,
          ),
        ),
      ],
    );
  }

  // 검색 결과
  Widget _buildSearchResults(SearchState state) {
    final l10n = AppLocalizations.of(context);

    // 로딩 중 - 검색어가 있고 검색 결과가 아직 없을 때만 로딩바 표시
    if (state.isLoading &&
        state.results.isEmpty &&
        state.artistResults.isEmpty &&
        state.query.isNotEmpty &&
        state.isSubmitted) {
      return const Center(child: CircularProgressIndicator());
    }

    // 에러
    if (state.error != null && state.results.isEmpty && state.artistResults.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () => _performSearch(state.query),
      );
    }

    // 결과 없음 - 검색어가 있지만 결과가 없을 때만 표시
    if (!state.isLoading &&
        state.results.isEmpty &&
        state.artistResults.isEmpty &&
        state.query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.search_no_results,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.search_try_another,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }

    // 검색어가 없는 경우 빈 화면 표시
    if (state.query.isEmpty) {
      return const SizedBox.shrink();
    }

    // 결과 표시
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      children: [
        // 아티스트 결과
        if (state.artistResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              l10n.search_category_artist,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.artistResults.length,
              itemBuilder: (context, index) {
                final artist = state.artistResults[index];
                return SizedBox(
                  width: 100,
                  child: InkWell(
                    onTap: () => context.push('${AppRoutes.artistBase}/${artist.id}'),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage:
                              artist.imageUrl != null ? NetworkImage(artist.imageUrl!) : null,
                          child: artist.imageUrl == null ? Text(artist.name.substring(0, 1)) : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artist.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
        ],

        // 비디오 결과
        if (state.results.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              l10n.search_category_video,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...state.results.map((video) => VideoCard(
                video: video,
                onTap: () => _navigateToVideoPlayer(context, video),
              )),

          // 추가 로딩 인디케이터
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ],
    );
  }

  // 동영상 플레이어로 이동하는 함수
  void _navigateToVideoPlayer(BuildContext context, Video video) {
    // 현재 선택한 비디오를 저장
    ref.read(selectedVideoProvider.notifier).state = video;
    ref.read(feedVideosProvider.notifier).selectVideo(video);

    // 구독 상태 확인
    final isSubscribed = ref.read(isPremiumUserProvider).maybeWhen(
          data: (value) => value,
          orElse: () => false,
        );

    if (isSubscribed) {
      // 구독자는 바로 비디오 플레이어로 이동
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(video: video),
          fullscreenDialog: true,
        ),
      );
    } else {
      // 비구독자는 광고 표시 전에 광고 로드
      _adService.loadInterstitialAd();

      // 전면 광고 표시 후 비디오 플레이어로 이동
      _adService.showInterstitialAd(
        onAdDismissed: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(video: video),
              fullscreenDialog: true,
            ),
          );
        },
        onAdFailedToShow: () {
          // 광고 표시 실패 시 바로 비디오 플레이어로 이동
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(video: video),
              fullscreenDialog: true,
            ),
          );
        },
      );
    }
  }
}
