import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/profile/provider/profile_provider.dart';
import 'package:mobile/features/subscription/provider/subscription_provider.dart';
import 'package:mobile/routes/routes.dart';

/// 프로필 화면
class ProfileScreen extends ConsumerWidget {
  /// 생성자
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 인증 상태 가져오기
    final authState = ref.watch(authControllerProvider);
    final isAuthenticated = authState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 설정 화면으로 이동
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 프로필 정보 새로고침
          await ref.read(profileProvider.notifier).loadProfile();
        },
        child: ListView(
          children: [
            const SizedBox(height: 20),
            // 프로필 헤더
            const _ProfileHeader(),
            const SizedBox(height: 20),

            // 콘텐츠 및 활동 섹션
            isAuthenticated
                ? _buildSection(
                    context,
                    '콘텐츠 및 활동',
                    [
                      MenuItem(
                        icon: Icons.people,
                        title: '팔로우한 아티스트',
                        onTap: () {
                          // 아티스트 목록 화면으로 이동
                          context.push('/profile/artists');
                        },
                      ),
                      MenuItem(
                        icon: Icons.bookmark,
                        title: '저장한 영상',
                        onTap: () {
                          context.go(AppRoutes.bookmarks);
                        },
                      ),
                    ],
                  )
                : const SizedBox(),

            // 계정 관리 섹션
            isAuthenticated
                ? _buildSection(
                    context,
                    '계정 관리',
                    [
                      MenuItem(
                        icon: Icons.person,
                        title: '프로필 편집',
                        onTap: () {
                          // TODO: 프로필 편집 화면으로 이동
                        },
                      ),
                      MenuItem(
                        icon: Icons.notifications,
                        title: '알림 설정',
                        onTap: () {
                          // TODO: 알림 설정 화면으로 이동
                        },
                      ),
                      MenuItem(
                        icon: Icons.feedback,
                        title: '건의하기',
                        subtitle: '앱 개선을 위한 의견 보내기',
                        onTap: () {
                          // 건의하기 화면으로 이동
                          context.push('/profile/feedback');
                        },
                      ),
                      /* MenuItem(
                        icon: Icons.privacy_tip,
                        title: '개인정보 설정',
                        onTap: () {
                          // TODO: 개인정보 설정 화면으로 이동
                        },
                      ), */
                      _buildSubscriptionMenuItem(context),
                      MenuItem(
                        icon: Icons.delete_forever,
                        title: '회원 탈퇴',
                        subtitle: '계정 및 모든 데이터 삭제',
                        badgeColor: Colors.red.shade100,
                        onTap: () {
                          // 회원 탈퇴 화면으로 이동
                          context.push('/profile/deactivate');
                        },
                      ),
                    ],
                  )
                : const SizedBox(),
            _buildSection(
              context,
              '앱 정보',
              [
                MenuItem(
                  icon: Icons.info,
                  title: '앱 정보',
                  onTap: () {
                    // 앱 정보 화면으로 이동
                    context.push('/profile/app-info');
                  },
                ),
                MenuItem(
                  icon: Icons.description,
                  title: '이용약관',
                  onTap: () {
                    // 이용약관 화면으로 이동
                    context.push('/profile/terms');
                  },
                ),
                MenuItem(
                  icon: Icons.privacy_tip,
                  title: '개인정보 처리방침',
                  onTap: () {
                    // 개인정보 처리방침 화면으로 이동
                    context.push('/profile/privacy');
                  },
                ),
                MenuItem(
                  icon: Icons.feedback,
                  title: '건의하기',
                  subtitle: '앱 개선을 위한 의견 보내기',
                  onTap: () {
                    // 건의하기 화면으로 이동
                    context.push('/profile/feedback');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child:
                  isAuthenticated ? _buildLogoutButton(context, ref) : _buildLoginButton(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 로그아웃 버튼 위젯
  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () async {
        // 로그아웃 확인 다이얼로그
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('로그아웃'),
            content: const Text('정말 로그아웃 하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('로그아웃'),
              ),
            ],
          ),
        );

        if (shouldLogout == true) {
          // 로그아웃 실행
          await ref.read(authControllerProvider.notifier).signOut();
          if (context.mounted) {
            context.go(AppRoutes.login);
          }
        }
      },
      icon: const Icon(Icons.logout),
      label: const Text('로그아웃'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade100,
        foregroundColor: Colors.red.shade800,
      ),
    );
  }

  // 로그인 버튼 위젯
  Widget _buildLoginButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // 로그인 화면으로 이동
        context.go(AppRoutes.login);
      },
      icon: const Icon(Icons.login),
      label: const Text('로그인'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade100,
        foregroundColor: Colors.blue.shade800,
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const Divider(),
        ...items,
        const Divider(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubscriptionMenuItem(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isActive = ref.watch(subscriptionProvider).isActive;
        return MenuItem(
          icon: Icons.workspace_premium,
          title: '구독 관리',
          subtitle: isActive ? '프리미엄 멤버십 이용 중' : '프리미엄으로 업그레이드',
          badgeColor: isActive ? Colors.amber.shade200 : null,
          onTap: () {
            // 구독 관리 화면으로 이동
            context.push(AppRoutes.subscription);
          },
        );
      },
    );
  }
}

/// 프로필 헤더 위젯
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final authState = ref.watch(authControllerProvider);
    final isAuthenticated = authState.isAuthenticated;

    if (!isAuthenticated) {
      // 로그인하지 않은 상태일 때 표시할 내용
      return Column(
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          Text(
            '로그인이 필요합니다',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '로그인하시면 프로필 정보와 활동 내역을 확인하실 수 있습니다.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    }

    return Column(
      children: [
        // 프로필 이미지
        if (profileState.isLoading)
          const CircleAvatar(
            radius: 50,
            child: CircularProgressIndicator(),
          )
        else if (profileState.avatarUrl != null)
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(
              profileState.avatarUrl!,
            ),
            onBackgroundImageError: (_, __) {
              // 이미지 로드 실패 - 이 콜백은 void 반환이므로 아무 작업도 하지 않음
              print('프로필 이미지 로드 실패: ${profileState.avatarUrl}');
            },
            child: profileState.avatarUrl == null ? const Icon(Icons.person, size: 50) : null,
          )
        else
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),

        const SizedBox(height: 16),

        // 사용자 이름
        Text(
          profileState.username.isEmpty ? '사용자' : profileState.username,
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 4),

        // 이메일
        Text(
          profileState.email.isEmpty ? '로그인이 필요합니다' : profileState.email,
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        // 자기소개가 있는 경우 표시
        if (profileState.bio != null && profileState.bio!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              profileState.bio!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],

        const SizedBox(height: 20),

        // 기본 정보 요약
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStat(context, '${profileState.bookmarksCount}', '북마크'),
            _buildStat(context, '${profileState.likesCount}', '좋아요'),
            _buildStat(context, '${profileState.commentsCount}', '댓글'),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// 메뉴 아이템 위젯
class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badgeColor,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final Color? badgeColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ??
          (badgeColor != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '활성',
                    style: TextStyle(fontSize: 12),
                  ),
                )
              : const Icon(Icons.chevron_right)),
      onTap: onTap,
    );
  }
}
