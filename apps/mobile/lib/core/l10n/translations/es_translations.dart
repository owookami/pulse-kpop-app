const Map<String, String> esTranslations = {
  // 앱 타이틀
  'appTitle': 'Pulse',

  // 공통 텍스트
  'common_retry': 'Reintentar',
  'common_skip': 'Saltar',
  'common_next': 'Siguiente',
  'common_start': 'Comenzar',
  'common_cancel': 'Cancelar',
  'common_confirm': 'Confirmar',
  'common_delete': 'Eliminar',
  'common_close': 'Cerrar',
  'common_edit': 'Editar',
  'common_save': 'Guardar',
  'common_error': 'Error',
  'common_success': 'Éxito',
  'common_loading': 'Cargando',
  'common_send': 'Enviar',
  'common_sending': 'Enviando',
  'common_refresh': 'Actualizar',
  'common_goHome': 'Ir a inicio',
  'common_exit_app_message': 'Presiona de nuevo para salir',

  // 내비게이션 바 항목
  'nav_home': 'Inicio',
  'nav_search': 'Buscar',
  'nav_bookmarks': 'Marcadores',
  'nav_profile': 'Perfil',

  // 로그인 관련
  'login_title': 'Iniciar sesión',
  'login_button': 'Iniciar sesión',
  'login_logout': 'Cerrar sesión',
  'login_logout_confirm': '¿Estás seguro de que quieres cerrar sesión?',

  // 온보딩 관련
  'onboarding_error': 'Error al cargar datos: {error}',
  'onboarding_welcome': 'Bienvenido a Pulse',
  'onboarding_welcome_desc': 'Disfruta de contenido exclusivo y de calidad',
  'onboarding_explore': 'Explora el contenido',
  'onboarding_explore_desc': 'Descubre videos exclusivos de tus creadores favoritos',
  'onboarding_bookmark': 'Guarda tus favoritos',
  'onboarding_bookmark_desc': 'Marca tus videos favoritos para verlos más tarde',

  // 컬렉션 관리 화면 관련
  'collection_management_title': 'Gestión de colecciones',
  'collection_management_new': 'Nueva colección',
  'collection_management_empty': 'No hay colecciones.',
  'collection_management_empty_description': 'Administra tus videos marcados en colecciones.',
  'collection_management_create': 'Crear colección',
  'collection_management_create_title': 'Crear una nueva colección',
  'collection_management_name': 'Nombre de la colección',
  'collection_management_name_hint': 'Ingresa el nombre de la nueva colección.',
  'collection_management_description': 'Descripción (opcional)',
  'collection_management_description_hint': 'Ingresa una descripción para la colección.',
  'collection_management_create_button': 'Crear',
  'collection_management_cancel': 'Cancelar',
  'collection_management_delete_title': 'Eliminar colección',
  'collection_management_delete_message':
      '¿Estás seguro de que quieres eliminar la colección \'{{name}}\'?',
  'collection_management_delete_button': 'Eliminar',
  'collection_management_error': 'Error al cargar las colecciones.',

  // 비디오 플레이어 화면 관련
  'video_player_load_error': 'No se pudo cargar el video: {error}',
  'video_player_info_dialog_title': 'Información del video',
  'video_player_share_subject': 'Compartir video de Pulse: {title}',
  'video_player_share_message': '¡Mira el video "{title}" en la aplicación Pulse!\n{url}',
  'video_player_no_description': 'Sin descripción',
  'video_player_no_video': 'Video no encontrado.',
  'video_player_youtube_error': 'No se pudo cargar el video de YouTube: {error}',
  'video_player_need_subscription': 'Se requiere suscripción\npara ver este contenido',
  'video_player_view_subscription': 'Ver información de suscripción',
  'video_player_youtube_id_error': 'No se pudo extraer un ID de YouTube válido.',
  'video_player_youtube_init_error': 'Error al inicializar el reproductor de YouTube: {error}',
  'video_player_open_youtube': 'Abrir en YouTube',
  'video_player_retry': 'Reintentar',
  'video_player_related_videos': 'Videos relacionados',
  'video_player_no_related_videos': 'No hay videos relacionados actualmente.',
  'video_player_like': 'Me gusta',
  'video_player_bookmark': 'Marcar',
  'video_player_share': 'Compartir',
  'video_player_share_error': 'Error al compartir: {error}',
  'video_player_related_videos_error': 'No se pudieron cargar videos relacionados: {error}',
  'video_player_youtube_loading': 'Cargando video de YouTube...',
  'video_player_player_init_failed': 'Falló la inicialización del reproductor',
  'video_player_web_player_message':
      'En el entorno web, debes reproducir en el reproductor externo de YouTube.',

  // 비디오 정보 필드 접두사
  'video_title_prefix': 'Título: ',
  'video_id_prefix': 'ID: ',
  'video_platform_prefix': 'Plataforma: ',
  'video_platform_id_prefix': 'ID de plataforma: ',
  'video_url_prefix': 'URL: ',
  'video_description_prefix': 'Descripción: ',

  // 앱 일반 오류 메시지
  'app_error_generic': 'Se ha producido un error',
  'app_error_network': 'Por favor, comprueba tu conexión de red',
  'app_error_timeout': 'Tiempo de espera agotado para la solicitud',
  'app_error_launching_url': 'No se pudo abrir la URL',

  /// Premium Features
  'premium_features': 'Funciones Premium',

  /// Subscription
  'subscription_title': 'Gestión de suscripciones',
  'subscription_restore_progress': 'Restaurando compras...',
  'subscription_restore_success': 'Suscripción restaurada con éxito',
  'subscription_restore_none': 'No hay suscripciones para restaurar',
  'subscription_restore_failed': 'Error al restaurar las compras. Por favor, inténtalo de nuevo',
  'subscription_manage_error': 'No se pudo abrir la página de gestión de suscripciones',
  'subscription_monthly': 'Mensual',
  'subscription_yearly': 'Anual',
  'subscription_free': 'Gratuito',
  'subscription_signup_required': 'Registro requerido',
  'subscription_signup_required_message':
      'Debes registrarte antes de suscribirte. ¿Quieres ir a la página de registro?',
  'subscription_signup': 'Registrarse',
  'subscription_limit_title': 'Límite de visualizaciones gratuitas alcanzado',
  'subscription_limit_message_guest': 'Por favor, regístrate para seguir viendo más vídeos',
  'subscription_limit_message_user':
      'Has utilizado todas tus visualizaciones gratuitas. Actualiza a premium o mira un anuncio para continuar',
  'subscription_later': 'Más tarde',

  /// Subscription Benefits
  'subscription_benefits_title': 'Beneficios de la suscripción Premium',

  /// Premium Banner Title
  'free_views_left': '%s visualizaciones gratuitas restantes',

  /// Premium Banner Description
  'premium_banner_description':
      'Suscríbete a premium para ver todos los vídeos sin anuncios, ilimitadamente',

  /// Premium Banner Button
  'premium_banner_button': 'Suscribirse ahora',

  /// Monthly Price
  'subscription_monthly_price': r'$1.99/mes',

  /// Free trial limit
  'free_trial_limit_reached': 'Has utilizado todas tus visualizaciones gratuitas',

  /// Watch ad to continue
  'watch_ad_to_continue': 'Ver anuncio para continuar',

  /// Subscribe to continue
  'subscribe_to_continue': 'Suscríbete para ver sin límites',

  /// Premium benefits
  'premium_benefit_1': 'Visualización ilimitada de vídeos',
  'premium_benefit_2': 'Streaming en calidad HD',
  'premium_benefit_3': 'Experiencia sin anuncios',
  'premium_benefit_4': 'Descargas offline',
  'premium_benefit_5': 'Acceso a contenido exclusivo',
  'premium_benefit_6': 'Soporte prioritario',

  /// Free tier benefits
  'free_tier_benefit_1': '10 vídeos gratuitos al día',
  'free_tier_benefit_2': 'Visualización en calidad estándar',
  'free_tier_benefit_3': 'Capacidad de búsqueda directa',
  'free_tier_benefit_4': 'Explorar contenido popular',

  /// Monthly plan description
  'monthly_plan_description': 'Disfruta de beneficios premium con máxima flexibilidad',

  /// Yearly plan description
  'yearly_plan_description': 'Obtén 2 meses gratis con la suscripción anual',

  /// Plan tags
  'most_popular_tag': 'Popular',
  'best_value_tag': 'Mejor valor',

  /// Ad completed message
  'ad_watch_completed': 'Anuncio completado. Ahora puedes continuar viendo el vídeo.',

  // 건의하기 화면 관련
  'feedback_title': 'Enviar comentarios',
  'feedback_question': '¿Tienes alguna sugerencia o comentario sobre la aplicación?',
  'feedback_description': 'Tu valioso feedback nos ayudará a mejorar nuestro servicio.',
  'feedback_email': 'Email de respuesta',
  'feedback_email_hint': 'Introduce tu dirección de email para recibir una respuesta',
  'feedback_email_validation': 'Por favor, introduce tu email',
  'feedback_email_invalid': 'Por favor, introduce una dirección de email válida',
  'feedback_subject': 'Asunto',
  'feedback_subject_hint': 'Introduce el asunto de tu feedback',
  'feedback_subject_validation': 'Por favor, introduce un asunto',
  'feedback_content': 'Contenido',
  'feedback_content_hint': 'Por favor, describe tu feedback en detalle',
  'feedback_content_validation': 'Por favor, introduce tu feedback',
  'feedback_content_length': 'Por favor, introduce al menos 10 caracteres',
  'feedback_send': 'Enviar feedback',
  'feedback_privacy_notice':
      '* Tu dirección de email será recopilada para procesar el feedback y responder.',

  /// Free Tier
  'free_tier': 'Plan gratuito',

  /// Premium Tier
  'premium_tier': 'Plan premium',
};
