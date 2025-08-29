class ChatConfig {
  // Message limits
  static const int maxMessageLength = 1000;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int messagesLoadLimit = 50;
  
  // Auto-scroll settings
  static const Duration autoScrollDelay = Duration(milliseconds: 300);
  static const Duration messageAnimationDuration = Duration(milliseconds: 300);
  
  // Typing indicator
  static const Duration typingIndicatorTimeout = Duration(seconds: 3);
  static const Duration typingDebounceDelay = Duration(milliseconds: 500);
  
  // Image compression
  static const int imageQuality = 70;
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  
  // Voice messages
  static const Duration maxVoiceMessageDuration = Duration(minutes: 5);
  static const String voiceMessageFormat = 'aac';
  
  // File upload
  static const List<String> allowedImageFormats = [
    'jpg', 'jpeg', 'png', 'gif', 'webp'
  ];
  
  static const List<String> allowedFileFormats = [
    'pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'
  ];
  
  // Chat colors
  static const Map<String, String> chatWallpapers = {
    'default': 'افتراضي',
    'blue': 'أزرق',
    'green': 'أخضر',
    'purple': 'بنفسجي',
    'orange': 'برتقالي',
    'custom': 'مخصص',
  };
  
  // Notification settings
  static const Map<String, String> notificationSounds = {
    'default': 'الافتراضي',
    'whistle': 'صافرة',
    'bell': 'جرس',
    'chime': 'رنين',
    'pop': 'نقرة',
    'none': 'بدون صوت',
  };
  
  // Connection settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Cache settings
  static const int maxCachedMessages = 1000;
  static const Duration cacheExpiration = Duration(days: 7);
  
  // Real-time settings
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 5);
  
  // UI Constants
  static const double messageBubbleMaxWidth = 0.75;
  static const double messageBubbleRadius = 18.0;
  static const double avatarRadius = 20.0;
  
  // Animation settings
  static const Duration fadeInDuration = Duration(milliseconds: 300);
  static const Duration slideInDuration = Duration(milliseconds: 400);
  static const Duration scaleInDuration = Duration(milliseconds: 200);
}

class ChatFeatures {
  // Feature flags
  static const bool voiceMessagesEnabled = true;
  static const bool videoCallEnabled = false;
  static const bool fileUploadEnabled = true;
  static const bool locationSharingEnabled = false;
  static const bool messageReactionsEnabled = false;
  static const bool messageEditingEnabled = false;
  static const bool messageForwardingEnabled = false;
  static const bool chatBackupEnabled = false;
  static const bool endToEndEncryptionEnabled = false;
  
  // Chat types
  static const bool groupChatsEnabled = false;
  static const bool broadcastMessagesEnabled = false;
  static const bool scheduledMessagesEnabled = false;
  
  // Advanced features
  static const bool readReceiptsEnabled = true;
  static const bool onlineStatusEnabled = true;
  static const bool typingIndicatorEnabled = true;
  static const bool messageSearchEnabled = true;
  static const bool chatExportEnabled = true;
  
  // Security features
  static const bool messageEncryptionEnabled = false;
  static const bool disappearingMessagesEnabled = false;
  static const bool screenshotBlockingEnabled = false;
  
  // Business features
  static const bool consultationFeeEnabled = true;
  static const bool appointmentBookingEnabled = false;
  static const bool prescriptionSharingEnabled = false;
  static const bool medicalRecordsEnabled = false;
}

class ChatConstants {
  // Error messages
  static const String connectionError = 'خطأ في الاتصال. يرجى المحاولة مرة أخرى.';
  static const String messageTooLong = 'الرسالة طويلة جداً. الحد الأقصى هو 1000 حرف.';
  static const String fileTooBig = 'حجم الملف كبير جداً. الحد الأقصى هو 10 ميجابايت.';
  static const String unsupportedFile = 'نوع الملف غير مدعوم.';
  static const String networkError = 'خطأ في الشبكة. تحقق من اتصالك بالإنترنت.';
  
  // Success messages
  static const String messageSent = 'تم إرسال الرسالة';
  static const String fileUploaded = 'تم رفع الملف بنجاح';
  static const String chatExported = 'تم تصدير المحادثة';
  static const String settingsSaved = 'تم حفظ الإعدادات';
  
  // Status messages
  static const String connecting = 'جاري الاتصال...';
  static const String reconnecting = 'جاري إعادة الاتصال...';
  static const String uploading = 'جاري الرفع...';
  static const String downloading = 'جاري التحميل...';
  static const String loading = 'جاري التحميل...';
  
  // User actions
  static const String typeMessage = 'اكتب رسالتك...';
  static const String searchMessages = 'البحث في الرسائل...';
  static const String noMessages = 'لا توجد رسائل بعد';
  static const String startConversation = 'ابدأ المحادثة';
  
  // Time formats
  static const String justNow = 'الآن';
  static const String minuteAgo = 'منذ دقيقة';
  static const String minutesAgo = 'منذ {count} دقائق';
  static const String hourAgo = 'منذ ساعة';
  static const String hoursAgo = 'منذ {count} ساعات';
  static const String yesterday = 'أمس';
  static const String daysAgo = 'منذ {count} أيام';
}

class ChatPermissions {
  // User permissions
  static const String sendMessages = 'send_messages';
  static const String sendImages = 'send_images';
  static const String sendFiles = 'send_files';
  static const String sendVoiceMessages = 'send_voice_messages';
  static const String makeVoiceCalls = 'make_voice_calls';
  static const String makeVideoCalls = 'make_video_calls';
  static const String shareLocation = 'share_location';
  
  // Chat permissions
  static const String viewChatHistory = 'view_chat_history';
  static const String exportChat = 'export_chat';
  static const String clearChatHistory = 'clear_chat_history';
  static const String deleteMessages = 'delete_messages';
  static const String editMessages = 'edit_messages';
  
  // Admin permissions
  static const String blockUsers = 'block_users';
  static const String muteUsers = 'mute_users';
  static const String manageChat = 'manage_chat';
  
  // Default permissions for regular users
  static const List<String> defaultUserPermissions = [
    sendMessages,
    sendImages,
    sendFiles,
    viewChatHistory,
    exportChat,
  ];
  
  // Default permissions for veterinarians
  static const List<String> defaultVetPermissions = [
    sendMessages,
    sendImages,
    sendFiles,
    sendVoiceMessages,
    makeVoiceCalls,
    makeVideoCalls,
    viewChatHistory,
    exportChat,
    manageChat,
  ];
} 