const Map<String, String> thTranslations = {
  // 앱 타이틀
  'appTitle': 'Pulse',

  // 공통 텍스트
  'common_retry': 'ลองอีกครั้ง',
  'common_skip': 'ข้าม',
  'common_next': 'ถัดไป',
  'common_start': 'เริ่มต้น',
  'common_cancel': 'ยกเลิก',
  'common_confirm': 'ยืนยัน',
  'common_delete': 'ลบ',
  'common_close': 'ปิด',
  'common_edit': 'แก้ไข',
  'common_save': 'บันทึก',
  'common_error': 'ข้อผิดพลาด',
  'common_success': 'สำเร็จ',
  'common_loading': 'กำลังโหลด...',
  'common_send': 'ส่ง',
  'common_sending': 'กำลังส่ง...',
  'common_refresh': 'รีเฟรช',
  'common_goHome': 'กลับหน้าหลัก',
  'common_exit_app_message': 'กดอีกครั้งเพื่อออก',

  // 내비게이션 바 항목
  'nav_home': 'หน้าหลัก',
  'nav_search': 'ค้นหา',
  'nav_bookmarks': 'บุ๊กมาร์ก',
  'nav_profile': 'โปรไฟล์',

  // 로그인 관련
  'login_title': 'เข้าสู่ระบบ',
  'login_button': 'เข้าสู่ระบบ',
  'login_logout': 'ออกจากระบบ',
  'login_logout_confirm': 'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?',

  // 온보딩 관련
  'onboarding_error': 'เกิดข้อผิดพลาดในการโหลดข้อมูล: {error}',
  'onboarding_welcome': 'ยินดีต้อนรับสู่ Pulse',
  'onboarding_welcome_desc': 'เพลิดเพลินกับเนื้อหาพิเศษที่มีคุณภาพ',
  'onboarding_explore': 'สำรวจเนื้อหา',
  'onboarding_explore_desc': 'ค้นพบวิดีโอพิเศษจากผู้สร้างที่คุณชื่นชอบ',
  'onboarding_bookmark': 'บันทึกรายการโปรด',
  'onboarding_bookmark_desc': 'บุ๊กมาร์กวิดีโอที่คุณชื่นชอบเพื่อดูภายหลัง',

  // 비디오 플레이어 화면 관련
  'video_player_load_error': 'ไม่สามารถโหลดวิดีโอ: {error}',
  'video_player_info_dialog_title': 'ข้อมูลวิดีโอ',
  'video_player_share_subject': 'แชร์วิดีโอ Pulse: {title}',
  'video_player_share_message': 'ดูวิดีโอ "{title}" บนแอป Pulse!\n{url}',
  'video_player_no_description': 'ไม่มีคำอธิบาย',
  'video_player_no_video': 'ไม่พบวิดีโอ',
  'video_player_youtube_error': 'ไม่สามารถโหลดวิดีโอ YouTube: {error}',
  'video_player_need_subscription': 'ต้องการสมัครสมาชิก\nเพื่อดูเนื้อหานี้',
  'video_player_view_subscription': 'ดูข้อมูลการสมัครสมาชิก',
  'video_player_youtube_id_error': 'ไม่สามารถแยก ID YouTube ที่ถูกต้อง',
  'video_player_youtube_init_error': 'การเริ่มต้นเครื่องเล่น YouTube ล้มเหลว: {error}',
  'video_player_open_youtube': 'เปิดใน YouTube',
  'video_player_retry': 'ลองอีกครั้ง',
  'video_player_related_videos': 'วิดีโอที่เกี่ยวข้อง',
  'video_player_no_related_videos': 'ไม่มีวิดีโอที่เกี่ยวข้องในขณะนี้',
  'video_player_like': 'ถูกใจ',
  'video_player_bookmark': 'บุ๊กมาร์ก',
  'video_player_share': 'แชร์',
  'video_player_share_error': 'เกิดข้อผิดพลาดในการแชร์: {error}',
  'video_player_related_videos_error': 'ไม่สามารถโหลดวิดีโอที่เกี่ยวข้อง: {error}',
  'video_player_youtube_loading': 'กำลังโหลดวิดีโอ YouTube...',
  'video_player_player_init_failed': 'การเริ่มต้นเครื่องเล่นล้มเหลว',
  'video_player_web_player_message': 'ในสภาพแวดล้อมเว็บ คุณต้องเล่นในเครื่องเล่น YouTube ภายนอก',

  // 비디오 정보 필드 접두사
  'video_title_prefix': 'ชื่อเรื่อง: ',
  'video_id_prefix': 'ID: ',
  'video_platform_prefix': 'แพลตฟอร์ม: ',
  'video_platform_id_prefix': 'ID แพลตฟอร์ม: ',
  'video_url_prefix': 'URL: ',
  'video_description_prefix': 'คำอธิบาย: ',

  // 앱 일반 오류 메시지
  'app_error_generic': 'เกิดข้อผิดพลาด',
  'app_error_network': 'โปรดตรวจสอบการเชื่อมต่อเครือข่ายของคุณ',
  'app_error_timeout': 'คำขอหมดเวลา',
  'app_error_launching_url': 'ไม่สามารถเปิด URL',

  /// Premium Features
  'premium_features': 'ฟีเจอร์พรีเมียม',

  /// Subscription
  'subscription_title': 'การจัดการสมาชิก',
  'subscription_restore_progress': 'กำลังกู้คืนการซื้อ...',
  'subscription_restore_success': 'กู้คืนการสมัครสมาชิกสำเร็จ',
  'subscription_restore_none': 'ไม่มีการสมัครสมาชิกที่จะกู้คืน',
  'subscription_restore_failed': 'การกู้คืนการซื้อล้มเหลว โปรดลองอีกครั้ง',
  'subscription_manage_error': 'ไม่สามารถเปิดหน้าจัดการการสมัครสมาชิก',
  'subscription_monthly': 'รายเดือน',
  'subscription_yearly': 'รายปี',
  'subscription_free': 'ฟรี',
  'subscription_signup_required': 'ต้องลงทะเบียน',
  'subscription_signup_required_message':
      'คุณต้องลงทะเบียนก่อนสมัครสมาชิก ต้องการไปที่หน้าลงทะเบียนหรือไม่?',
  'subscription_signup': 'ลงทะเบียน',
  'subscription_limit_title': 'ถึงขีดจำกัดการรับชมฟรี',
  'subscription_limit_message_guest': 'โปรดลงทะเบียนเพื่อรับชมวิดีโอต่อ',
  'subscription_limit_message_user':
      'คุณใช้การรับชมฟรีหมดแล้ว อัพเกรดเป็นพรีเมียมหรือดูโฆษณาเพื่อรับชมต่อ',
  'subscription_later': 'ภายหลัง',

  /// Subscription Benefits
  'subscription_benefits_title': 'สิทธิประโยชน์สมาชิกพรีเมียม',

  /// Premium Banner Title
  'free_views_left': 'เหลือการรับชมฟรี %s ครั้ง',

  /// Premium Banner Description
  'premium_banner_description': 'สมัครสมาชิกพรีเมียมเพื่อรับชมวิดีโอทั้งหมดแบบไม่มีโฆษณา ไม่จำกัด',

  /// Premium Banner Button
  'premium_banner_button': 'สมัครเลย',

  /// Monthly Price
  'subscription_monthly_price': r'$1.99/เดือน',

  /// Free trial limit
  'free_trial_limit_reached': 'คุณใช้การรับชมฟรีหมดแล้ว',

  /// Watch ad to continue
  'watch_ad_to_continue': 'รับชมโฆษณาเพื่อรับชมต่อ',

  /// Subscribe to continue
  'subscribe_to_continue': 'สมัครสมาชิกเพื่อรับชมไม่จำกัด',

  /// Premium benefits
  'premium_benefit_1': 'รับชมวิดีโอไม่จำกัด',
  'premium_benefit_2': 'สตรีมมิ่งคุณภาพ HD',
  'premium_benefit_3': 'ประสบการณ์ปราศจากโฆษณา',
  'premium_benefit_4': 'ดาวน์โหลดออฟไลน์',
  'premium_benefit_5': 'เข้าถึงเนื้อหาพิเศษ',
  'premium_benefit_6': 'การสนับสนุนลูกค้าแบบเร่งด่วน',

  /// Free tier benefits
  'free_tier_benefit_1': 'วิดีโอฟรี 10 รายการต่อวัน',
  'free_tier_benefit_2': 'รับชมคุณภาพมาตรฐาน',
  'free_tier_benefit_3': 'ค้นหาได้โดยตรง',
  'free_tier_benefit_4': 'ดูเนื้อหายอดนิยม',

  /// Monthly plan description
  'monthly_plan_description': 'เพลิดเพลินกับสิทธิประโยชน์พรีเมียมด้วยความยืดหยุ่นสูงสุด',

  /// Yearly plan description
  'yearly_plan_description': 'รับฟรี 2 เดือนกับการสมัครสมาชิกรายปี',

  /// Plan tags
  'most_popular_tag': 'ยอดนิยม',
  'best_value_tag': 'คุ้มค่าที่สุด',

  /// Ad completed message
  'ad_watch_completed': 'รับชมโฆษณาเสร็จสิ้น คุณสามารถรับชมวิดีโอต่อได้แล้ว',

  // 건의하기 화면 관련
  'feedback_title': 'ส่งความคิดเห็น',
  'feedback_question': 'คุณมีความคิดเห็นหรือข้อเสนอแนะเกี่ยวกับแอปหรือไม่?',
  'feedback_description': 'ความคิดเห็นที่มีค่าของคุณจะช่วยให้เราปรับปรุงบริการ',
  'feedback_email': 'อีเมลสำหรับตอบกลับ',
  'feedback_email_hint': 'ใส่อีเมลของคุณเพื่อรับการตอบกลับ',
  'feedback_email_validation': 'โปรดใส่อีเมลของคุณ',
  'feedback_email_invalid': 'โปรดใส่อีเมลที่ถูกต้อง',
  'feedback_subject': 'หัวข้อ',
  'feedback_subject_hint': 'ใส่หัวข้อความคิดเห็นของคุณ',
  'feedback_subject_validation': 'โปรดใส่หัวข้อ',
  'feedback_content': 'เนื้อหา',
  'feedback_content_hint': 'โปรดอธิบายความคิดเห็นของคุณโดยละเอียด',
  'feedback_content_validation': 'โปรดใส่ความคิดเห็นของคุณ',
  'feedback_content_length': 'โปรดใส่อย่างน้อย 10 ตัวอักษร',
  'feedback_send': 'ส่งความคิดเห็น',
  'feedback_privacy_notice':
      '* อีเมลของคุณจะถูกเก็บรวบรวมเพื่อวัตถุประสงค์ในการประมวลผลและตอบกลับความคิดเห็น',

  /// Free Tier
  'free_tier': 'แพ็คเกจฟรี',

  /// Premium Tier
  'premium_tier': 'แพ็คเกจพรีเมียม',
};
