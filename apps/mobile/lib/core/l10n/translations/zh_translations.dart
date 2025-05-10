const Map<String, String> zhTranslations = {
  // 앱 타이틀
  'appTitle': 'Pulse',

  // 공통 텍스트
  'common_retry': '重试',
  'common_skip': '跳过',
  'common_next': '下一步',
  'common_start': '开始',
  'common_cancel': '取消',
  'common_confirm': '确认',
  'common_delete': '删除',
  'common_close': '关闭',
  'common_edit': '编辑',
  'common_save': '保存',
  'common_error': '错误',
  'common_success': '成功',
  'common_loading': '加载中...',
  'common_send': '发送',
  'common_sending': '发送中...',
  'common_refresh': '刷新',
  'common_goHome': '返回首页',
  'common_exit_app_message': '再按一次退出应用',

  // 내비게이션 바 항목
  'nav_home': '首页',
  'nav_search': '搜索',
  'nav_bookmarks': '收藏',
  'nav_profile': '个人资料',

  // 로그인 관련
  'login_title': '登录',
  'login_button': '登录',
  'login_logout': '退出登录',
  'login_logout_confirm': '确定要退出登录吗？',

  // 온보딩 관련
  'onboarding_error': '加载数据时出错: {error}',
  'onboarding_welcome': '欢迎使用 Pulse',
  'onboarding_welcome_desc': '享受高质量的独家内容',
  'onboarding_explore': '探索内容',
  'onboarding_explore_desc': '发现你喜爱的创作者的独家视频',
  'onboarding_bookmark': '保存你的收藏',
  'onboarding_bookmark_desc': '标记你喜欢的视频以便稍后观看',

  // 비디오 플레이어 화면 관련
  'video_player_load_error': '无法加载视频: {error}',
  'video_player_info_dialog_title': '视频信息',
  'video_player_share_subject': 'Pulse 视频分享: {title}',
  'video_player_share_message': '在 Pulse 应用上查看视频 "{title}"！\n{url}',
  'video_player_no_description': '无描述',
  'video_player_no_video': '未找到视频',
  'video_player_youtube_error': '无法加载 YouTube 视频: {error}',
  'video_player_need_subscription': '需要订阅\n才能观看此内容',
  'video_player_view_subscription': '查看订阅信息',
  'video_player_youtube_id_error': '无法提取有效的 YouTube ID',
  'video_player_youtube_init_error': 'YouTube 播放器初始化失败: {error}',
  'video_player_open_youtube': '在 YouTube 中打开',
  'video_player_retry': '重试',
  'video_player_related_videos': '相关视频',
  'video_player_no_related_videos': '当前没有相关视频',
  'video_player_like': '点赞',
  'video_player_bookmark': '收藏',
  'video_player_share': '分享',
  'video_player_share_error': '分享时出错: {error}',
  'video_player_related_videos_error': '无法加载相关视频: {error}',
  'video_player_youtube_loading': '正在加载 YouTube 视频...',
  'video_player_player_init_failed': '播放器初始化失败',
  'video_player_web_player_message': '在网页环境中，您需要使用外部 YouTube 播放器播放视频',

  // 비디오 정보 필드 접두사
  'video_title_prefix': '标题: ',
  'video_id_prefix': 'ID: ',
  'video_platform_prefix': '平台: ',
  'video_platform_id_prefix': '平台 ID: ',
  'video_url_prefix': '网址: ',
  'video_description_prefix': '描述: ',

  // 앱 일반 오류 메시지
  'app_error_generic': '发生错误',
  'app_error_network': '请检查您的网络连接',
  'app_error_timeout': '请求超时',
  'app_error_launching_url': '无法打开URL',

  /// Premium Features
  'premium_features': '高级功能',

  /// Subscription
  'subscription_title': '订阅管理',
  'subscription_restore_progress': '正在恢复购买...',
  'subscription_restore_success': '订阅恢复成功',
  'subscription_restore_none': '没有可恢复的订阅',
  'subscription_restore_failed': '恢复购买失败。请重试',
  'subscription_manage_error': '无法打开订阅管理页面',
  'subscription_monthly': '月度',
  'subscription_yearly': '年度',
  'subscription_free': '免费',
  'subscription_signup_required': '需要注册',
  'subscription_signup_required_message': '您需要先注册才能订阅。是否前往注册页面？',
  'subscription_signup': '注册',
  'subscription_limit_title': '已达到免费观看限制',
  'subscription_limit_message_guest': '请注册以继续观看更多视频',
  'subscription_limit_message_user': '您已用完所有免费观看次数。升级到高级会员或观看广告以继续',
  'subscription_later': '稍后',

  /// Subscription Benefits
  'subscription_benefits_title': '高级订阅福利',

  /// Premium Banner Title
  'free_views_left': '剩余%s次免费观看',

  /// Premium Banner Description
  'premium_banner_description': '订阅高级会员，无广告无限观看所有视频',

  /// Premium Banner Button
  'premium_banner_button': '立即订阅',

  /// Monthly Price
  'subscription_monthly_price': r'$1.99/月',

  /// Free trial limit
  'free_trial_limit_reached': '您已用完所有免费观看次数',

  /// Watch ad to continue
  'watch_ad_to_continue': '观看广告以继续',

  /// Subscribe to continue
  'subscribe_to_continue': '订阅以无限观看',

  /// Premium benefits
  'premium_benefit_1': '无限视频观看',
  'premium_benefit_2': '高清画质流媒体',
  'premium_benefit_3': '无广告体验',
  'premium_benefit_4': '离线下载',
  'premium_benefit_5': '访问独家内容',
  'premium_benefit_6': '优先客户支持',

  /// Free tier benefits
  'free_tier_benefit_1': '每天10个免费视频',
  'free_tier_benefit_2': '标准画质观看',
  'free_tier_benefit_3': '直接搜索功能',
  'free_tier_benefit_4': '浏览热门内容',

  /// Monthly plan description
  'monthly_plan_description': '以最大灵活性享受高级福利',

  /// Yearly plan description
  'yearly_plan_description': '年度订阅可获得2个月免费',

  /// Plan tags
  'most_popular_tag': '热门',
  'best_value_tag': '最佳价值',

  /// Ad completed message
  'ad_watch_completed': '广告观看完毕。您现在可以继续观看视频。',

  // 건의하기 화면 관련
  'feedback_title': '发送反馈',
  'feedback_question': '您对应用有任何反馈或建议吗？',
  'feedback_description': '您的宝贵反馈将帮助我们改进服务。',
  'feedback_email': '回复邮箱',
  'feedback_email_hint': '输入您的邮箱地址以接收回复',
  'feedback_email_validation': '请输入您的邮箱',
  'feedback_email_invalid': '请输入有效的邮箱地址',
  'feedback_subject': '主题',
  'feedback_subject_hint': '输入您反馈的主题',
  'feedback_subject_validation': '请输入主题',
  'feedback_content': '内容',
  'feedback_content_hint': '请详细描述您的反馈',
  'feedback_content_validation': '请输入您的反馈',
  'feedback_content_length': '请至少输入10个字符',
  'feedback_send': '发送反馈',
  'feedback_privacy_notice': '* 您的邮箱地址将用于反馈处理和回复目的。',

  /// Free Tier
  'free_tier': '免费计划',

  /// Premium Tier
  'premium_tier': '高级计划',
};
