import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:storify/admin/widgets/dashboardWidgets/dashboard_models.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class OrdersByCustomers extends StatelessWidget {
  final TopCustomersResponse customersData;

  const OrdersByCustomers({
    super.key,
    required this.customersData,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isRtl = LocalizationHelper.isRTL(context);
    final Color backgroundColor = const Color.fromARGB(255, 36, 50, 69);

    // Generate colors for the pie chart
    final List<Color> pieColors =
        _generateColors(customersData.customers.length);

    return Container(
      width: double.infinity,
      height: 467.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  l10n.ordersByCustomers,
                  style: LocalizationHelper.isArabic(context)
                      ? GoogleFonts.cairo(
                          fontSize: 25.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 25.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                ),
                SizedBox(height: 16.h),

                // Scrollable customer list
                SizedBox(
                  height: 300.h, // Fixed height for scrollable area
                  child: CustomScrollView(
                    slivers: [
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= customersData.customers.length) {
                              return null;
                            }

                            final customer = customersData.customers[index];
                            final color = pieColors[index % pieColors.length];

                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: _buildCustomerSection(
                                customer.name,
                                customer.orderPercentage,
                                color,
                                customer,
                                context,
                              ),
                            );
                          },
                          childCount: customersData.customers.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 20.w),
          _buildDonutChart(
            customersData.customers,
            customersData.summary.totalCustomers,
            pieColors,
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(String customerName, double percentage,
      Color color, Customer customer, BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final clampedPercent = percentage.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: LocalizationHelper.isArabic(context)
                              ? GoogleFonts.cairo(
                                  fontSize: 16.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  fontSize: 16.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${customer.orderCount} ${l10n.orders.toLowerCase()} • \$${customer.totalSpent.toStringAsFixed(0)}",
                          style: LocalizationHelper.isArabic(context)
                              ? GoogleFonts.cairo(
                                  fontSize: 12.sp,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  fontSize: 12.sp,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _getSegmentColor(customer.segment),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                "${percentage.toStringAsFixed(1)}%",
                style: LocalizationHelper.isArabic(context)
                    ? GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      )
                    : GoogleFonts.spaceGrotesk(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                Container(
                  width: availableWidth * (clampedPercent / 100.0),
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDonutChart(
    List<Customer> customers,
    int totalCustomers,
    List<Color> colorList,
    BuildContext context,
  ) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    // Prepare data for pie chart (top 6 customers to avoid overcrowding)
    final topCustomers = customers.take(6).toList();
    final dataMap = <String, double>{};

    for (int i = 0; i < topCustomers.length; i++) {
      final customer = topCustomers[i];
      dataMap[customer.name] = customer.orderPercentage;
    }

    // If there are more customers, group them as "Others"
    if (customers.length > 6) {
      final otherPercentage = customers
          .skip(6)
          .fold(0.0, (sum, customer) => sum + customer.orderPercentage);
      if (otherPercentage > 0) {
        dataMap["Others"] = otherPercentage;
      }
    }

    final double chartSize = 0.19.sw;
    return SizedBox(
      width: chartSize,
      height: chartSize,
      child: PieChart(
        dataMap: dataMap,
        chartType: ChartType.ring,
        baseChartColor: Colors.white.withOpacity(0.1),
        colorList: colorList,
        chartRadius: chartSize * 0.5,
        ringStrokeWidth: chartSize * 0.1,
        centerWidget: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.total,
              style: LocalizationHelper.isArabic(context)
                  ? GoogleFonts.cairo(
                      textStyle: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : GoogleFonts.spaceGrotesk(
                      textStyle: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
            ),
            Text(
              "$totalCustomers",
              style: LocalizationHelper.isArabic(context)
                  ? GoogleFonts.cairo(
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : GoogleFonts.spaceGrotesk(
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            Text(
              l10n.customers,
              style: LocalizationHelper.isArabic(context)
                  ? GoogleFonts.cairo(
                      textStyle: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : GoogleFonts.spaceGrotesk(
                      textStyle: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
            ),
          ],
        ),
        legendOptions: const LegendOptions(showLegends: false),
        chartValuesOptions: const ChartValuesOptions(showChartValues: false),
        animationDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  List<Color> _generateColors(int count) {
    final baseColors = [
      const Color(0xB200E074), // Green
      const Color(0xB2FE8A00), // Orange
      const Color(0xB200A6FF), // Blue
      const Color(0xB2FF1474), // Pink
      const Color(0xB29D67FF), // Purple
      const Color(0xB2FFD700), // Gold
      const Color(0xB2FF6B6B), // Red
      const Color(0xB24ECDC4), // Teal
      const Color(0xB2A8E6CF), // Mint
      const Color(0xB2F7DC6F), // Yellow
    ];

    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      colors.add(baseColors[i % baseColors.length]);
    }
    return colors;
  }

  Color _getSegmentColor(String segment) {
    switch (segment.toLowerCase()) {
      case 'vip active':
        return const Color(0xFF9D67FF); // Purple
      case 'regular active':
        return const Color(0xFF00A6FF); // Blue
      case 'new':
        return const Color(0xFF00E074); // Green
      case 'occasional':
        return const Color(0xFFFE8A00); // Orange
      case 'inactive':
        return const Color(0xFF666666); // Gray
      default:
        return const Color(0xFF444444); // Default gray
    }
  }
}
