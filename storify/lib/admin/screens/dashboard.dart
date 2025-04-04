import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/admin/widgets/longPressDraggable.dart';

// Import your four dashboard widgets:
import 'package:storify/admin/widgets/ordersBySuperMarket.dart';
import 'package:storify/admin/widgets/ordersOverview.dart';
import 'package:storify/admin/widgets/orderCount.dart';
import 'package:storify/admin/widgets/profit.dart';
import 'package:storify/GeneralWidgets/navigationBar.dart';
import 'package:storify/admin/widgets/cards.dart';
import 'package:storify/admin/widgets/topProductsList.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Our 4 dashboard widgets in a list (initial order).
  final List<Widget> _dashboardWidgets = [
    Ordersbysupermarket(
      alShiniPercent: 50,
      alSudaniPercent: 10,
      alNidalPercent: 35,
      tilalSurdaPercent: 30,
      totalStores: 4,
      key: UniqueKey(),
    ),
    Ordersoverview(key: UniqueKey()),
    Ordercount(key: UniqueKey()),
    Profit(key: UniqueKey()),
  ];

  // Our 4 StatsCards in a list (initial order).
  final List<Widget> _statsCards = [
    StatsCard(
      percentage: "20 %",
      svgIconPath: "assets/images/totalProducts.svg",
      title: "Total Products",
      value: "25,430",
      key: UniqueKey(),
    ),
    StatsCard(
      percentage: "12 %",
      svgIconPath: "assets/images/totalPaidOrders.svg",
      title: "Total paid Orders",
      value: "16,000",
      key: UniqueKey(),
    ),
    StatsCard(
      percentage: "15 %",
      svgIconPath: "assets/images/totalUsers.svg",
      title: "Total User",
      value: "18,540k",
      key: UniqueKey(),
    ),
    StatsCard(
      percentage: "20 %",
      svgIconPath: "assets/images/totalStores.svg",
      title: "24,763",
      value: "24,763",
      key: UniqueKey(),
    ),
  ];

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        // Dashboard
        break;
      case 1:
        // Products
        break;
      case 2:
        // Orders
        break;
      case 3:
        // Stores
        break;
      case 4:
        // More
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: MyNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavItemTap,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(left: 45.w, top: 20.h, right: 45.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// --- Dashboard Title & Filter Button ---
                Row(
                  children: [
                    Text(
                      "Dashboard",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 246, 246, 246),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 36, 50, 69),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        fixedSize: Size(138.w, 50.h),
                        elevation: 1,
                      ),
                      onPressed: () {},
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/images/filter.svg',
                            width: 18.w,
                            height: 18.h,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Filter',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color.fromARGB(255, 105, 123, 123),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40.h),

                /// --- Draggable Stats Cards (2x1 grid) ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Total available width for stats cards
                    final availableWidth = constraints.maxWidth;
                    // We display the stats cards in a single row (or adjust columns as needed)
                    // Here, we use 4 cards in one row.
                    const numberOfCards = 4;
                    const spacing = 40.0;
                    final cardWidth =
                        (availableWidth - ((numberOfCards - 1) * spacing)) /
                            numberOfCards;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: 20,
                      children: List.generate(_statsCards.length, (index) {
                        return _buildDraggableStatsCardItem(index, cardWidth);
                      }),
                    );
                  },
                ),
                SizedBox(height: 20.h),

                /// --- Draggable 2x2 Grid of the Dashboard Widgets ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing = 20.w;
                    const columns = 2;
                    final itemWidth =
                        (constraints.maxWidth - (columns - 1) * spacing) /
                            columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children:
                          List.generate(_dashboardWidgets.length, (index) {
                        return _buildDraggableItem(index, itemWidth);
                      }),
                    );
                  },
                ),

                ProductsTable(),
                SizedBox(height: 101.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a single draggable + droppable dashboard widget
  Widget _buildDraggableItem(int index, double itemWidth) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: SizedBox(
        width: itemWidth,
        child: DragTarget<int>(
          builder: (context, candidateData, rejectedData) {
            return CustomLongPressDraggable<int>(
              data: index,
              feedback: SizedBox(
                width: itemWidth,
                child: Material(
                  color: Colors.transparent,
                  child: _dashboardWidgets[index],
                ),
              ),
              childWhenDragging: SizedBox(
                width: itemWidth,
                child: Opacity(
                  opacity: 0.3,
                  child: _dashboardWidgets[index],
                ),
              ),
              child: _dashboardWidgets[index],
            );
          },
          onWillAccept: (oldIndex) => oldIndex != index,
          onAccept: (oldIndex) {
            setState(() {
              final temp = _dashboardWidgets[oldIndex];
              _dashboardWidgets[oldIndex] = _dashboardWidgets[index];
              _dashboardWidgets[index] = temp;
            });
          },
        ),
      ),
    );
  }

  /// Build a single draggable + droppable stats card
  Widget _buildDraggableStatsCardItem(int index, double cardWidth) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: SizedBox(
        width: cardWidth,
        child: DragTarget<int>(
          builder: (context, candidateData, rejectedData) {
            return CustomLongPressDraggable<int>(
              data: index,
              feedback: SizedBox(
                width: cardWidth,
                child: Material(
                  color: Colors.transparent,
                  child: _statsCards[index],
                ),
              ),
              childWhenDragging: SizedBox(
                width: cardWidth,
                child: Opacity(
                  opacity: 0.3,
                  child: _statsCards[index],
                ),
              ),
              child: _statsCards[index],
            );
          },
          onWillAccept: (oldIndex) => oldIndex != index,
          onAccept: (oldIndex) {
            setState(() {
              final temp = _statsCards[oldIndex];
              _statsCards[oldIndex] = _statsCards[index];
              _statsCards[index] = temp;
            });
          },
        ),
      ),
    );
  }
}
