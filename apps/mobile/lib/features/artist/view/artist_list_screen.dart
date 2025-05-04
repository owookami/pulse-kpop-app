import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/artist_provider.dart';
import '../widgets/artist_info_card.dart';

/// 아티스트 목록 화면
class ArtistListScreen extends ConsumerStatefulWidget {
  /// 생성자
  const ArtistListScreen({super.key});

  @override
  ConsumerState<ArtistListScreen> createState() => _ArtistListScreenState();
}

class _ArtistListScreenState extends ConsumerState<ArtistListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Artist> _searchResults = [];
  bool _initialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArtists() async {
    // 아티스트 목록 로드
    await ref.read(artistProvider.notifier).getAllArtists();
    // 팔로우한 아티스트 목록 로드
    await ref.read(artistProvider.notifier).loadFollowedArtists();

    if (mounted) {
      setState(() {
        _initialLoadComplete = true;
      });
    }
  }

  Future<void> _searchArtists(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await ref.read(artistProvider.notifier).searchArtists(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final artistState = ref.watch(artistProvider);
    final followedArtists = artistState.followedArtists;
    // 로딩 상태는 추적하지만 UI에 표시하지 않음
    final error = artistState.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('아티스트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArtists,
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '아티스트 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchArtists('');
                        },
                      )
                    : null,
              ),
              onChanged: _searchArtists,
            ),
          ),

          // 에러 표시
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),

          // 콘텐츠 영역
          Expanded(
            child: _isSearching
                ? // 검색 결과
                _searchResults.isEmpty
                    ? const Center(
                        child: Text('검색 결과가 없습니다'),
                      )
                    : _buildArtistList(_searchResults)
                : // 팔로우한 아티스트 목록
                followedArtists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '아직 팔로우한 아티스트가 없습니다',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '아티스트를 검색해서 팔로우해보세요!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildArtistList(followedArtists),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistList(List<Artist> artists) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: artists.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final artist = artists[index];
        return ArtistInfoCard(
          artist: artist,
          onTap: () {
            // 아티스트 프로필 화면으로 이동
            ref.read(artistProvider.notifier).setSelectedArtist(artist);
            context.push('/artist/${artist.id}');
          },
        );
      },
    );
  }
}
