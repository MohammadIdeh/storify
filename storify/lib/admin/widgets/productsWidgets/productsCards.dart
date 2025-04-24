import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate sizes based on available dimensions.
              final spacingBetween =
                  constraints.maxHeight * 0.16; // ~12/199 of height
              final titleFontSize =
                  constraints.maxWidth * 0.090; // ~15/318 of width
              final valueFontSize =
                  constraints.maxWidth * 0.10; // ~32/318 of width
              final subtextFontSize = constraints.maxWidth * 0.045;
              final arrowSize =
                  constraints.maxWidth * 0.1; // roughly responsive arrow size

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromARGB(214, 255, 255, 255),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: spacingBetween),
                  // Main value text.
                  Center(
                    child: Text(
                      value,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: spacingBetween * 0.26),
                  // Subtext.
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0),
                    child: Text(
                      subtext,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: subtextFontSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
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
