import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'locale';
  
  Locale _locale = const Locale('en');
  
  Locale get locale => _locale;
  
  bool get isUrdu => _locale.languageCode == 'ur';
  bool get isEnglish => _locale.languageCode == 'en';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null) {
      _locale = Locale(savedLocale);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> toggleLocale() async {
    final newLocale = _locale.languageCode == 'en' 
        ? const Locale('ur') 
        : const Locale('en');
    await setLocale(newLocale);
  }

  String get currentLanguageName => _locale.languageCode == 'ur' ? 'اردو' : 'English';
  String get currentLanguageCode => _locale.languageCode.toUpperCase();
}