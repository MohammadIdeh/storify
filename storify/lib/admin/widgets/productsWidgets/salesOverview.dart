import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class Salesoverview extends StatefulWidget {
  const Salesoverview({super.key});

  @override
  State<Salesoverview> createState() => _SalesoverviewState();
}

class _SalesoverviewState extends State<Salesoverview> {
  @override
  Widget build(BuildContext context) {
    // Dark background color
    final Color backgroundColor = const Color.fromARGB(255, 36, 50, 69);
    // Purple line color
    final Color lineColor = const Color(0xFF9D67FF);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- Header Row: "Order Count" & "↑12%" ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sales Overview",
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 25.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: Colors.green,
                    size: 16.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    "12%",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.green,
                      fontSize: 16.sp, // Slightly bigger
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 16.h),

          /// --- The Line Chart ---
          SizedBox(
            width: double.infinity,
            height: 482.h,
            child: LineChart(
              LineChartData(
                // Y-axis from 0 to 25
                minY: 0,
                maxY: 25,
                // X-axis from 0 to 6 (SAT=0 -> FRI=6)
                minX: 0,
                maxX: 6,

                /// --- Tooltip ("value  ↑15%") ---
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final value = spot.y.toStringAsFixed(0);
                        return LineTooltipItem(
                          "$value  ↑ 15%",
                          GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),

                /// --- No grid lines or border ---
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: false,
                ),
                borderData: FlBorderData(show: false),

                /// --- Axis Titles & Ticks ---
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  // Bottom axis: days
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
                  // Left axis: 0,5,10,15,20,25
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return _buildLeftTitle("0");
                          case 5:
                            return _buildLeftTitle("5");
                          case 10:
                            return _buildLeftTitle("10");
                          case 15:
                            return _buildLeftTitle("15");
                          case 20:
                            return _buildLeftTitle("20");
                          case 25:
                            return _buildLeftTitle("25");
                          default:
                            return Container();
                        }
                      },
                    ),
                  ),
                ),

                /// --- The purple zig-zag line with dots ---
                lineBarsData: [
                  LineChartBarData(
                    // Zig-zag pattern
                    spots: const [
                      FlSpot(0, 8), // SAT
                      FlSpot(1, 21), // SUN
                      FlSpot(2, 15), // MON
                      FlSpot(3, 10), // TUE
                      FlSpot(4, 17), // WED
                      FlSpot(5, 12), // THU
                      FlSpot(6, 25), // FRI
                    ],
                    isCurved: false, // Straight lines for zig-zag
                    color: lineColor,
                    barWidth: 3,
                    // Turn dots on, use white
                    dotData: FlDotData(
                      show: false,
                    ),
                    // Fill under the line
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withOpacity(0.3),
                          lineColor.withOpacity(0.0),
                        ],
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

  /// --- Bottom axis labels (SAT, SUN, etc.) ---
  Widget _buildBottomTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12.sp,
        ),
      ),
    );
  }

  /// --- Left axis labels (0, 5, 10, 15, 20, 25) ---
  Widget _buildLeftTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12.sp,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}
