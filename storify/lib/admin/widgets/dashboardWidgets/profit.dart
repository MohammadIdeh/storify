import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:storify/admin/widgets/dashboardWidgets/dashboard_models.dart';
import 'package:storify/admin/widgets/dashboardWidgets/dashboard_service.dart';

class Profit extends StatefulWidget {
  const Profit({super.key});

  @override
  State<Profit> createState() => _ProfitState();
}

class _ProfitState extends State<Profit> {
  ProfitChartResponse? _profitData;
  bool _isLoading = false;
  String? _error;

  // Date selection
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _fetchProfitChart();
  }

  Future<void> _fetchProfitChart({String? startDate, String? endDate}) async {
    print(
        '🔄 Fetching profit chart with startDate: $startDate, endDate: $endDate');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await DashboardService.getProfitChart(
        startDate: startDate,
        endDate: endDate,
      );

      print(
          '✅ Profit chart data received: ${response.data.length} data points');
      print('💰 Total profit: ${response.profit}');
      print('📈 Growth: ${response.growth}%');

      setState(() {
        _profitData = response;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching profit chart: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final result = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (BuildContext context) {
        return _DateRangePickerDialog(
          initialStartDate: _startDate,
          initialEndDate: _endDate,
        );
      },
    );

    if (result != null) {
      setState(() {
        _startDate = result['start'];
        _endDate = result['end'];
      });

      await _fetchProfitChart(
        startDate: _dateFormatter.format(result['start']!),
        endDate: _dateFormatter.format(result['end']!),
      );
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _fetchProfitChart();
  }

  @override
  Widget build(BuildContext context) {
    // Bright blue background
    final Color backgroundColor = const Color(0xFF008CFF);
    // White line color
    final Color lineColor = Colors.white;
    // Purple color for the growth pill
    final Color pillColor = const Color(0xFF9D67FF);

    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 467.h,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
              ),
              SizedBox(height: 16.h),
              Text(
                'Loading profit data...',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
            ],
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
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                'Error loading profit data',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  _error!,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                    fontSize: 10.sp,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () => _fetchProfitChart(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: backgroundColor,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Retry',
                  style:
                      TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_profitData == null) {
      return Container(
        width: double.infinity,
        height: 467.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: Text(
            'No profit data available',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 16.sp,
            ),
          ),
        ),
      );
    }

    // Convert API data to chart spots
    final List<FlSpot> chartSpots = _generateChartSpots(_profitData!.data);
    final maxY = _calculateMaxY(chartSpots);
    final bool isGrowthPositive = _profitData!.growth >= 0;

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
              // Left side: "Profit" + profit value + date range
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
                      "\$${_profitData!.profit.toStringAsFixed(2)}",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "${_profitData!.dateRange.start} - ${_profitData!.dateRange.end}",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Right side: date picker and growth pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Date Range Picker Button
                  ElevatedButton.icon(
                    onPressed: _selectDateRange,
                    icon: Icon(
                      Icons.date_range,
                      size: 14.sp,
                      color: backgroundColor,
                    ),
                    label: Text(
                      _startDate != null && _endDate != null
                          ? "Custom"
                          : "Select",
                      style: GoogleFonts.spaceGrotesk(
                        color: backgroundColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size(0, 28.h),
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Growth pill
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isGrowthPositive ? pillColor : Colors.red,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGrowthPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          "${_profitData!.growth.abs()}%",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Clear Filter Button (only show if dates are selected)
                  if (_startDate != null && _endDate != null) ...[
                    SizedBox(height: 4.h),
                    TextButton(
                      onPressed: _clearDateFilter,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        minimumSize: Size(0, 20.h),
                      ),
                      child: Text(
                        "Clear",
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          SizedBox(height: 16.h),

          /// --- The Line Chart ---
          Expanded(
            child: LineChart(
              LineChartData(
                // X-axis: 0..6 (SAT..FRI), Y-axis: 0..maxY
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,

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
                        final dayNames = [
                          "SAT",
                          "SUN",
                          "MON",
                          "TUE",
                          "WED",
                          "THU",
                          "FRI"
                        ];
                        final dayIndex = spot.x.toInt();
                        final dayName = dayIndex < dayNames.length
                            ? dayNames[dayIndex]
                            : "";
                        final val = spot.y.toStringAsFixed(1);
                        return LineTooltipItem(
                          "$dayName\n\$$val",
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
                    spots: chartSpots,
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

  List<FlSpot> _generateChartSpots(List<double> data) {
    if (data.isEmpty || data.length != 7) {
      // Return default spots if data is invalid
      return List.generate(7, (index) => FlSpot(index.toDouble(), 0));
    }

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value;
      return FlSpot(index.toDouble(), value);
    }).toList();
  }

  double _calculateMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 10;

    final maxValue =
        spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    // Ensure minimum of 10 for better visual, add 20% padding
    return (maxValue < 10 ? 10 : maxValue * 1.2).ceilToDouble();
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

// Reuse the same DateRangePickerDialog from OrdersOverview
class _DateRangePickerDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const _DateRangePickerDialog({
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _displayFormatter = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF008CFF),
              onPrimary: Colors.white,
              surface: Color.fromARGB(255, 36, 50, 69),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF008CFF),
              onPrimary: Colors.white,
              surface: Color.fromARGB(255, 36, 50, 69),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _selectPresetRange(String preset) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (preset) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'Yesterday':
        start = DateTime(now.year, now.month, now.day - 1);
        end = DateTime(now.year, now.month, now.day - 1);
        break;
      case 'Last 7 days':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'Last 30 days':
        start = now.subtract(const Duration(days: 30));
        break;
      case 'This month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'Last month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
        break;
      default:
        return;
    }

    setState(() {
      _startDate = start;
      _endDate = end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canApply = _startDate != null && _endDate != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400.w,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF008CFF).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Date Range',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 20.sp,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Quick presets
            Text(
              'Quick Select',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                'Today',
                'Yesterday',
                'Last 7 days',
                'Last 30 days',
                'This month',
                'Last month',
              ].map((preset) {
                return GestureDetector(
                  onTap: () => _selectPresetRange(preset),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008CFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF008CFF).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      preset,
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF008CFF),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 20.h),

            // Date selectors
            Row(
              children: [
                // Start Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white70,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      GestureDetector(
                        onTap: _selectStartDate,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.white70,
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  _startDate != null
                                      ? _displayFormatter.format(_startDate!)
                                      : 'Select start',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: _startDate != null
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12.w),

                // End Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white70,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      GestureDetector(
                        onTap: _selectEndDate,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.white70,
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  _endDate != null
                                      ? _displayFormatter.format(_endDate!)
                                      : 'Select end',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: _endDate != null
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canApply
                        ? () {
                            Navigator.of(context).pop({
                              'start': _startDate!,
                              'end': _endDate!,
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canApply
                          ? const Color(0xFF008CFF)
                          : Colors.grey.withOpacity(0.3),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
