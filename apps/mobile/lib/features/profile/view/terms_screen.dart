import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/l10n/app_localizations.dart';

/// 이용약관 화면
class TermsScreen extends ConsumerWidget {
  /// 생성자
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile_terms),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profile_terms,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.terms_intro_title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.terms_intro_content,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.terms_definition_title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.terms_definition_content,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.terms_posting_title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.terms_posting_content,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.terms_service_title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '① 회사는 다음과 같은 서비스를 제공합니다.\n'
              ' 1. K-POP 관련 동영상 제공 서비스\n'
              ' 2. 아티스트 정보 및 콘텐츠 제공\n'
              ' 3. 회원 맞춤형 추천 콘텐츠 제공\n'
              ' 4. 기타 회사가 추가 개발하거나 다른 회사와의 제휴계약 등을 통해 이용자에게 제공하는 일체의 서비스\n'
              '② 회사는 필요한 경우 서비스의 내용을 변경할 수 있으며, 이 경우 변경된 서비스의 내용 및 제공일자를 명시하여 현행 서비스 내용과 함께 그 적용일자 7일 이전부터 적용일자 전일까지 공지합니다.',
            ),
            const SizedBox(height: 16),
            Text(
              l10n.terms_membership_title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.terms_membership_content,
            ),
          ],
        ),
      ),
    );
  }
}
