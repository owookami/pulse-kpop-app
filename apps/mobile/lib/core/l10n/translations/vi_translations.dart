const Map<String, String> viTranslations = {
  // 앱 타이틀
  'appTitle': 'Pulse',

  // 공통 텍스트
  'common_retry': 'Thử lại',
  'common_skip': 'Bỏ qua',
  'common_next': 'Tiếp theo',
  'common_start': 'Bắt đầu',
  'common_cancel': 'Hủy',
  'common_confirm': 'Xác nhận',
  'common_delete': 'Xóa',
  'common_close': 'Đóng',
  'common_edit': 'Chỉnh sửa',
  'common_save': 'Lưu',
  'common_error': 'Lỗi',
  'common_success': 'Thành công',
  'common_loading': 'Đang tải...',
  'common_send': 'Gửi',
  'common_sending': 'Đang gửi...',
  'common_refresh': 'Làm mới',
  'common_goHome': 'Về trang chủ',
  'common_exit_app_message': 'Nhấn lại để thoát',

  // 내비게이션 바 항목
  'nav_home': 'Trang chủ',
  'nav_search': 'Tìm kiếm',
  'nav_bookmarks': 'Đánh dấu',
  'nav_profile': 'Hồ sơ',

  // 로그인 관련
  'login_title': 'Đăng nhập',
  'login_button': 'Đăng nhập',
  'login_logout': 'Đăng xuất',
  'login_logout_confirm': 'Bạn có chắc chắn muốn đăng xuất?',

  // 온보딩 관련
  'onboarding_error': 'Lỗi khi tải dữ liệu: {error}',
  'onboarding_welcome': 'Chào mừng đến với Pulse',
  'onboarding_welcome_desc': 'Tận hưởng nội dung độc quyền chất lượng cao',
  'onboarding_explore': 'Khám phá nội dung',
  'onboarding_explore_desc':
      'Khám phá các video độc quyền từ những người sáng tạo yêu thích của bạn',
  'onboarding_bookmark': 'Lưu mục yêu thích',
  'onboarding_bookmark_desc': 'Đánh dấu video yêu thích để xem sau',

  // 비디오 플레이어 화면 관련
  'video_player_load_error': 'Không thể tải video: {error}',
  'video_player_info_dialog_title': 'Thông tin video',
  'video_player_share_subject': 'Chia sẻ video Pulse: {title}',
  'video_player_share_message': 'Xem video "{title}" trên ứng dụng Pulse!\n{url}',
  'video_player_no_description': 'Không có mô tả',
  'video_player_no_video': 'Không tìm thấy video',
  'video_player_youtube_error': 'Không thể tải video YouTube: {error}',
  'video_player_need_subscription': 'Cần đăng ký\nđể xem nội dung này',
  'video_player_view_subscription': 'Xem thông tin đăng ký',
  'video_player_youtube_id_error': 'Không thể trích xuất ID YouTube hợp lệ',
  'video_player_youtube_init_error': 'Khởi tạo trình phát YouTube thất bại: {error}',
  'video_player_open_youtube': 'Mở trong YouTube',
  'video_player_retry': 'Thử lại',
  'video_player_related_videos': 'Video liên quan',
  'video_player_no_related_videos': 'Hiện không có video liên quan',
  'video_player_like': 'Thích',
  'video_player_bookmark': 'Đánh dấu',
  'video_player_share': 'Chia sẻ',
  'video_player_share_error': 'Lỗi khi chia sẻ: {error}',
  'video_player_related_videos_error': 'Không thể tải video liên quan: {error}',
  'video_player_youtube_loading': 'Đang tải video YouTube...',
  'video_player_player_init_failed': 'Khởi tạo trình phát thất bại',
  'video_player_web_player_message':
      'Trong môi trường web, bạn cần phát trong trình phát YouTube bên ngoài',

  // 비디오 정보 필드 접두사
  'video_title_prefix': 'Tiêu đề: ',
  'video_id_prefix': 'ID: ',
  'video_platform_prefix': 'Nền tảng: ',
  'video_platform_id_prefix': 'ID nền tảng: ',
  'video_url_prefix': 'URL: ',
  'video_description_prefix': 'Mô tả: ',

  // 앱 일반 오류 메시지
  'app_error_generic': 'Đã xảy ra lỗi',
  'app_error_network': 'Vui lòng kiểm tra kết nối mạng của bạn',
  'app_error_timeout': 'Yêu cầu đã hết thời gian chờ',
  'app_error_launching_url': 'Không thể mở URL',

  /// Premium Features
  'premium_features': 'Tính năng Cao cấp',

  /// Subscription
  'subscription_title': 'Quản lý Đăng ký',
  'subscription_restore_progress': 'Đang khôi phục mua hàng...',
  'subscription_restore_success': 'Đã khôi phục đăng ký thành công',
  'subscription_restore_none': 'Không có đăng ký nào để khôi phục',
  'subscription_restore_failed': 'Không thể khôi phục mua hàng. Vui lòng thử lại',
  'subscription_manage_error': 'Không thể mở trang quản lý đăng ký',
  'subscription_monthly': 'Hàng tháng',
  'subscription_yearly': 'Hàng năm',
  'subscription_free': 'Miễn phí',
  'subscription_signup_required': 'Yêu cầu Đăng ký',
  'subscription_signup_required_message':
      'Bạn cần đăng ký trước khi đăng ký gói. Bạn có muốn đến trang đăng ký không?',
  'subscription_signup': 'Đăng ký',
  'subscription_limit_title': 'Đã đạt đến giới hạn xem miễn phí',
  'subscription_limit_message_guest': 'Vui lòng đăng ký để tiếp tục xem thêm video',
  'subscription_limit_message_user':
      'Bạn đã sử dụng hết lượt xem miễn phí. Nâng cấp lên phiên bản cao cấp hoặc xem quảng cáo để tiếp tục',
  'subscription_later': 'Để sau',

  /// Subscription Benefits
  'subscription_benefits_title': 'Quyền lợi Đăng ký Cao cấp',

  /// Premium Banner Title
  'free_views_left': 'Còn %s lượt xem miễn phí',

  /// Premium Banner Description
  'premium_banner_description':
      'Đăng ký cao cấp để xem tất cả video không có quảng cáo, không giới hạn',

  /// Premium Banner Button
  'premium_banner_button': 'Đăng ký ngay',

  /// Monthly Price
  'subscription_monthly_price': r'$1.99/tháng',

  /// Free trial limit
  'free_trial_limit_reached': 'Bạn đã sử dụng hết lượt xem miễn phí',

  /// Watch ad to continue
  'watch_ad_to_continue': 'Xem quảng cáo để tiếp tục',

  /// Subscribe to continue
  'subscribe_to_continue': 'Đăng ký để xem không giới hạn',

  /// Premium benefits
  'premium_benefit_1': 'Xem video không giới hạn',
  'premium_benefit_2': 'Phát trực tuyến chất lượng HD',
  'premium_benefit_3': 'Trải nghiệm không quảng cáo',
  'premium_benefit_4': 'Tải xuống ngoại tuyến',
  'premium_benefit_5': 'Truy cập nội dung độc quyền',
  'premium_benefit_6': 'Hỗ trợ khách hàng ưu tiên',

  /// Free tier benefits
  'free_tier_benefit_1': '10 video miễn phí mỗi ngày',
  'free_tier_benefit_2': 'Xem chất lượng tiêu chuẩn',
  'free_tier_benefit_3': 'Khả năng tìm kiếm trực tiếp',
  'free_tier_benefit_4': 'Duyệt nội dung phổ biến',

  /// Monthly plan description
  'monthly_plan_description': 'Tận hưởng quyền lợi cao cấp với độ linh hoạt tối đa',

  /// Yearly plan description
  'yearly_plan_description': 'Nhận 2 tháng miễn phí với đăng ký hàng năm',

  /// Plan tags
  'most_popular_tag': 'Phổ biến',
  'best_value_tag': 'Giá trị nhất',

  /// Ad completed message
  'ad_watch_completed': 'Đã hoàn thành quảng cáo. Bạn có thể tiếp tục xem video.',

  // 건의하기 화면 관련
  'feedback_title': 'Gửi Phản hồi',
  'feedback_question': 'Bạn có phản hồi hoặc đề xuất nào về ứng dụng không?',
  'feedback_description': 'Phản hồi quý báu của bạn sẽ giúp chúng tôi cải thiện dịch vụ.',
  'feedback_email': 'Email phản hồi',
  'feedback_email_hint': 'Nhập địa chỉ email của bạn để nhận phản hồi',
  'feedback_email_validation': 'Vui lòng nhập email của bạn',
  'feedback_email_invalid': 'Vui lòng nhập địa chỉ email hợp lệ',
  'feedback_subject': 'Chủ đề',
  'feedback_subject_hint': 'Nhập chủ đề phản hồi của bạn',
  'feedback_subject_validation': 'Vui lòng nhập chủ đề',
  'feedback_content': 'Nội dung',
  'feedback_content_hint': 'Vui lòng mô tả chi tiết phản hồi của bạn',
  'feedback_content_validation': 'Vui lòng nhập phản hồi của bạn',
  'feedback_content_length': 'Vui lòng nhập ít nhất 10 ký tự',
  'feedback_send': 'Gửi phản hồi',
  'feedback_privacy_notice':
      '* Địa chỉ email của bạn sẽ được thu thập cho mục đích xử lý phản hồi và trả lời.',

  /// Free Tier
  'free_tier': 'Gói miễn phí',

  /// Premium Tier
  'premium_tier': 'Gói cao cấp',
};
