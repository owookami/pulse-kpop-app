import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 앱 정보 화면
class AppInfoScreen extends ConsumerStatefulWidget {
  /// 생성자
  const AppInfoScreen({super.key});

  @override
  ConsumerState<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends ConsumerState<AppInfoScreen> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Pulse',
    packageName: '알 수 없음',
    version: '알 수 없음',
    buildNumber: '알 수 없음',
    buildSignature: '',
    installerStore: '',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile_app_info_title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 앱 아이콘
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.music_note,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 앱 이름과 버전
          Center(
            child: Text(
              _packageInfo.appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.app_info_version(_packageInfo.version, _packageInfo.buildNumber),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 32),

          // 앱 정보 섹션
          _buildInfoSection(
            context: context,
            title: l10n.app_info_introduction,
            content: l10n.app_info_introduction_content,
          ),
          const SizedBox(height: 16),

          // 개발사 정보
          _buildInfoSection(
            context: context,
            title: l10n.app_info_developer,
            content: l10n.app_info_developer_content,
          ),
          const SizedBox(height: 16),

          // 기술적 정보
          _buildInfoSection(
            context: context,
            title: l10n.app_info_technical,
            content: l10n.app_info_technical_content,
          ),
          const SizedBox(height: 16),

          // 추가 링크
          ..._buildInfoLinks(context),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  List<Widget> _buildInfoLinks(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return [
      const Divider(),
      ListTile(
        leading: const Icon(Icons.library_books),
        title: Text(l10n.app_info_opensource),
        onTap: () {
          showLicensePage(
            context: context,
            applicationName: _packageInfo.appName,
            applicationVersion: _packageInfo.version,
            applicationLegalese: '© 2023 Pulse Team',
          );
        },
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.policy),
        title: Text(l10n.profile_privacy_policy),
        onTap: () {
          context.push('/profile/privacy');
        },
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.description),
        title: Text(l10n.profile_terms),
        onTap: () {
          context.push('/profile/terms');
        },
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.contact_support),
        title: Text(l10n.app_info_customer_support),
        onTap: () {
          // TODO: 고객 지원 화면으로 이동
        },
      ),
    ];
  }
}
