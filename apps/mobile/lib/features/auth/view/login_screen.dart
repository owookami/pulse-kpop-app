import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    // 에러 메시지 업데이트
    if (authState.hasError && _errorMessage == null) {
      _errorMessage = _parseErrorMessage(authState.error);
      // UI 업데이트를 예약
      Future.microtask(() => setState(() {}));
    }

    return Scaffold(
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
                    '즐겨찾는 K-POP 팬캠을 한곳에서',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // 에러 메시지 (있을 경우)
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: theme.colorScheme.error,
                              size: 16,
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
                    ),

                  // 이메일 입력
                  InputField(
                    controller: _emailController,
                    label: '이메일',
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validateEmail,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),

                  const SizedBox(height: 16),

                  // 비밀번호 입력
                  PasswordField(
                    controller: _passwordController,
                    hint: '비밀번호를 입력하세요',
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
                            '자동 로그인',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),

                      // 비밀번호 재설정
                      TextBtn(
                        text: '비밀번호 찾기',
                        onPressed: () {
                          context.push(AppRoutes.resetPassword);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 로그인 버튼
                  PrimaryButton(
                    text: '로그인',
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
                          '또는',
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
                        '계정이 없으신가요?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      TextBtn(
                        text: '회원가입',
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
  void _attemptLogin() {
    // 에러 메시지 초기화
    setState(() {
      _errorMessage = null;
    });

    // 폼 유효성 검사
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // 로그인 실행
      ref.read(authControllerProvider.notifier).signIn(
            email: email,
            password: password,
          );
    }
  }

  /// 이메일 유효성 검사
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }

    // 간단한 이메일 형식 검사
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegExp.hasMatch(value)) {
      return '유효한 이메일 주소를 입력해주세요';
    }

    return null;
  }

  /// 비밀번호 유효성 검사
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }

    if (value.length < 6) {
      return '비밀번호는 최소 6자 이상이어야 합니다';
    }

    return null;
  }

  /// 오류 메시지 파싱
  String _parseErrorMessage(Object? error) {
    if (error == null) {
      return '알 수 없는 오류가 발생했습니다';
    }

    final message = error.toString();

    // Supabase 오류 메시지 파싱
    if (message.contains('Invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다';
    } else if (message.contains('Email not confirmed')) {
      return '이메일 인증이 필요합니다. 이메일을 확인해주세요';
    } else if (message.contains('network')) {
      return '네트워크 연결을 확인해주세요';
    }

    return message;
  }
}
