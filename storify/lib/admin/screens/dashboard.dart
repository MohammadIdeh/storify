import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/admin/screens/Categories.dart';
import 'package:storify/admin/screens/orders.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/screens/roleManegment.dart';
import 'package:storify/GeneralWidgets/longPressDraggable.dart';
import 'package:storify/admin/screens/track.dart';
import 'package:storify/admin/widgets/dashboardWidgets/ordersBySuperMarket.dart';
import 'package:storify/admin/widgets/dashboardWidgets/ordersOverview.dart';
import 'package:storify/admin/widgets/dashboardWidgets/orderCount.dart';
import 'package:storify/admin/widgets/dashboardWidgets/profit.dart';
import 'package:storify/admin/widgets/navigationBar.dart';
import 'package:storify/admin/widgets/dashboardWidgets/cards.dart';
import 'package:storify/admin/widgets/dashboardWidgets/topProductsList.dart';
import 'package:storify/admin/widgets/dashboardWidgets/topStoresList.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String? profilePictureUrl;

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
  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

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
        break;
      case 1:
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Productsscreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
        break;
      case 2:
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const CategoriesScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
        break;
      case 3:
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Orders(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
        break;
      case 4:
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Rolemanegment(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
        break;
      case 5:
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const Track(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ));
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
          profilePictureUrl:
              profilePictureUrl, // Pass the profile picture URL here
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
                        fontSize: 35.sp,
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
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Text(
                      'Top products',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 246, 246, 246),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15.h),
                ProductsTable(),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Text(
                      'Top Stores',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 246, 246, 246),
                      ),
                    ),
                    SizedBox(
                      width: 830.w,
                    ),
                    Text(
                      'Best Selling Product',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 246, 246, 246),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15.h),
                Wrap(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SalesTableWidget(),
                        ),
                        SizedBox(
                            width: 20
                                .w), // Optional spacing between the two widgets
                        Expanded(
                          child: SalesTableWidget(),
                        ),
                      ],
                    )
                  ],
                ),

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
