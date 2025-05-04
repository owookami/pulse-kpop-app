import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/routes/router.dart';

/// 앱의 루트 위젯
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  // 뒤로가기 버튼을 마지막으로 누른 시간
  DateTime? _lastBackPressedTime;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: _handlePopInvoked,
      child: MaterialApp.router(
        title: 'Pulse',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // 시스템 설정에 따름
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  // 뒤로가기 버튼 처리 함수
  Future<void> _handlePopInvoked(bool didPop) async {
    if (didPop) {
      return;
    }

    final now = DateTime.now();

    // 마지막으로 뒤로가기를 누른 적이 없거나, 마지막으로 누른 시간에서 2초가 지났으면
    if (_lastBackPressedTime == null ||
        now.difference(_lastBackPressedTime!) > const Duration(seconds: 2)) {
      // 현재 시간 저장
      _lastBackPressedTime = now;

      // 안내 메시지 표시
      Fluttertoast.showToast(
          msg: "앱을 종료하려면 뒤로가기를 한번 더 누르세요",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black87,
          textColor: Colors.white,
          fontSize: 16.0);

      return;
    }

    // 2초 이내에 두 번 누른 경우 앱 종료
    await SystemNavigator.pop();
  }
}
