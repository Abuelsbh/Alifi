import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static TranslationService? _instance;
  static TranslationService get instance => _instance ??= TranslationService._internal();
  
  TranslationService._internal();
  
  Map<String, dynamic> _translations = {};
  String _currentLanguage = 'en';
  
  String get currentLanguage => _currentLanguage;
  Map<String, dynamic> get translations => _translations;
  
  // تحميل ملف الترجمة
  Future<void> loadTranslations(String languageCode) async {
    try {
      final String jsonString = await rootBundle.loadString('i18n/$languageCode.json');
      _translations = json.decode(jsonString) as Map<String, dynamic>;
      _currentLanguage = languageCode;
      
      // حفظ اللغة المحددة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
    } catch (e) {
      print('Error loading translations: $e');
      // استخدام اللغة الإنجليزية كاحتياطي
      await loadTranslations('en');
    }
  }
  
  // الحصول على النص المترجم
  String translate(String key) {
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
  
  // تحميل اللغة المحفوظة
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language') ?? 'en';
    await loadTranslations(savedLanguage);
  }
  
  // تغيير اللغة
  Future<void> changeLanguage(String languageCode) async {
    await loadTranslations(languageCode);
  }
  
  // الحصول على قائمة اللغات المتاحة
  List<Map<String, String>> get availableLanguages => [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
  ];
  
  // التحقق من اتجاه النص
  bool get isRTL => _currentLanguage == 'ar';
} 