import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/l10n/translations/de_translations.dart';
import 'package:mobile/core/l10n/translations/en_translations.dart';
import 'package:mobile/core/l10n/translations/es_translations.dart';
import 'package:mobile/core/l10n/translations/fr_translations.dart';
import 'package:mobile/core/l10n/translations/id_translations.dart';
import 'package:mobile/core/l10n/translations/ja_translations.dart';
import 'package:mobile/core/l10n/translations/ko_translations.dart';
import 'package:mobile/core/l10n/translations/ms_translations.dart';
import 'package:mobile/core/l10n/translations/pt_translations.dart';
import 'package:mobile/core/l10n/translations/th_translations.dart';
import 'package:mobile/core/l10n/translations/vi_translations.dart';
import 'package:mobile/core/l10n/translations/zh_translations.dart';

/// Material widgets 국제화를 위한 위임자
class GlobalMaterialLocalizations extends LocalizationsDelegate<MaterialLocalizations> {
  const GlobalMaterialLocalizations();

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      GlobalMaterialLocalizations();

  @override
  bool isSupported(Locale locale) => [
        'ko',
        'en',
        'es',
        'pt',
        'zh',
        'id',
        'vi',
        'de',
        'fr',
        'th',
        'ms',
        'ja',
      ].contains(locale.languageCode);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      Future.value(const DefaultMaterialLocalizations());

  @override
  bool shouldReload(GlobalMaterialLocalizations old) => false;
}

/// 한국어 Material 국제화 구현
class _KoreanMaterialLocalizations extends DefaultMaterialLocalizations {
  const _KoreanMaterialLocalizations();

  @override
  String get closeButtonLabel => '닫기';

  @override
  String get okButtonLabel => '확인';

  @override
  String get cancelButtonLabel => '취소';

  @override
  String get continueButtonLabel => '계속';
}

/// 스페인어 Material 국제화 구현
class _SpanishMaterialLocalizations extends DefaultMaterialLocalizations {
  const _SpanishMaterialLocalizations();

  @override
  String get closeButtonLabel => 'Cerrar';

  @override
  String get okButtonLabel => 'Aceptar';

  @override
  String get cancelButtonLabel => 'Cancelar';

  @override
  String get continueButtonLabel => 'Continuar';
}

/// 포르투갈어 Material 국제화 구현
class _PortugueseMaterialLocalizations extends DefaultMaterialLocalizations {
  const _PortugueseMaterialLocalizations();

  @override
  String get closeButtonLabel => 'Fechar';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get cancelButtonLabel => 'Cancelar';

  @override
  String get continueButtonLabel => 'Continuar';
}

/// 영어 Material 국제화 구현
class _EnglishMaterialLocalizations extends DefaultMaterialLocalizations {
  const _EnglishMaterialLocalizations();
}

/// 동기 Future 구현 - Future를 확장하지 않고 구현
class MySynchronousFuture<T> implements Future<T> {
  final T _value;

  MySynchronousFuture(this._value);

  @override
  Stream<T> asStream() {
    return Stream<T>.fromIterable([_value]);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) {
    try {
      final result = onValue(_value);
      if (result is Future<R>) {
        return result;
      }
      return MySynchronousFuture<R>(result);
    } catch (e, stack) {
      if (onError != null) {
        if (onError is Function(Object, StackTrace)) {
          final result = onError(e, stack);
          if (result is Future<R>) {
            return result;
          }
          return MySynchronousFuture<R>(result as R);
        } else if (onError is Function(Object)) {
          final result = onError(e);
          if (result is Future<R>) {
            return result;
          }
          return MySynchronousFuture<R>(result as R);
        }
        throw ArgumentError(
            'onError callback must take either Object or both Object and StackTrace as arguments.');
      }
      return Future<R>.error(e, stack);
    }
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return then<T>((T value) => value, onError: onError);
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
    return this; // 동기식이므로 타임아웃이 발생하지 않음
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    try {
      final result = action();
      if (result is Future) {
        return result.then((_) => _value);
      }
      return this;
    } catch (e, stack) {
      return Future<T>.error(e, stack);
    }
  }
}

/// Cupertino widgets 국제화를 위한 위임자
class GlobalCupertinoLocalizations extends LocalizationsDelegate<CupertinoLocalizations> {
  const GlobalCupertinoLocalizations();

  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      GlobalCupertinoLocalizations();

  @override
  bool isSupported(Locale locale) => [
        'ko',
        'en',
        'es',
        'pt',
        'zh',
        'id',
        'vi',
        'de',
        'fr',
        'th',
        'ms',
        'ja',
      ].contains(locale.languageCode);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      Future.value(const DefaultCupertinoLocalizations());

  @override
  bool shouldReload(GlobalCupertinoLocalizations old) => false;
}

