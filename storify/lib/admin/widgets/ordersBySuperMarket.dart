import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pie_chart/pie_chart.dart';

class Ordersbysupermarket extends StatelessWidget {
  // Percentages for each supermarket (0-100)
  final double alShiniPercent;
  final double alSudaniPercent;
  final double alNidalPercent;
  final double tilalSurdaPercent;
  // Total stores (shown in the donut center)
  final int totalStores;

  const Ordersbysupermarket({
    super.key,
    required this.alShiniPercent,
    required this.alSudaniPercent,
    required this.alNidalPercent,
    required this.tilalSurdaPercent,
    required this.totalStores,
  });

  @override
  Widget build(BuildContext context) {
    // Colors with ~70% opacity (B2 ~ hex opacity)
    final Color backgroundColor = const Color.fromARGB(255, 36, 50, 69);
    final Color greenColor = const Color(0xB200E074);
    final Color orangeColor = const Color(0xB2FE8A00);
    final Color blueColor = const Color(0xB200A6FF);
    final Color pinkColor = const Color(0xB2FF1474);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  "Orders By Supermarket",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 25.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.h),

                _buildBarSection("Al-Shini", alShiniPercent, greenColor),
                SizedBox(height: 12.h),
                _buildBarSection("Al-Sudani", alSudaniPercent, orangeColor),
                SizedBox(height: 12.h),
                _buildBarSection("Al-Nidal", alNidalPercent, blueColor),
                SizedBox(height: 12.h),
                _buildBarSection("Tilal Surda", tilalSurdaPercent, pinkColor),
              ],
            ),
          ),
          _buildDonutChart(
            alShiniPercent,
            alSudaniPercent,
            alNidalPercent,
            tilalSurdaPercent,
            totalStores,
            [greenColor, orangeColor, blueColor, pinkColor],
          ),
        ],
      ),
    );
  }

  Widget _buildBarSection(String label, double percentage, Color color) {
    final clampedPercent = percentage.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 17.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              "${percentage.toStringAsFixed(0)}%",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  width: availableWidth,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                Container(
                  width: availableWidth * (clampedPercent / 100.0),
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ),
                SizedBox(
                  height: 40,
                )
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDonutChart(
    double alShini,
    double alSudani,
    double alNidal,
    double tilalSurda,
    int total,
    List<Color> colorList,
  ) {
    // Data for the pie chart
    final dataMap = <String, double>{
      "Al-Shini": alShini,
      "Al-Sudani": alSudani,
      "Al-Nidal": alNidal,
      "Tilal Surda": tilalSurda,
    };

    final double chartSize = 0.2.sw;
    return SizedBox(
      width: chartSize,
      height: chartSize,
      child: PieChart(
        dataMap: dataMap,
        chartType: ChartType.ring,
        baseChartColor: Colors.white.withOpacity(0.2),
        colorList: colorList,
        chartRadius: chartSize * 0.57,
        ringStrokeWidth: chartSize * 0.12,
        centerWidget: Text(
          textAlign: TextAlign.center,
          "Total stores\n$total",
          style: GoogleFonts.spaceGrotesk(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.transparent,
          ),
        ),
        legendOptions: const LegendOptions(showLegends: false),
        chartValuesOptions: const ChartValuesOptions(showChartValues: false),
        animationDuration: const Duration(milliseconds: 800),
      ),
    );
  }
}
