import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Models for the API response
class ProductSalesData {
  final String day;
  final double value;

  ProductSalesData({required this.day, required this.value});

  factory ProductSalesData.fromJson(Map<String, dynamic> json) {
    return ProductSalesData(
      day: json['day'],
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}

class ProductSalesResponse {
  final ProductInfo product;
  final SalesInfo sales;
  final List<ProductSalesData> data;
  final DateRangeInfo dateRange;
  final double maxValue;

  ProductSalesResponse({
    required this.product,
    required this.sales,
    required this.data,
    required this.dateRange,
    required this.maxValue,
  });

  factory ProductSalesResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List)
        .map((item) => ProductSalesData.fromJson(item))
        .toList();

    // Calculate max value for chart scaling
    final maxValue = dataList.isEmpty
        ? 100.0
        : dataList.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return ProductSalesResponse(
      product: ProductInfo.fromJson(json['product']),
      sales: SalesInfo.fromJson(json['sales']),
      data: dataList,
      dateRange: DateRangeInfo.fromJson(json['dateRange']),
      maxValue: maxValue,
    );
  }
}

class ProductInfo {
  final int productId;
  final String name;
  final int currentStock;

  ProductInfo({
    required this.productId,
    required this.name,
    required this.currentStock,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      productId: json['productId'],
      name: json['name'],
      currentStock: json['currentStock'],
    );
  }
}

class SalesInfo {
  final int totalSold;
  final double revenue;
  final double growth;

  SalesInfo({
    required this.totalSold,
    required this.revenue,
    required this.growth,
  });

  factory SalesInfo.fromJson(Map<String, dynamic> json) {
    return SalesInfo(
      totalSold: json['totalSold'],
      revenue: (json['revenue'] ?? 0).toDouble(),
      growth: (json['growth'] ?? 0).toDouble(),
    );
  }
}

class DateRangeInfo {
  final String start;
  final String end;

  DateRangeInfo({required this.start, required this.end});

  factory DateRangeInfo.fromJson(Map<String, dynamic> json) {
    return DateRangeInfo(
      start: json['start'],
      end: json['end'],
    );
  }
}

class ProductSalesOverviewWidget extends StatefulWidget {
  final int productId;

  const ProductSalesOverviewWidget({
    super.key,
    required this.productId,
  });

  @override
  State<ProductSalesOverviewWidget> createState() =>
      _ProductSalesOverviewWidgetState();
}

