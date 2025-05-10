import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/routes/routes.dart';

/// 회원 탈퇴 화면
class DeactivateAccountScreen extends ConsumerStatefulWidget {
  /// 생성자
  const DeactivateAccountScreen({super.key});

  @override
  ConsumerState<DeactivateAccountScreen> createState() => _DeactivateAccountScreenState();
}

class _DeactivateAccountScreenState extends ConsumerState<DeactivateAccountScreen> {
  bool _isConfirmed = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deactivate_title),
        backgroundColor: Colors.red.shade50,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.deactivate_warning,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.deactivate_warning_message,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildBulletPoint(l10n.deactivate_warning_profile),
                    _buildBulletPoint(l10n.deactivate_warning_bookmarks),
                    _buildBulletPoint(l10n.deactivate_warning_activity),
                    _buildBulletPoint(l10n.deactivate_warning_artists),
                    _buildBulletPoint(l10n.deactivate_warning_subscription),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _isConfirmed,
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _isConfirmed = value ?? false;
                          });
                        },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isConfirmed = !_isConfirmed;
                            });
                          },
                    child: Text(l10n.deactivate_confirm_checkbox),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || !_isConfirmed ? null : _confirmDeactivation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.deactivate_button),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: Text(l10n.deactivate_cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivation() async {
    final l10n = AppLocalizations.of(context);

    // 최종 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deactivate_confirm_title),
        content: Text(l10n.deactivate_confirm_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 회원 탈퇴 실행
      final success = await ref.read(authControllerProvider.notifier).deleteAccount();

      if (!mounted) return;

      if (success) {
        // 탈퇴 성공
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(l10n.deactivate_success_title),
            content: Text(l10n.deactivate_success_message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.common_confirm),
              ),
            ],
          ),
        );

        if (mounted && result == true) {
          // 로그인 화면으로 이동
          context.go(AppRoutes.login);
        }
      } else {
        // 탈퇴 실패
        setState(() {
          _isLoading = false;
          _errorMessage = '계정 삭제 중 오류가 발생했습니다. 나중에 다시 시도해주세요.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '오류: $e';
        });
      }
    }
  }
}
