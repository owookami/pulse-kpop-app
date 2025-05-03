import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/artist_provider.dart';
import 'follow_button.dart';

/// 아티스트 정보 카드 위젯
class ArtistInfoCard extends ConsumerWidget {
  /// 생성자
  const ArtistInfoCard({
    required this.artist,
    this.onTap,
    this.showFollowButton = true,
    super.key,
  });

  /// 아티스트 정보
  final Artist artist;

  /// 탭 이벤트 핸들러
  final VoidCallback? onTap;

  /// 팔로우 버튼 표시 여부
  final bool showFollowButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistState = ref.watch(artistProvider);
    final followersCount =
        artistState.selectedArtist?.id == artist.id ? artistState.followedArtistsCount : 0;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 프로필 이미지
                  _buildProfileImage(),
                  const SizedBox(width: 16),

                  // 아티스트 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (artist.groupName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            artist.groupName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        if (followersCount > 0)
                          Text(
                            '팔로워 $followersCount명',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 팔로우 버튼
                  if (showFollowButton) ...[
                    const SizedBox(width: 8),
                    FollowButton(artistId: artist.id),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 프로필 이미지 위젯
  Widget _buildProfileImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      clipBehavior: Clip.antiAlias,
      child: artist.imageUrl != null
          ? Image.network(
              artist.imageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.person,
                size: 40,
                color: Colors.grey,
              ),
            )
          : const Icon(
              Icons.person,
              size: 40,
              color: Colors.grey,
            ),
    );
  }
}
