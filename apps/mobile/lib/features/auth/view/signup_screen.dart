import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/widgets/buttons.dart';
import 'package:mobile/core/widgets/input_field.dart';
import 'package:mobile/features/auth/controller/auth_controller.dart';
import 'package:mobile/features/subscription/helpers/subscription_helpers.dart';
import 'package:mobile/routes/routes.dart';

/// 회원가입 스크린
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  String? _errorMessage;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
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
      Future.microtask(() => setState(() {}));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        centerTitle: true,
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
                  // 헤더 타이틀
                  Text(
                    'Pulse 계정 만들기',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 서브타이틀
                  Text(
                    '다양한 K-POP 팬캠을 저장하고 공유하세요',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

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

                  // 사용자명 입력
                  InputField(
                    controller: _usernameController,
                    label: '닉네임',
                    hint: '사용하실 닉네임을 입력하세요',
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validateUsername,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),

                  const SizedBox(height: 16),

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
                    hint: '비밀번호를 입력하세요 (6자 이상)',
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validatePassword,
                  ),

                  const SizedBox(height: 16),

                  // 비밀번호 확인 입력
                  PasswordField(
                    controller: _confirmPasswordController,
                    label: '비밀번호 확인',
                    hint: '비밀번호를 다시 입력하세요',
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validateConfirmPassword,
                    onSubmitted: (_) => _attemptSignup(),
                  ),

                  const SizedBox(height: 16),

                  // 이용약관 동의
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // 이용약관 페이지로 이동 또는 모달 표시
                            _showTermsDialog(context);
                          },
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyMedium,
                              children: [
                                const TextSpan(
                                  text: '이용약관',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(
                                  text: ' 및 ',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const TextSpan(
                                  text: '개인정보 처리방침',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(
                                  text: '에 동의합니다',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 회원가입 버튼
                  PrimaryButton(
                    text: '회원가입',
                    onPressed: _attemptSignup,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 24),

                  // 로그인 안내
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '이미 계정이 있으신가요?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      TextBtn(
                        text: '로그인',
                        onPressed: () {
                          // 로그인 화면으로 이동
                          context.push(AppRoutes.login);
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

  /// 회원가입 시도
  Future<void> _attemptSignup() async {
    // 폼 검증
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 이용약관 동의 확인
    if (!_acceptTerms) {
      setState(() {
        _errorMessage = '이용약관에 동의해주세요.';
      });
      return;
    }

    // 에러 메시지 초기화
    setState(() {
      _errorMessage = null;
    });

    // 회원가입 실행
    final success = await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _usernameController.text.trim(),
        );

    if (success && mounted) {
      // 회원가입 성공 후 자동 로그인 상태가 되면 구독 화면으로 이동
      SubscriptionHelpers.handleAfterSignup(context, ref);
    }
  }

  /// 사용자명 유효성 검사
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return '닉네임을 입력해주세요';
    }

    if (value.length < 2) {
      return '닉네임은 최소 2자 이상이어야 합니다';
    }

    // 특수문자 제한 (한글, 영문, 숫자만 허용)
    final usernameRegExp = RegExp(r'^[a-zA-Z0-9가-힣]*$');
    if (!usernameRegExp.hasMatch(value)) {
      return '닉네임은 한글, 영문, 숫자만 사용 가능합니다';
    }

    return null;
  }

  /// 이메일 유효성 검사
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }

    // 이메일 형식 검사
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

  /// 비밀번호 확인 유효성 검사
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }

    if (value != _passwordController.text) {
      return '비밀번호가 일치하지 않습니다';
    }

    return null;
  }

  /// 이용약관 다이얼로그 표시
  void _showTermsDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이용약관 및 개인정보 처리방침'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '이용약관',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pulse 서비스 이용약관에 동의합니다. 본 서비스는 K-POP 팬캠 영상의 저장 및 공유를 위한 서비스이며, 콘텐츠의 저작권은 각 콘텐츠 제작자에게 있습니다.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                '개인정보 처리방침',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '회원가입 시 제공하신 이메일 및 닉네임 정보는 서비스 이용을 위해 필요한 최소한의 개인정보로, 안전하게 보호됩니다. 자세한 내용은 개인정보 처리방침을 참고하세요.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _acceptTerms = true;
              });
              Navigator.of(context).pop();
            },
            child: const Text('동의'),
          ),
        ],
      ),
    );
  }

  /// 오류 메시지 파싱
  String _parseErrorMessage(Object? error) {
    if (error == null) {
      return '알 수 없는 오류가 발생했습니다';
    }

    final message = error.toString();

    // Supabase 오류 메시지 파싱
    if (message.contains('already registered')) {
      return '이미 등록된 이메일 주소입니다';
    } else if (message.contains('weak password')) {
      return '비밀번호가 너무 취약합니다. 더 강력한 비밀번호를 사용해주세요';
    } else if (message.contains('network')) {
      return '네트워크 연결을 확인해주세요';
    }

    return message;
  }
}
