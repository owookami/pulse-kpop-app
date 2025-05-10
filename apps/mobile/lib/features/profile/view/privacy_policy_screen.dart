import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/l10n/app_localizations.dart';

/// 개인정보 처리방침 화면
class PrivacyPolicyScreen extends ConsumerWidget {
  /// 생성자
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile_privacy_policy),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profile_privacy_policy,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacy_intro,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacy_purpose_title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.privacy_purpose_content,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacy_retention_title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.privacy_retention_content,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacy_thirdparty_title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.privacy_thirdparty_content,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacy_rights_title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.privacy_rights_content,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacy_security_title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.privacy_security_content,
            ),
          ],
        ),
      ),
    );
  }
}
