import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// 사용자 건의사항을 입력받고 이메일로 발송하는 화면
class FeedbackScreen extends StatefulWidget {
  /// 생성자
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 이메일 발송 함수
  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final String email = _emailController.text.trim();
    final String subject = _subjectController.text.trim();
    final String content = _contentController.text.trim();

    // 이메일 발송용 URL 생성
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'zanedutainment@gmail.com',
      query: _encodeQueryParameters({
        'subject': '[$subject] 앱 건의사항',
        'body': '보낸 사람: $email\n\n$content',
      }),
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.profile_feedback_email_success)),
          );
          // 메일 앱이 열리면 성공으로 간주하고 이전 화면으로 돌아감
          context.pop();
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.profile_feedback_email_error),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profile_feedback_error(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  /// URL 쿼리 파라미터 인코딩
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.feedback_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                l10n.feedback_question,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.feedback_description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // 이메일 입력 필드
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.feedback_email,
                  hintText: l10n.feedback_email_hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.feedback_email_validation;
                  }
                  // 간단한 이메일 형식 검사
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return l10n.feedback_email_invalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 제목 입력 필드
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: l10n.feedback_subject,
                  hintText: l10n.feedback_subject_hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.feedback_subject_validation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 내용 입력 필드
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: l10n.feedback_content,
                  hintText: l10n.feedback_content_hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.feedback_content_validation;
                  }
                  if (value.length < 10) {
                    return l10n.feedback_content_length;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 발송 버튼
              ElevatedButton.icon(
                onPressed: _isSending ? null : _sendEmail,
                icon: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSending ? l10n.common_sending : l10n.feedback_send),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 개인정보 수집 동의 안내
              Text(
                l10n.feedback_privacy_notice,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
