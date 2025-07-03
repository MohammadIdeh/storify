// Updated Orders_employee class with API integration
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/employee/screens/order_history_screen.dart';
import 'package:storify/employee/screens/viewOrderScreenEmp.dart';
import 'package:storify/employee/widgets/navbar_employee.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:storify/employee/widgets/network_diagnostics.dart';
import 'package:storify/employee/widgets/orderServiceEmp.dart';

// OrderItem model now properly matches the API response structure
class OrderItem {
  final int orderId;
  final String name;
  final String phoneNo;
  final String orderDate;
  final int totalProducts;
  final double totalAmount;
  final String status;
  final String type; // "Supplier" or "Customer"

  OrderItem({
    required this.orderId,
    required this.name,
    required this.phoneNo,
    required this.orderDate,
    required this.totalProducts,
    required this.totalAmount,
    required this.status,
    required this.type,
  });

  // Factory method to create OrderItem from customer order API response
  factory OrderItem.fromCustomerOrderJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final user = customer['user'];
    final items = json['items'] as List;

    // Format date from API (2025-05-03T11:10:50.000Z) to MM-DD-YYYY
    final DateTime orderDate = DateTime.parse(json['createdAt']);
    final String formattedDate =
        '${orderDate.month}-${orderDate.day}-${orderDate.year}';

    return OrderItem(
      orderId: json['id'],
      name: user['name'] ?? 'Unknown',
      phoneNo: user['phoneNumber'] ?? 'N/A',
      orderDate: formattedDate,
      totalProducts: items.length,
      totalAmount: (json['totalCost'] as num).toDouble(),
      status: json['status'],
      type: "Customer",
    );
  }

  // Factory method to create OrderItem from supplier order API response
  factory OrderItem.fromSupplierOrderJson(Map<String, dynamic> json) {
    final supplier = json['supplier'];
    final user = supplier['user'];
    final items = json['items'] as List;

    // Format date
    final DateTime orderDate = DateTime.parse(json['createdAt']);
    final String formattedDate =
        '${orderDate.month}-${orderDate.day}-${orderDate.year}';

    return OrderItem(
      orderId: json['id'],
      name: user['name'] ?? 'Unknown',
      phoneNo: user['phoneNumber'] ?? 'N/A',
      orderDate: formattedDate,
      totalProducts: items.length,
      totalAmount: (json['totalCost'] as num).toDouble(),
      status: json['status'],
      type: "Supplier",
    );
  }
}

// StatsCard widget remains unchanged
class StatsCard extends StatelessWidget {
  final String svgIconPath;
  final String title;
  final String count;
  final double percentage;
  final Color circleColor;
  final bool isSelected;

