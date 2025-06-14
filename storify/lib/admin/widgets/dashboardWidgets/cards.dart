import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsCard extends StatelessWidget {
  final String svgIconPath;
  final String title;
  final String value;
  final String percentage;
  final bool isPositive;

  const StatsCard({
    Key? key,
    required this.svgIconPath,
    required this.title,
    required this.value,
    required this.percentage,
    required this.isPositive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use AspectRatio to maintain the design's proportions.
    return AspectRatio(
      aspectRatio: 318 / 199, // original width/height ratio
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(105, 65, 198, 0),
              Color.fromRGBO(180, 180, 180, 0.089),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate sizes based on available dimensions.
              final iconSize = constraints.maxWidth * 0.17; // ~55/318 of width
              final spacingBetween =
                  constraints.maxHeight * 0.06; // ~12/199 of height
              final titleFontSize =
                  constraints.maxWidth * 0.045; // ~15/318 of width
              final valueFontSize =
                  constraints.maxWidth * 0.10; // ~35/318 of width
              final percentageFontSize =
                  constraints.maxWidth * 0.045; // ~15/318 of width
              // The stats container originally was 140x140 which is about 44% of the width and 70% of the height.
              final statsContainerWidth = constraints.maxWidth * 0.44;
              final statsContainerHeight = constraints.maxHeight * 0.70;

              // Dynamic colors based on isPositive
              final percentageColor = isPositive
                  ? const Color.fromARGB(178, 0, 224, 116) // Green for positive
                  : const Color.fromARGB(178, 255, 87, 87); // Red for negative

              final arrowIcon = isPositive
                  ? 'assets/images/arrow_up.svg'
                  : 'assets/images/arrow_down.svg';

              return Row(
                children: [
                  // Left side: Icon and title.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          svgIconPath,
                          width: iconSize,
                          height: iconSize,
                        ),
                        SizedBox(height: spacingBetween),
                        Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromARGB(255, 196, 196, 196),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right side: Value and percentage inside a styled container.
                  Container(
                    width: statsContainerWidth,
                    height: statsContainerHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: const Color.fromARGB(34, 92, 61, 141)),
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.fromRGBO(105, 65, 198, 0.007),
                          Color.fromRGBO(180, 180, 180, 0.034),
                        ],
                      ),
                    ),
                    child: Container(
                      margin: EdgeInsets.all(
                          statsContainerWidth * 0.035), // ~5/140 of width
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              value,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: valueFontSize,
                                fontWeight: FontWeight.w700,
                                color: const Color.fromARGB(255, 246, 246, 246),
                              ),
                            ),
                            SizedBox(
                              height: statsContainerHeight *
                                  0.057, // ~8/140 of height
                            ),
                            // Row for the arrow and percentage.
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 30.0),
                                  child: Container(
                                    width: statsContainerWidth *
                                        0.57, // ~80/140 of width
                                    height: statsContainerHeight *
                                        0.214, // ~30/140 of height
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(20)),
                                      border:
                                          Border.all(color: percentageColor),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: statsContainerWidth *
                                              0.043, // ~6/140 of width
                                        ),
                                        // Use fallback icon if SVG doesn't exist
                                        _buildArrowIcon(
                                          arrowIcon,
                                          statsContainerWidth * 0.143,
                                          percentageColor,
                                          isPositive,
                                        ),
                                        SizedBox(
                                          width: statsContainerWidth *
                                              0.029, // ~4/140 of width
                                        ),
                                        Flexible(
                                          child: Text(
                                            percentage,
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: percentageFontSize,
                                              fontWeight: FontWeight.w500,
                                              color: percentageColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
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

  Widget _buildArrowIcon(
      String assetPath, double size, Color color, bool isUp) {
    // Try to load SVG, fallback to Icon if not available
    try {
      return SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    } catch (e) {
      // Fallback to Flutter Icon if SVG is not available
      return Icon(
        isUp ? Icons.arrow_upward : Icons.arrow_downward,
        size: size,
        color: color,
      );
    }
  }
}
