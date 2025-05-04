import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../provider/artist_provider.dart';

/// 아티스트 팔로우 버튼 위젯
class FollowButton extends ConsumerWidget {
  /// 생성자
  const FollowButton({
    super.key,
    required this.artistId,
    this.size,
  });

  /// 아티스트 ID
  final String artistId;

  /// 버튼 크기
  final Size? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistState = ref.watch(artistProvider);
    final isFollowing = artistState.isFollowingSelectedArtist;
    final isLoading = artistState.isLoadingFollow;

    // 팔로우 상태에 따른 색상 및 텍스트
    final buttonColor = isFollowing ? Colors.grey.shade200 : Theme.of(context).primaryColor;

    final textColor = isFollowing ? Colors.black87 : Colors.white;

    final buttonText = isFollowing ? '팔로잉' : '팔로우';
    final leadingIcon = isFollowing ? Icons.check : Icons.add;

    // 팔로우 버튼 클릭 핸들러
    void handleFollow() {
      // 로딩 중이면 중복 클릭 방지
      if (isLoading) return;

      // 아티스트 팔로우/언팔로우 토글
      ref.read(artistProvider.notifier).toggleFollow(artistId);
    }

    return SizedBox(
      width: size?.width,
      height: size?.height ?? 40,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : handleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Icon(leadingIcon, size: 16),
        label: Text(
          buttonText,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