class _ProductSalesOverviewWidgetState
    extends State<ProductSalesOverviewWidget> {
  ProductSalesResponse? _salesData;
  bool _isLoading = false;
  String? _error;

  // Date selection
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _fetchProductSales();
  }

  Future<void> _fetchProductSales({String? startDate, String? endDate}) async {
    debugPrint('🔄 Fetching product sales for product ${widget.productId}');
    if (startDate != null && endDate != null) {
      debugPrint('📅 Date range: $startDate to $endDate');
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Build URL with optional date parameters
      String url =
          'https://finalproject-a5ls.onrender.com/dashboard/product-sales/${widget.productId}';
      if (startDate != null && endDate != null) {
        url += '?startDate=$startDate&endDate=$endDate';
      }

      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Product sales data received');
        debugPrint('📊 Total sold: ${data['sales']['totalSold']}');
        debugPrint('💰 Revenue: ${data['sales']['revenue']}');

        setState(() {
          _salesData = ProductSalesResponse.fromJson(data);
          _isLoading = false;
        });
      } else {
        debugPrint('❌ Error fetching product sales: ${response.statusCode}');
        setState(() {
          _error = 'Failed to load sales data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Exception fetching product sales: $e');
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
        return _ProductSalesDateRangePickerDialog(
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

      await _fetchProductSales(
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
    _fetchProductSales();
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = const Color.fromARGB(255, 36, 50, 69);

    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 585.h,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: const Color(0xFF00A6FF),
              ),
              SizedBox(height: 16.h),
              Text(
                'Loading sales data...',
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
                'Error loading sales data',
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
                onPressed: () => _fetchProductSales(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A6FF),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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

    if (_salesData == null) {
      return Container(
        width: double.infinity,
        height: 585.h,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            'No sales data available',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 16.sp,
            ),
          ),
        ),
      );
    }

    // Convert API data to chart points
    final List<FlSpot> chartSpots = _generateChartSpots(_salesData!.data);
    final maxY = _salesData!.maxValue > 0 ? _salesData!.maxValue * 1.2 : 100.0;

    return Container(
      height: 585.h,
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- Header Row: Title & Date Selector ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Product Sales",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 25.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        "\$${_salesData!.sales.revenue.toStringAsFixed(0)}",
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      if (_salesData!.sales.growth > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              color: Colors.green,
                              size: 16.sp,
                            ),
                            Text(
                              "${_salesData!.sales.growth.toStringAsFixed(1)}%",
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.green,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Text(
                    "${_salesData!.sales.totalSold} units sold",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    "${_salesData!.dateRange.start} - ${_salesData!.dateRange.end}",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  // Date Range Picker Button
                  ElevatedButton.icon(
                    onPressed: _selectDateRange,
                    icon: Icon(
                      Icons.date_range,
                      size: 16.sp,
                      color: Colors.white,
                    ),
                    label: Text(
                      _startDate != null && _endDate != null
                          ? "Custom Range"
                          : "Select Dates",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A6FF),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size(0, 32.h),
                    ),
                  ),

                  // Clear Filter Button (only show if dates are selected)
                  if (_startDate != null && _endDate != null) ...[
                    SizedBox(height: 4.h),
                    TextButton(
                      onPressed: _clearDateFilter,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        minimumSize: Size(0, 24.h),
                      ),
                      child: Text(
                        "Clear Filter",
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white70,
                          fontSize: 10.sp,
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
          SizedBox(
            width: double.infinity,
            height: 410.h, // Increased from 300.h to 420.h

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
                      return touchedSpots
                          .map((spot) {
                            final index = spot.x.toInt();
                            if (index < _salesData!.data.length) {
                              final dataPoint = _salesData!.data[index];
                              return LineTooltipItem(
                                "${dataPoint.day}\n${dataPoint.value.toStringAsFixed(0)} units",
                                GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              );
                            }
                            return null;
                          })
                          .where((item) => item != null)
                          .cast<LineTooltipItem>()
                          .toList();
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
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),

                  // Bottom axis: days
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _salesData!.data.length) {
                          return _buildBottomTitle(_salesData!.data[index].day);
                        }
                        return Container();
                      },
                    ),
                  ),

                  // Left axis: sales values
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        return _buildLeftTitle("${_formatNumber(value)}");
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
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF00A6FF),
                        );
                      },
                    ),
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

  List<FlSpot> _generateChartSpots(List<ProductSalesData> data) {
    if (data.isEmpty) {
      return [FlSpot(0, 0)];
    }

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final salesData = entry.value;
      return FlSpot(index.toDouble(), salesData.value);
    }).toList();
  }

  Widget _buildBottomTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Text(
        text,
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
          fontSize: 10.sp,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000) {
      return (value / 1000).toStringAsFixed(1) + 'k';
    }
    return value.toInt().toString();
  }
}

// Custom Date Range Picker Dialog (copied from OrdersOverviewWidget)
class _ProductSalesDateRangePickerDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const _ProductSalesDateRangePickerDialog({
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<_ProductSalesDateRangePickerDialog> createState() =>
      _ProductSalesDateRangePickerDialogState();
}

class _ProductSalesDateRangePickerDialogState
    extends State<_ProductSalesDateRangePickerDialog> {
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
              primary: Color(0xFF00A6FF),
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
        // If end date is before start date, adjust it
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
              primary: Color(0xFF00A6FF),
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
            color: const Color(0xFF00A6FF).withOpacity(0.3),
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
                      color: const Color(0xFF00A6FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00A6FF).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      preset,
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFF00A6FF),
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
                          ? const Color(0xFF00A6FF)
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
