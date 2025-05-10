const Map<String, String> idTranslations = {
  // 앱 타이틀
  'appTitle': 'Pulse',

  // 공통 텍스트
  'common_retry': 'Coba Lagi',
  'common_skip': 'Lewati',
  'common_next': 'Selanjutnya',
  'common_start': 'Mulai',
  'common_cancel': 'Batal',
  'common_confirm': 'Konfirmasi',
  'common_delete': 'Hapus',
  'common_close': 'Tutup',
  'common_edit': 'Edit',
  'common_save': 'Simpan',
  'common_error': 'Error',
  'common_success': 'Berhasil',
  'common_loading': 'Memuat...',
  'common_send': 'Kirim',
  'common_sending': 'Mengirim...',
  'common_refresh': 'Segarkan',
  'common_goHome': 'Kembali ke Beranda',
  'common_exit_app_message': 'Tekan sekali lagi untuk keluar',

  // 내비게이션 바 항목
  'nav_home': 'Beranda',
  'nav_search': 'Cari',
  'nav_bookmarks': 'Markah',
  'nav_profile': 'Profil',

  // 로그인 관련
  'login_title': 'Masuk',
  'login_button': 'Masuk',
  'login_logout': 'Keluar',
  'login_logout_confirm': 'Apakah Anda yakin ingin keluar?',

  // 온보딩 관련
  'onboarding_error': 'Terjadi kesalahan saat memuat data: {error}',
  'onboarding_welcome': 'Selamat Datang di Pulse',
  'onboarding_welcome_desc': 'Nikmati konten eksklusif berkualitas',
  'onboarding_explore': 'Jelajahi Konten',
  'onboarding_explore_desc': 'Temukan video eksklusif dari kreator favorit Anda',
  'onboarding_bookmark': 'Simpan Favorit Anda',
  'onboarding_bookmark_desc': 'Tandai video favorit Anda untuk ditonton nanti',

  // 비디오 플레이어 화면 관련
  'video_player_load_error': 'Tidak dapat memuat video: {error}',
  'video_player_info_dialog_title': 'Informasi Video',
  'video_player_share_subject': 'Bagikan video Pulse: {title}',
  'video_player_share_message': 'Lihat video "{title}" di aplikasi Pulse!\n{url}',
  'video_player_no_description': 'Tidak ada deskripsi',
  'video_player_no_video': 'Video tidak ditemukan',
  'video_player_youtube_error': 'Tidak dapat memuat video YouTube: {error}',
  'video_player_need_subscription': 'Perlu berlangganan\nuntuk menonton konten ini',
  'video_player_view_subscription': 'Lihat Info Langganan',
  'video_player_youtube_id_error': 'Tidak dapat mengekstrak ID YouTube yang valid',
  'video_player_youtube_init_error': 'Gagal menginisialisasi pemutar YouTube: {error}',
  'video_player_open_youtube': 'Buka di YouTube',
  'video_player_retry': 'Coba Lagi',
  'video_player_related_videos': 'Video Terkait',
  'video_player_no_related_videos': 'Tidak ada video terkait saat ini',
  'video_player_like': 'Suka',
  'video_player_bookmark': 'Markah',
  'video_player_share': 'Bagikan',
  'video_player_share_error': 'Terjadi kesalahan saat berbagi: {error}',
  'video_player_related_videos_error': 'Tidak dapat memuat video terkait: {error}',
  'video_player_youtube_loading': 'Memuat video YouTube...',
  'video_player_player_init_failed': 'Inisialisasi pemutar gagal',
  'video_player_web_player_message':
      'Di lingkungan web, Anda perlu memutar di pemutar YouTube eksternal',

  // 비디오 정보 필드 접두사
  'video_title_prefix': 'Judul: ',
  'video_id_prefix': 'ID: ',
  'video_platform_prefix': 'Platform: ',
  'video_platform_id_prefix': 'ID Platform: ',
  'video_url_prefix': 'URL: ',
  'video_description_prefix': 'Deskripsi: ',

  // 앱 일반 오류 메시지
  'app_error_generic': 'Terjadi kesalahan',
  'app_error_network': 'Silakan periksa koneksi jaringan Anda',
  'app_error_timeout': 'Permintaan waktu habis',
  'app_error_launching_url': 'Tidak dapat membuka URL',

  /// Premium Features
  'premium_features': 'Fitur Premium',

  /// Subscription
  'subscription_title': 'Manajemen Langganan',
  'subscription_restore_progress': 'Memulihkan pembelian...',
  'subscription_restore_success': 'Langganan berhasil dipulihkan',
  'subscription_restore_none': 'Tidak ada langganan untuk dipulihkan',
  'subscription_restore_failed': 'Gagal memulihkan pembelian. Silakan coba lagi',
  'subscription_manage_error': 'Tidak dapat membuka halaman manajemen langganan',
  'subscription_monthly': 'Bulanan',
  'subscription_yearly': 'Tahunan',
  'subscription_free': 'Gratis',
  'subscription_signup_required': 'Pendaftaran Diperlukan',
  'subscription_signup_required_message':
      'Anda perlu mendaftar sebelum berlangganan. Apakah Anda ingin pergi ke halaman pendaftaran?',
  'subscription_signup': 'Mendaftar',
  'subscription_limit_title': 'Batas Tayangan Gratis Tercapai',
  'subscription_limit_message_guest': 'Silakan mendaftar untuk terus menonton lebih banyak video',
  'subscription_limit_message_user':
      'Anda telah menggunakan semua tayangan gratis. Tingkatkan ke premium atau tonton iklan untuk melanjutkan',
  'subscription_later': 'Nanti',

  /// Subscription Benefits
  'subscription_benefits_title': 'Manfaat Langganan Premium',

  /// Premium Banner Title
  'free_views_left': 'Tersisa %s tayangan gratis',

  /// Premium Banner Description
  'premium_banner_description':
      'Berlangganan premium untuk menonton semua video tanpa iklan, tanpa batas',

  /// Premium Banner Button
  'premium_banner_button': 'Berlangganan Sekarang',

  /// Monthly Price
  'subscription_monthly_price': r'$1,99/bulan',

  /// Free trial limit
  'free_trial_limit_reached': 'Anda telah menggunakan semua tayangan gratis',

  /// Watch ad to continue
  'watch_ad_to_continue': 'Tonton iklan untuk melanjutkan',

  /// Subscribe to continue
  'subscribe_to_continue': 'Berlangganan untuk menonton tanpa batas',

  /// Premium benefits
  'premium_benefit_1': 'Menonton video tanpa batas',
  'premium_benefit_2': 'Streaming kualitas HD',
  'premium_benefit_3': 'Pengalaman tanpa iklan',
  'premium_benefit_4': 'Unduhan offline',
  'premium_benefit_5': 'Akses ke konten eksklusif',
  'premium_benefit_6': 'Dukungan pelanggan prioritas',

  /// Free tier benefits
  'free_tier_benefit_1': '10 video gratis per hari',
  'free_tier_benefit_2': 'Menonton kualitas standar',
  'free_tier_benefit_3': 'Kemampuan pencarian langsung',
  'free_tier_benefit_4': 'Jelajahi konten populer',

  /// Monthly plan description
  'monthly_plan_description': 'Nikmati manfaat premium dengan fleksibilitas maksimum',

  /// Yearly plan description
  'yearly_plan_description': 'Dapatkan 2 bulan gratis dengan langganan tahunan',

  /// Plan tags
  'most_popular_tag': 'Populer',
  'best_value_tag': 'Nilai Terbaik',

  /// Ad completed message
  'ad_watch_completed': 'Iklan selesai. Anda sekarang dapat melanjutkan menonton video.',

  // 건의하기 화면 관련
  'feedback_title': 'Kirim Masukan',
  'feedback_question': 'Apakah Anda memiliki masukan atau saran tentang aplikasi?',
  'feedback_description': 'Masukan berharga Anda akan membantu kami meningkatkan layanan kami.',
  'feedback_email': 'Email Balasan',
  'feedback_email_hint': 'Masukkan alamat email Anda untuk menerima balasan',
  'feedback_email_validation': 'Silakan masukkan email Anda',
  'feedback_email_invalid': 'Silakan masukkan alamat email yang valid',
  'feedback_subject': 'Subjek',
  'feedback_subject_hint': 'Masukkan subjek masukan Anda',
  'feedback_subject_validation': 'Silakan masukkan subjek',
  'feedback_content': 'Konten',
  'feedback_content_hint': 'Silakan jelaskan masukan Anda secara detail',
  'feedback_content_validation': 'Silakan masukkan masukan Anda',
  'feedback_content_length': 'Silakan masukkan minimal 10 karakter',
  'feedback_send': 'Kirim Masukan',
  'feedback_privacy_notice':
      '* Alamat email Anda akan dikumpulkan untuk tujuan pemrosesan masukan dan balasan.',

  /// Free Tier
  'free_tier': 'Paket Gratis',

  /// Premium Tier
  'premium_tier': 'Paket Premium',
};
