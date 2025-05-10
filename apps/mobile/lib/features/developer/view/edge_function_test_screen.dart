import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/core/l10n/app_localizations.dart';

/// Edge Function 테스트 화면
class EdgeFunctionTestScreen extends HookConsumerWidget {
  /// 생성자
  const EdgeFunctionTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isLoading = useState(false);
    final queryController = useTextEditingController(text: 'kpop fancam');
    final limitController = useTextEditingController(text: '5');
    final groupController = useTextEditingController();
    final artistController = useTextEditingController();
    final eventController = useTextEditingController();
    final resultText = useState<String>('');

    // 크롤러 서비스 인스턴스
    final crawlerService = useMemoized(() => CrawlerService(), []);

    // 크롤링 실행 함수
    Future<void> runCrawler() async {
      try {
        isLoading.value = true;
        resultText.value = '크롤링 작업 요청 중...';

        final limit = int.tryParse(limitController.text) ?? 5;
        final group = groupController.text.isEmpty ? null : groupController.text;
        final artist = artistController.text.isEmpty ? null : artistController.text;
        final event = eventController.text.isEmpty ? null : eventController.text;

        final result = await crawlerService.crawlYouTubeVideos(
          query: queryController.text,
          limit: limit,
          groupName: group,
          artist: artist,
          event: event,
        );

        // 결과 표시
        resultText.value = const JsonEncoder.withIndent('  ').convert(result);
      } catch (e) {
        resultText.value = '오류 발생: $e';
      } finally {
        isLoading.value = false;
      }
    }

    // 일일 리포트 생성 함수
    Future<void> generateReport() async {
      try {
        isLoading.value = true;
        resultText.value = '일일 리포트 생성 요청 중...';

        final result = await crawlerService.generateDailyReport();

        // 결과 표시
        resultText.value = const JsonEncoder.withIndent('  ').convert(result);
      } catch (e) {
        resultText.value = '오류 발생: $e';
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edge Function 테스트'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 크롤링 설정 폼
            Text(
              '크롤러 매개변수',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // 검색어 입력
            TextField(
              controller: queryController,
              decoration: const InputDecoration(
                labelText: '검색어 (필수)',
                hintText: 'kpop fancam',
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading.value,
            ),
            const SizedBox(height: 8),

            // 결과 수 제한
            TextField(
              controller: limitController,
              decoration: const InputDecoration(
                labelText: '결과 수 제한',
                hintText: '5',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              enabled: !isLoading.value,
            ),
            const SizedBox(height: 8),

            // 그룹명 입력
            TextField(
              controller: groupController,
              decoration: const InputDecoration(
                labelText: '그룹명 (선택)',
                hintText: 'NewJeans, BLACKPINK 등',
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading.value,
            ),
            const SizedBox(height: 8),

            // 아티스트 입력
            TextField(
              controller: artistController,
              decoration: const InputDecoration(
                labelText: '아티스트 (선택)',
                hintText: '아티스트 이름',
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading.value,
            ),
            const SizedBox(height: 8),

            // 이벤트 입력
            TextField(
              controller: eventController,
              decoration: const InputDecoration(
                labelText: '이벤트 (선택)',
                hintText: '뮤직뱅크, 인기가요 등',
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading.value,
            ),
            const SizedBox(height: 16),

            // 실행 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading.value ? null : runCrawler,
                    child: const Text('크롤링 실행'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading.value ? null : generateReport,
                    child: const Text('일일 리포트 생성'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 결과 표시
            Text(
              '결과',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : SelectableText(
                      resultText.value,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
