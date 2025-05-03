import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/routes/routes.dart';

/// 프로필 화면
class ProfileScreen extends ConsumerWidget {
  /// 생성자
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: ListView(
        children: [
          const SizedBox(height: 20),
          // 프로필 헤더
          const _ProfileHeader(),
          const SizedBox(height: 20),

          // 콘텐츠 및 활동 섹션
          _buildSection(
            context,
            '콘텐츠 및 활동',
            [
              _MenuItem(
                icon: Icons.people,
                title: '팔로우한 아티스트',
                onTap: () {
                  // 아티스트 목록 화면으로 이동
                  context.push('/profile/artists');
                },
              ),
              _MenuItem(
                icon: Icons.bookmark,
                title: '저장한 영상',
                onTap: () {
                  context.go(AppRoutes.bookmarks);
                },
              ),
              _MenuItem(
                icon: Icons.history,
                title: '시청 기록',
                onTap: () {
                  // TODO: 시청 기록 화면으로 이동
                },
              ),
            ],
          ),

          // 계정 관리 섹션
          _buildSection(
            context,
            '계정 관리',
            [
              _MenuItem(
                icon: Icons.person,
                title: '프로필 편집',
                onTap: () {
                  // TODO: 프로필 편집 화면으로 이동
                },
              ),
              _MenuItem(
                icon: Icons.notifications,
                title: '알림 설정',
                onTap: () {
                  // TODO: 알림 설정 화면으로 이동
                },
              ),
              _MenuItem(
                icon: Icons.privacy_tip,
                title: '개인정보 설정',
                onTap: () {
                  // TODO: 개인정보 설정 화면으로 이동
                },
              ),
            ],
          ),
          _buildSection(
            context,
            '앱 정보',
            [
              _MenuItem(
                icon: Icons.info,
                title: '앱 정보',
                onTap: () {
                  // TODO: 앱 정보 화면으로 이동
                },
              ),
              _MenuItem(
                icon: Icons.help,
                title: '고객 지원',
                onTap: () {
                  // TODO: 고객 지원 화면으로 이동
                },
              ),
              _MenuItem(
                icon: Icons.policy,
                title: '이용약관 및 개인정보 처리방침',
                onTap: () {
                  // TODO: 약관 화면으로 이동
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
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
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<_MenuItem> items,
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
        ...items.map((item) => _buildMenuItem(item)).toList(),
        const Divider(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return ListTile(
      leading: Icon(item.icon),
      title: Text(item.title),
      trailing: const Icon(Icons.chevron_right),
      onTap: item.onTap,
    );
  }
}

/// 프로필 헤더 위젯
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(
            'https://via.placeholder.com/150',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '사용자 이름',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'user@example.com',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        // 기본 정보 요약
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStat(context, '0', '북마크'),
            _buildStat(context, '0', '좋아요'),
            _buildStat(context, '0', '댓글'),
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

/// 메뉴 아이템 모델
class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
