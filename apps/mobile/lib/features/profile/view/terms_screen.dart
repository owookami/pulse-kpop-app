import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 이용약관 화면
class TermsScreen extends ConsumerWidget {
  /// 생성자
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이용약관'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이용약관',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              '제1조 (목적)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '이 약관은 Pulse(이하 "회사"라 합니다)가 제공하는 서비스의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.',
            ),
            const SizedBox(height: 16),
            Text(
              '제2조 (정의)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '① "서비스"란 회사가 제공하는 모든 서비스를 의미합니다.\n'
              '② "이용자"란 회사의 서비스에 접속하여 이 약관에 따라 회사가 제공하는 서비스를 받는 회원 및 비회원을 말합니다.\n'
              '③ "회원"이란 회사에 개인정보를 제공하여 회원등록을 한 자로서, 회사의 정보를 지속적으로 제공받으며, 회사가 제공하는 서비스를 계속적으로 이용할 수 있는 자를 말합니다.\n'
              '④ "비회원"이란 회원으로 가입하지 않고 회사가 제공하는 서비스를 이용하는 자를 말합니다.',
            ),
            const SizedBox(height: 16),
            Text(
              '제3조 (약관의 게시와 개정)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '① 회사는 이 약관의 내용을 이용자가 쉽게 알 수 있도록 서비스 초기 화면에 게시합니다.\n'
              '② 회사는 필요한 경우 관련법에 위배되지 않는 범위 내에서 이 약관을 개정할 수 있습니다.\n'
              '③ 회사가 약관을 개정할 경우에는 적용일자 및 개정사유를 명시하여 현행 약관과 함께 서비스 초기화면에 그 적용일자 7일 이전부터 적용일자 전일까지 공지합니다.',
            ),
            const SizedBox(height: 16),
            Text(
              '제4조 (서비스의 제공 및 변경)',
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
              '제5조 (서비스 이용계약의 성립)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '① 서비스 이용계약은 이용자가 약관의 내용에 대하여 동의를 하고 회사가 정한 가입 양식에 따라 회원정보를 기입한 후 이용신청을 하고, 회사가 이러한 신청에 대하여 승낙함으로써 체결됩니다.\n'
              '② 회사는 다음 각 호에 해당하는 이용신청에 대하여는 승낙을 하지 않을 수 있습니다.\n'
              ' 1. 기술상 서비스 제공이 불가능한 경우\n'
              ' 2. 실명이 아니거나 타인의 명의를 이용한 경우\n'
              ' 3. 허위의 정보를 기재하거나, 회사가 요구하는 내용을 기재하지 않은 경우\n'
              ' 4. 이용자가 만 14세 미만인 경우\n'
              ' 5. 기타 회사가 합리적인 판단에 의하여 필요하다고 인정하는 경우',
            ),
          ],
        ),
      ),
    );
  }
}
