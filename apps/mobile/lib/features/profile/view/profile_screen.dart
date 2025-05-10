import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/profile/provider/profile_provider.dart';
import 'package:mobile/features/subscription/provider/new_subscription_provider.dart';
import 'package:mobile/routes/routes.dart';

/// 프로필 화면
class ProfileScreen extends ConsumerWidget {
  /// 생성자
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 국제화 텍스트 가져오기
    final l10n = AppLocalizations.of(context);

    // 인증 상태 가져오기
    final authState = ref.watch(authControllerProvider);
    final isAuthenticated = authState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile_title),
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
                    l10n.profile_content_activity,
                    [
                      // MenuItem(
                      //   icon: Icons.people,
                      //   title: l10n.profile_followed_artists,
                      //   onTap: () {
                      //     // 아티스트 목록 화면으로 이동
                      //     context.push('/profile/artists');
                      //   },
                      // ),
                      MenuItem(
                        icon: Icons.bookmark,
                        title: l10n.profile_saved_videos,
                        onTap: () {
                          context.go(AppRoutes.bookmarks);
                        },
                      ),
                    ],
                  )
                : const SizedBox(),

            // 구독 섹션 (로그인 여부와 상관없이 표시)
            _buildSection(
              context,
              l10n.subscription_benefits_title,
              [
                _buildSubscriptionMenuItem(context),
                MenuItem(
                  icon: Icons.star,
                  title: l10n.premium_features,
                  subtitle: l10n.premium_banner_description,
                  badgeColor: Colors.amber.shade100,
                  onTap: () {
                    // 프리미엄 혜택 소개 화면으로 이동
                    context.push(AppRoutes.subscriptionBenefits);
                  },
                ),
              ],
            ),

            // 계정 관리 섹션
            isAuthenticated
                ? _buildSection(
                    context,
                    l10n.profile_account_management,
                    [
                      MenuItem(
                        icon: Icons.person,
                        title: l10n.profile_edit_profile,
                        onTap: () {
                          // TODO: 프로필 편집 화면으로 이동
                        },
                      ),
                      // MenuItem(
                      //   icon: Icons.notifications,
                      //   title: l10n.profile_notification_settings,
                      //   onTap: () {
                      //     // TODO: 알림 설정 화면으로 이동
                      //   },
                      // ),
                      MenuItem(
                        icon: Icons.feedback,
                        title: l10n.profile_feedback,
                        subtitle: l10n.profile_feedback_subtitle,
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
                      MenuItem(
                        icon: Icons.delete_forever,
                        title: l10n.deactivate_title,
                        subtitle: l10n.profile_deactivate_subtitle,
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
              l10n.profile_app_info,
              [
                MenuItem(
                  icon: Icons.info,
                  title: l10n.profile_app_info_title,
                  onTap: () {
                    // 앱 정보 화면으로 이동
                    context.push('/profile/app-info');
                  },
                ),
                MenuItem(
                  icon: Icons.language,
                  title: l10n.language_settings,
                  onTap: () {
                    // 언어 설정 화면으로 이동
                    context.push('/profile/language');
                  },
                ),
                MenuItem(
                  icon: Icons.description,
                  title: l10n.profile_terms,
                  onTap: () {
                    // 이용약관 화면으로 이동
                    context.push('/profile/terms');
                  },
                ),
                MenuItem(
                  icon: Icons.privacy_tip,
                  title: l10n.profile_privacy_policy,
                  onTap: () {
                    // 개인정보 처리방침 화면으로 이동
                    context.push('/profile/privacy');
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
    final l10n = AppLocalizations.of(context);

    return ElevatedButton.icon(
      onPressed: () async {
        // 로그아웃 확인 다이얼로그
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.login_logout),
            content: Text(l10n.login_logout_confirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.common_cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.login_logout),
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
      label: Text(l10n.login_logout),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.red,
        backgroundColor: Colors.red.shade50,
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  // 로그인 버튼 위젯
  Widget _buildLoginButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ElevatedButton.icon(
      onPressed: () {
        context.go(AppRoutes.login);
      },
      icon: const Icon(Icons.login),
      label: Text(l10n.login_button),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
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
        final l10n = AppLocalizations.of(context);
        final authState = ref.watch(authControllerProvider);
        final isAuthenticated = authState.isAuthenticated;

        // 로그인 상태에 따라 다른 텍스트 표시
        String subtitle;
        Color? badgeColor;

        if (isAuthenticated) {
          // 로그인 상태에서는 프리미엄 여부 확인
          final isActive = ref.watch(isPremiumUserProvider).maybeWhen(
                data: (value) => value,
                orElse: () => false,
              );
          subtitle = isActive ? l10n.profile_premium_active : l10n.profile_premium_upgrade;
          badgeColor = isActive ? Colors.amber.shade200 : null;
        } else {
          // 비로그인 상태에서는 구독 안내 메시지
          subtitle = l10n.subscription_signup_required;
          badgeColor = null;
        }

        return MenuItem(
          icon: Icons.workspace_premium,
          title: l10n.profile_subscription,
          subtitle: subtitle,
          badgeColor: badgeColor,
          onTap: () {
            // 비로그인 상태에서는 로그인 화면으로 먼저 이동
            if (!isAuthenticated) {
              // 로그인 안내 다이얼로그 표시
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.subscription_signup_required),
                  content: Text(l10n.subscription_limit_message_guest),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.common_cancel),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go(AppRoutes.login);
                      },
                      child: Text(l10n.subscription_signup),
                    ),
                  ],
                ),
              );
            } else {
              // 로그인 상태에서는 바로 구독 상품 화면으로 이동
              context.push(AppRoutes.subscriptionPlans);
            }
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
    final l10n = AppLocalizations.of(context);

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
            l10n.profile_login_required,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.profile_login_description,
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
          profileState.username.isEmpty ? l10n.profile_username_default : profileState.username,
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 4),

        // 이메일
        Text(
          profileState.email.isEmpty ? l10n.profile_email_login_required : profileState.email,
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
            //_buildStat(context, '${profileState.commentsCount}', '댓글'),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String count, String label) {
    final l10n = AppLocalizations.of(context);
    String translatedLabel;

    switch (label) {
      case '북마크':
        translatedLabel = l10n.profile_stat_bookmarks;
        break;
      case '좋아요':
        translatedLabel = l10n.profile_stat_likes;
        break;
      case '댓글':
        translatedLabel = l10n.profile_stat_comments;
        break;
      default:
        translatedLabel = label;
    }

    return Column(
      children: [
        Text(
          count,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          translatedLabel,
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
    final l10n = AppLocalizations.of(context);

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
                  child: Text(
                    l10n.profile_badge_active,
                    style: const TextStyle(fontSize: 12),
                  ),
                )
              : const Icon(Icons.chevron_right)),
      onTap: onTap,
    );
  }
}
