import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/dashboardWidgets/dashboard_models.dart';
import 'package:storify/admin/widgets/dashboardWidgets/dashboard_service.dart';

class OrdersOverviewWidget extends StatefulWidget {
  final OrdersOverviewResponse ordersData;

  const OrdersOverviewWidget({
    super.key,
    required this.ordersData,
  });

  @override
  State<OrdersOverviewWidget> createState() => _OrdersOverviewWidgetState();
}

class _OrdersOverviewWidgetState extends State<OrdersOverviewWidget> {
  String _selectedPeriod = "weekly";
  OrdersOverviewResponse? _currentData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentData = widget.ordersData;
    _selectedPeriod = widget.ordersData.period;
  }

  Future<void> _fetchDataForPeriod(String period) async {
    if (period == _selectedPeriod && _currentData != null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await DashboardService.getOrdersOverview(period: period);
      setState(() {
        _currentData = response;
        _selectedPeriod = period;
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

    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 467.h,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF00A6FF),
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
          borderRadius: BorderRadius.circular(24),
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
                'Error loading data',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              ElevatedButton(
                onPressed: () => _fetchDataForPeriod(_selectedPeriod),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A6FF),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentData == null) {
      return Container(
        width: double.infinity,
        height: 467.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 16.sp,
            ),
          ),
        ),
      );
    }

    // Convert API data to chart points
    final List<FlSpot> chartSpots = _generateChartSpots(_currentData!.data);
    final maxY = _calculateMaxY(chartSpots);

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
          /// --- Header Row: Title & Period Selector ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Orders Overview",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 25.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "\$${_currentData!.summary.current['revenue']?.toStringAsFixed(0) ?? '0'}",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        _currentData!.summary.changes['revenue'] >= 0 
                            ? Icons.arrow_upward 
                            : Icons.arrow_downward,
                        color: _currentData!.summary.changes['revenue'] >= 0 
                            ? Colors.green 
                            : Colors.red,
                        size: 14.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        "${_currentData!.summary.changes['revenue']?.toStringAsFixed(0) ?? '0'}%",
                        style: GoogleFonts.spaceGrotesk(
                          color: _currentData!.summary.changes['revenue'] >= 0 
                              ? Colors.green 
                              : Colors.red,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: _fetchDataForPeriod,
                color: const Color.fromARGB(255, 36, 50, 69),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white.withOpacity(0.7),
                      size: 18.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _selectedPeriod.capitalize(),
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
                  PopupMenuItem(
                    value: "daily",
                    child: Text(
                      "Daily",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: "weekly",
                    child: Text(
                      "Weekly",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: "monthly",
                    child: Text(
                      "Monthly",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: "yearly",
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
            height: 300.h,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (chartSpots.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,

                /// --- Tooltip ---
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < _currentData!.data.length) {
                          final dataPoint = _currentData!.data[index];
                          return LineTooltipItem(
                            "${dataPoint.label}\n\$${dataPoint.revenue.toStringAsFixed(0)}",
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
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),

                  // Bottom axis: labels from API data
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _currentData!.data.length) {
                          return _buildBottomTitle(_currentData!.data[index].label);
                        }
                        return Container();
                      },
                    ),
                  ),

                  // Left axis: revenue values
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        return _buildLeftTitle("\$${value.toInt()}");
                      },
                    ),
                  ),
                ),

                /// --- The actual line data ---
                lineBarsData: [
                  LineChartBarData(
                    spots: chartSpots,
                    isCurved: true,
                    color: const Color(0xFF00A6FF),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
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

  List<FlSpot> _generateChartSpots(List<OrderData> data) {
    if (data.isEmpty) {
      return [FlSpot(0, 0)];
    }
    
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final orderData = entry.value;
      return FlSpot(index.toDouble(), orderData.revenue);
    }).toList();
  }

  double _calculateMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;
    
    final maxValue = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    // Add 20% padding to the max value
    return (maxValue * 1.2).ceilToDouble();
  }

  Widget _buildBottomTitle(String text) {
    // Truncate long labels
    final displayText = text.length > 3 ? text.substring(0, 3) : text;
    
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Text(
        displayText,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white.withOpacity(0.7),
          fontSize: 11.sp,
        ),
      ),
    );
  }

  Widget _buildLeftTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white.withOpacity(0.7),
          fontSize: 11.sp,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}