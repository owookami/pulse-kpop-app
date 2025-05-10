const Map<String, String> deTranslations = {
  // 앱 타이틀
  'appTitle': 'Pulse',

  // 공통 텍스트
  'common_retry': 'Wiederholen',
  'common_skip': 'Überspringen',
  'common_next': 'Weiter',
  'common_start': 'Starten',
  'common_cancel': 'Abbrechen',
  'common_confirm': 'Bestätigen',
  'common_delete': 'Löschen',
  'common_close': 'Schließen',
  'common_edit': 'Bearbeiten',
  'common_save': 'Speichern',
  'common_error': 'Fehler',
  'common_success': 'Erfolg',
  'common_loading': 'Laden...',
  'common_send': 'Senden',
  'common_sending': 'Senden...',
  'common_refresh': 'Aktualisieren',
  'common_goHome': 'Zur Startseite',
  'common_exit_app_message': 'Zum Beenden erneut drücken',

  // 내비게이션 바 항목
  'nav_home': 'Startseite',
  'nav_search': 'Suche',
  'nav_bookmarks': 'Lesezeichen',
  'nav_profile': 'Profil',

  // 로그인 관련
  'login_title': 'Anmelden',
  'login_button': 'Anmelden',
  'login_logout': 'Abmelden',
  'login_logout_confirm': 'Sind Sie sicher, dass Sie sich abmelden möchten?',

  // 온보딩 관련
  'onboarding_error': 'Fehler beim Laden der Daten: {error}',
  'onboarding_welcome': 'Willkommen bei Pulse',
  'onboarding_welcome_desc': 'Genießen Sie exklusive Inhalte von hoher Qualität',
  'onboarding_explore': 'Inhalte erkunden',
  'onboarding_explore_desc': 'Entdecken Sie exklusive Videos Ihrer Lieblingskünstler',
  'onboarding_bookmark': 'Favoriten speichern',
  'onboarding_bookmark_desc': 'Markieren Sie Ihre Lieblingsvideos für später',

  // 비디오 플레이어 화면 관련
  'video_player_load_error': 'Video konnte nicht geladen werden: {error}',
  'video_player_info_dialog_title': 'Video-Informationen',
  'video_player_share_subject': 'Pulse Video-Freigabe: {title}',
  'video_player_share_message': 'Schau dir das Video "{title}" in der Pulse App an!\n{url}',
  'video_player_no_description': 'Keine Beschreibung',
  'video_player_no_video': 'Video nicht gefunden',
  'video_player_youtube_error': 'YouTube-Video konnte nicht geladen werden: {error}',
  'video_player_need_subscription': 'Abonnement erforderlich,\num diesen Inhalt anzusehen',
  'video_player_view_subscription': 'Abonnementinformationen anzeigen',
  'video_player_youtube_id_error': 'Konnte keine gültige YouTube-ID extrahieren',
  'video_player_youtube_init_error': 'YouTube-Player-Initialisierung fehlgeschlagen: {error}',
  'video_player_open_youtube': 'In YouTube öffnen',
  'video_player_retry': 'Wiederholen',
  'video_player_related_videos': 'Ähnliche Videos',
  'video_player_no_related_videos': 'Derzeit keine ähnlichen Videos',
  'video_player_like': 'Gefällt mir',
  'video_player_bookmark': 'Lesezeichen',
  'video_player_share': 'Teilen',
  'video_player_share_error': 'Fehler beim Teilen: {error}',
  'video_player_related_videos_error': 'Ähnliche Videos konnten nicht geladen werden: {error}',
  'video_player_youtube_loading': 'YouTube-Video wird geladen...',
  'video_player_player_init_failed': 'Player-Initialisierung fehlgeschlagen',
  'video_player_web_player_message':
      'In der Webumgebung müssen Sie externe YouTube-Player verwenden',

  // 비디오 정보 필드 접두사
  'video_title_prefix': 'Titel: ',
  'video_id_prefix': 'ID: ',
  'video_platform_prefix': 'Plattform: ',
  'video_platform_id_prefix': 'Plattform-ID: ',
  'video_url_prefix': 'URL: ',
  'video_description_prefix': 'Beschreibung: ',

  // 앱 일반 오류 메시지
  'app_error_generic': 'Ein Fehler ist aufgetreten',
  'app_error_network': 'Bitte überprüfen Sie Ihre Netzwerkverbindung',
  'app_error_timeout': 'Zeitüberschreitung der Anfrage',
  'app_error_launching_url': 'URL konnte nicht geöffnet werden',

  /// Premium Features
  'premium_features': 'Premium-Funktionen',

  /// Subscription
  'subscription_title': 'Abonnementverwaltung',
  'subscription_restore_progress': 'Käufe werden wiederhergestellt...',
  'subscription_restore_success': 'Abonnement erfolgreich wiederhergestellt',
  'subscription_restore_none': 'Keine Abonnements zum Wiederherstellen',
  'subscription_restore_failed':
      'Wiederherstellung der Käufe fehlgeschlagen. Bitte versuchen Sie es erneut',
  'subscription_manage_error': 'Abonnementverwaltungsseite konnte nicht geöffnet werden',
  'subscription_monthly': 'Monatlich',
  'subscription_yearly': 'Jährlich',
  'subscription_free': 'Kostenlos',
  'subscription_signup_required': 'Registrierung erforderlich',
  'subscription_signup_required_message':
      'Sie müssen sich registrieren, bevor Sie abonnieren können. Möchten Sie zur Registrierungsseite gehen?',
  'subscription_signup': 'Registrieren',
  'subscription_limit_title': 'Grenze für kostenlose Ansichten erreicht',
  'subscription_limit_message_guest': 'Bitte registrieren Sie sich, um weitere Videos anzusehen',
  'subscription_limit_message_user':
      'Sie haben alle kostenlosen Ansichten verbraucht. Upgraden Sie auf Premium oder sehen Sie sich eine Werbung an, um fortzufahren',
  'subscription_later': 'Später',

  /// Subscription Benefits
  'subscription_benefits_title': 'Premium-Abonnementvorteile',

  /// Premium Banner Title
  'free_views_left': 'Noch %s kostenlose Ansichten',

  /// Premium Banner Description
  'premium_banner_description':
      'Abonnieren Sie Premium, um alle Videos ohne Werbung und unbegrenzt anzusehen',

  /// Premium Banner Button
  'premium_banner_button': 'Jetzt abonnieren',

  /// Monthly Price
  'subscription_monthly_price': r'$1,99/Monat',

  /// Free trial limit
  'free_trial_limit_reached': 'Sie haben alle kostenlosen Ansichten verbraucht',

  /// Watch ad to continue
  'watch_ad_to_continue': 'Werbung ansehen, um fortzufahren',

  /// Subscribe to continue
  'subscribe_to_continue': 'Abonnieren Sie, um unbegrenzt anzusehen',

  /// Premium benefits
  'premium_benefit_1': 'Unbegrenztes Video-Ansehen',
  'premium_benefit_2': 'HD-Qualitäts-Streaming',
  'premium_benefit_3': 'Werbefreies Erlebnis',
  'premium_benefit_4': 'Offline-Downloads',
  'premium_benefit_5': 'Zugriff auf exklusive Inhalte',
  'premium_benefit_6': 'Bevorzugter Kundensupport',

  /// Free tier benefits
  'free_tier_benefit_1': '10 kostenlose Videos pro Tag',
  'free_tier_benefit_2': 'Standardqualität',
  'free_tier_benefit_3': 'Direkte Suchfunktion',
  'free_tier_benefit_4': 'Beliebte Inhalte durchsuchen',

  /// Monthly plan description
  'monthly_plan_description': 'Genießen Sie Premium-Vorteile mit maximaler Flexibilität',

  /// Yearly plan description
  'yearly_plan_description': 'Erhalten Sie 2 Monate gratis mit dem Jahresabonnement',

  /// Plan tags
  'most_popular_tag': 'Beliebt',
  'best_value_tag': 'Bestes Angebot',

  /// Ad completed message
  'ad_watch_completed': 'Werbung abgeschlossen. Sie können jetzt das Video weiterschauen.',

  // 건의하기 화면 관련
  'feedback_title': 'Feedback senden',
  'feedback_question': 'Haben Sie Feedback oder Vorschläge zur App?',
  'feedback_description': 'Ihr wertvolles Feedback hilft uns, unseren Service zu verbessern.',
  'feedback_email': 'Antwort-E-Mail',
  'feedback_email_hint': 'Geben Sie Ihre E-Mail-Adresse ein, um eine Antwort zu erhalten',
  'feedback_email_validation': 'Bitte geben Sie Ihre E-Mail ein',
  'feedback_email_invalid': 'Bitte geben Sie eine gültige E-Mail-Adresse ein',
  'feedback_subject': 'Betreff',
  'feedback_subject_hint': 'Geben Sie den Betreff Ihres Feedbacks ein',
  'feedback_subject_validation': 'Bitte geben Sie einen Betreff ein',
  'feedback_content': 'Inhalt',
  'feedback_content_hint': 'Bitte beschreiben Sie Ihr Feedback ausführlich',
  'feedback_content_validation': 'Bitte geben Sie Ihr Feedback ein',
  'feedback_content_length': 'Bitte geben Sie mindestens 10 Zeichen ein',
  'feedback_send': 'Feedback senden',
  'feedback_privacy_notice':
      '* Ihre E-Mail-Adresse wird für die Feedback-Verarbeitung und Antwortzwecke gesammelt.',

  /// Free Tier
  'free_tier': 'Kostenloses Abonnement',

  /// Premium Tier
  'premium_tier': 'Premium-Abonnement',
};
