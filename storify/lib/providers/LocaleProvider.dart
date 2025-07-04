// lib/providers/locale_provider.dart
// Enhanced LocaleProvider with role-based language preferences
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); // Default to English
  bool _isRtl = false;
  bool _isLoading = false;

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('ar'), // Arabic
  ];

  // Getters
  Locale get locale => _locale;
  bool get isRtl => _isRtl;
  bool get isLoading => _isLoading;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';

  LocaleProvider() {
    _initializeLocale();
  }

  /// Initialize locale on app startup
  Future<void> _initializeLocale() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First check if user is logged in
      final currentRole = await AuthService.getCurrentRole();

      if (currentRole != null) {
        // Load role-specific language preference
        await _loadRoleSpecificLocale(currentRole);
      } else {
        // Load global default language
        await _loadGlobalLocale();
      }
    } catch (e) {
      debugPrint('❌ Error initializing locale: $e');
      // Fallback to default locale
      _setLocaleInternal(const Locale('en'));
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load role-specific language preference
  Future<void> _loadRoleSpecificLocale(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check for role-specific language setting
      final roleLanguageKey = 'language_$role';
      String? languageCode = prefs.getString(roleLanguageKey);

      // If no role-specific setting, check global setting
      languageCode ??= prefs.getString('language_global');

      // Default to English if nothing found
      languageCode ??= 'en';

      debugPrint('🌐 Loading locale for role $role: $languageCode');

      final newLocale = Locale(languageCode);
      if (_isValidLocale(newLocale)) {
        _setLocaleInternal(newLocale);
      } else {
        _setLocaleInternal(const Locale('en'));
      }
    } catch (e) {
      debugPrint('❌ Error loading role-specific locale: $e');
      _setLocaleInternal(const Locale('en'));
    }
  }

  /// Load global language preference (for non-authenticated users)
  Future<void> _loadGlobalLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_global') ?? 'en';

      debugPrint('🌐 Loading global locale: $languageCode');

      final newLocale = Locale(languageCode);
      if (_isValidLocale(newLocale)) {
        _setLocaleInternal(newLocale);
      } else {
        _setLocaleInternal(const Locale('en'));
      }
    } catch (e) {
      debugPrint('❌ Error loading global locale: $e');
      _setLocaleInternal(const Locale('en'));
    }
  }

  /// Set locale for current role (if authenticated) or globally
  Future<void> setLocale(Locale newLocale) async {
    if (!_isValidLocale(newLocale)) {
      debugPrint('❌ Invalid locale: ${newLocale.languageCode}');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final currentRole = await AuthService.getCurrentRole();

      if (currentRole != null) {
        // Save as role-specific preference
        final roleLanguageKey = 'language_$currentRole';
        await prefs.setString(roleLanguageKey, newLocale.languageCode);
        debugPrint(
            '💾 Saved locale ${newLocale.languageCode} for role: $currentRole');
      } else {
        // Save as global preference
        await prefs.setString('language_global', newLocale.languageCode);
        debugPrint('💾 Saved global locale: ${newLocale.languageCode}');
      }

      _setLocaleInternal(newLocale);

      _isLoading = false;
      notifyListeners();

      debugPrint('✅ Locale changed to: ${newLocale.languageCode}');
    } catch (e) {
      debugPrint('❌ Error setting locale: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set locale internally and update RTL status
  void _setLocaleInternal(Locale newLocale) {
    _locale = newLocale;
    _isRtl = _isRightToLeft(newLocale.languageCode);
  }

  /// Check if language code requires RTL
  bool _isRightToLeft(String languageCode) {
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.contains(languageCode);
  }

  /// Validate if locale is supported
  bool _isValidLocale(Locale locale) {
    return supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  /// Update locale when role changes (call this after role switch)
  Future<void> onRoleChanged(String newRole) async {
    debugPrint('🔄 Role changed to: $newRole, updating locale...');
    await _loadRoleSpecificLocale(newRole);
    notifyListeners();
  }

  /// Reset to default locale
  Future<void> resetToDefault() async {
    await setLocale(const Locale('en'));
  }

  /// Get display name for locale
  String getLocaleDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return locale.languageCode.toUpperCase();
    }
  }

  /// Get all supported locales with display names
  Map<Locale, String> getSupportedLocalesWithNames() {
    return {
      for (final locale in supportedLocales)
        locale: getLocaleDisplayName(locale),
    };
  }

  /// Clear all language preferences (useful for logout)
  Future<void> clearAllLanguagePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove all role-specific language preferences
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith('language_')) {
          await prefs.remove(key);
        }
      }

      debugPrint('🧹 Cleared all language preferences');
    } catch (e) {
      debugPrint('❌ Error clearing language preferences: $e');
    }
  }

  /// Clear language preference for specific role
  Future<void> clearRoleLanguagePreference(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleLanguageKey = 'language_$role';
      await prefs.remove(roleLanguageKey);
      debugPrint('🧹 Cleared language preference for role: $role');
    } catch (e) {
      debugPrint('❌ Error clearing role language preference: $e');
    }
  }

  /// Get language preference for specific role (without switching to it)
  Future<String?> getRoleLanguagePreference(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleLanguageKey = 'language_$role';
      return prefs.getString(roleLanguageKey);
    } catch (e) {
      debugPrint('❌ Error getting role language preference: $e');
      return null;
    }
  }

  /// Force refresh locale (useful after login)
  Future<void> refreshLocale() async {
    await _initializeLocale();
  }

  /// Get current language code
  String get currentLanguageCode => _locale.languageCode;

  /// Get current language display name
  String get currentLanguageDisplayName => getLocaleDisplayName(_locale);

  /// Debug info
  void printDebugInfo() {
    debugPrint('🌐 === LOCALE PROVIDER DEBUG INFO ===');
    debugPrint('   Current Locale: $_locale');
    debugPrint('   Is RTL: $_isRtl');
    debugPrint('   Is Loading: $_isLoading');
    debugPrint('   Supported Locales: $supportedLocales');
    debugPrint('=====================================');
  }
}
