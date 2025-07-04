// // lib/utils/localization_helper.dart
// // Helper utilities for localization throughout the app
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:storify/providers/LocaleProvider.dart';

// class LocalizationHelper {
//   /// Get AppLocalizations instance from context
//   static AppLocalizations of(BuildContext context) {
//     return AppLocalizations.of(context)!;
//   }

//   /// Get current locale from context
//   static Locale getCurrentLocale(BuildContext context) {
//     return Provider.of<LocaleProvider>(context, listen: false).locale;
//   }

//   /// Check if current locale is RTL
//   static bool isRTL(BuildContext context) {
//     return Provider.of<LocaleProvider>(context, listen: false).isRtl;
//   }

//   /// Check if current locale is Arabic
//   static bool isArabic(BuildContext context) {
//     return Provider.of<LocaleProvider>(context, listen: false).isArabic;
//   }

//   /// Change locale programmatically
//   static Future<void> changeLocale(BuildContext context, Locale locale) async {
//     final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
//     await localeProvider.setLocale(locale);
//   }

//   /// Get role name with proper formatting and localization
//   static String getRoleDisplayName(BuildContext context, String? role) {
//     final l10n = of(context);
//     if (role == null) return '';

//     switch (role) {
//       case 'DeliveryEmployee':
//         return l10n.deliveryEmployee;
//       case 'WareHouseEmployee':
//         return l10n.warehouseEmployee;
//       case 'Customer':
//         return l10n.customer;
//       case 'Supplier':
//         return l10n.supplier;
//       case 'Admin':
//         return l10n.admin;
//       default:
//         return role;
//     }
//   }

//   /// Format text direction based on current locale
//   static TextDirection getTextDirection(BuildContext context) {
//     return isRTL(context) ? TextDirection.rtl : TextDirection.ltr;
//   }

//   /// Get appropriate text alignment for current locale
//   static TextAlign getTextAlign(BuildContext context, {TextAlign? fallback}) {
//     if (isRTL(context)) {
//       return TextAlign.right;
//     }
//     return fallback ?? TextAlign.left;
//   }

//   /// Get appropriate edge insets for current locale (useful for padding)
//   static EdgeInsets getDirectionalPadding(
//     BuildContext context, {
//     double start = 0,
//     double top = 0,
//     double end = 0,
//     double bottom = 0,
//   }) {
//     if (isRTL(context)) {
//       return EdgeInsets.fromLTRB(end, top, start, bottom);
//     }
//     return EdgeInsets.fromLTRB(start, top, end, bottom);
//   }

//   /// Wrap widget with proper directionality
//   static Widget withDirectionality(BuildContext context, Widget child) {
//     return Directionality(
//       textDirection: getTextDirection(context),
//       child: child,
//     );
//   }

//   /// Format date according to current locale
//   static String formatDate(BuildContext context, DateTime date) {
//     final locale = getCurrentLocale(context);
//     // You can use intl package for more sophisticated date formatting
//     if (locale.languageCode == 'ar') {
//       // Arabic date formatting
//       return '${date.day}/${date.month}/${date.year}';
//     }
//     // English date formatting
//     return '${date.month}/${date.day}/${date.year}';
//   }

//   /// Format numbers according to current locale
//   static String formatNumber(BuildContext context, num number) {
//     final locale = getCurrentLocale(context);
//     if (locale.languageCode == 'ar') {
//       // Convert to Arabic-Indic numerals if needed
//       return number.toString().replaceAllMapped(
//         RegExp(r'[0-9]'),
//         (match) {
//           const arabicDigits = [
//             '٠',
//             '١',
//             '٢',
//             '٣',
//             '٤',
//             '٥',
//             '٦',
//             '٧',
//             '٨',
//             '٩'
//           ];
//           return arabicDigits[int.parse(match.group(0)!)];
//         },
//       );
//     }
//     return number.toString();
//   }

//   /// Get appropriate font family for current locale
//   static String getFontFamily(BuildContext context) {
//     return isArabic(context) ? 'Cairo' : 'SpaceGrotesk';
//   }

//   /// Debug method to print current localization state
//   static void debugLocalizationState(BuildContext context) {
//     final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
//     debugPrint('🌐 === LOCALIZATION DEBUG ===');
//     debugPrint('   Current Locale: ${localeProvider.locale}');
//     debugPrint('   Is RTL: ${localeProvider.isRtl}');
//     debugPrint('   Is Arabic: ${localeProvider.isArabic}');
//     debugPrint('   Font Family: ${getFontFamily(context)}');
//     debugPrint('   Text Direction: ${getTextDirection(context)}');
//     debugPrint('===============================');
//   }
// }

// /// Extension methods for easier localization access
// extension LocalizationContext on BuildContext {
//   /// Quick access to AppLocalizations
//   AppLocalizations get l10n => LocalizationHelper.of(this);

//   /// Quick access to current locale
//   Locale get currentLocale => LocalizationHelper.getCurrentLocale(this);

//   /// Quick access to RTL check
//   bool get isRTL => LocalizationHelper.isRTL(this);

//   /// Quick access to Arabic check
//   bool get isArabic => LocalizationHelper.isArabic(this);

//   /// Quick access to text direction
//   TextDirection get textDirection => LocalizationHelper.getTextDirection(this);

//   /// Quick access to font family
//   String get fontFamily => LocalizationHelper.getFontFamily(this);
// }

// /// Widget wrapper for automatic directionality
// class LocalizedWidget extends StatelessWidget {
//   final Widget child;
//   final bool forceDirection;

//   const LocalizedWidget({
//     Key? key,
//     required this.child,
//     this.forceDirection = true,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     if (forceDirection) {
//       return LocalizationHelper.withDirectionality(context, child);
//     }
//     return child;
//   }
// }

// /// Custom text widget that automatically handles RTL
// class LocalizedText extends StatelessWidget {
//   final String text;
//   final TextStyle? style;
//   final TextAlign? textAlign;
//   final int? maxLines;
//   final TextOverflow? overflow;

//   const LocalizedText(
//     this.text, {
//     Key? key,
//     this.style,
//     this.textAlign,
//     this.maxLines,
//     this.overflow,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       text,
//       style: style?.copyWith(
//         fontFamily: style?.fontFamily ?? context.fontFamily,
//       ),
//       textAlign: textAlign ?? LocalizationHelper.getTextAlign(context),
//       textDirection: context.textDirection,
//       maxLines: maxLines,
//       overflow: overflow,
//     );
//   }
// }
