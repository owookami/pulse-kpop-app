import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 정보'),
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
              '버전 ${_packageInfo.version} (빌드 ${_packageInfo.buildNumber})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 32),

          // 앱 정보 섹션
          _buildInfoSection(
            context: context,
            title: '앱 소개',
            content: 'Pulse는 K-POP 아티스트의 팬캠 영상을 모아보고 공유할 수 있는 플랫폼입니다. '
                '좋아하는 아티스트의 영상을 쉽게 찾고, 저장하고, 평가할 수 있습니다.',
          ),
          const SizedBox(height: 16),

          // 개발사 정보
          _buildInfoSection(
            context: context,
            title: '개발사 정보',
            content: '© 2023 Pulse Team\n모든 권리 보유',
          ),
          const SizedBox(height: 16),

          // 기술적 정보
          _buildInfoSection(
            context: context,
            title: '기술 정보',
            content: '이 앱은 Flutter 프레임워크로 개발되었으며, Supabase를 백엔드로 사용합니다.',
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
    return [
      const Divider(),
      ListTile(
        leading: const Icon(Icons.library_books),
        title: const Text('오픈소스 라이선스'),
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
        title: const Text('개인정보 처리방침'),
        onTap: () {
          context.push('/profile/privacy');
        },
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.description),
        title: const Text('이용약관'),
        onTap: () {
          context.push('/profile/terms');
        },
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.feedback),
        title: const Text('건의하기'),
        subtitle: const Text('앱 개선을 위한 의견 보내기'),
        onTap: () {
          context.push('/profile/feedback');
        },
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.contact_support),
        title: const Text('고객 지원'),
        onTap: () {
          // TODO: 고객 지원 화면으로 이동
        },
      ),
    ];
  }
}
