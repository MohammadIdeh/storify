import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class Profit extends StatefulWidget {
  const Profit({super.key});

  @override
  State<Profit> createState() => _ProfitState();
}

class _ProfitState extends State<Profit> {
  @override
  Widget build(BuildContext context) {
    // Bright blue background
    final Color backgroundColor = const Color(0xFF008CFF);
    // White line color
    final Color lineColor = Colors.white;
    // Purple color for the top-right pill
    final Color pillColor = const Color(0xFF9D67FF);

    return Container(
      width: double.infinity,
      height: 467.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- Header Row ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side: "Profit" + $12.09
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Profit",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 25.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "\$12.09",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Right side: purple pill with arrow & "12%"
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      size: 14.sp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "12%",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          /// --- The Line Chart ---
          SizedBox(
            width: double.infinity,
            height: 220.h, // Adjust as you like
            child: LineChart(
              LineChartData(
                // X-axis: 0..6 (SAT..FRI), Y-axis: 0..14
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 14,

                /// --- Grid lines (dotted) ---
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false, // no vertical lines
                  drawHorizontalLine: true, // dotted horizontal lines
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.3),
                    strokeWidth: 1,
                    dashArray: [4, 4], // dotted pattern
                  ),
                ),
                borderData: FlBorderData(show: false),

                /// --- Axis titles & ticks ---
                titlesData: FlTitlesData(
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),

                  // Bottom axis: SAT..FRI
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return _buildBottomTitle("SAT");
                          case 1:
                            return _buildBottomTitle("SUN");
                          case 2:
                            return _buildBottomTitle("MON");
                          case 3:
                            return _buildBottomTitle("TUE");
                          case 4:
                            return _buildBottomTitle("WED");
                          case 5:
                            return _buildBottomTitle("THU");
                          case 6:
                            return _buildBottomTitle("FRI");
                          default:
                            return Container();
                        }
                      },
                    ),
                  ),
                  // Left axis: optional if you want numeric labels
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),

                /// --- Touch/Tooltip ---
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final val = spot.y.toStringAsFixed(1);
                        return LineTooltipItem(
                          "\$$val",
                          GoogleFonts.spaceGrotesk(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),

                /// --- The actual line data ---
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 5),
                      FlSpot(1, 8),
                      FlSpot(2, 3),
                      FlSpot(3, 10),
                      FlSpot(4, 6),
                      FlSpot(5, 12),
                      FlSpot(6, 9),
                    ],
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    // Fill under line
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom axis labels: SAT..FRI
  Widget _buildBottomTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white.withOpacity(0.8),
          fontSize: 12.sp,
        ),
      ),
    );
  }
}
