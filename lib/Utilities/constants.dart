class AppConstants {
  // App Information
  static const String appName = 'Alifi';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'All-in-one platform for pet owners';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String lostPetsCollection = 'lost_pets';
  static const String foundPetsCollection = 'found_pets';
  static const String veterinaryChatsCollection = 'veterinary_chats';
  static const String veterinariansCollection = 'veterinarians';
  static const String chatMessagesCollection = 'messages';
  
  // Storage Paths
  static const String petReportsPath = 'pet_reports';
  static const String chatImagesPath = 'chat_images';
  static const String userAvatarsPath = 'user_avatars';
  
  // Image Settings
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const double maxImageSizeMB = 5.0; // 5MB
  static const int maxImagesPerReport = 5;
  static const int imageQuality = 85;
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  
  // Location Settings
  static const double defaultSearchRadius = 50.0; // km
  static const double maxSearchRadius = 100.0; // km
  static const double minSearchRadius = 1.0; // km
  
  // Chat Settings
  static const int maxMessageLength = 1000;
  static const int maxMessagesPerChat = 50;
  static const Duration messageRetentionPeriod = Duration(days: 365);
  
  // Validation Rules
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 500;
  
  // Animation Durations
  static const Duration splashAnimationDuration = Duration(milliseconds: 3000);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 200);
  static const Duration cardAnimationDuration = Duration(milliseconds: 400);
  
  // API Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  // Cache Settings
  static const Duration imageCacheDuration = Duration(days: 7);
  static const Duration dataCacheDuration = Duration(hours: 1);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Notification Settings
  static const String defaultNotificationChannel = 'alifi_notifications';
  static const String chatNotificationChannel = 'alifi_chat';
  static const String lostPetNotificationChannel = 'alifi_lost_pet';
  
  // Error Messages
  static const String networkErrorMessage = 'Please check your internet connection';
  static const String generalErrorMessage = 'Something went wrong. Please try again';
  static const String authenticationErrorMessage = 'Authentication failed. Please try again';
  static const String permissionErrorMessage = 'Permission denied. Please grant the required permissions';
  
  // Success Messages
  static const String reportSubmittedMessage = 'Report submitted successfully';
  static const String messageSentMessage = 'Message sent successfully';
  static const String profileUpdatedMessage = 'Profile updated successfully';
  static const String passwordResetMessage = 'Password reset email sent';
  
  // Pet Types
  static const List<String> petTypes = [
    'Dog',
    'Cat',
    'Bird',
    'Fish',
    'Rabbit',
    'Hamster',
    'Guinea Pig',
    'Other',
  ];
  
  // Pet Breeds (Common)
  static const Map<String, List<String>> petBreeds = {
    'Dog': [
      'Golden Retriever',
      'Labrador Retriever',
      'German Shepherd',
      'Bulldog',
      'Beagle',
      'Poodle',
      'Rottweiler',
      'Yorkshire Terrier',
      'Boxer',
      'Dachshund',
      'Other',
    ],
    'Cat': [
      'Persian',
      'Maine Coon',
      'Siamese',
      'British Shorthair',
      'Ragdoll',
      'Abyssinian',
      'Russian Blue',
      'Bengal',
      'Sphynx',
      'Other',
    ],
    'Bird': [
      'Budgerigar',
      'Cockatiel',
      'African Grey',
      'Macaw',
      'Cockatoo',
      'Canary',
      'Finch',
      'Parakeet',
      'Lovebird',
      'Other',
    ],
  };
  
  // Veterinary Specializations
  static const List<String> veterinarySpecializations = [
    'General Practice',
    'Emergency Medicine',
    'Surgery',
    'Dermatology',
    'Cardiology',
    'Oncology',
    'Neurology',
    'Orthopedics',
    'Dentistry',
    'Behavior',
    'Nutrition',
    'Other',
  ];
  
  // Report Status
  static const String statusActive = 'active';
  static const String statusResolved = 'resolved';
  static const String statusClosed = 'closed';
  
  // Message Types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeVideo = 'video';
  
  // User Roles
  static const String roleUser = 'user';
  static const String roleVeterinarian = 'veterinarian';
  static const String roleAdmin = 'admin';
  
  // Theme Modes
  static const String themeLight = 'light';
  static const String themeDark = 'dark';
  static const String themeSystem = 'system';
  
  // Languages
  static const String languageEnglish = 'en';
  static const String languageArabic = 'ar';
  
  // Shared Preferences Keys
  static const String keyTheme = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyUserId = 'user_id';
  static const String keyUserToken = 'user_token';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyNotificationSettings = 'notification_settings';
  
  // Deep Link Schemes
  static const String deepLinkScheme = 'alifi';
  static const String deepLinkHost = 'alifi.com';
  
  // Social Media Links
  static const String facebookUrl = 'https://facebook.com/alifi';
  static const String twitterUrl = 'https://twitter.com/alifi';
  static const String instagramUrl = 'https://instagram.com/alifi';
  static const String linkedinUrl = 'https://linkedin.com/company/alifi';
  
  // Support Information
  static const String supportEmail = 'support@alifi.com';
  static const String supportPhone = '+1-800-ALIFI-HELP';
  static const String supportWebsite = 'https://alifi.com/support';
  
  // Legal Information
  static const String privacyPolicyUrl = 'https://alifi.com/privacy';
  static const String termsOfServiceUrl = 'https://alifi.com/terms';
  static const String cookiePolicyUrl = 'https://alifi.com/cookies';
} 