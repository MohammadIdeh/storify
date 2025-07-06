import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class ProductsCards extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;

  const ProductsCards({
    Key? key,
    required this.title,
    required this.value,
    required this.subtext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return AspectRatio(
      aspectRatio: 318 / 199, // original width/height ratio
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(105, 65, 198, 0.3), // rgba(105, 65, 198, 0.3)
              Color.fromRGBO(105, 65, 198, 0.0), // rgba(105, 65, 198, 0)
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color.fromARGB(255, 46, 57, 84),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate sizes based on available dimensions (reduced sizes)
              final spacingBetween =
                  constraints.maxHeight * 0.16; // ~12/199 of height
              final titleFontSize =
                  constraints.maxWidth * 0.070; // reduced from 0.090
              final valueFontSize =
                  constraints.maxWidth * 0.080; // reduced from 0.10
              final subtextFontSize =
                  constraints.maxWidth * 0.038; // reduced from 0.045
              final arrowSize =
                  constraints.maxWidth * 0.1; // roughly responsive arrow size

              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center all content
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center vertically
                children: [
                  // Title text - centered
                  Text(
                    title,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromARGB(214, 255, 255, 255),
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromARGB(214, 255, 255, 255),
                          ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: spacingBetween),
                  // Main value text - centered
                  Text(
                    value,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: valueFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: valueFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: spacingBetween * 0.26),
                  // Subtext - centered
                  Text(
                    subtext,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: subtextFontSize,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          )
                        : GoogleFonts.spaceGrotesk(
                            fontSize: subtextFontSize,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
