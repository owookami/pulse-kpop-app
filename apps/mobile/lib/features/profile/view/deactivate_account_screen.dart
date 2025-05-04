import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 탈퇴'),
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
                    const Text(
                      '⚠️ 주의',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '회원 탈퇴 시 다음 정보가 모두 삭제되며 복구할 수 없습니다:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildBulletPoint('프로필 정보'),
                    _buildBulletPoint('북마크한 영상'),
                    _buildBulletPoint('좋아요 및 댓글 기록'),
                    _buildBulletPoint('팔로우한 아티스트 정보'),
                    _buildBulletPoint('구독 정보 (유료 구독 중인 경우 별도 해지 필요)'),
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
                    child: const Text(
                      '위 내용을 모두 이해했으며, 계정을 삭제하는 데 동의합니다.',
                    ),
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
                    : const Text('회원 탈퇴 진행'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: const Text('취소'),
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
    // 최종 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('최종 확인'),
        content: const Text('계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다. 정말 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
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
            title: const Text('탈퇴 완료'),
            content: const Text('계정이 성공적으로 삭제되었습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('확인'),
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
