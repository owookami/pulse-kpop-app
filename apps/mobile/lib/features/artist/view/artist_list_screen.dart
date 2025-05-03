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

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final artistState = ref.watch(artistProvider);
    final followedArtists = artistState.followedArtists;
    final isLoading = artistState.isLoading;
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

          // 로딩 인디케이터
          if (isLoading && !_isSearching)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_isSearching)
            // 검색 결과
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(
                      child: Text('검색 결과가 없습니다'),
                    )
                  : _buildArtistList(_searchResults),
            )
          else
            // 팔로우한 아티스트 목록
            Expanded(
              child: followedArtists.isEmpty
                  ? const Center(
                      child: Text('아직 팔로우한 아티스트가 없습니다'),
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
