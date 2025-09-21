import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static TranslationService? _instance;
  static TranslationService get instance => _instance ??= TranslationService._internal();
  
  TranslationService._internal();
  
  Map<String, dynamic> _translations = {};
  String _currentLanguage = 'en';
  bool _isInitialized = false;
  
  String get currentLanguage => _currentLanguage;
  Map<String, dynamic> get translations => _translations;
  bool get isInitialized => _isInitialized;
  
  // تحميل ملف الترجمة مع معالجة آمنة للأخطاء
  Future<void> loadTranslations(String languageCode) async {
    try {
      final String jsonString = await rootBundle.loadString('i18n/$languageCode.json');
      _translations = json.decode(jsonString) as Map<String, dynamic>;
      _currentLanguage = languageCode;
      _isInitialized = true;
      
      // حفظ اللغة المحددة
      try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
      } catch (e) {
        print('Warning: Could not save language preference: $e');
      }
    } catch (e) {
      print('Error loading translations for $languageCode: $e');
      
      // إذا فشل تحميل اللغة المطلوبة، جرب الإنجليزية
      if (languageCode != 'en') {
        print('Falling back to English translations');
        await _loadFallbackTranslations();
      } else {
        // إذا فشلت الإنجليزية أيضاً، استخدم ترجمات افتراضية
        _loadDefaultTranslations();
      }
    }
  }
  
  // تحميل ترجمات افتراضية في حالة فشل تحميل الملفات
  Future<void> _loadFallbackTranslations() async {
    try {
      final String jsonString = await rootBundle.loadString('i18n/en.json');
      _translations = json.decode(jsonString) as Map<String, dynamic>;
      _currentLanguage = 'en';
      _isInitialized = true;
    } catch (e) {
      print('Fallback translation loading failed: $e');
      _loadDefaultTranslations();
    }
  }
  
  // ترجمات افتراضية مبرمجة للحالات الطارئة
  void _loadDefaultTranslations() {
    _translations = {
      'app_description': 'Pet Care Platform',
      'loading': 'Loading...',
      'welcome': 'Welcome',
      'home': 'Home',
      'profile': 'Profile',
      'pets': 'Pets',
      'veterinary': 'Veterinary',
      'lost_found': 'Lost & Found',
    };
    _currentLanguage = 'en';
    _isInitialized = true;
    print('Using default translations');
  }
  
  // الحصول على النص المترجم مع fallback آمن
  String translate(String key) {
    if (!_isInitialized) {
      return key; // إرجاع المفتاح إذا لم يتم التهيئة بعد
    }
    
    final keys = key.split('.');
    dynamic value = _translations;
    
    for (final k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key; // إرجاع المفتاح إذا لم يتم العثور على الترجمة
      }
    }
    
    return value?.toString() ?? key;
  }
  
  // تحميل اللغة المحفوظة مع معالجة آمنة
  Future<void> loadSavedLanguage() async {
    try {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language') ?? 'en';
    await loadTranslations(savedLanguage);
    } catch (e) {
      print('Error loading saved language: $e');
      // استخدام الإنجليزية كافتراضي
      await loadTranslations('en');
    }
  }
  
  // تغيير اللغة مع معالجة آمنة
  Future<void> changeLanguage(String languageCode) async {
    await loadTranslations(languageCode);
  }
  
  // الحصول على قائمة اللغات المتاحة
  List<Map<String, String>> get availableLanguages => [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
    {'code': 'he', 'name': 'Hebrew', 'nativeName': 'עברית'},
  ];
  
  // التحقق من اتجاه النص
  bool get isRTL => _currentLanguage == 'ar' || _currentLanguage == 'he';
} 