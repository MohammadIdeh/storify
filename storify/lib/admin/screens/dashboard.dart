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
import 'package:storify/admin/widgets/dashboardWidgets/dashboard_models.dart';
import 'package:storify/admin/widgets/dashboardWidgets/dashboard_service.dart';
import 'package:storify/admin/widgets/dashboardWidgets/ordersByCustomer.dart';
import 'package:storify/admin/widgets/dashboardWidgets/ordersOverview.dart';
import 'package:storify/admin/widgets/dashboardWidgets/orderCount.dart';
import 'package:storify/admin/widgets/dashboardWidgets/profit.dart';
import 'package:storify/admin/widgets/navigationBar.dart';
import 'package:storify/admin/widgets/dashboardWidgets/cards.dart';
import 'package:storify/admin/widgets/dashboardWidgets/topProductsList.dart';

import 'package:storify/utilis/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String? profilePictureUrl;

  // API Data
  List<DashboardCard> _dashboardCards = [];
  TopCustomersResponse? _topCustomersData;
  OrdersOverviewResponse? _ordersOverviewData;
  TopProductsResponse? _topProductsData;
  OrderCountResponse? _orderCountData;

  // Loading states
  bool _isLoadingCards = true;
  bool _isLoadingCustomers = true;
  bool _isLoadingOrdersOverview = true;
  bool _isLoadingProducts = true;
  bool _isLoadingOrderCount = true;

  // Error states
  String? _cardsError;
  String? _customersError;
  String? _ordersOverviewError;
  String? _productsError;
  String? _orderCountError;

  // Drag & Drop Order Lists
  List<int> _statsCardsOrder = [];
  List<int> _dashboardWidgetsOrder = [];

  // Widget caches to prevent unnecessary recreation
  List<Widget>? _cachedBaseDashboardWidgets;
  List<Widget>? _cachedBaseStatsCards;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _loadSavedOrders();
    _fetchDashboardData();
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  // Load saved orders from SharedPreferences
  Future<void> _loadSavedOrders() async {
    final prefs = await SharedPreferences.getInstance();

    // Load stats cards order (default: [0, 1, 2, 3])
    final savedStatsOrder = prefs.getStringList('dashboard_stats_order');
    if (savedStatsOrder != null) {
      _statsCardsOrder = savedStatsOrder.map((e) => int.parse(e)).toList();
    } else {
      _statsCardsOrder = [0, 1, 2, 3]; // Default order
    }

    // Load dashboard widgets order (default: [0, 1, 2, 3])
    final savedWidgetsOrder = prefs.getStringList('dashboard_widgets_order');
    if (savedWidgetsOrder != null) {
      _dashboardWidgetsOrder =
          savedWidgetsOrder.map((e) => int.parse(e)).toList();
    } else {
      _dashboardWidgetsOrder = [0, 1, 2, 3]; // Default order
    }
  }

  // Save orders to SharedPreferences
  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();

    // Save stats cards order
    await prefs.setStringList(
      'dashboard_stats_order',
      _statsCardsOrder.map((e) => e.toString()).toList(),
    );

    // Save dashboard widgets order
    await prefs.setStringList(
      'dashboard_widgets_order',
      _dashboardWidgetsOrder.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _fetchDashboardData() async {
    // Fetch all dashboard data in parallel
    await Future.wait([
      _fetchDashboardCards(),
      _fetchTopCustomers(),
      _fetchOrdersOverview(),
      _fetchTopProducts(),
      _fetchOrderCount(),
    ]);
  }

  Future<void> _fetchDashboardCards() async {
    try {
      final response = await DashboardService.getDashboardCards();
      setState(() {
        _dashboardCards = response.cards;
        _isLoadingCards = false;
        _cardsError = null;

        // Clear cache to rebuild with new data
        _cachedBaseStatsCards = null;

        // Initialize stats cards order if needed
        if (_statsCardsOrder.isEmpty ||
            _statsCardsOrder.length != _dashboardCards.length) {
          _statsCardsOrder =
              List.generate(_dashboardCards.length, (index) => index);
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCards = false;
        _cardsError = e.toString();
        // Clear cache on error too
        _cachedBaseStatsCards = null;
      });
    }
  }

  Future<void> _fetchTopCustomers() async {
    try {
      final response = await DashboardService.getTopCustomers();
      setState(() {
        _topCustomersData = response;
        _isLoadingCustomers = false;
        _customersError = null;
        // Clear cache to rebuild with new data
        _cachedBaseDashboardWidgets = null;
      });
    } catch (e) {
      setState(() {
        _isLoadingCustomers = false;
        _customersError = e.toString();
        // Clear cache on error too
        _cachedBaseDashboardWidgets = null;
      });
    }
  }

  Future<void> _fetchOrdersOverview() async {
    try {
      final response = await DashboardService.getOrdersOverview();
      setState(() {
        _ordersOverviewData = response;
        _isLoadingOrdersOverview = false;
        _ordersOverviewError = null;
        // Clear cache to rebuild with new data
        _cachedBaseDashboardWidgets = null;
      });
    } catch (e) {
      setState(() {
        _isLoadingOrdersOverview = false;
        _ordersOverviewError = e.toString();
        // Clear cache on error too
        _cachedBaseDashboardWidgets = null;
      });
    }
  }

  Future<void> _fetchTopProducts() async {
    try {
      final response = await DashboardService.getTopProducts();
      setState(() {
        _topProductsData = response;
        _isLoadingProducts = false;
        _productsError = null;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
        _productsError = e.toString();
      });
    }
  }

  Future<void> _fetchOrderCount() async {
    try {
      final response = await DashboardService.getOrderCounts();
      setState(() {
        _orderCountData = response;
        _isLoadingOrderCount = false;
        _orderCountError = null;
        // Clear cache to rebuild with new data
        _cachedBaseDashboardWidgets = null;
      });
    } catch (e) {
      setState(() {
        _isLoadingOrderCount = false;
        _orderCountError = e.toString();
        // Clear cache on error too
        _cachedBaseDashboardWidgets = null;
      });
    }
  }

  // Build dashboard widgets with real data
  List<Widget> get _baseDashboardWidgets {
    // Only rebuild if data has changed or cache is empty
    if (_cachedBaseDashboardWidgets == null ||
        _isLoadingCustomers ||
        _isLoadingOrdersOverview ||
        _isLoadingOrderCount ||
        _customersError != null ||
        _ordersOverviewError != null ||
        _orderCountError != null) {
      _cachedBaseDashboardWidgets = [
        _isLoadingCustomers
            ? _buildLoadingWidget(key: const Key('loading_customers'))
            : _customersError != null
                ? _buildErrorWidget(_customersError!, _fetchTopCustomers,
                    key: const Key('error_customers'))
                : OrdersByCustomers(
                    customersData: _topCustomersData!,
                    key: const Key('customers_widget'),
                  ),
        _isLoadingOrdersOverview
            ? _buildLoadingWidget(key: const Key('loading_orders'))
            : _ordersOverviewError != null
                ? _buildErrorWidget(_ordersOverviewError!, _fetchOrdersOverview,
                    key: const Key('error_orders'))
                : OrdersOverviewWidget(
                    ordersData: _ordersOverviewData!,
                    key: const Key('orders_widget'),
                  ),
        _isLoadingOrderCount
            ? _buildLoadingWidget(key: const Key('loading_count'))
            : _orderCountError != null
                ? _buildErrorWidget(_orderCountError!, _fetchOrderCount,
                    key: const Key('error_count'))
                : OrderCountWidget(key: const Key('count_widget')),
        Profit(key: const Key('profit_widget')),
      ];
    }

    return _cachedBaseDashboardWidgets!;
  }

  // Get dashboard widgets in the current order
  List<Widget> get _dashboardWidgets {
    final baseWidgets = _baseDashboardWidgets;
    if (_dashboardWidgetsOrder.isEmpty ||
        _dashboardWidgetsOrder.length != baseWidgets.length) {
      return baseWidgets;
    }

    return _dashboardWidgetsOrder.map((index) {
      if (index >= 0 && index < baseWidgets.length) {
        return baseWidgets[index];
      }
      return baseWidgets[0]; // Fallback
    }).toList();
  }

  // Build stats cards with real data
  List<Widget> get _statsCards {
    if (_isLoadingCards) {
      return List.generate(
          4, (index) => _buildLoadingCard(key: Key('loading_card_$index')));
    }

    if (_cardsError != null) {
      return [_buildErrorCard(key: const Key('error_card'))];
    }

    // Only rebuild if data has changed or cache is empty
    if (_cachedBaseStatsCards == null || _dashboardCards.isEmpty) {
      _cachedBaseStatsCards = _dashboardCards.map((card) {
        return StatsCard(
          percentage: card.growth,
          svgIconPath: _getSvgIconPath(card.title),
          title: card.title,
          value: card.value,
          isPositive: card.isPositive,
          key: Key('stats_${card.title.replaceAll(' ', '_').toLowerCase()}'),
        );
      }).toList();
    }

    // Return cards in the current order
    if (_statsCardsOrder.isEmpty ||
        _statsCardsOrder.length != _cachedBaseStatsCards!.length) {
      return _cachedBaseStatsCards!;
    }

    return _statsCardsOrder.map((index) {
      if (index >= 0 && index < _cachedBaseStatsCards!.length) {
        return _cachedBaseStatsCards![index];
      }
      return _cachedBaseStatsCards![0]; // Fallback
    }).toList();
  }

  String _getSvgIconPath(String title) {
    switch (title.toLowerCase()) {
      case 'total products':
        return "assets/images/totalProducts.svg";
      case 'total paid orders':
        return "assets/images/totalPaidOrders.svg";
      case 'total users':
        return "assets/images/totalUsers.svg";
      case 'total customers':
        return "assets/images/totalStores.svg";
      default:
        return "assets/images/totalProducts.svg";
    }
  }

  Widget _buildLoadingWidget({Key? key}) {
    return Container(
      key: key,
      height: 400.h,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF9D67FF),
        ),
      ),
    );
  }

  Widget _buildLoadingCard({Key? key}) {
    return Container(
      key: key,
      height: 150.h,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF9D67FF),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry, {Key? key}) {
    return Container(
      key: key,
      height: 400.h,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
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
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                error,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white70,
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D67FF),
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

  Widget _buildErrorCard({Key? key}) {
    return Container(
      key: key,
      height: 150.h,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 24.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              'Error loading cards',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 8.h),
            ElevatedButton(
              onPressed: _fetchDashboardCards,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D67FF),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(color: Colors.white, fontSize: 10.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          profilePictureUrl: profilePictureUrl,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: const Color(0xFF9D67FF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      SizedBox(width: 8.w),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 36, 50, 69),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          elevation: 1,
                        ),
                        onPressed: _fetchDashboardData,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh,
                              color: const Color.fromARGB(255, 105, 123, 123),
                              size: 16.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Refresh',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14.sp,
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

                  /// --- Draggable Stats Cards ---
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final numberOfCards = _statsCards.length;
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

                  SizedBox(height: 40.h),
                ],
              ),
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
            // Swap the order indices
            final temp = _dashboardWidgetsOrder[oldIndex];
            _dashboardWidgetsOrder[oldIndex] = _dashboardWidgetsOrder[index];
            _dashboardWidgetsOrder[index] = temp;

            // Save the new order without triggering setState immediately
            _saveOrders();

            // Only trigger setState for the UI update, not widget recreation
            setState(() {});
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
            // Swap the order indices
            final temp = _statsCardsOrder[oldIndex];
            _statsCardsOrder[oldIndex] = _statsCardsOrder[index];
            _statsCardsOrder[index] = temp;

            // Save the new order without triggering setState immediately
            _saveOrders();

            // Only trigger setState for the UI update, not widget recreation
            setState(() {});
          },
        ),
      ),
    );
  }
}
