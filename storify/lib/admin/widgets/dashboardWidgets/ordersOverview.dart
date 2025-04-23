import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class Ordersoverview extends StatefulWidget {
  const Ordersoverview({super.key});

  @override
  State<Ordersoverview> createState() => _OrdersoverviewState();
}

class _OrdersoverviewState extends State<Ordersoverview> {
  // The currently selected period. Default = "Monthly"
  String _selectedPeriod = "Monthly";

  // Example data sets for each period (just placeholders).
  // Adjust to your real data as needed.
  final Map<String, List<FlSpot>> _dataMap = {
    "Monthly": [
      FlSpot(0, 10),
      FlSpot(1, 12),
      FlSpot(2, 8),
      FlSpot(3, 15),
      FlSpot(4, 10),
      FlSpot(5, 18),
      FlSpot(6, 7),
    ],
    "Weekly": [
      FlSpot(0, 3),
      FlSpot(1, 6),
      FlSpot(2, 4),
      FlSpot(3, 9),
      FlSpot(4, 7),
      FlSpot(5, 11),
      FlSpot(6, 5),
    ],
    "Yearly": [
      FlSpot(0, 18),
      FlSpot(1, 14),
      FlSpot(2, 10),
      FlSpot(3, 16),
      FlSpot(4, 12),
      FlSpot(5, 19),
      FlSpot(6, 15),
    ],
  };

  @override
  Widget build(BuildContext context) {
    // Background color similar to your screenshot (#2D3C4E)
    final Color backgroundColor = const Color.fromARGB(255, 36, 50, 69);

    // Retrieve the FlSpot data for the currently selected period
    final List<FlSpot> currentSpots = _dataMap[_selectedPeriod] ?? [];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- Header Row: Title & "Dropdown" ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Orders Overview",
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 25.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Wrap the "Weekly" text & icon in a PopupMenuButton
              PopupMenuButton<String>(
                // The currently selected period will update here
                onSelected: (value) {
                  setState(() {
                    _selectedPeriod = value;
                  });
                },
                // Gray background for the small appearing container
                color: const Color.fromARGB(255, 36, 50, 69),

                // The button's child is your row with the icon + text
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white.withOpacity(0.7),
                      size: 18.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _selectedPeriod, // e.g. "Monthly", "Weekly", "Yearly"
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14.sp,
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white.withOpacity(0.7),
                      size: 20.sp,
                    )
                  ],
                ),
                itemBuilder: (context) => [
                  // Popup items: "Monthly", "Weekly", "Yearly"
                  PopupMenuItem(
                    value: "Monthly",
                    child: Text(
                      "Monthly",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: "Weekly",
                    child: Text(
                      "Weekly",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: "Yearly",
                    child: Text(
                      "Yearly",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
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
            height: 377.h,
            child: LineChart(
              LineChartData(
                // The range of our chart
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 20,

                /// --- Tooltip (shows "January\n$xxk", or "Week\n$xxk", etc.) ---
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      // We'll change the label based on _selectedPeriod
                      String periodLabel;
                      switch (_selectedPeriod) {
                        case "Weekly":
                          periodLabel = "Week";
                          break;
                        case "Yearly":
                          periodLabel = "Year";
                          break;
                        default:
                          periodLabel = "January";
                      }

                      return touchedSpots.map((spot) {
                        final value = spot.y.toStringAsFixed(0);
                        return LineTooltipItem(
                          "$periodLabel\n\$$value" "k",
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

                /// --- Grid lines (horizontal only) ---
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),

                /// --- Borders around the chart (disabled) ---
                borderData: FlBorderData(
                  show: false,
                ),

                /// --- Axis Titles & Ticks ---
                titlesData: FlTitlesData(
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),

                  // Bottom axis: days of the week
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

                  // Left axis: $0, $5k, $10k, $15k, $20k
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return _buildLeftTitle("\$0");
                          case 5:
                            return _buildLeftTitle("\$5k");
                          case 10:
                            return _buildLeftTitle("\$10k");
                          case 15:
                            return _buildLeftTitle("\$15k");
                          case 20:
                            return _buildLeftTitle("\$20k");
                          default:
                            return Container();
                        }
                      },
                    ),
                  ),
                ),

                /// --- The actual line data (spots) ---
                lineBarsData: [
                  LineChartBarData(
                    // Use the current data for the selected period
                    spots: currentSpots,
                    isCurved: true,
                    color: const Color(0xFF00A6FF), // Bright blue line
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                    ),
                    // Blue fill under the line
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF00A6FF).withOpacity(0.3),
                          const Color(0xFF00A6FF).withOpacity(0.0),
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

  /// --- Helpers for bottom axis labels (SAT, SUN, etc.) ---
  Widget _buildBottomTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white.withOpacity(0.7),
          fontSize: 13.sp,
        ),
      ),
    );
  }

  /// --- Helpers for left axis labels ($0, $5k, etc.) ---
  Widget _buildLeftTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white.withOpacity(0.7),
          fontSize: 13.sp,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}
