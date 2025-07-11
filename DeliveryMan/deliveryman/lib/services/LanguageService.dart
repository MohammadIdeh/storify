import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService with ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';

  String _currentLanguageCode = _defaultLanguage;
  Locale _currentLocale = const Locale(_defaultLanguage);

  String get currentLanguageCode => _currentLanguageCode;
  Locale get currentLocale => _currentLocale;

  // Initialize language from preferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;

      _currentLanguageCode = savedLanguage;
      _currentLocale = Locale(savedLanguage);

      print('Language service initialized with: $savedLanguage');
      notifyListeners();
    } catch (e) {
      print('Error initializing language service: $e');
      // Use default language if error occurs
      _currentLanguageCode = _defaultLanguage;
      _currentLocale = const Locale(_defaultLanguage);
    }
  }

  // Change language and save to preferences
  Future<bool> changeLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      _currentLanguageCode = languageCode;
      _currentLocale = Locale(languageCode);

      print('Language changed to: $languageCode');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error changing language: $e');
      return false;
    }
  }

  // Get available languages
  List<Map<String, String>> getAvailableLanguages() {
    return [
      {
        'code': 'en',
        'name': 'English',
        'nativeName': 'English',
      },
      {
        'code': 'ar',
        'name': 'Arabic',
        'nativeName': 'العربية',
      },
    ];
  }

  // Check if current language is RTL
  bool get isRTL => _currentLanguageCode == 'ar';

  // Check if current language is Arabic
  bool get isArabic => _currentLanguageCode == 'ar';

  // Check if current language is English
  bool get isEnglish => _currentLanguageCode == 'en';

  // Get language name by code
  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return 'English';
    }
  }

  // Toggle between languages (for quick switching)
  Future<bool> toggleLanguage() async {
    final newLanguage = _currentLanguageCode == 'en' ? 'ar' : 'en';
    return await changeLanguage(newLanguage);
  }
}
