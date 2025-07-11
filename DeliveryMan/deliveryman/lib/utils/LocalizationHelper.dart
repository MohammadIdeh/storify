import 'package:flutter/material.dart';

class LocalizationHelper {
  static const String englishCode = 'en';
  static const String arabicCode = 'ar';
  
  static bool isArabic(BuildContext context) {
    return Localizations.localeOf(context).languageCode == arabicCode;
  }
  
  static bool isRTL(BuildContext context) {
    return isArabic(context);
  }
  
  static bool isEnglish(BuildContext context) {
    return Localizations.localeOf(context).languageCode == englishCode;
  }
  
  static String getCurrentLanguageCode(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }
  
  static Locale getCurrentLocale(BuildContext context) {
    return Localizations.localeOf(context);
  }
  
  static AppLocalizations getLocalizations(BuildContext context) {
    return AppLocalizations.of(context)!;
  }
  
  static TextDirection getTextDirection(BuildContext context) {
    return isRTL(context) ? TextDirection.rtl : TextDirection.ltr;
  }
  
  static EdgeInsets getDirectionalPadding({
    double? start,
    double? end,
    double? top,
    double? bottom,
    required BuildContext context,
  }) {
    if (isRTL(context)) {
      return EdgeInsets.only(
        left: end ?? 0,
        right: start ?? 0,
        top: top ?? 0,
        bottom: bottom ?? 0,
      );
    } else {
      return EdgeInsets.only(
        left: start ?? 0,
        right: end ?? 0,
        top: top ?? 0,
        bottom: bottom ?? 0,
      );
    }
  }
  
  static CrossAxisAlignment getDirectionalCrossAxisAlignment({
    required bool isStart,
    required BuildContext context,
  }) {
    if (isRTL(context)) {
      return isStart ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    } else {
      return isStart ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    }
  }
}