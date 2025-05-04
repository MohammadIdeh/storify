import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

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

  @override
  Widget build(BuildContext context) {
    // Using AspectRatio to maintain a consistent shape.
    return AspectRatio(
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
                  // Top-left: Icon and title.
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          svgIconPath,
                          width: iconSize,
                          height: iconSize,
                        ),
                        SizedBox(width: 20.w),
                        Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromARGB(255, 196, 196, 196),
                          ),
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
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: countFontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Bottom-center circular progress indicator.
                  Positioned(
                    bottom: 0,
                    left: (cardWidth - circleSize) / 2, // Center it.
                    child: CircularPercentIndicator(
                      radius: circleSize / 3,
                      lineWidth: circleSize * 0.05,
                      percent: percentage.clamp(0.0, 1.0),
                      center: Text(
                        "${(percentage * 100).toStringAsFixed(0)}%",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: circleSize * 0.18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      progressColor: circleColor,
                      backgroundColor: Colors.transparent,
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
