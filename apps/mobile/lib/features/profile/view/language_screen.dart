import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 언어 설정 화면
class LanguageScreen extends ConsumerWidget {
  /// 생성자
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language_settings),
      ),
      body: ListView(
        children: [
          _buildLanguageOption(
            context,
            ref,
            '한국어',
            'ko',
            currentLocale.languageCode == 'ko',
          ),
          _buildLanguageOption(
            context,
            ref,
            'English',
            'en',
            currentLocale.languageCode == 'en',
          ),
          _buildLanguageOption(
            context,
            ref,
            'Español',
            'es',
            currentLocale.languageCode == 'es',
          ),
          _buildLanguageOption(
            context,
            ref,
            'Português',
            'pt',
            currentLocale.languageCode == 'pt',
          ),
          _buildLanguageOption(
            context,
            ref,
            '中文',
            'zh',
            currentLocale.languageCode == 'zh',
          ),
          _buildLanguageOption(
            context,
            ref,
            'Bahasa Indonesia',
            'id',
            currentLocale.languageCode == 'id',
          ),
          _buildLanguageOption(
            context,
            ref,
            'Tiếng Việt',
            'vi',
            currentLocale.languageCode == 'vi',
          ),
          _buildLanguageOption(
            context,
            ref,
            'Deutsch',
            'de',
            currentLocale.languageCode == 'de',
          ),
          _buildLanguageOption(
            context,
            ref,
            'Français',
            'fr',
            currentLocale.languageCode == 'fr',
          ),
          _buildLanguageOption(
            context,
            ref,
            'ไทย',
            'th',
            currentLocale.languageCode == 'th',
          ),
          _buildLanguageOption(
            context,
            ref,
            'Bahasa Melayu',
            'ms',
            currentLocale.languageCode == 'ms',
          ),
          _buildLanguageOption(
            context,
            ref,
            '日本語',
            'ja',
            currentLocale.languageCode == 'ja',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    String title,
    String languageCode,
    bool isSelected,
  ) {
    return ListTile(
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () async {
        // 언어 설정 변경
        final newLocale = Locale(languageCode);
        ref.read(localeProvider.notifier).state = newLocale;

        // 설정 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_locale', languageCode);
      },
    );
  }
}