  const StatsCard({
    Key? key,
    required this.svgIconPath,
    required this.title,
    required this.count,
    required this.percentage,
    required this.circleColor,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Existing build method implementation...
    return AspectRatio(
      aspectRatio: 318 / 199,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isSelected
              ? const Color.fromARGB(255, 105, 65, 198)
              : const Color.fromARGB(255, 36, 50, 69),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth;
              final cardHeight = constraints.maxHeight;

              // Calculate sizes relative to the card's width
              final iconSize = cardWidth * 0.17;
              final countFontSize = cardWidth * 0.12;
              final circleSize = cardWidth * 0.35;

              return Stack(
                children: [
                  // Top-left: Icon and title
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          svgIconPath,
                          width: iconSize,
                          height: iconSize,
                        ),
                        SizedBox(width: 20.w),
                        Text(
                          title,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromARGB(255, 196, 196, 196),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Centered count text
                  Positioned(
                    top: cardHeight * 0.25,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        count,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: countFontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Bottom-center circular progress indicator
                  Positioned(
                    bottom: 0,
                    left: (cardWidth - circleSize) / 2, // Center it
                    child: CircularPercentIndicator(
                      radius: circleSize / 3,
                      lineWidth: circleSize * 0.05,
                      percent: percentage.clamp(0.0, 1.0),
                      center: Text(
                        "${(percentage * 100).toStringAsFixed(0)}%",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: circleSize * 0.18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      progressColor: circleColor,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ignore: camel_case_types
class Orders_employee extends StatefulWidget {
  const Orders_employee({super.key});

  @override
  State<Orders_employee> createState() => _OrdersState();
}

class _OrdersState extends State<Orders_employee> {
  int _currentIndex = 0;
  String? profilePictureUrl;
  bool _isSupplierMode = true; // Default to supplier mode
  bool _isLoading = true; // Start with loading state
  String _searchQuery = "";
  String _selectedFilter = "Total";
  int _selectedCardIndex = 0;
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  String? _errorMessage;

  // Real data from API
  List<OrderItem> _supplierOrders = [];
  List<OrderItem> _customerOrders = [];

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _fetchOrders(); // Fetch real data on init
  }

  // Load orders from API
  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch supplier orders
      final supplierResponse = await OrderService.getSupplierOrders();
      final supplierOrders = (supplierResponse['pendingOrders'] as List)
          .map((order) => OrderItem.fromSupplierOrderJson(order))
          .toList();

      // Fetch customer orders
      final customerResponse = await OrderService.getCustomerOrders();
      final customerOrders = (customerResponse['pendingOrders'] as List)
          .map((order) => OrderItem.fromCustomerOrderJson(order))
          .toList();

      if (mounted) {
        setState(() {
          _supplierOrders = supplierOrders;
          _customerOrders = customerOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load orders: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  // Get the active orders list based on mode
  List<OrderItem> get _activeOrdersList {
    return _isSupplierMode ? _supplierOrders : _customerOrders;
  }

  // Compute counts based on orders list (same as original implementation)
  int get totalOrdersCount => _activeOrdersList.length;

  int get activeCount => _activeOrdersList
      .where((o) =>
          o.status == "Accepted" ||
          o.status == "Pending" ||
          o.status == "Preparing")
      .length;

  int get completedCount => _activeOrdersList
      .where((o) =>
          o.status == "Delivered" ||
          o.status == "Prepared" ||
          o.status == "Shipped")
      .length;

  // Build card data dynamically (same as original)
// Build card data dynamically
  List<Map<String, dynamic>> get _ordersData {
    return [
      {
        'svgIconPath': 'assets/images/totalorders.svg',
        'title': 'Total Orders',
        'count': totalOrdersCount.toString(),
        'percentage': 1.0, // Always full for Total Orders
        'circleColor': const Color.fromARGB(255, 0, 196, 255), // cyan
      },
      {
        'svgIconPath': 'assets/images/Activeorders.svg',
        'title': 'Active Orders',
        'count': activeCount.toString(),
        'percentage':
            totalOrdersCount > 0 ? activeCount / totalOrdersCount : 0.0,
        'circleColor': const Color.fromARGB(255, 255, 232, 29), // yellow
      },
      {
        'svgIconPath': 'assets/images/completedOrders.svg',
        'title': 'Completed Orders',
        'count': completedCount.toString(),
        'percentage':
            totalOrdersCount > 0 ? completedCount / totalOrdersCount : 0.0,
        'circleColor': const Color.fromARGB(255, 0, 224, 116), // green
      },
      // Removed the cancelled orders card
    ];
  }

  // Toggle between supplier and customer mode
  void _toggleOrderMode(bool isSupplier) {
    if (isSupplier != _isSupplierMode) {
      setState(() {
        _isSupplierMode = isSupplier;
        _currentPage = 1; // Reset to first page when switching modes
      });
    }
  }

  // When a card is tapped update the filter
  void _onCardTap(int index) {
    setState(() {
      _selectedCardIndex = index;
      if (index == 0) {
        _selectedFilter = "Total";
      } else if (index == 1) {
        _selectedFilter = "Active";
      } else if (index == 2) {
        _selectedFilter = "Completed";
      }
    });
  }

  // Apply filter based on the selected filter value
// Apply filter based on the selected filter value
  List<OrderItem> get _filteredOrders {
    List<OrderItem> filtered = _activeOrdersList;
    if (_selectedFilter != "Total") {
      if (_selectedFilter == "Active") {
        filtered = filtered
            .where((order) =>
                order.status == "Accepted" ||
                order.status == "Pending" ||
                order.status == "Preparing")
            .toList();
      } else if (_selectedFilter == "Completed") {
        filtered = filtered
            .where((order) =>
                order.status == "Delivered" ||
                order.status == "Prepared" ||
                order.status == "Shipped")
            .toList();
      }
      // Removed "Cancelled" filter case
    }
    // Filter by search query on orderId
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((order) => order.orderId.toString().contains(_searchQuery))
          .toList();
    }
    return filtered;
  }

  // Calculate which orders are shown on the current page (same as original)
  List<OrderItem> get _visibleOrders {
    final totalItems = _filteredOrders.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > totalItems
        ? totalItems
        : startIndex + _itemsPerPage;

    // Check if there are any orders before trying to slice
    if (totalItems == 0) {
      return [];
    }

    return _filteredOrders.sublist(startIndex, endIndex);
  }

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        // Stay on current screen
        break;
      case 1:
        // Navigate to order history with URL change
        Navigator.pushNamed(context, '/warehouse/history');
        break;
    }
  }

  // Navigate to view order screen
  void _viewOrderDetails(OrderItem order) {
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ViewOrderScreen(order: order),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    )
        .then((updatedOrder) {
      if (updatedOrder != null) {
        // Refresh data when returning from order detail screen
        _fetchOrders();
      }
    });
  }

  // Build a status pill widget (same as original)
  Widget _buildStatusPill(String status) {
    Color textColor;
    Color borderColor;

    switch (status) {
      case "Accepted":
        textColor = const Color.fromARGB(255, 0, 196, 255); // cyan
        borderColor = textColor;
        break;
      case "Pending":
        textColor = const Color.fromARGB(255, 255, 232, 29); // yellow
        borderColor = textColor;
        break;
      case "Delivered":
      case "Shipped":
      case "Prepared":
        textColor = const Color.fromARGB(178, 0, 224, 116); // green
        borderColor = textColor;
        break;
      case "Declined":
      case "Rejected":
        textColor = const Color.fromARGB(255, 229, 62, 62); // red
        borderColor = textColor;
        break;
      case "Preparing":
        textColor = const Color.fromARGB(255, 255, 150, 30); // orange
        borderColor = textColor;
        break;
      default:
        textColor = Colors.white70;
        borderColor = Colors.white54;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _filteredOrders.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: NavigationBarEmployee(
          currentIndex: _currentIndex,
          onTap: _onNavItemTap,
          profilePictureUrl: profilePictureUrl,
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color.fromARGB(255, 105, 65, 198),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NetworkDiagnosticsWidget(),
                      Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 48.sp,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16.sp,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _fetchOrders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 105, 65, 198),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: 45.w, top: 20.h, right: 45.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top header with title and mode toggle
                        Row(
                          children: [
                            Text(
                              _isSupplierMode
                                  ? "Supplier Orders"
                                  : "Customer Orders",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 35.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 20.w),
                            // Mode toggle
                            Container(
                              height: 40.h,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 36, 50, 69),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Suppliers tab
                                  GestureDetector(
                                    onTap: () => _toggleOrderMode(true),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w),
                                      height: 40.h,
                                      decoration: BoxDecoration(
                                        color: _isSupplierMode
                                            ? const Color.fromARGB(
                                                255, 105, 65, 198)
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(20.r),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Suppliers",
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Customers tab
                                  GestureDetector(
                                    onTap: () => _toggleOrderMode(false),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16.w),
                                      height: 40.h,
                                      decoration: BoxDecoration(
                                        color: !_isSupplierMode
                                            ? const Color.fromARGB(
                                                255, 105, 65, 198)
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(20.r),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Customers",
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Refresh button
                            IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                              onPressed: _fetchOrders,
                            ),
                          ],
                        ),
                        SizedBox(height: 40.h),

                        // Filter Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            const numberOfCards = 4;
                            const spacing = 40.0;
                            final cardWidth = (availableWidth -
                                    ((numberOfCards - 1) * spacing)) /
                                numberOfCards;
                            return Wrap(
                              spacing: spacing,
                              runSpacing: 20,
                              children:
                                  List.generate(_ordersData.length, (index) {
                                final bool isSelected =
                                    (_selectedCardIndex == index);
                                final data = _ordersData[index];
                                return GestureDetector(
                                  onTap: () => _onCardTap(index),
                                  child: SizedBox(
                                    width: cardWidth,
                                    child: StatsCard(
                                      svgIconPath: data['svgIconPath'],
                                      title: data['title'],
                                      count: data['count'],
                                      percentage: data['percentage'],
                                      circleColor: data['circleColor'],
                                      isSelected: isSelected,
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),

                        SizedBox(height: 40.h),

                        // Row with title and search box
                        Row(
                          children: [
                            Text(
                              // Optionally update title based on filter.
                              _selectedFilter == "Total"
                                  ? "All Orders"
                                  : _selectedFilter == "Active"
                                      ? "Active Orders"
                                      : _selectedFilter == "Completed"
                                          ? "Completed Orders"
                                          : "Cancelled Orders",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 24.w),
                            // Placeholder for potential filter chips.
                            Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 36, 50, 69),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            const Spacer(),
                            // Search box: filters table by order ID in real time.
                            Container(
                              width: 300.w,
                              height: 55.h,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 36, 50, 69),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.w, vertical: 8.h),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 120.w,
                                    child: TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value;
                                        });
                                      },
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search ID',
                                        hintStyle: GoogleFonts.spaceGrotesk(
                                          color: Colors.white70,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Search icon
                                  Icon(
                                    Icons.search,
                                    color: Colors.white70,
                                    size: 20.sp,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 25.w),

                        // Orders table and pagination
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Table container
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 36, 50, 69),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30.r),
                                  topRight: Radius.circular(30.r),
                                  bottomLeft: Radius.circular(30.r),
                                  bottomRight: Radius.circular(30.r),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Empty state for no orders
                                  if (_filteredOrders.isEmpty)
                                    Container(
                                      height: 300.h,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 36, 50, 69),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(30.r),
                                          topRight: Radius.circular(30.r),
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.inbox_outlined,
                                              size: 64.sp,
                                              color:
                                                  Colors.white.withOpacity(0.3),
                                            ),
                                            SizedBox(height: 16.h),
                                            Text(
                                              'No orders found',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            SizedBox(height: 8.h),
                                            Text(
                                              'There are no orders to display',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 14.sp,
                                                color: Colors.white38,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    // Table with horizontal scrolling
                                    Container(
                                      width: double.infinity,
                                      color:
                                          const Color.fromARGB(255, 36, 50, 69),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth: MediaQuery.of(context)
                                                    .size
                                                    .width -
                                                90.w, // Full width minus padding
                                          ),
                                          child: DataTable(
                                            dataRowColor: MaterialStateProperty
                                                .resolveWith<Color?>(
                                              (Set<MaterialState> states) =>
                                                  Colors.transparent,
                                            ),
                                            showCheckboxColumn: false,
                                            headingRowColor:
                                                MaterialStateProperty.all<
                                                        Color>(
                                                    const Color.fromARGB(
                                                        255, 36, 50, 69)),
                                            border: TableBorder(
                                              top: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 34, 53, 62),
                                                  width: 1),
                                              bottom: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 34, 53, 62),
                                                  width: 1),
                                              left: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 34, 53, 62),
                                                  width: 1),
                                              right: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 34, 53, 62),
                                                  width: 1),
                                              horizontalInside: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 36, 50, 69),
                                                  width: 2),
                                              verticalInside: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 36, 50, 69),
                                                  width: 2),
                                            ),
                                            columnSpacing: 20.w,
                                            dividerThickness: 0,
                                            headingTextStyle:
                                                GoogleFonts.spaceGrotesk(
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            dataTextStyle:
                                                GoogleFonts.spaceGrotesk(
                                              color:
                                                  Colors.white.withOpacity(0.8),
                                              fontSize: 13.sp,
                                            ),
                                            columns: [
                                              const DataColumn(
                                                  label: Text("Order ID")),
                                              DataColumn(
                                                label: Text(_isSupplierMode
                                                    ? "Supplier Name"
                                                    : "Customer Name"),
                                              ),
                                              const DataColumn(
                                                  label: Text("Phone No")),
                                              const DataColumn(
                                                  label: Text("Order Date")),
                                              const DataColumn(
                                                  label:
                                                      Text("Total Products")),
                                              const DataColumn(
                                                  label: Text("Total Amount")),
                                              const DataColumn(
                                                  label: Text("Status")),
                                            ],
                                            rows: _visibleOrders.map((order) {
                                              // Pre-format total amount string
                                              final String totalAmountStr =
                                                  "\$" +
                                                      order.totalAmount
                                                          .toStringAsFixed(2);

                                              return DataRow(
                                                onSelectChanged: (selected) {
                                                  if (selected == true) {
                                                    _viewOrderDetails(order);
                                                  }
                                                },
                                                cells: [
                                                  DataCell(Text(order.orderId
                                                      .toString())),
                                                  DataCell(Text(order.name)),
                                                  DataCell(Text(order.phoneNo)),
                                                  DataCell(
                                                      Text(order.orderDate)),
                                                  DataCell(Text(order
                                                      .totalProducts
                                                      .toString())),
                                                  DataCell(
                                                      Text(totalAmountStr)),
                                                  DataCell(_buildStatusPill(
                                                      order.status)),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Pagination Row - only show if there are orders
                            // Now outside and below the table container
                            if (_filteredOrders.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 16.h, right: 8.w),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Total ${_filteredOrders.length} Orders",
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    // Left arrow button
                                    IconButton(
                                      icon: Icon(Icons.arrow_back,
                                          size: 20.sp, color: Colors.white70),
                                      onPressed: _currentPage > 1
                                          ? () {
                                              setState(() {
                                                _currentPage--;
                                              });
                                            }
                                          : null,
                                    ),
                                    // Page buttons
                                    Row(
                                      children: List.generate(
                                        (totalItems / _itemsPerPage).ceil(),
                                        (index) {
                                          final pageIndex = index + 1;
                                          final bool isSelected =
                                              (pageIndex == _currentPage);
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 4.w),
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor: isSelected
                                                    ? const Color.fromARGB(
                                                        255, 105, 65, 198)
                                                    : Colors.transparent,
                                                side: BorderSide(
                                                  color: const Color.fromARGB(
                                                      255, 34, 53, 62),
                                                  width: 1.5,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.r),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 14.w,
                                                    vertical: 10.h),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _currentPage = pageIndex;
                                                });
                                              },
                                              child: Text(
                                                "$pageIndex",
                                                style: GoogleFonts.spaceGrotesk(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.white70,
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Right arrow button
                                    IconButton(
                                      icon: Icon(Icons.arrow_forward,
                                          size: 20.sp, color: Colors.white70),
                                      onPressed: _currentPage < totalPages
                                          ? () {
                                              setState(() {
                                                _currentPage++;
                                              });
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
