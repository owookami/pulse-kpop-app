const Map<String, String> ptTranslations = {
  // 앱 타이틀
  'appTitle': 'Pulse',

  // 공통 텍스트
  'common_retry': 'Tentar novamente',
  'common_skip': 'Pular',
  'common_next': 'Próximo',
  'common_start': 'Começar',
  'common_cancel': 'Cancelar',
  'common_confirm': 'Confirmar',
  'common_delete': 'Excluir',
  'common_close': 'Fechar',
  'common_edit': 'Editar',
  'common_save': 'Salvar',
  'common_error': 'Erro',
  'common_success': 'Sucesso',
  'common_loading': 'Carregando',
  'common_send': 'Enviar',
  'common_sending': 'Enviando',
  'common_refresh': 'Atualizar',
  'common_goHome': 'Ir para o início',
  'common_exit_app_message': 'Pressione novamente para sair',

  // 내비게이션 바 항목
  'nav_home': 'Início',
  'nav_search': 'Buscar',
  'nav_bookmarks': 'Favoritos',
  'nav_profile': 'Perfil',

  // 로그인 관련
  'login_title': 'Entrar',
  'login_button': 'Entrar',
  'login_logout': 'Sair',
  'login_logout_confirm': 'Tem certeza que deseja sair?',

  // 온보딩 관련
  'onboarding_error': 'Erro ao carregar dados: {error}',
  'onboarding_welcome': 'Bem-vindo ao Pulse',
  'onboarding_welcome_desc': 'Desfrute de conteúdo exclusivo e de qualidade',
  'onboarding_explore': 'Explore o conteúdo',
  'onboarding_explore_desc': 'Descubra vídeos exclusivos dos seus criadores favoritos',
  'onboarding_bookmark': 'Salve seus favoritos',
  'onboarding_bookmark_desc': 'Marque seus vídeos favoritos para assistir mais tarde',

  // 컬렉션 관리 화면 관련
  'collection_management_title': 'Gerenciamento de coleções',
  'collection_management_new': 'Nova coleção',
  'collection_management_empty': 'Não há coleções.',
  'collection_management_empty_description': 'Gerencie seus vídeos marcados em coleções.',
  'collection_management_create': 'Criar coleção',
  'collection_management_create_title': 'Criar uma nova coleção',
  'collection_management_name': 'Nome da coleção',
  'collection_management_name_hint': 'Digite o nome da nova coleção.',
  'collection_management_description': 'Descrição (opcional)',
  'collection_management_description_hint': 'Digite uma descrição para a coleção.',
  'collection_management_create_button': 'Criar',
  'collection_management_cancel': 'Cancelar',
  'collection_management_delete_title': 'Excluir coleção',
  'collection_management_delete_message': 'Tem certeza que deseja excluir a coleção \'{{name}}\'?',
  'collection_management_delete_button': 'Excluir',
  'collection_management_error': 'Erro ao carregar coleções.',

  // 비디오 플레이어 화면 관련
  'video_player_load_error': 'Não foi possível carregar o vídeo: {error}',
  'video_player_info_dialog_title': 'Informações do vídeo',
  'video_player_share_subject': 'Compartilhamento de vídeo do Pulse: {title}',
  'video_player_share_message': 'Confira o vídeo "{title}" no aplicativo Pulse!\n{url}',
  'video_player_no_description': 'Sem descrição',
  'video_player_no_video': 'Vídeo não encontrado.',
  'video_player_youtube_error': 'Não foi possível carregar o vídeo do YouTube: {error}',
  'video_player_need_subscription': 'Assinatura necessária\npara assistir este conteúdo',
  'video_player_view_subscription': 'Ver informações de assinatura',
  'video_player_youtube_id_error': 'Não foi possível extrair um ID válido do YouTube.',
  'video_player_youtube_init_error': 'Falha na inicialização do reprodutor do YouTube: {error}',
  'video_player_open_youtube': 'Abrir no YouTube',
  'video_player_retry': 'Tentar novamente',
  'video_player_related_videos': 'Vídeos relacionados',
  'video_player_no_related_videos': 'Não há vídeos relacionados no momento.',
  'video_player_like': 'Curtir',
  'video_player_bookmark': 'Marcar',
  'video_player_share': 'Compartilhar',
  'video_player_share_error': 'Erro ao compartilhar: {error}',
  'video_player_related_videos_error': 'Não foi possível carregar vídeos relacionados: {error}',
  'video_player_youtube_loading': 'Carregando vídeo do YouTube...',
  'video_player_player_init_failed': 'Falha na inicialização do reprodutor',
  'video_player_web_player_message':
      'No ambiente web, você precisa reproduzir no reprodutor externo do YouTube.',

  // 비디오 정보 필드 접두사
  'video_title_prefix': 'Título: ',
  'video_id_prefix': 'ID: ',
  'video_platform_prefix': 'Plataforma: ',
  'video_platform_id_prefix': 'ID da plataforma: ',
  'video_url_prefix': 'URL: ',
  'video_description_prefix': 'Descrição: ',

  // 앱 일반 오류 메시지
  'app_error_generic': 'Ocorreu um erro',
  'app_error_network': 'Por favor, verifique sua conexão de rede',
  'app_error_timeout': 'Tempo limite da solicitação esgotado',
  'app_error_launching_url': 'Não foi possível abrir o URL',

  /// Premium Features
  'premium_features': 'Recursos Premium',

  /// Subscription
  'subscription_title': 'Gerenciamento de Assinatura',
  'subscription_restore_progress': 'Restaurando compras...',
  'subscription_restore_success': 'Assinatura restaurada com sucesso',
  'subscription_restore_none': 'Não há assinaturas para restaurar',
  'subscription_restore_failed': 'Falha ao restaurar compras. Por favor, tente novamente',
  'subscription_manage_error': 'Não foi possível abrir a página de gerenciamento de assinatura',
  'subscription_monthly': 'Mensal',
  'subscription_yearly': 'Anual',
  'subscription_free': 'Gratuito',
  'subscription_signup_required': 'Registro Necessário',
  'subscription_signup_required_message':
      'Você precisa se registrar antes de assinar. Gostaria de ir para a página de registro?',
  'subscription_signup': 'Registrar',
  'subscription_limit_title': 'Limite de Visualizações Gratuitas Atingido',
  'subscription_limit_message_guest':
      'Por favor, registre-se para continuar assistindo mais vídeos',
  'subscription_limit_message_user':
      'Você usou todas as suas visualizações gratuitas. Atualize para premium ou assista a um anúncio para continuar',
  'subscription_later': 'Mais tarde',

  /// Subscription Benefits
  'subscription_benefits_title': 'Benefícios da Assinatura Premium',

  /// Premium Banner Title
  'free_views_left': '%s visualizações gratuitas restantes',

  /// Premium Banner Description
  'premium_banner_description':
      'Assine premium para assistir a todos os vídeos sem anúncios, ilimitadamente',

  /// Premium Banner Button
  'premium_banner_button': 'Assinar Agora',

  /// Monthly Price
  'subscription_monthly_price': r'$1,99/mês',

  /// Free trial limit
  'free_trial_limit_reached': 'Você usou todas as suas visualizações gratuitas',

  /// Watch ad to continue
  'watch_ad_to_continue': 'Assistir anúncio para continuar',

  /// Subscribe to continue
  'subscribe_to_continue': 'Assine para assistir sem limites',

  /// Premium benefits
  'premium_benefit_1': 'Visualização ilimitada de vídeos',
  'premium_benefit_2': 'Streaming em qualidade HD',
  'premium_benefit_3': 'Experiência sem anúncios',
  'premium_benefit_4': 'Downloads offline',
  'premium_benefit_5': 'Acesso a conteúdo exclusivo',
  'premium_benefit_6': 'Suporte prioritário ao cliente',

  /// Free tier benefits
  'free_tier_benefit_1': '10 vídeos gratuitos por dia',
  'free_tier_benefit_2': 'Visualização em qualidade padrão',
  'free_tier_benefit_3': 'Capacidade de pesquisa direta',
  'free_tier_benefit_4': 'Navegar por conteúdo popular',

  /// Monthly plan description
  'monthly_plan_description': 'Aproveite benefícios premium com máxima flexibilidade',

  /// Yearly plan description
  'yearly_plan_description': 'Obtenha 2 meses grátis com assinatura anual',

  /// Plan tags
  'most_popular_tag': 'Popular',
  'best_value_tag': 'Melhor Valor',

  /// Ad completed message
  'ad_watch_completed': 'Anúncio concluído. Você pode continuar assistindo ao vídeo.',

  // 건의하기 화면 관련
  'feedback_title': 'Enviar Feedback',
  'feedback_question': 'Você tem algum feedback ou sugestão sobre o aplicativo?',
  'feedback_description': 'Seu valioso feedback nos ajudará a melhorar nosso serviço.',
  'feedback_email': 'Email para Resposta',
  'feedback_email_hint': 'Digite seu endereço de email para receber uma resposta',
  'feedback_email_validation': 'Por favor, digite seu email',
  'feedback_email_invalid': 'Por favor, digite um endereço de email válido',
  'feedback_subject': 'Assunto',
  'feedback_subject_hint': 'Digite o assunto do seu feedback',
  'feedback_subject_validation': 'Por favor, digite um assunto',
  'feedback_content': 'Conteúdo',
  'feedback_content_hint': 'Por favor, descreva seu feedback em detalhes',
  'feedback_content_validation': 'Por favor, digite seu feedback',
  'feedback_content_length': 'Por favor, digite pelo menos 10 caracteres',
  'feedback_send': 'Enviar Feedback',
  'feedback_privacy_notice':
      '* Seu endereço de email será coletado para fins de processamento e resposta de feedback.',

  /// Free Tier
  'free_tier': 'Plano Gratuito',

  /// Premium Tier
  'premium_tier': 'Plano Premium',
};
