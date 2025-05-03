import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/artist_provider.dart';

/// 아티스트 팔로우 버튼 위젯
class FollowButton extends ConsumerWidget {
  /// 생성자
  const FollowButton({
    required this.artistId,
    this.size = const Size(120, 40),
    this.radius = 20,
    this.textSize = 14,
    super.key,
  });

  /// 아티스트 ID
  final String artistId;

  /// 버튼 크기
  final Size size;

  /// 버튼 모서리 반경
  final double radius;

  /// 글자 크기
  final double textSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistState = ref.watch(artistProvider);
    final isFollowing = artistState.isFollowingSelectedArtist;
    final isLoading = artistState.isLoadingFollow;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: ElevatedButton(
        onPressed:
            isLoading ? null : () => ref.read(artistProvider.notifier).toggleFollow(artistId),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isFollowing ? Colors.grey.shade200 : Theme.of(context).colorScheme.primary,
          foregroundColor: isFollowing ? Colors.black87 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: isFollowing ? BorderSide(color: Colors.grey.shade400) : BorderSide.none,
          ),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).primaryColor,
                ),
              )
            : Text(
                isFollowing ? '팔로잉' : '팔로우',
                style: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
