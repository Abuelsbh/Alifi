import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Utilities/shared_preferences.dart';
import 'translation_service.dart';

enum Languages {en,ar,he}

Languages appLanguage(BuildContext context) => Provider.of<AppLanguage>(context, listen: false).appLang;

class AppLanguage extends ChangeNotifier {
  static const Languages defaultLanguage = Languages.en;

  Languages _appLanguage = defaultLanguage;
  final TranslationService _translationService = TranslationService.instance;
  bool _isInitialized = false;

  Languages get appLang => _appLanguage;
  TranslationService get translationService => _translationService;
  bool get isInitialized => _isInitialized;

  Future fetchLocale() async {
    try {
      // تحميل اللغة المحفوظة من خدمة الترجمة بشكل آمن
      await _translationService.loadSavedLanguage();
      
      // تحديث اللغة المحلية بناءً على خدمة الترجمة
      _appLanguage = Languages.values.firstWhere(
        (lang) => lang.name == _translationService.currentLanguage,
        orElse: () => defaultLanguage,
      );
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error fetching locale: $e');
      _appLanguage = defaultLanguage;
      _isInitialized = true;
      
      // محاولة تحميل الترجمات الافتراضية
      try {
        await _translationService.loadTranslations('en');
      } catch (e2) {
        print('Error loading default translations: $e2');
      }
      
      notifyListeners();
    }
  }

  Future changeLanguage({Languages? language}) async {
    try {
    if(language == _appLanguage) return;
    
    Languages newLanguage;
    switch(language){
      case Languages.en:
        newLanguage = Languages.en;
        break;
      case Languages.ar:
        newLanguage = Languages.ar;
        break;
        case Languages.he:
          newLanguage = Languages.he;
          break;
      case null:
          // التنقل بين اللغات بدورة: EN -> AR -> HE -> EN
          switch(_appLanguage) {
            case Languages.en:
              newLanguage = Languages.ar;
              break;
            case Languages.ar:
              newLanguage = Languages.he;
              break;
            case Languages.he:
              newLanguage = Languages.en;
              break;
          }
        break;
    }
    
    // تغيير اللغة في خدمة الترجمة
    await _translationService.changeLanguage(newLanguage.name);
    
    // تحديث اللغة المحلية
    _appLanguage = newLanguage;
    
      // حفظ اللغة في SharedPreferences بشكل آمن
      try {
    await SharedPref.setLanguage(lang: _appLanguage.name);
      } catch (e) {
        print('Warning: Could not save language to preferences: $e');
      }
    
    notifyListeners();
    } catch (e) {
      print('Error changing language: $e');
    }
  }
  
  // الحصول على النص المترجم مع fallback آمن
  String translate(String key) {
    try {
    return _translationService.translate(key);
    } catch (e) {
      print('Error translating key "$key": $e');
      return key; // إرجاع المفتاح كـ fallback
    }
  }
  
  // التحقق من اتجاه النص مع معالجة آمنة
  bool get isRTL {
    try {
      return _translationService.isRTL;
    } catch (e) {
      print('Error checking RTL status: $e');
      return _appLanguage == Languages.ar || _appLanguage == Languages.he; // استخدام القيمة المحلية كـ fallback
    }
  }
  
  // الحصول على قائمة اللغات المتاحة مع معالجة آمنة
  List<Map<String, String>> get availableLanguages {
    try {
      return _translationService.availableLanguages;
    } catch (e) {
      print('Error getting available languages: $e');
      // إرجاع قائمة افتراضية
      return [
        {'code': 'en', 'name': 'English', 'nativeName': 'English'},
        {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
        {'code': 'he', 'name': 'Hebrew', 'nativeName': 'עברית'},
      ];
    }
  }
}