/// 한국어 Cupertino 국제화 구현
class _KoreanCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const _KoreanCupertinoLocalizations();

  @override
  String get alertDialogLabel => '알림';

  @override
  String get copyButtonLabel => '복사';

  @override
  String get cutButtonLabel => '잘라내기';

  @override
  String get okButtonLabel => '확인';

  @override
  String get pasteButtonLabel => '붙여넣기';

  @override
  String get selectAllButtonLabel => '전체 선택';

  @override
  String get todayLabel => '오늘';

  @override
  String get modalBarrierDismissLabel => '닫기';

  // 기본 Cupertino 로컬라이제이션 중 한국어로 변경이 필요한 항목들만 오버라이드
  @override
  String datePickerYear(int yearIndex) => '$yearIndex년';

  @override
  String datePickerMonth(int monthIndex) {
    return const <String>[
      '1월',
      '2월',
      '3월',
      '4월',
      '5월',
      '6월',
      '7월',
      '8월',
      '9월',
      '10월',
      '11월',
      '12월'
    ][monthIndex - 1];
  }

  @override
  String datePickerDayOfMonth(int dayIndex, [int? weekDay]) => '$dayIndex일';

  @override
  String datePickerHour(int hour) => '$hour시';

  @override
  String datePickerHourSemantic(int hour) => '$hour시';

  @override
  String datePickerMinute(int minute) => '$minute분';

  @override
  String datePickerMinuteSemantic(int minute) => '$minute분';

  @override
  String datePickerMediumDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  @override
  DatePickerDateOrder get datePickerDateOrder => DatePickerDateOrder.ymd;

  @override
  DatePickerDateTimeOrder get datePickerDateTimeOrder =>
      DatePickerDateTimeOrder.date_time_dayPeriod;

  @override
  String get anteMeridiemAbbreviation => '오전';

  @override
  String get postMeridiemAbbreviation => '오후';

  @override
  String timerPickerHour(int hour) => '$hour시';

  @override
  String timerPickerMinute(int minute) => '$minute분';

  @override
  String timerPickerSecond(int second) => '$second초';

  @override
  String timerPickerHourLabel(int hour) => '시간';

  @override
  String timerPickerMinuteLabel(int minute) => '분';

  @override
  String timerPickerSecondLabel(int second) => '초';

  @override
  String get searchTextFieldPlaceholderLabel => '검색';
}

/// 스페인어 Cupertino 국제화 구현
class _SpanishCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const _SpanishCupertinoLocalizations();

  @override
  String get alertDialogLabel => 'Alerta';

  @override
  String get copyButtonLabel => 'Copiar';

  @override
  String get cutButtonLabel => 'Cortar';

  @override
  String get okButtonLabel => 'Aceptar';

  @override
  String get pasteButtonLabel => 'Pegar';

  @override
  String get selectAllButtonLabel => 'Seleccionar todo';

  @override
  String get todayLabel => 'Hoy';

  @override
  String get modalBarrierDismissLabel => 'Cerrar';
}

/// 포르투갈어 Cupertino 국제화 구현
class _PortugueseCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const _PortugueseCupertinoLocalizations();

  @override
  String get alertDialogLabel => 'Alerta';

  @override
  String get copyButtonLabel => 'Copiar';

  @override
  String get cutButtonLabel => 'Cortar';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get pasteButtonLabel => 'Colar';

  @override
  String get selectAllButtonLabel => 'Selecionar tudo';

  @override
  String get todayLabel => 'Hoje';

  @override
  String get modalBarrierDismissLabel => 'Fechar';
}

/// 기본 Flutter widgets 국제화를 위한 위임자
class GlobalWidgetsLocalizations extends LocalizationsDelegate<WidgetsLocalizations> {
  const GlobalWidgetsLocalizations();

  static const LocalizationsDelegate<WidgetsLocalizations> delegate = GlobalWidgetsLocalizations();

  @override
  bool isSupported(Locale locale) => ['ko', 'en', 'es', 'pt'].contains(locale.languageCode);

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    if (locale.languageCode == 'ko') {
      return MySynchronousFuture<WidgetsLocalizations>(const _KoreanWidgetsLocalizations());
    } else if (locale.languageCode == 'es') {
      return MySynchronousFuture<WidgetsLocalizations>(const _SpanishWidgetsLocalizations());
    } else if (locale.languageCode == 'pt') {
      return MySynchronousFuture<WidgetsLocalizations>(const _PortugueseWidgetsLocalizations());
    } else {
      return MySynchronousFuture<WidgetsLocalizations>(const DefaultWidgetsLocalizations());
    }
  }

  @override
  bool shouldReload(LocalizationsDelegate<WidgetsLocalizations> old) => false;
}

/// 한국어 Widgets 국제화 구현
class _KoreanWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const _KoreanWidgetsLocalizations();

  @override
  String get reorderItemToStart => '맨 앞으로 이동';

  @override
  String get reorderItemToEnd => '맨 뒤로 이동';

  @override
  String get reorderItemUp => '위로 이동';

  @override
  String get reorderItemDown => '아래로 이동';

  @override
  String get reorderItemLeft => '왼쪽으로 이동';

  @override
  String get reorderItemRight => '오른쪽으로 이동';
}

/// 스페인어 Widgets 국제화 구현
class _SpanishWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const _SpanishWidgetsLocalizations();

  @override
  String get reorderItemToStart => 'Mover al inicio';

  @override
  String get reorderItemToEnd => 'Mover al final';

  @override
  String get reorderItemUp => 'Mover hacia arriba';

  @override
  String get reorderItemDown => 'Mover hacia abajo';

  @override
  String get reorderItemLeft => 'Mover a la izquierda';

  @override
  String get reorderItemRight => 'Mover a la derecha';
}

