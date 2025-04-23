import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TrackCards extends StatelessWidget {
  final String title;
  final String value;
  final String? subtext;

  const TrackCards({
    Key? key,
    required this.title,
    required this.value,
    this.subtext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 318 / 150, // original width/height ratio
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color.fromARGB(255, 46, 57, 84),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate sizes based on available dimensions
              final spacingBetween = constraints.maxHeight * 0.16;
              final titleFontSize = constraints.maxWidth * 0.060;
              final valueFontSize = constraints.maxWidth * 0.07;
              final subtextFontSize = constraints.maxWidth * 0.045;
              final iconSize =
                  constraints.maxWidth * 0.18; // Responsive icon size

              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SVG Icon
                  Padding(
                    padding: const EdgeInsets.only(right: 50.0),
                    child: SvgPicture.asset(
                      'assets/images/truck.svg',
                      width: iconSize,
                      height: iconSize,
                    ),
                  ),
                  SizedBox(height: spacingBetween * 0.5),

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                      color: const Color.fromARGB(214, 255, 255, 255),
                    ),
                  ),

                  SizedBox(height: spacingBetween * 0.26),

                  // Value
                  Text(
                    value,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  // Optional subtext
                  if (subtext != null) ...[
                    SizedBox(height: spacingBetween * 0.26),
                    Text(
                      subtext!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: subtextFontSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
