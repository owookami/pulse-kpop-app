import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/buttons.dart';
import 'package:mobile/core/widgets/input_field.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/routes/routes.dart';

/// 로그인 스크린
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    // 에러 메시지 업데이트
    if (authState.hasError && _errorMessage == null) {
      _errorMessage = _parseErrorMessage(authState.error);
      // UI 업데이트를 예약
      Future.microtask(() {
        if (mounted) {
          setState(() {});
          // 오류 발생 시 스낵바로 표시 (팝업 다이얼로그 대신)
          _showErrorSnackBar(context, _errorMessage!);
        }
      });
    } else if (!authState.hasError && _errorMessage != null) {
      // 오류가 해결된 경우 메시지 초기화
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 뒤로가기 버튼 클릭 시 홈 화면으로 이동
            context.go(AppRoutes.home);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 로고
                  Icon(
                    Icons.play_circle_outline,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),

                  const SizedBox(height: 16),

                  // 앱 이름
                  Text(
                    'Pulse',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 서브타이틀
                  Text(
                    l10n.login_app_subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // 에러 메시지 (있을 경우)
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.error.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.error,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '로그인 오류',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: theme.colorScheme.error,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                },
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 36.0),
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error.withOpacity(0.9),
                              ),
                            ),
                          ),
                          if (_errorMessage!.contains('인증') || _errorMessage!.contains('확인'))
                            Padding(
                              padding: const EdgeInsets.only(left: 36.0, top: 8.0),
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.help_outline, size: 16),
                                label: const Text('이메일 인증 도움말'),
                                onPressed: () {
                                  _showEmailVerificationHelpDialog(
                                      context, _emailController.text.trim());
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                  side: BorderSide(color: theme.colorScheme.error.withOpacity(0.6)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // 이메일 입력
                  InputField(
                    controller: _emailController,
                    label: l10n.login_email,
                    hint: l10n.login_email_hint,
                    keyboardType: TextInputType.emailAddress,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validateEmail,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),

                  const SizedBox(height: 16),

                  // 비밀번호 입력
                  PasswordField(
                    controller: _passwordController,
                    hint: l10n.login_password_hint,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validatePassword,
                    onSubmitted: (_) => _attemptLogin(),
                  ),

                  const SizedBox(height: 8),

                  // 로그인 추가 옵션
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 자동 로그인
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          Text(
                            l10n.login_remember_me,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),

                      // 비밀번호 재설정
                      TextBtn(
                        text: l10n.login_forgot_password,
                        onPressed: () {
                          context.push(AppRoutes.resetPassword);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 로그인 버튼
                  PrimaryButton(
                    text: l10n.login_button,
                    onPressed: _attemptLogin,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 24),

                  // 또는 구분선
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: theme.dividerColor),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.login_or_divider,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: theme.dividerColor),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 회원가입 안내
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.login_signup_prompt,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      TextBtn(
                        text: l10n.login_signup_button,
                        onPressed: () {
                          context.push(AppRoutes.signup);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 로그인 시도
  Future<void> _attemptLogin() async {
    try {
      print('=========== 로그인 시도 시작 ===========');

      // 1. mounted 체크 - 위젯이 이미 해제되었는지 확인
      if (!mounted) {
        print('위젯이 이미 언마운트됨 - 로그인 시도 중단');
        return;
      }

      // 2. 폼 유효성 검사
      if (!(_formKey.currentState?.validate() ?? false)) {
        print('폼 검증 실패');
        return;
      }

      // 3. 에러 메시지 초기화 및 로딩 상태 표시
      setState(() {
        _errorMessage = null;
      });

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print('로그인 시도: $email (폼 검증 완료)');

      // 4. 로딩 상태 표시 (스낵바)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인 중...'),
            duration: Duration(seconds: 1),
          ),
        );
        print('로그인 중 스낵바 표시됨');
      }

      // 5. 로그인 API 호출
      print('authController.signIn 호출 전');
      final authNotifier = ref.read(authControllerProvider.notifier);
      final success = await authNotifier.signIn(
        email: email,
        password: password,
      );
      print('authController.signIn 호출 완료, 결과: $success');

      // 6. 위젯이 여전히 마운트되어 있는지 확인
      if (!mounted) {
        print('위젯이 언마운트됨 - 로그인 결과 처리 불가');
        return;
      }

      // 7. 이전 스낵바 숨기기
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      print('로그인 중 스낵바 숨김');

      // 8. 로그인 결과 확인 - 에러 상태 직접 확인
      final authState = ref.read(authControllerProvider);

      print('로그인 결과 확인 - 오류 있음: ${authState.hasError}, 인증됨: ${authState.isAuthenticated}');

      if (authState.hasError) {
        // 로그인 실패 - 오류 메시지 표시
        print('로그인 실패 - 오류 메시지 표시');

        final errorMsg = _parseErrorMessage(authState.error);
        print('로그인 실패 오류: $errorMsg');

        // 에러 메시지 상단에 표시
        setState(() {
          _errorMessage = errorMsg;
        });

        // 로그인 실패 메시지 표시 (스낵바)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // 이메일 인증 관련 오류인 경우 도움말 대화상자 표시
        if (errorMsg.contains('이메일 인증') ||
            authState.error.toString().contains('Email not confirmed')) {
          print('이메일 인증 필요 - 도움말 표시');
          Future.microtask(() {
            if (mounted) {
              _showEmailVerificationHelpDialog(context, email);
            }
          });
        }

        // 비밀번호 초기화 및 오류 메시지로 스크롤
        _passwordController.clear();
        print('비밀번호 필드 초기화됨');
        _scrollToErrorMessage();
      } else if (authState.isAuthenticated) {
        // 로그인 성공 - 홈 화면으로 이동
        print('로그인 성공 - 성공 메시지 표시');

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인이 성공적으로 완료되었습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        print('홈 화면으로 이동 준비 중 (지연: 1200ms)');
        // 홈 화면으로 이동 (SnackBar를 볼 수 있도록 약간 대기)
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            print('로그인 성공 - 홈 화면으로 이동 시도 (context.go 사용)');
            // 홈 화면으로 직접 이동 (goNamed 대신 go 사용)
            context.go(AppRoutes.home);
            print('context.go 호출 완료');
          } else {
            print('위젯이 이미 해제됨 - 홈 화면 이동 불가');
          }
        });
      } else {
        // 알 수 없는 상태 (로딩 중이거나 예상치 못한 상태)
        print('알 수 없는 상태 - 로그인 화면 유지');

        // 알 수 없는 오류 메시지 표시
        setState(() {
          _errorMessage = '로그인 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // 비밀번호 초기화
        _passwordController.clear();
      }
    } catch (e) {
      // 예외 처리
      print('로그인 과정에서 예외 발생: $e');

      if (mounted) {
        final errorMsg = _parseErrorMessage(e);

        // 에러 메시지 저장
        setState(() {
          _errorMessage = errorMsg;
        });

        // 실패 메시지 표시 (스낵바)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        // 비밀번호 초기화
        _passwordController.clear();

        // 오류 메시지를 포커스하기 위해 스크롤
        _scrollToErrorMessage();
      }
    } finally {
      // 최종 정리
      print('=========== 로그인 시도 종료 ===========');
    }
  }

  /// 오류 메시지로 스크롤하는 메서드
  void _scrollToErrorMessage() {
    // 에러 메시지가 화면에 잘 보이도록 스크롤 조정
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        // SingleChildScrollView를 위한 스크롤 컨트롤러가 없으므로
        // 상단으로 스크롤하는 간단한 방법 사용
        final scrollController = PrimaryScrollController.of(context);
        if (scrollController.hasClients) {
          scrollController.animateTo(
            0, // 상단으로 스크롤
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 의존성이 변경될 때마다 오류 상태를 확인
    final authState = ref.read(authControllerProvider);
    if (authState.hasError && _errorMessage == null) {
      _errorMessage = _parseErrorMessage(authState.error);
      Future.microtask(() {
        if (mounted) {
          setState(() {});

          // 오류 발생 시 스낵바 표시 (다이얼로그 대신)
          _showErrorSnackBar(context, _errorMessage!);
        }
      });
    }
  }

  /// 이메일 유효성 검사
  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context);

    if (value == null || value.isEmpty) {
      return l10n.login_validation_email_required;
    }

    // 간단한 이메일 형식 검사
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegExp.hasMatch(value)) {
      return l10n.login_validation_email_invalid;
    }

    return null;
  }

  /// 비밀번호 유효성 검사
  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);

    if (value == null || value.isEmpty) {
      return l10n.login_validation_password_required;
    }

    if (value.length < 6) {
      return l10n.login_validation_password_length;
    }

    return null;
  }

  /// 오류 메시지 파싱
  String _parseErrorMessage(Object? error) {
    final l10n = AppLocalizations.of(context);

    if (error == null) {
      return l10n.login_error_unknown;
    }

    final message = error.toString();

    // "Exception:" 접두사 제거
    final cleanMessage =
        message.startsWith('Exception:') ? message.substring('Exception:'.length).trim() : message;

    // Supabase 오류 메시지 파싱
    if (cleanMessage.contains('Invalid login credentials') ||
        cleanMessage.contains('invalid_credentials')) {
      return l10n.login_error_invalid_credentials;
    } else if (cleanMessage.contains('Email not confirmed')) {
      // 이메일 인증 필요 메시지를 더 자세하게 수정
      final email = _emailController.text.trim();
      return '이메일 인증이 완료되지 않았습니다. $email로 발송된 인증 메일을 확인하고 인증 링크를 클릭해주세요.';
    } else if (cleanMessage.contains('network') || cleanMessage.contains('timeout')) {
      return l10n.login_error_network;
    } else if (cleanMessage.contains('too many')) {
      return '로그인 시도 횟수가 너무 많습니다. 잠시 후 다시 시도해주세요.';
    }

    return cleanMessage;
  }

  /// 오류 스낵바 표시
  void _showErrorSnackBar(BuildContext context, String errorMessage) {
    print('오류 스낵바 표시: $errorMessage');

    // 이미 스낵바가 표시되고 있는지 확인
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: AppLocalizations.of(context).common_close,
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 이메일 인증 도움말 대화상자 표시
  void _showEmailVerificationHelpDialog(BuildContext context, String email) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.email, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('이메일 인증 안내'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이메일 인증이 필요합니다',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '1. $email로 발송된 인증 메일을 확인해주세요.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '2. 메일에 포함된 인증 링크를 클릭하여 계정을 활성화해주세요.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '3. 인증 완료 후 다시 로그인해주세요.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '인증 메일이 도착하지 않았나요?',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '• 스팸함을 확인해보세요.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              '• 이메일 주소가 올바르게 입력되었는지 확인해보세요.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              '• 잠시 후 다시 시도해보세요.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 회원가입 화면으로 이동하여 다시 시도
              context.push(AppRoutes.signup);
            },
            child: const Text('새로 가입하기'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