/// 포르투갈어 Widgets 국제화 구현
class _PortugueseWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const _PortugueseWidgetsLocalizations();

  @override
  String get reorderItemToStart => 'Mover para o início';

  @override
  String get reorderItemToEnd => 'Mover para o fim';

  @override
  String get reorderItemUp => 'Mover para cima';

  @override
  String get reorderItemDown => 'Mover para baixo';

  @override
  String get reorderItemLeft => 'Mover para a esquerda';

  @override
  String get reorderItemRight => 'Mover para a direita';
}

/// AppLocalizations 위임자 클래스
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => [
        'ko',
        'en',
        'es',
        'pt',
        'zh',
        'id',
        'vi',
        'de',
        'fr',
        'th',
        'ms',
        'ja',
      ].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return MySynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// 앱 국제화 클래스
class AppLocalizations {
  final Locale locale;

  /// 생성자
  AppLocalizations(this.locale);

  /// 현재 언어의 번역 데이터
  Map<String, String> get _localizedStrings {
    return _getTranslations(locale.languageCode);
  }

  Map<String, String> _getTranslations(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return koTranslations;
      case 'en':
        return enTranslations;
      case 'es':
        return esTranslations;
      case 'pt':
        return ptTranslations;
      case 'zh':
        return zhTranslations;
      case 'id':
        return idTranslations;
      case 'vi':
        return viTranslations;
      case 'de':
        return deTranslations;
      case 'fr':
        return frTranslations;
      case 'th':
        return thTranslations;
      case 'ms':
        return msTranslations;
      case 'ja':
        return jaTranslations;
      default:
        return koTranslations;
    }
  }

  /// 언어 이름 (현지화된 표시용)
  String get languageName {
    switch (locale.languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'pt':
        return 'Português';
      case 'zh':
        return '中文';
      case 'id':
        return 'Bahasa Indonesia';
      case 'vi':
        return 'Tiếng Việt';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'th':
        return 'ไทย';
      case 'ms':
        return 'Bahasa Melayu';
      case 'ja':
        return '日本語';
      default:
        return '한국어';
    }
  }

  /// 로케일 이름 (언어 선택 화면용)
  static String languageNameForLocale(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'pt':
        return 'Português';
      case 'zh':
        return '中文';
      case 'id':
        return 'Bahasa Indonesia';
      case 'vi':
        return 'Tiếng Việt';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'th':
        return 'ไทย';
      case 'ms':
        return 'Bahasa Melayu';
      case 'ja':
        return '日本語';
      default:
        return '알 수 없는 언어';
    }
  }

  /// 현재 컨텍스트의 AppLocalizations 인스턴스 가져오기
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ko'));
  }

  /// Locale 객체로부터 AppLocalizations 인스턴스 생성
  static Future<AppLocalizations> load(Locale locale) {
    return MySynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  /// AppLocalizations 다국어 위임자
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// 지원되는 로케일 목록
  static const List<Locale> supportedLocales = [
    Locale('ko'), // 한국어 (기본)
    Locale('en'), // 영어
    Locale('es'), // 스페인어
    Locale('pt'), // 포르투갈어
    Locale('zh'),
    Locale('id'),
    Locale('vi'),
    Locale('de'),
    Locale('fr'),
    Locale('th'),
    Locale('ms'),
    Locale('ja'),
  ];

  /// 키를 통해 번역된 문자열 가져오기
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  /// 포맷 문자열 처리 (동적 변수가 있는 문자열의 국제화에 사용)
  /// 예: formatMessage('greeting', {'name': '홍길동', 'age': 30})
  /// ko_translations.dart: 'greeting': '안녕하세요, {name}님! {age}세이시네요.'
  String formatMessage(String key, Map<String, dynamic> params) {
    String message = translate(key);

    params.forEach((paramKey, paramValue) {
      message = message.replaceAll('{$paramKey}', paramValue.toString());
    });

    return message;
  }

  // 앱 타이틀
  String get appTitle => translate('appTitle');

  // 공통 텍스트
  String get common_retry => translate('common_retry');
  String get common_skip => translate('common_skip');
  String get common_next => translate('common_next');
  String get common_start => translate('common_start');
  String get common_cancel => translate('common_cancel');
  String get common_confirm => translate('common_confirm');
  String get common_delete => translate('common_delete');
  String get common_close => translate('common_close');
  String get common_edit => translate('common_edit');
  String get common_save => translate('common_save');
  String get common_error => translate('common_error');
  String get common_success => translate('common_success');
  String get common_loading => translate('common_loading');
  String get common_send => translate('common_send');
  String get common_sending => translate('common_sending');
  String get common_refresh => translate('common_refresh');
  String get common_goHome => translate('common_goHome');
  String get common_exit_app_message => translate('common_exit_app_message');

  // 내비게이션 바 항목
  String get nav_home => translate('nav_home');
  String get nav_search => translate('nav_search');
  String get nav_bookmarks => translate('nav_bookmarks');
  String get nav_profile => translate('nav_profile');

  // 로그인 관련
  String get login_title => translate('login_title');
  String get login_button => translate('login_button');
  String get login_logout => translate('login_logout');
  String get login_logout_confirm => translate('login_logout_confirm');

  // 온보딩 관련
  String onboarding_error(String error) =>
      translate('onboarding_error').replaceAll('{error}', error);
  String get onboarding_welcome => translate('onboarding_welcome');
  String get onboarding_welcome_desc => translate('onboarding_welcome_desc');
  String get onboarding_explore => translate('onboarding_explore');
  String get onboarding_explore_desc => translate('onboarding_explore_desc');
  String get onboarding_bookmark => translate('onboarding_bookmark');
  String get onboarding_bookmark_desc => translate('onboarding_bookmark_desc');
  String get onboarding_ready => translate('onboarding_ready');
  String get onboarding_ready_desc => translate('onboarding_ready_desc');

  // 프로필 관련
  String get profile_title => translate('profile_title');
  String get profile_feedback => translate('profile_feedback');
  String get profile_feedback_email_success => translate('profile_feedback_email_success');
  String get profile_feedback_email_error => translate('profile_feedback_email_error');
  String profile_feedback_error(String error) =>
      translate('profile_feedback_error').replaceAll('{error}', error);
  String get profile_feedback_send => translate('profile_feedback_send');

  // 프로필 추가 메서드
  String get profile_content_activity => translate('profile_content_activity');
  String get profile_followed_artists => translate('profile_followed_artists');
  String get profile_saved_videos => translate('profile_saved_videos');
  String get profile_account_management => translate('profile_account_management');
  String get profile_edit_profile => translate('profile_edit_profile');
  String get profile_notification_settings => translate('profile_notification_settings');
  String get profile_feedback_subtitle => translate('profile_feedback_subtitle');
  String get profile_subscription => translate('profile_subscription');
  String get profile_premium_active => translate('profile_premium_active');
  String get profile_premium_upgrade => translate('profile_premium_upgrade');
  String get profile_deactivate_subtitle => translate('profile_deactivate_subtitle');
  String get profile_app_info => translate('profile_app_info');
  String get profile_app_info_title => translate('profile_app_info_title');
  String get profile_terms => translate('profile_terms');
  String get profile_privacy_policy => translate('profile_privacy_policy');
  String get profile_login_required => translate('profile_login_required');
  String get profile_login_description => translate('profile_login_description');
  String get profile_stat_bookmarks => translate('profile_stat_bookmarks');
  String get profile_stat_likes => translate('profile_stat_likes');
  String get profile_stat_comments => translate('profile_stat_comments');
  String get profile_badge_active => translate('profile_badge_active');

  // 회원 탈퇴 관련
  String get deactivate_title => translate('deactivate_title');
  String get deactivate_button => translate('deactivate_button');
  String get deactivate_confirm_title => translate('deactivate_confirm_title');
  String get deactivate_confirm_message => translate('deactivate_confirm_message');
  String get deactivate_success_title => translate('deactivate_success_title');
  String get deactivate_success_message => translate('deactivate_success_message');

  // 구독 관련
  String get subscription_title => translate('subscription_title');
  String get subscription_manage => translate('subscription_manage');
  String subscription_type(String type) =>
      translate('subscription_type').replaceAll('{type}', type);
  String subscription_expiry(String date) =>
      translate('subscription_expiry').replaceAll('{date}', date);
  String get subscription_unlimited => translate('subscription_unlimited');
  String subscription_free_count(int count) =>
      translate('subscription_free_count').replaceAll('{count}', count.toString());
  String get subscription_premium_promo => translate('subscription_premium_promo');
  String get subscription_no_products => translate('subscription_no_products');
  String get subscription_subscribe => translate('subscription_subscribe');
  String get subscription_restore => translate('subscription_restore');
  String get subscription_manage_subscription => translate('subscription_manage_subscription');
  String get subscription_already => translate('subscription_already');
  String get subscription_in_progress => translate('subscription_in_progress');
  String get subscription_completed => translate('subscription_completed');
  String get subscription_failed => translate('subscription_failed');
  String get subscription_restore_progress => translate('subscription_restore_progress');
  String get subscription_restore_success => translate('subscription_restore_success');
  String get subscription_restore_none => translate('subscription_restore_none');
  String get subscription_restore_failed => translate('subscription_restore_failed');
  String get subscription_manage_error => translate('subscription_manage_error');
  String get subscription_monthly => translate('subscription_monthly');
  String get subscription_yearly => translate('subscription_yearly');
  String get subscription_free => translate('subscription_free');
  String get subscription_signup_required => translate('subscription_signup_required');
  String get subscription_signup_required_message =>
      translate('subscription_signup_required_message');
  String get subscription_signup => translate('subscription_signup');
  String get subscription_limit_title => translate('subscription_limit_title');
  String get subscription_limit_message_guest => translate('subscription_limit_message_guest');
  String get subscription_limit_message_user => translate('subscription_limit_message_user');
  String get subscription_later => translate('subscription_later');
  String get subscription_monthly_price => translate('subscription_monthly_price');
  String get free_trial_limit_reached => translate('free_trial_limit_reached');
  String get watch_ad_to_continue => translate('watch_ad_to_continue');
  String get subscribe_to_continue => translate('subscribe_to_continue');

  // 비디오 관련
  String video_error(String error) => translate('video_error').replaceAll('{error}', error);
  String get video_info => translate('video_info');
  String video_title(String title) => translate('video_title').replaceAll('{title}', title);
  String video_id(String id) => translate('video_id').replaceAll('{id}', id);
  String video_platform(String platform) =>
      translate('video_platform').replaceAll('{platform}', platform);
  String video_platform_id(String id) => translate('video_platform_id').replaceAll('{id}', id);
  String video_url(String url) => translate('video_url').replaceAll('{url}', url);
  String video_description(String description) =>
      translate('video_description').replaceAll('{description}', description);
  String get video_not_found => translate('video_not_found');
  String get video_view_subscription => translate('video_view_subscription');
  String video_related_error(String error) =>
      translate('video_related_error').replaceAll('{error}', error);
  String get video_youtube_loading => translate('video_youtube_loading');
  String get video_open_youtube => translate('video_open_youtube');
  String get video_no_thumbnail => translate('video_no_thumbnail');

  // 아티스트 관련
  String get artist_not_found => translate('artist_not_found');
  String get artist_filter_all => translate('artist_filter_all');
  String get artist_filter_stage => translate('artist_filter_stage');
  String get artist_filter_practice => translate('artist_filter_practice');
  String get artist_filter_behind => translate('artist_filter_behind');
  String get artist_sort_newest => translate('artist_sort_newest');
  String get artist_sort_oldest => translate('artist_sort_oldest');
  String get artist_sort_popularity => translate('artist_sort_popularity');

  // 언어 설정
  String get language_settings => translate('language_settings');
  String get language_current => translate('language_current');

  // 이용약관 관련
  String get terms_definition_title => translate('terms_definition_title');
  String get terms_definition_content => translate('terms_definition_content');
  String get terms_posting_title => translate('terms_posting_title');
  String get terms_posting_content => translate('terms_posting_content');
  String get terms_service_title => translate('terms_service_title');

  // 개인정보 처리방침 관련
  String get privacy_security_title => translate('privacy_security_title');
  String get privacy_security_content => translate('privacy_security_content');

  // 검색 화면 관련
  String get search_title => translate('search_title');
  String get search_discover => translate('search_discover');
  String get search_hint => translate('search_hint');
  String get search_filter_all => translate('search_filter_all');
  String get search_filter_video => translate('search_filter_video');
  String get search_filter_artist => translate('search_filter_artist');
  String get search_sort_relevance => translate('search_sort_relevance');
  String get search_sort_latest => translate('search_sort_latest');
  String get search_sort_popularity => translate('search_sort_popularity');
  String get search_recent => translate('search_recent');
  String get search_clear_all => translate('search_clear_all');
  String get search_popular => translate('search_popular');
  String get search_no_results => translate('search_no_results');
  String get search_try_another => translate('search_try_another');
  String get search_category_artist => translate('search_category_artist');
  String get search_category_video => translate('search_category_video');

  // 발견 화면 관련
  String get discover_title => translate('discover_title');
  String get discover_popular_artists => translate('discover_popular_artists');
  String get discover_trending_fancams => translate('discover_trending_fancams');
  String get discover_recent_fancams => translate('discover_recent_fancams');
  String get discover_popular_by_group => translate('discover_popular_by_group');
  String get discover_view_more => translate('discover_view_more');

  // 로그인 화면 관련
  String get login_app_subtitle => translate('login_app_subtitle');
  String get login_email => translate('login_email');
  String get login_email_hint => translate('login_email_hint');
  String get login_password => translate('login_password');
  String get login_password_hint => translate('login_password_hint');
  String get login_remember_me => translate('login_remember_me');
  String get login_forgot_password => translate('login_forgot_password');
  String get login_or_divider => translate('login_or_divider');
  String get login_signup_prompt => translate('login_signup_prompt');
  String get login_signup_button => translate('login_signup_button');
  String get login_validation_email_required => translate('login_validation_email_required');
  String get login_validation_email_invalid => translate('login_validation_email_invalid');
  String get login_validation_password_required => translate('login_validation_password_required');
  String get login_validation_password_length => translate('login_validation_password_length');
  String get login_error_invalid_credentials => translate('login_error_invalid_credentials');
  String get login_error_email_not_confirmed => translate('login_error_email_not_confirmed');
  String get login_error_network => translate('login_error_network');
  String get login_error_unknown => translate('login_error_unknown');

  // 피드 화면 관련
  String get feed_title => translate('feed_title');
  String get feed_tab_popular => translate('feed_tab_popular');
  String get feed_tab_latest => translate('feed_tab_latest');
  String get feed_offline_mode => translate('feed_offline_mode');
  String feed_free_views_remaining(int count, int total) => translate('feed_free_views_remaining')
      .replaceAll('{count}', count.toString())
      .replaceAll('{total}', total.toString());
  String get feed_premium_promo => translate('feed_premium_promo');
  String get feed_unlimited_access => translate('feed_unlimited_access');
  String feed_error_message(String error) =>
      translate('feed_error_message').replaceAll('{error}', error);
  String get feed_retry => translate('feed_retry');

  // 북마크 화면 관련
  String get bookmarks_title => translate('bookmarks_title');
  String get bookmarks_refresh => translate('bookmarks_refresh');
  String get bookmarks_collection_management => translate('bookmarks_collection_management');
  String get bookmarks_videos_tab => translate('bookmarks_videos_tab');
  String get bookmarks_collections_tab => translate('bookmarks_collections_tab');
  String get bookmarks_new_collection => translate('bookmarks_new_collection');
  String get bookmarks_collection_name => translate('bookmarks_collection_name');
  String get bookmarks_collection_desc => translate('bookmarks_collection_desc');
  String get bookmarks_collection_public => translate('bookmarks_collection_public');
  String get bookmarks_collection_public_desc => translate('bookmarks_collection_public_desc');
  String get bookmarks_cancel => translate('bookmarks_cancel');
  String get bookmarks_create => translate('bookmarks_create');
  String get bookmarks_name_required => translate('bookmarks_name_required');
  String get bookmarks_empty_title => translate('bookmarks_empty_title');
  String get bookmarks_empty_desc => translate('bookmarks_empty_desc');
  String get bookmarks_go_home => translate('bookmarks_go_home');
  String get bookmarks_error_title => translate('bookmarks_error_title');
  String get bookmarks_retry => translate('bookmarks_retry');
  String bookmarks_view_count(int count) =>
      translate('bookmarks_view_count').replaceAll('{count}', count.toString());
  String get bookmarks_collection_empty_title => translate('bookmarks_collection_empty_title');
  String get bookmarks_collection_empty_desc => translate('bookmarks_collection_empty_desc');
  String get bookmarks_create_collection => translate('bookmarks_create_collection');

  // 컬렉션 관리 화면 관련
  String get collection_management_title => translate('collection_management_title');
  String get collection_management_new => translate('collection_management_new');
  String get collection_management_empty => translate('collection_management_empty');
  String get collection_management_empty_description =>
      translate('collection_management_empty_description');
  String get collection_management_create => translate('collection_management_create');
  String get collection_management_create_title => translate('collection_management_create_title');
  String get collection_management_name => translate('collection_management_name');
  String get collection_management_name_hint => translate('collection_management_name_hint');
  String get collection_management_description => translate('collection_management_description');
  String get collection_management_description_hint =>
      translate('collection_management_description_hint');
  String get collection_management_create_button =>
      translate('collection_management_create_button');
  String get collection_management_cancel => translate('collection_management_cancel');
  String get collection_management_delete_title => translate('collection_management_delete_title');
  String collection_management_delete_message(String name) =>
      translate('collection_management_delete_message').replaceAll('{{name}}', name);
  String get collection_management_delete_button =>
      translate('collection_management_delete_button');
  String get collection_management_error => translate('collection_management_error');

  // 프로필 기본 정보 관련
  String profile_stat_count(int count) =>
      translate('profile_stat_count').replaceAll('{count}', count.toString());
  String get profile_username_default => translate('profile_username_default');
  String get profile_email_login_required => translate('profile_email_login_required');
  String get profile_settings => translate('profile_settings');
  String get profile_bio => translate('profile_bio');

  // 추가 프로필 설정 정보
  String get profile_settings_title => translate('profile_settings_title');
  String get profile_app_lang => translate('profile_app_lang');
  String get profile_theme => translate('profile_theme');
  String get profile_theme_light => translate('profile_theme_light');
  String get profile_theme_dark => translate('profile_theme_dark');
  String get profile_theme_system => translate('profile_theme_system');
  String get profile_notifications => translate('profile_notifications');
  String get profile_autoplay => translate('profile_autoplay');
  String get profile_quality => translate('profile_quality');
  String get profile_quality_auto => translate('profile_quality_auto');
  String get profile_quality_high => translate('profile_quality_high');
  String get profile_quality_medium => translate('profile_quality_medium');
  String get profile_quality_low => translate('profile_quality_low');
  String get profile_data_usage => translate('profile_data_usage');
  String get profile_data_wifi_only => translate('profile_data_wifi_only');
  String get profile_cache => translate('profile_cache');
  String get profile_clear_cache => translate('profile_clear_cache');
  String get profile_cache_confirm => translate('profile_cache_confirm');
  String get profile_cache_confirm_desc => translate('profile_cache_confirm_desc');
  String profile_cache_size(String size) =>
      translate('profile_cache_size').replaceAll('{size}', size);
  String get profile_cache_cleared => translate('profile_cache_cleared');

  // 건의하기 화면 관련
  String get feedback_title => translate('feedback_title');
  String get feedback_question => translate('feedback_question');
  String get feedback_description => translate('feedback_description');
  String get feedback_email => translate('feedback_email');
  String get feedback_email_hint => translate('feedback_email_hint');
  String get feedback_email_validation => translate('feedback_email_validation');
  String get feedback_email_invalid => translate('feedback_email_invalid');
  String get feedback_subject => translate('feedback_subject');
  String get feedback_subject_hint => translate('feedback_subject_hint');
  String get feedback_subject_validation => translate('feedback_subject_validation');
  String get feedback_content => translate('feedback_content');
  String get feedback_content_hint => translate('feedback_content_hint');
  String get feedback_content_validation => translate('feedback_content_validation');
  String get feedback_content_length => translate('feedback_content_length');
  String get feedback_send => translate('feedback_send');
  String get feedback_privacy_notice => translate('feedback_privacy_notice');

  // 구독관리 화면 관련
  String get subscription_login_required_card => translate('subscription_login_required_card');
  String get subscription_login_button => translate('subscription_login_button');
  String get subscription_available_products => translate('subscription_available_products');
  String get subscription_no_products_available => translate('subscription_no_products_available');
  String get subscription_loading_products => translate('subscription_loading_products');
  String get subscription_error_loading => translate('subscription_error_loading');
  String get subscription_restore_purchase => translate('subscription_restore_purchase');
  String get subscription_status_active => translate('subscription_status_active');
  String get subscription_status_type => translate('subscription_status_type');
  String get subscription_status_until => translate('subscription_status_until');
  String get subscription_unlimited_access => translate('subscription_unlimited_access');
  String get subscription_expired => translate('subscription_expired');
  String get subscription_expires_on => translate('subscription_expires_on');
  String get subscription_cancel_info => translate('subscription_cancel_info');
  String get subscription_manage_button => translate('subscription_manage_button');
  String get subscription_free_tier => translate('subscription_free_tier');
  String get subscription_free_remaining => translate('subscription_free_remaining');
  String get subscription_upgrade_prompt => translate('subscription_upgrade_prompt');
  String get subscription_upgrade_button => translate('subscription_upgrade_button');
  String get subscription_product_monthly => translate('subscription_product_monthly');
  String get subscription_product_yearly => translate('subscription_product_yearly');
  String get subscription_product_monthly_description =>
      translate('subscription_product_monthly_description');
  String get subscription_product_yearly_description =>
      translate('subscription_product_yearly_description');
  String get subscription_subscribe_button => translate('subscription_subscribe_button');
  String get subscription_confirm_title => translate('subscription_confirm_title');
  String get subscription_confirm_message => translate('subscription_confirm_message');
  String get subscription_confirm_recur_message => translate('subscription_confirm_recur_message');
  String get subscription_confirm_button => translate('subscription_confirm_button');
  String get subscription_success_title => translate('subscription_success_title');
  String get subscription_success_message => translate('subscription_success_message');
  String get subscription_error_title => translate('subscription_error_title');
  String get subscription_error_message => translate('subscription_error_message');
  String get subscription_restore_message => translate('subscription_restore_message');

  // 회원 탈퇴 화면 관련
  String get deactivate_warning => translate('deactivate_warning');
  String get deactivate_warning_message => translate('deactivate_warning_message');
  String get deactivate_warning_profile => translate('deactivate_warning_profile');
  String get deactivate_warning_bookmarks => translate('deactivate_warning_bookmarks');
  String get deactivate_warning_activity => translate('deactivate_warning_activity');
  String get deactivate_warning_artists => translate('deactivate_warning_artists');
  String get deactivate_warning_subscription => translate('deactivate_warning_subscription');
  String get deactivate_confirm_checkbox => translate('deactivate_confirm_checkbox');
  String get deactivate_cancel => translate('deactivate_cancel');

  // 앱 정보 화면 관련
  String app_info_version(String version, String build) {
    return translate('app_info_version')
        .replaceAll('{version}', version)
        .replaceAll('{build}', build);
  }

  String get app_info_introduction => translate('app_info_introduction');
  String get app_info_introduction_content => translate('app_info_introduction_content');
  String get app_info_developer => translate('app_info_developer');
  String get app_info_developer_content => translate('app_info_developer_content');
  String get app_info_technical => translate('app_info_technical');
  String get app_info_technical_content => translate('app_info_technical_content');
  String get app_info_opensource => translate('app_info_opensource');
  String get app_info_customer_support => translate('app_info_customer_support');

  // 이용약관 화면 관련
  String get terms_intro_title => translate('terms_intro_title');
  String get terms_intro_content => translate('terms_intro_content');
  String get terms_membership_title => translate('terms_membership_title');
  String get terms_membership_content => translate('terms_membership_content');

  // 스플래시 화면 관련
  String get splash_app_name => translate('splash_app_name');
  String get splash_app_description => translate('splash_app_description');

  // 개인정보 처리방침 화면 관련
  String get privacy_intro => translate('privacy_intro');
  String get privacy_purpose_title => translate('privacy_purpose_title');
  String get privacy_purpose_content => translate('privacy_purpose_content');
  String get privacy_retention_title => translate('privacy_retention_title');
  String get privacy_retention_content => translate('privacy_retention_content');
  String get privacy_thirdparty_title => translate('privacy_thirdparty_title');
  String get privacy_thirdparty_content => translate('privacy_thirdparty_content');
  String get privacy_rights_title => translate('privacy_rights_title');
  String get privacy_rights_content => translate('privacy_rights_content');

  // 비디오 플레이어 화면 관련
  String get video_player_error_icon => translate('video_player_error_icon');
  String get video_player_loading => translate('video_player_loading');
  String get video_player_back => translate('video_player_back');
  String get video_player_no_data => translate('video_player_no_data');
  String video_player_load_error(String error) =>
      translate('video_player_load_error').replaceAll('{error}', error);
  String get video_player_info_dialog_title => translate('video_player_info_dialog_title');
  String video_player_share_subject(String title) =>
      translate('video_player_share_subject').replaceAll('{title}', title);
  String video_player_share_message(String title, String url) =>
      translate('video_player_share_message').replaceAll('{title}', title).replaceAll('{url}', url);
  String get video_player_no_description => translate('video_player_no_description');
  String get video_player_no_video => translate('video_player_no_video');
  String video_player_youtube_error(String error) =>
      translate('video_player_youtube_error').replaceAll('{error}', error);
  String get video_player_need_subscription => translate('video_player_need_subscription');
  String get video_player_view_subscription => translate('video_player_view_subscription');
  String get video_player_youtube_id_error => translate('video_player_youtube_id_error');
  String video_player_youtube_init_error(String error) =>
      translate('video_player_youtube_init_error').replaceAll('{error}', error);
  String get video_player_open_youtube => translate('video_player_open_youtube');
  String get video_player_retry => translate('video_player_retry');
  String get video_player_related_videos => translate('video_player_related_videos');
  String get video_player_no_related_videos => translate('video_player_no_related_videos');
  String get video_player_like => translate('video_player_like');
  String get video_player_bookmark => translate('video_player_bookmark');
  String get video_player_share => translate('video_player_share');
  String video_player_share_error(String error) =>
      translate('video_player_share_error').replaceAll('{error}', error);
  String video_player_related_videos_error(String error) =>
      translate('video_player_related_videos_error').replaceAll('{error}', error);
  String get video_player_youtube_loading => translate('video_player_youtube_loading');
  String get video_player_player_init_failed => translate('video_player_player_init_failed');
  String get video_player_web_player_message => translate('video_player_web_player_message');
  String get video_player_mute => translate('video_player_mute');
  String get video_player_unmute => translate('video_player_unmute');
  String get video_player_play => translate('video_player_play');
  String get video_player_pause => translate('video_player_pause');
  String get video_player_progress => translate('video_player_progress');
  String get video_player_fullscreen => translate('video_player_fullscreen');
  String get video_player_exit_fullscreen => translate('video_player_exit_fullscreen');
  String get video_player_playback_speed => translate('video_player_playback_speed');
  String get video_player_normal_speed => translate('video_player_normal_speed');

  // 비디오 정보 필드
  String get video_title_prefix => translate('video_title_prefix');
  String get video_id_prefix => translate('video_id_prefix');
  String get video_platform_prefix => translate('video_platform_prefix');
  String get video_platform_id_prefix => translate('video_platform_id_prefix');
  String get video_url_prefix => translate('video_url_prefix');
  String get video_description_prefix => translate('video_description_prefix');

  // 숫자 포맷 접미사
  String get count_thousand_suffix => translate('count_thousand_suffix');
  String get count_million_suffix => translate('count_million_suffix');

  // 앱 일반 오류 메시지
  String get app_error_generic => translate('app_error_generic');
  String get app_error_network => translate('app_error_network');
  String get app_error_timeout => translate('app_error_timeout');
  String get app_error_launching_url => translate('app_error_launching_url');

  // 구독 신규 메서드
  String get premium_features => translate('premium_features');
  String get subscription_benefits_title => translate('subscription_benefits_title');
  String free_views_left(String count) => translate('free_views_left').replaceAll('%s', count);
  String get premium_banner_description => translate('premium_banner_description');
  String get premium_banner_button => translate('premium_banner_button');
  String get premium_benefit_1 => translate('premium_benefit_1');
  String get premium_benefit_2 => translate('premium_benefit_2');
  String get premium_benefit_3 => translate('premium_benefit_3');
  String get premium_benefit_4 => translate('premium_benefit_4');
  String get premium_benefit_5 => translate('premium_benefit_5');
  String get premium_benefit_6 => translate('premium_benefit_6');
  String get free_tier_benefit_1 => translate('free_tier_benefit_1');
  String get free_tier_benefit_2 => translate('free_tier_benefit_2');
  String get free_tier_benefit_3 => translate('free_tier_benefit_3');
  String get free_tier_benefit_4 => translate('free_tier_benefit_4');
  String get monthly_plan_description => translate('monthly_plan_description');
  String get yearly_plan_description => translate('yearly_plan_description');
  String get most_popular_tag => translate('most_popular_tag');
  String get best_value_tag => translate('best_value_tag');

  /// Ad completed message
  String get ad_watch_completed => translate('ad_watch_completed');

  // 온보딩 화면 관련 getter 추가
  String get onboarding_welcome_title => translate('onboarding_welcome_title');
  String get onboarding_welcome_description => translate('onboarding_welcome_description');
  String get onboarding_videos_title => translate('onboarding_videos_title');
  String get onboarding_videos_description => translate('onboarding_videos_description');
  String get onboarding_community_title => translate('onboarding_community_title');
  String get onboarding_community_description => translate('onboarding_community_description');
  String get skip => translate('skip');
  String get get_started => translate('get_started');
  String get next => translate('next');

  // 구독 관련 추가 getter
  String get free_tier => translate('free_tier');
  String get premium_tier => translate('premium_tier');
}
