import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class OrdersCard extends StatelessWidget {
  final String svgIconPath;
  final String title;
  final String count;
  final double percentage;
  final Color circleColor;
  final bool isSelected;

  const OrdersCard({
    Key? key,
    required this.svgIconPath,
    required this.title,
    required this.count,
    required this.percentage,
    required this.circleColor,
    this.isSelected = false,
  }) : super(key: key);

  TextStyle _getTextStyle(
    BuildContext context, {
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final isArabic = LocalizationHelper.isArabic(context);

    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    } else {
      return GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    // Using AspectRatio to maintain a consistent shape.
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: AspectRatio(
        aspectRatio: 318 / 199,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isSelected
                ? const Color.fromARGB(255, 105, 65, 198)
                : const Color.fromARGB(255, 36, 50, 69),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth;
                final cardHeight = constraints.maxHeight;

                // Calculate sizes relative to the card's width.
                final iconSize = cardWidth * 0.17;
                final countFontSize = cardWidth * 0.12;
                final circleSize = cardWidth * 0.35;

                return Stack(
                  children: [
                    // Top-left/right: Icon and title (direction aware).
                    Positioned(
                      top: 0,
                      left: isRtl ? null : 0,
                      right: isRtl ? 0 : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        textDirection:
                            isRtl ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          SvgPicture.asset(
                            svgIconPath,
                            width: iconSize,
                            height: iconSize,
                          ),
                          SizedBox(width: 20.w),
                          Text(
                            title,
                            style: _getTextStyle(
                              context,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color.fromARGB(255, 196, 196, 196),
                            ),
                            textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    // Centered count text.
                    Positioned(
                      top: cardHeight * 0.25,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          count,
                          style: _getTextStyle(
                            context,
                            fontSize: countFontSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Bottom-center circular progress indicator.
                    Positioned(
                      bottom: 0,
                      left: (cardWidth - circleSize) / 1.75, // Center it.
                      child: CircularPercentIndicator(
                        radius: circleSize / 3,
                        lineWidth: circleSize * 0.05,
                        percent: percentage.clamp(0.0, 1.0),
                        center: Text(
                          "${(percentage * 100).toStringAsFixed(0)}%",
                          style: _getTextStyle(
                            context,
                            fontSize: circleSize * 0.18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        progressColor: circleColor,
                        backgroundColor: Colors.transparent,
                        circularStrokeCap: CircularStrokeCap.round,
                        // Direction aware for RTL
                        animation: true,
                        animationDuration: 1200,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced OrdersCard with additional localization features
class LocalizedOrdersCard extends StatelessWidget {
  final String svgIconPath;
  final String titleKey; // Localization key instead of hardcoded title
  final String count;
  final double percentage;
  final Color circleColor;
  final bool isSelected;
  final String? subtitle; // Optional subtitle for additional info

  const LocalizedOrdersCard({
    Key? key,
    required this.svgIconPath,
    required this.titleKey,
    required this.count,
    required this.percentage,
    required this.circleColor,
    this.isSelected = false,
    this.subtitle,
  }) : super(key: key);

  TextStyle _getTextStyle(
    BuildContext context, {
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final isArabic = LocalizationHelper.isArabic(context);

    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    } else {
      return GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }

  String _getLocalizedTitle(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    // Map title keys to localized strings
    switch (titleKey) {
      case 'pendingOrders':
        return l10n.pendingOrders;
      case 'completedOrders':
        return l10n.completedOrders;
      case 'cancelledOrders':
        return l10n.cancelledOrders;
      case 'totalOrders':
        return l10n.totalOrders;
      case 'activeSuppliers':
        return l10n.activeSuppliers;
      case 'lowStockItems':
        return l10n.lowStockItems;
      case 'monthlyRevenue':
        return l10n.monthlyRevenue;
      case 'totalProducts':
        return l10n.totalProducts;
      default:
        return titleKey; // Fallback to key if not found
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    final localizedTitle = _getLocalizedTitle(context);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: AspectRatio(
        aspectRatio: 318 / 199,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isSelected
                ? const Color.fromARGB(255, 105, 65, 198)
                : const Color.fromARGB(255, 36, 50, 69),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth;
                final cardHeight = constraints.maxHeight;

                // Calculate sizes relative to the card's width.
                final iconSize = cardWidth * 0.17;
                final countFontSize = cardWidth * 0.12;
                final circleSize = cardWidth * 0.35;

                return Stack(
                  children: [
                    // Top: Icon and title section (direction aware)
                    Positioned(
                      top: 0,
                      left: isRtl ? null : 0,
                      right: isRtl ? 0 : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        textDirection:
                            isRtl ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          SvgPicture.asset(
                            svgIconPath,
                            width: iconSize,
                            height: iconSize,
                          ),
                          SizedBox(
                              width: isArabic
                                  ? 15.w
                                  : 20.w), // Adjust spacing for Arabic
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isRtl
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  localizedTitle,
                                  style: _getTextStyle(
                                    context,
                                    fontSize: isArabic
                                        ? 18.sp
                                        : 20.sp, // Slightly smaller for Arabic
                                    fontWeight: FontWeight.w500,
                                    color: const Color.fromARGB(
                                        255, 196, 196, 196),
                                  ),
                                  textAlign:
                                      isRtl ? TextAlign.right : TextAlign.left,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subtitle != null) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    subtitle!,
                                    style: _getTextStyle(
                                      context,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                      color: const Color.fromARGB(
                                          255, 150, 150, 150),
                                    ),
                                    textAlign: isRtl
                                        ? TextAlign.right
                                        : TextAlign.left,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Centered count text
                    Positioned(
                      top: cardHeight * 0.25,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          count,
                          style: _getTextStyle(
                            context,
                            fontSize: countFontSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Bottom-center circular progress indicator
                    Positioned(
                      bottom: 0,
                      left: (cardWidth - circleSize) / 1.75,
                      child: CircularPercentIndicator(
                        radius: circleSize / 3,
                        lineWidth: circleSize * 0.05,
                        percent: percentage.clamp(0.0, 1.0),
                        center: Text(
                          "${(percentage * 100).toStringAsFixed(0)}%",
                          style: _getTextStyle(
                            context,
                            fontSize: circleSize * 0.18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        progressColor: circleColor,
                        backgroundColor: Colors.transparent,
                        circularStrokeCap: CircularStrokeCap.round,
                        animation: true,
                        animationDuration: 1200,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
