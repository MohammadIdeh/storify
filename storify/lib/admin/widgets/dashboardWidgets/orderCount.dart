import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/dashboardWidgets/dashboard_models.dart';
import 'package:storify/admin/widgets/dashboardWidgets/dashboard_service.dart';
// Import your models and service

class OrderCountWidget extends StatefulWidget {
  const OrderCountWidget({super.key});

  @override
  State<OrderCountWidget> createState() => _OrderCountWidgetState();
}

class _OrderCountWidgetState extends State<OrderCountWidget> {
  // API Data
  OrderCountResponse? _orderCountData;
  
  // Loading and error states
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrderCounts();
  }

  Future<void> _fetchOrderCounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await DashboardService.getOrderCounts();
      setState(() {
        _orderCountData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = const Color.fromARGB(255, 36, 50, 69);
    final Color lineColor = const Color(0xFF9D67FF);

    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 467.h,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: lineColor,
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        height: 467.h,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                'Error loading order counts',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _error!,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white70,
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _fetchOrderCounts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: lineColor,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_orderCountData == null) {
      return Container(
        width: double.infinity,
        height: 467.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Center(
          child: Text(
            'No order count data available',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 16.sp,
            ),
          ),
        ),
      );
    }

    // Convert API data to chart spots
    final List<FlSpot> chartSpots = _convertToChartSpots(_orderCountData!.data);
    final maxY = _calculateMaxY(chartSpots);
    final isGrowthPositive = _orderCountData!.growth >= 0;

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
          /// --- Header Row: "Order Count" & Growth ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order Count",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 25.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Total: ${_orderCountData!.total}",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isGrowthPositive 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isGrowthPositive ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGrowthPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isGrowthPositive ? Colors.green : Colors.red,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "${_orderCountData!.growth.abs()}%",
                      style: GoogleFonts.spaceGrotesk(
                        color: isGrowthPositive ? Colors.green : Colors.red,
                        fontSize: 16.sp,
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
            height: 350.h,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                minX: 0,
                maxX: (chartSpots.length - 1).toDouble(),

                /// --- Tooltip ---
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < _orderCountData!.data.length) {
                          final dayData = _orderCountData!.data[index];
                          return LineTooltipItem(
                            "${dayData.day}\n${dayData.count} orders",
                            GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          );
                        }
                        return null;
                      }).where((item) => item != null).cast<LineTooltipItem>().toList();
                    },
                  ),
                ),

                /// --- Grid lines ---
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
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
                        final index = value.toInt();
                        if (index >= 0 && index < _orderCountData!.data.length) {
                          return _buildBottomTitle(_orderCountData!.data[index].day);
                        }
                        return Container();
                      },
                    ),
                  ),
                  // Left axis: order counts
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: maxY > 5 ? (maxY / 5).ceilToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        return _buildLeftTitle(value.toInt().toString());
                      },
                    ),
                  ),
                ),

                /// --- The line with dots ---
                lineBarsData: [
                  LineChartBarData(
                    spots: chartSpots,
                    isCurved: false, // Straight lines for zig-zag effect
                    color: lineColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: lineColor,
                        );
                      },
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

  List<FlSpot> _convertToChartSpots(List<OrderCountData> data) {
    if (data.isEmpty) {
      return [FlSpot(0, 0)];
    }
    
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final orderData = entry.value;
      return FlSpot(index.toDouble(), orderData.count.toDouble());
    }).toList();
  }

  double _calculateMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 5;
    
    final maxValue = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    // Ensure minimum of 5 for better visual, add 20% padding
    return (maxValue < 5 ? 5 : maxValue * 1.2).ceilToDouble();
  }

  /// --- Bottom axis labels (days) ---
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

  /// --- Left axis labels (counts) ---
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