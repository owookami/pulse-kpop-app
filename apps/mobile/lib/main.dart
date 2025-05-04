import 'package:api_client/api_client.dart' as api_client;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app.dart';

/// SharedPreferences 제공자
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider는 메인에서 초기화해야 합니다');
});

/// 앱의 시작점
void main() async {
  // 위젯 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 로드
  await dotenv.load();

  // SharedPreferences 초기화
  final sharedPreferences = await SharedPreferences.getInstance();

  // Supabase 초기화
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // 앱 시작
  runApp(
    ProviderScope(
      overrides: [
        // 앱의 SharedPreferences 제공자 초기화
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        // api_client 패키지의 SharedPreferences 제공자도 초기화
        api_client.sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}
