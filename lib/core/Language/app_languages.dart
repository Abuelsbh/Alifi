import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Utilities/shared_preferences.dart';
import 'translation_service.dart';

enum Languages {en,ar}

Languages appLanguage(BuildContext context) => Provider.of<AppLanguage>(context, listen: false).appLang;

class AppLanguage extends ChangeNotifier {
  static const Languages defaultLanguage = Languages.en;

  Languages _appLanguage = defaultLanguage;
  final TranslationService _translationService = TranslationService.instance;

  Languages get appLang => _appLanguage;
  TranslationService get translationService => _translationService;

  Future fetchLocale() async {
    try {
      // تحميل اللغة المحفوظة من خدمة الترجمة
      await _translationService.loadSavedLanguage();
      
      // تحديث اللغة المحلية بناءً على خدمة الترجمة
      _appLanguage = Languages.values.firstWhere(
        (lang) => lang.name == _translationService.currentLanguage,
        orElse: () => defaultLanguage,
      );
      
      notifyListeners();
    } catch (e) {
      print('Error fetching locale: $e');
      _appLanguage = defaultLanguage;
    }
  }

  Future changeLanguage({Languages? language}) async {
    if(language == _appLanguage) return;
    
    Languages newLanguage;
    switch(language){
      case Languages.en:
        newLanguage = Languages.en;
        break;
      case Languages.ar:
        newLanguage = Languages.ar;
        break;
      case null:
        newLanguage = _appLanguage == Languages.ar ? Languages.en : Languages.ar;
        break;
    }
    
    // تغيير اللغة في خدمة الترجمة
    await _translationService.changeLanguage(newLanguage.name);
    
    // تحديث اللغة المحلية
    _appLanguage = newLanguage;
    
    // حفظ اللغة في SharedPreferences
    await SharedPref.setLanguage(lang: _appLanguage.name);
    
    notifyListeners();
  }
  
  // الحصول على النص المترجم
  String translate(String key) {
    return _translationService.translate(key);
  }
  
  // التحقق من اتجاه النص
  bool get isRTL => _translationService.isRTL;
  
  // الحصول على قائمة اللغات المتاحة
  List<Map<String, String>> get availableLanguages => _translationService.availableLanguages;
}


