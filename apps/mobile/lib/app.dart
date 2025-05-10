import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/app_color.dart';
import 'package:mobile/core/l10n/app_localizations.dart';
import 'package:mobile/features/ads/service/ad_service.dart';
import 'package:mobile/features/subscription/provider/new_subscription_provider.dart';
import 'package:mobile/routes/router.dart';

/// 앱 엔트리 포인트
class App extends ConsumerStatefulWidget {
  /// 생성자
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();

    // 앱 시작 시 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 구독 서비스 초기화 (프로바이더를 읽어서 서비스 인스턴스 생성)
      ref.read(subscriptionServiceProvider);

      // 광고 서비스 초기화
      ref.read(adServiceProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Pulse - 팬캠',
      theme: ThemeData(
        primaryColor: AppColor.primary,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.black,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColor.primary,
          primary: AppColor.primary,
          secondary: AppColor.secondary,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', ''),
        Locale('en', ''),
      ],
      locale: const Locale('ko', ''),
      routerConfig: router,
    );
  }
}
