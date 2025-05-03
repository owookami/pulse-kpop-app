import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/routes.dart';
import '../provider/feed_provider.dart';

/// FeedVideosNotifier에 네비게이션 기능을 확장하는 클래스
extension FeedProviderExtensions on FeedVideosNotifier {
  /// 비디오 플레이어 화면으로 이동
  void navigateToVideoPlayer(BuildContext context, Video video) {
    context.pushNamed(
      AppRoutes.videoPlayer,
      extra: video,
    );
  }
}
