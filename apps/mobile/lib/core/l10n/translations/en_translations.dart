/// 영어 번역 맵
final Map<String, String> enTranslations = {
  'appTitle': 'Pulse - K-POP Fancams',

  // 공통 텍스트
  'common_retry': 'Retry',
  'common_skip': 'Skip',
  'common_next': 'Next',
  'common_start': 'Start',
  'common_cancel': 'Cancel',
  'common_confirm': 'Confirm',
  'common_delete': 'Delete',
  'common_close': 'Close',
  'common_edit': 'Edit',
  'common_save': 'Save',
  'common_error': 'Error',
  'common_success': 'Success',
  'common_loading': 'Loading...',
  'common_send': 'Send',
  'common_sending': 'Sending...',
  'common_refresh': 'Refresh',
  'common_goHome': 'Go to Home',
  'common_exit_app_message': 'Press back again to exit',

  // 동적 변수 예제
  'dynamic_greeting': 'Hello, {name}! Today is {date}.',
  'dynamic_video_stats': 'This video has been played {views} times and received {likes} likes.',
  'dynamic_user_info':
      'User {username} has watched {videoCount} videos and follows {followCount} artists.',
  'dynamic_complex':
      '{artist}\'s "{title}" video was uploaded on {uploadDate} and has been played {viewCount} times so far. Category: {category}.',

  // 내비게이션 바 항목
  'nav_home': 'Home',
  'nav_search': 'Search',
  'nav_bookmarks': 'Bookmarks',
  'nav_profile': 'Profile',

  // 로그인 관련
  'login_title': 'Login',
  'login_button': 'Login',
  'login_logout': 'Logout',
  'login_logout_confirm': 'Are you sure you want to log out?',

  // 온보딩 관련
  'onboarding_error': 'An error occurred while completing onboarding: {error}',
  'onboarding_welcome': 'Welcome to Pulse',
  'onboarding_welcome_desc':
      'Pulse is the ultimate app for K-POP fancams. Discover the latest videos of your favorite artists.',
  'onboarding_explore': 'Explore Latest Fancams',
  'onboarding_explore_desc':
      'Check out the latest popular fancams and trending videos, never miss new content from your favorite artists.',
  'onboarding_bookmark': 'Bookmark and Save',
  'onboarding_bookmark_desc':
      'Bookmark and save your favorite fancams to watch them anytime later.',
  'onboarding_ready': 'Ready to Start?',
  'onboarding_ready_desc': 'Now enjoy all features of Pulse!',
  'onboarding_welcome_title': 'Welcome to Pulse',
  'onboarding_welcome_description':
      'Your ultimate destination for K-POP fancams and exclusive content',
  'onboarding_videos_title': 'Discover Amazing Videos',
  'onboarding_videos_description':
      'Watch HD fancams of your favorite K-POP idols anytime, anywhere',
  'onboarding_community_title': 'Join Our Community',
  'onboarding_community_description':
      'Connect with other fans, share your favorite moments, and stay updated',
  'skip': 'Skip',
  'get_started': 'Get Started',
  'next': 'Next',

  // 프로필 관련
  'profile_title': 'My Profile',
  'profile_feedback': 'Send Feedback',
  'profile_feedback_email_success': 'Email app opened. Please complete sending.',
  'profile_feedback_email_error': 'Could not open email app. Please check your settings.',
  'profile_feedback_error': 'An error occurred: {error}',
  'profile_feedback_send': 'Send Feedback',
  'profile_content_activity': 'Content & Activity',
  'profile_followed_artists': 'Followed Artists',
  'profile_saved_videos': 'Saved Videos',
  'profile_account_management': 'Account Management',
  'profile_edit_profile': 'Edit Profile',
  'profile_notification_settings': 'Notification Settings',
  'profile_feedback_subtitle': 'Send your suggestions for app improvement',
  'profile_subscription': 'Manage Subscription',
  'profile_premium_active': 'Premium membership active',
  'profile_premium_upgrade': 'Upgrade to Premium',
  'profile_deactivate_subtitle': 'Delete account and all data',
  'profile_app_info': 'App Information',
  'profile_app_info_title': 'App Information',
  'profile_terms': 'Terms of Service',
  'profile_privacy_policy': 'Privacy Policy',
  'profile_login_required': 'Login Required',
  'profile_login_description': 'Login to view your profile information and activity history.',
  'profile_stat_bookmarks': 'Bookmarks',
  'profile_stat_likes': 'Likes',
  'profile_stat_comments': 'Comments',
  'profile_badge_active': 'Active',

  // 회원 탈퇴 관련
  'deactivate_title': 'Delete Account',
  'deactivate_button': 'Delete Account',
  'deactivate_confirm_title': 'Final Confirmation',
  'deactivate_confirm_message':
      'Deleting your account will permanently remove all your data. Are you sure you want to continue?',
  'deactivate_success_title': 'Account Deleted',
  'deactivate_success_message': 'Your account has been successfully deleted.',

  // 구독 관련
  'subscription_title': 'Subscription Management',
  'subscription_manage': 'Manage Subscription',
  'subscription_type': 'Subscription Type: {type}',
  'subscription_expiry': 'Expiry Date: {date}',
  'subscription_unlimited': 'You can watch all content without limitations.',
  'subscription_free_count': 'Free Views Remaining: {count}',
  'subscription_premium_promo': 'Subscribe to Premium to enjoy unlimited access to all content!',
  'subscription_no_products': 'No subscription products available.',
  'subscription_subscribe': 'Subscribe',
  'subscription_restore': 'Restore Purchase',
  'subscription_manage_subscription': 'Manage Subscription',
  'subscription_already': 'You\'re already subscribed.',
  'subscription_in_progress': 'Subscription in progress...',
  'subscription_completed': 'Subscription completed successfully.',
  'subscription_failed': 'Subscription failed. Please try again.',
  'subscription_restore_progress': 'Restoring purchases...',
  'subscription_restore_success': 'Subscription restored successfully.',
  'subscription_restore_none': 'No subscriptions to restore.',
  'subscription_restore_failed': 'Failed to restore purchases. Please try again.',
  'subscription_manage_error': 'Could not open subscription management page.',
  'subscription_monthly': 'Monthly',
  'subscription_yearly': 'Yearly',
  'subscription_free': 'Free',
  'subscription_signup_required': 'Sign Up Required',
  'subscription_signup_required_message':
      'You need to sign up before subscribing. Would you like to go to the sign-up page?',
  'subscription_signup': 'Sign Up',
  'subscription_limit_title': 'Free View Limit Reached',
  'subscription_limit_message_guest': 'Please sign up to continue watching more videos.',
  'subscription_limit_message_user':
      'You have used all your free views. Upgrade to premium or watch an ad to continue.',
  'subscription_later': 'Later',

  // 비디오 관련
  'video_error': 'Could not load video: {error}',
  'video_info': 'Video Information',
  'video_title': 'Title: {title}',
  'video_id': 'ID: {id}',
  'video_platform': 'Platform: {platform}',
  'video_platform_id': 'Platform ID: {id}',
  'video_url': 'URL: {url}',
  'video_description': 'Description: {description}',
  'video_not_found': 'Video not found.',
  'video_view_subscription': 'View Subscription',
  'video_related_error': 'Could not load related videos: {error}',
  'video_youtube_loading': 'Loading YouTube video...',
  'video_open_youtube': 'Open in YouTube',
  'video_no_thumbnail': 'No thumbnail',

  // 아티스트 관련
  'artist_not_found': 'Artist information not found',
  'artist_filter_all': 'All',
  'artist_filter_stage': 'Stage',
  'artist_filter_practice': 'Practice',
  'artist_filter_behind': 'Behind',
  'artist_sort_newest': 'Newest',
  'artist_sort_oldest': 'Oldest',
  'artist_sort_popularity': 'Popular',

  // 언어 설정
  'language_settings': 'Language Settings',
  'language_current': 'Current Language: {language}',

  // 이용약관 관련
  'terms_definition_title': 'Article 2 (Definitions)',
  'terms_definition_content':
      '① "Service" refers to all services provided by the company.\n② "User" refers to members and non-members who access the company\'s service and receive services provided by the company in accordance with these terms.\n③ "Member" refers to a person who has registered as a member by providing personal information to the company, continuously receives information from the company, and can continuously use the services provided by the company.\n④ "Non-member" refers to a person who uses the services provided by the company without registering as a member.',
  'terms_posting_title': 'Article 3 (Posting and Revision of Terms)',
  'terms_posting_content':
      '① The company posts the contents of these terms on the initial screen of the service so that users can easily understand them.\n② The company may revise these terms if necessary within the scope that does not violate relevant laws.\n③ When the company revises the terms, it will specify the application date and reasons for revision, and announce them on the initial screen of the service along with the current terms from 7 days before the application date until the day before the application date.',
  'terms_service_title': 'Article 4 (Provision and Change of Services)',

  // 개인정보 처리방침 관련
  'privacy_security_title': 'Security Measures for Personal Information',
  'privacy_security_content':
      'The company takes the following technical/administrative and physical measures necessary to ensure security in accordance with Article 29 of the Personal Information Protection Act.\n\n① Encryption of personal information\nUsers\' personal information and passwords are encrypted and stored and managed, so only the user can know them, and important data is encrypted or uses separate security functions such as file encryption and transmission data encryption or file locking.\n\n② Technical measures against hacking\nThe company installs security programs and regularly updates and checks them to prevent personal information leakage and damage from hacking or computer viruses, and installs systems in areas where access from outside is controlled and technically/physically monitors and blocks them.',

  // 검색 화면 관련
  'search_title': 'Search',
  'search_discover': 'Discover',
  'search_hint': 'Search for artists, groups, events, etc.',
  'search_filter_all': 'All',
  'search_filter_video': 'Videos',
  'search_filter_artist': 'Artists',
  'search_sort_relevance': 'Relevance',
  'search_sort_latest': 'Latest',
  'search_sort_popularity': 'Popularity',
  'search_recent': 'Recent Searches',
  'search_clear_all': 'Clear All',
  'search_popular': 'Popular Searches',
  'search_no_results': 'No search results found',
  'search_try_another': 'Try another search term',
  'search_category_artist': 'Artists',
  'search_category_video': 'Videos',

  // 발견 화면 관련
  'discover_title': 'Discover',
  'discover_popular_artists': 'Popular Artists',
  'discover_trending_fancams': 'Trending Fancams',
  'discover_recent_fancams': 'Recent Fancams',
  'discover_popular_by_group': 'Popular Videos by Group',
  'discover_view_more': 'View More',

  // 로그인 화면 관련
  'login_app_subtitle': 'All your favorite K-POP fancams in one place',
  'login_email': 'Email',
  'login_email_hint': 'example@email.com',
  'login_password': 'Password',
  'login_password_hint': 'Enter your password',
  'login_remember_me': 'Remember Me',
  'login_forgot_password': 'Forgot Password',
  'login_or_divider': 'OR',
  'login_signup_prompt': 'Don\'t have an account?',
  'login_signup_button': 'Sign Up',
  'login_validation_email_required': 'Please enter your email',
  'login_validation_email_invalid': 'Please enter a valid email address',
  'login_validation_password_required': 'Please enter your password',
  'login_validation_password_length': 'Password must be at least 6 characters',
  'login_error_invalid_credentials': 'Invalid email or password',
  'login_error_email_not_confirmed': 'Email not confirmed. Please check your email',
  'login_error_network': 'Please check your network connection',
  'login_error_unknown': 'An unknown error occurred',

  // 피드 화면 관련
  'feed_title': 'Pulse',
  'feed_tab_popular': 'Popular',
  'feed_tab_latest': 'Latest',
  'feed_offline_mode': 'Offline Mode',
  'feed_free_views_remaining': '{count} free views remaining (out of {total})',
  'feed_premium_promo': 'Subscribe to Premium for unlimited access to all content',
  'feed_unlimited_access': 'Get Unlimited Access',
  'feed_error_message': 'An error occurred: {error}',
  'feed_retry': 'Retry',
  'trendingTab': 'Trending',
  'latestTab': 'Latest',
  'favoritesTab': 'Favorites',
  'refreshButton': 'Refresh',
  'tryAgainButton': 'Try Again',

  // 북마크 화면 관련
  'bookmarks_title': 'Bookmarks',
  'bookmarks_refresh': 'Refresh',
  'bookmarks_collection_management': 'Manage Collections',
  'bookmarks_videos_tab': 'Bookmarked Videos',
  'bookmarks_collections_tab': 'Collections',
  'bookmarks_new_collection': 'New Collection',
  'bookmarks_collection_name': 'Collection Name',
  'bookmarks_collection_desc': 'Description (Optional)',
  'bookmarks_collection_public': 'Public Collection',
  'bookmarks_collection_public_desc': 'Allow other users to view this collection',
  'bookmarks_cancel': 'Cancel',
  'bookmarks_create': 'Create',
  'bookmarks_name_required': 'Please enter a collection name',
  'bookmarks_empty_title': 'No Bookmarks',
  'bookmarks_empty_desc': 'Add bookmarks while watching videos',
  'bookmarks_go_home': 'Go Home',
  'bookmarks_error_title': 'Error Occurred',
  'bookmarks_retry': 'Retry',
  'bookmarks_view_count': '{count} views',
  'bookmarks_collection_empty_title': 'Empty Collection',
  'bookmarks_collection_empty_desc': 'Add videos to your collection',
  'bookmarks_create_collection': 'Create Collection',

  // 프로필 기본 정보 관련
  'profile_stat_count': '{count}',
  'profile_username_default': 'User',
  'profile_email_login_required': 'Login required',
  'profile_settings': 'Settings',
  'profile_bio': 'Bio',

  // 추가 프로필 설정 정보
  'profile_settings_title': 'Settings',
  'profile_app_lang': 'App Language',
  'profile_theme': 'Theme',
  'profile_theme_light': 'Light',
  'profile_theme_dark': 'Dark',
  'profile_theme_system': 'System Default',
  'profile_notifications': 'Notifications',
  'profile_autoplay': 'Autoplay',
  'profile_quality': 'Video Quality',
  'profile_quality_auto': 'Auto',
  'profile_quality_high': 'High',
  'profile_quality_medium': 'Medium',
  'profile_quality_low': 'Low',
  'profile_data_usage': 'Data Usage',
  'profile_data_wifi_only': 'Only load videos on Wi-Fi',
  'profile_cache': 'Cache Management',
  'profile_clear_cache': 'Clear Cache',
  'profile_cache_confirm': 'Clear Cache?',
  'profile_cache_confirm_desc':
      'This will remove temporarily stored videos and images. It frees up space but may take longer to load content next time.',
  'profile_cache_size': 'Current cache size: {size}',
  'profile_cache_cleared': 'Cache cleared',

  // 건의하기 화면 관련
  'feedback_title': 'Send Feedback',
  'feedback_question': 'Do you have any feedback or suggestions about the app?',
  'feedback_description': 'Your valuable feedback will help us improve our service.',
  'feedback_email': 'Reply Email',
  'feedback_email_hint': 'Enter your email address to receive a reply',
  'feedback_email_validation': 'Please enter your email',
  'feedback_email_invalid': 'Please enter a valid email address',
  'feedback_subject': 'Subject',
  'feedback_subject_hint': 'Enter the subject of your feedback',
  'feedback_subject_validation': 'Please enter a subject',
  'feedback_content': 'Content',
  'feedback_content_hint': 'Please describe your feedback in detail',
  'feedback_content_validation': 'Please enter your feedback',
  'feedback_content_length': 'Please enter at least 10 characters',
  'feedback_send': 'Send Feedback',
  'feedback_privacy_notice':
      '* Your email address will be collected for feedback processing and reply purposes.',

  // 구독관리 화면 관련
  'subscription_login_required_card': 'Login required for subscription management',
  'subscription_login_button': 'Login',
  'subscription_available_products': 'Available Subscription Plans',
  'subscription_no_products_available': 'No subscription plans currently available.',
  'subscription_loading_products': 'Loading subscription plans...',
  'subscription_error_loading': 'Error loading subscription information: ',
  'subscription_restore_purchase': 'Restore Purchases',
  'subscription_status_active': 'Active Subscription',
  'subscription_status_type': 'Subscription Type',
  'subscription_status_until': 'Subscription Period',
  'subscription_unlimited_access': 'Unlimited access to all content',
  'subscription_expired': 'Expired',
  'subscription_expires_on': 'Expires on {date}',
  'subscription_cancel_info': 'Subscription will automatically renew at the end of the period.',
  'subscription_manage_button': 'Manage Subscription',
  'subscription_free_tier': 'Free Plan',
  'subscription_free_remaining': 'Free views remaining: {count}',
  'subscription_upgrade_prompt': 'Upgrade to Premium for unlimited access',
  'subscription_upgrade_button': 'Upgrade',
  'subscription_product_monthly': 'Monthly Subscription',
  'subscription_product_yearly': 'Annual Subscription',
  'subscription_product_monthly_description': 'Premium subscription that renews monthly',
  'subscription_product_yearly_description': 'Save more with an annual subscription',
  'subscription_subscribe_button': 'Subscribe',
  'subscription_confirm_title': 'Confirm Subscription',
  'subscription_confirm_message':
      'Would you like to start {type} subscription? You will be charged {price}.',
  'subscription_confirm_recur_message':
      'This subscription will automatically renew until canceled.',
  'subscription_confirm_button': 'Subscribe',
  'subscription_success_title': 'Subscription Complete',
  'subscription_success_message': 'Your subscription has been successfully completed.',
  'subscription_error_title': 'Subscription Error',
  'subscription_error_message': 'An error occurred during subscription: ',
  'subscription_restore_message': 'Restoring purchases...',
  'subscription_restore_success': 'Subscription restored successfully.',
  'subscription_restore_none': 'No subscriptions to restore.',
  'subscription_restore_error': 'Failed to restore purchases. Please try again.',

  // 회원 탈퇴 화면 관련
  'deactivate_warning': '⚠️ Warning',
  'deactivate_warning_message':
      'All of the following information will be permanently deleted when you delete your account:',
  'deactivate_warning_profile': 'Profile information',
  'deactivate_warning_bookmarks': 'Bookmarked videos',
  'deactivate_warning_activity': 'Likes and comments history',
  'deactivate_warning_artists': 'Followed artists information',
  'deactivate_warning_subscription':
      'Subscription information (separate cancellation required for paid subscriptions)',
  'deactivate_confirm_checkbox': 'I understand and agree to delete my account.',
  'deactivate_cancel': 'Cancel',

  // 앱 정보 화면 관련
  'app_info_version': 'Version {version} (Build {build})',
  'app_info_introduction': 'App Introduction',
  'app_info_introduction_content':
      'Pulse is a platform where you can browse and share fancam videos of K-POP artists. Easily find, save, and rate videos of your favorite artists.',
  'app_info_developer': 'Developer Information',
  'app_info_developer_content': '© 2023 Pulse Team\nAll rights reserved',
  'app_info_technical': 'Technical Information',
  'app_info_technical_content':
      'This app is developed with Flutter framework and uses Supabase as the backend.',
  'app_info_opensource': 'Open Source Licenses',
  'app_info_customer_support': 'Customer Support',

  // 이용약관 화면 관련
  'terms_intro_title': 'Article 1 (Purpose)',
  'terms_intro_content':
      'These terms and conditions aim to regulate the rights, obligations, and responsibilities between Pulse (hereinafter referred to as the "Company") and users regarding the use of services provided by the Company, along with other necessary matters.',
  'terms_membership_title': 'Article 5 (Formation of Service Use Contract)',
  'terms_membership_content':
      '① The service use contract is concluded when the user agrees to the terms and conditions, enters member information according to the registration form specified by the company, makes a use request, and the company accepts such request.\n② The company may not accept use applications in the following cases:\n 1. When service provision is technically impossible\n 2. When not using a real name or using someone else\'s name\n 3. When providing false information or not providing information required by the company\n 4. When the user is under 14 years of age\n 5. When deemed necessary by the company based on reasonable judgment',

  // 개인정보 화면 관련
  'privacy_intro':
      'Pulse (hereinafter referred to as the "Company") has established the following privacy policy to protect users\' personal information and rights in accordance with the Personal Information Protection Act and to handle user complaints related to personal information smoothly.',
  'privacy_purpose_title': '1. Purpose of Processing Personal Information',
  'privacy_purpose_content':
      'The company processes personal information for the following purposes. The personal information being processed will not be used for purposes other than the following, and if the purpose of use changes, necessary measures such as obtaining separate consent will be taken in accordance with Article 18 of the Personal Information Protection Act.\n\n① Member registration and management\nPersonal information is processed for the purpose of confirming membership registration intention, identification and authentication for providing membership services, maintaining and managing membership qualifications, preventing service misuse, and various notices.\n\n② Service provision\nPersonal information is processed for the purpose of providing content, providing customized services, and managing service usage records.',
  'privacy_retention_title': '2. Processing and Retention Period of Personal Information',
  'privacy_retention_content':
      '① The company processes and retains personal information within the retention and use period of personal information according to laws or the personal information retention and use period agreed upon when collecting personal information from the data subject.\n\n② The processing and retention periods for each type of personal information are as follows:\n- Member registration and management: Until membership withdrawal\n- However, in the following cases, until the end of the relevant reason:\n 1) When investigation or inquiry is in progress due to violation of relevant laws, until the end of such investigation or inquiry\n 2) When credit and debt relationships from service use remain, until the settlement of such credit and debt relationships',
  'privacy_thirdparty_title': '3. Provision of Personal Information to Third Parties',
  'privacy_thirdparty_content':
      'The company provides personal information to third parties only in cases falling under Article 17 and Article 18 of the Personal Information Protection Act, such as the consent of the data subject or special provisions of the law.',
  'privacy_rights_title':
      '4. Rights and Obligations of Data Subjects and Legal Representatives and How to Exercise Them',
  'privacy_rights_content':
      '① The data subject may exercise rights such as viewing, correcting, deleting, or requesting suspension of processing of personal information to the company at any time.\n② The exercise of rights under paragraph 1 may be made to the company in writing, email, fax, etc. in accordance with Article 41(1) of the Enforcement Decree of the Personal Information Protection Act, and the company will take action without delay.\n③ The exercise of rights under paragraph 1 may be made through a legal representative of the data subject or a delegate such as a person who has been delegated. In this case, you must submit a power of attorney according to Form No. 11 of the Enforcement Rules of the Personal Information Protection Act.\n④ The right to view personal information and request suspension of processing may be restricted according to Article 35, Paragraph 4 and Article 37, Paragraph 2 of the Personal Information Protection Act.\n⑤ Requests for correction and deletion of personal information cannot be requested to delete if the personal information is specified as a collection target in other laws.',

  // 스플래시 화면 관련
  'splash_app_name': 'Pulse',
  'splash_app_description': 'K-POP Fancam Platform',

  // 컬렉션 관리 화면 관련
  'collection_management_title': 'Collection Management',
  'collection_management_new': 'New Collection',
  'collection_management_empty': 'No collections found.',
  'collection_management_empty_description': 'Manage your bookmarked videos with collections.',
  'collection_management_create': 'Create Collection',
  'collection_management_create_title': 'Create New Collection',
  'collection_management_name': 'Collection Name',
  'collection_management_name_hint': 'Enter new collection name',
  'collection_management_description': 'Description (Optional)',
  'collection_management_description_hint': 'Enter description for the collection',
  'collection_management_create_button': 'Create',
  'collection_management_cancel': 'Cancel',
  'collection_management_delete_title': 'Delete Collection',
  'collection_management_delete_message':
      'Are you sure you want to delete \'{{name}}\' collection?',
  'collection_management_delete_button': 'Delete',
  'collection_management_error': 'An error occurred while loading collections.',

  // 비디오 플레이어 화면 관련
  'video_player_load_error': 'Could not load video: {error}',
  'video_player_info_dialog_title': 'Video Information',
  'video_player_share_subject': 'Pulse video share: {title}',
  'video_player_share_message': 'All FanCam videos are available on the Pulse app!\n{url}',
  'video_player_no_description': 'No description',
  'video_player_no_video': 'Video not found.',
  'video_player_youtube_error': 'Could not load YouTube video: {error}',
  'video_player_need_subscription': 'Subscription required\nto watch this content',
  'video_player_view_subscription': 'View Subscription Info',
  'video_player_youtube_id_error': 'Could not extract a valid YouTube ID.',
  'video_player_youtube_init_error': 'YouTube player initialization failed: {error}',
  'video_player_open_youtube': 'Open in YouTube',
  'video_player_retry': 'Retry',
  'video_player_related_videos': 'Related Videos',
  'video_player_no_related_videos': 'No related videos available.',
  'video_player_like': 'Like',
  'video_player_bookmark': 'Bookmark',
  'video_player_share': 'Share',
  'video_player_share_error': 'An error occurred while sharing: {error}',
  'video_player_related_videos_error': 'Could not load related videos: {error}',
  'video_player_youtube_loading': 'Loading YouTube video...',
  'video_player_player_init_failed': 'Player initialization failed',
  'video_player_web_player_message':
      'In web environment, you need to play videos in external YouTube player.',
  'video_player_error_icon': 'Error',
  'video_player_loading': 'Loading...',
  'video_player_back': 'Back',
  'video_player_no_data': 'No data',
  'video_player_mute': 'Mute',
  'video_player_unmute': 'Unmute',
  'video_player_play': 'Play',
  'video_player_pause': 'Pause',
  'video_player_progress': 'Video progress',
  'video_player_fullscreen': 'Fullscreen',
  'video_player_exit_fullscreen': 'Exit fullscreen',
  'video_player_playback_speed': 'Playback speed',
  'video_player_normal_speed': 'Normal',

  // 비디오 정보 필드 접두사
  'video_title_prefix': 'Title: ',
  'video_id_prefix': 'ID: ',
  'video_platform_prefix': 'Platform: ',
  'video_platform_id_prefix': 'Platform ID: ',
  'video_url_prefix': 'URL: ',
  'video_description_prefix': 'Description: ',

  // 숫자 포맷 접미사
  'count_thousand_suffix': 'K',
  'count_million_suffix': 'M',

  // 앱 일반 오류 메시지
  'app_error_generic': 'An error has occurred',
  'app_error_network': 'Please check your network connection',
  'app_error_timeout': 'Request timed out',
  'app_error_launching_url': 'Could not open URL',

  /// Premium Features
  'premium_features': 'Premium Features',

  /// Subscription
  'subscription_title': 'Subscription Management',

  /// Subscription Benefits
  'subscription_benefits_title': 'Premium Subscription Benefits',

  /// Premium Banner Title
  'free_views_left': '%s free views left',

  /// Premium Banner Description
  'premium_banner_description':
      'Subscribe to premium to watch all videos without ads, unlimited times.',

  /// Premium Banner Button
  'premium_banner_button': 'Subscribe',

  /// Monthly Price
  'subscription_monthly_price': r'$1.99/month',

  /// Free trial limit
  'free_trial_limit_reached': 'You have used all your free views',

  /// Watch ad to continue
  'watch_ad_to_continue': 'Watch an ad to continue',

  /// Subscribe to continue
  'subscribe_to_continue': 'Subscribe to continue watching',

  /// Premium benefits
  'premium_benefit_1': 'Unlimited video watching',
  'premium_benefit_2': 'HD quality streaming',
  'premium_benefit_3': 'Ad-free experience',
  'premium_benefit_4': 'Offline downloads',
  'premium_benefit_5': 'Access to exclusive content',
  'premium_benefit_6': 'Priority customer support',

  /// Free tier benefits
  'free_tier_benefit_1': '10 free videos per day',
  'free_tier_benefit_2': 'Standard quality viewing',
  'free_tier_benefit_3': 'Direct search capability',
  'free_tier_benefit_4': 'Browse popular content',

  /// Monthly plan description
  'monthly_plan_description': 'Enjoy premium benefits with maximum flexibility',

  /// Yearly plan description
  'yearly_plan_description': 'Get 2 months free with annual subscription',

  /// Plan tags
  'most_popular_tag': 'Popular',
  'best_value_tag': 'Best Value',

  /// Ad completed message
  'ad_watch_completed': 'Ad completed. You can now continue watching the video.',

  /// Subscription Benefit Offline Download
  'subscription_benefit_offline_download': 'Offline download',

  /// Free Tier
  'free_tier': 'Free Plan',

  /// Premium Tier
  'premium_tier': 'Premium Plan',
};
