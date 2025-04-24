import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Ensure these imports point to your local files.
import 'package:storify/GeneralWidgets/navigationBar.dart';
import 'package:storify/admin/screens/Categories.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/screens/roleManegment.dart';
import 'package:storify/admin/screens/track.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/orderCards.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/orderModel.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/orderTable.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/supplierOrderPopUp.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  // Bottom navigation index.
  int _currentIndex = 3;
  String? profilePictureUrl;

  // Added state to track if we're in supplier mode or customer mode
  bool _isSupplierMode = true;

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

  // Currently selected card filter.
  // Options: "Total", "Active", "Completed", "Cancelled"
  String _selectedFilter = "Total";
  int _selectedCardIndex = 0; // initial selection is Total Orders.

  // Search query from the search box.
  String _searchQuery = "";

  // Fake order list for suppliers (shared as the single data source).
  final List<OrderItem> _supplierOrders = [
    OrderItem(
      orderId: "267400",
      storeName: "Ralph Edwards",
      phoneNo: "972694737544",
      orderDate: "12-7-2024 22:16",
      totalProducts: 20,
      totalAmount: 328.85,
      status: "Awaiting",
    ),
    OrderItem(
      orderId: "267401",
      storeName: "Ralph Edwards",
      phoneNo: "972694737544",
      orderDate: "12-7-2024 22:16",
      totalProducts: 25,
      totalAmount: 500.55,
      status: "Accepted",
    ),
    // ... remaining supplier orders
  ];

  // New fake order list for customers
  final List<OrderItem> _customerOrders = [
    OrderItem(
      orderId: "367400",
      storeName: "John Smith", // This will be displayed as Customer Name
      phoneNo: "972694737111",
      orderDate: "14-7-2024 18:30",
      totalProducts: 8,
      totalAmount: 156.70,
      status: "Awaiting",
    ),
    OrderItem(
      orderId: "367400",
      storeName: "John Smith", // This will be displayed as Customer Name
      phoneNo: "972694737111",
      orderDate: "14-7-2024 18:30",
      totalProducts: 8,
      totalAmount: 156.70,
      status: "Awaiting",
    ),
    OrderItem(
      orderId: "367401",
      storeName: "Mary Johnson", // This will be displayed as Customer Name
      phoneNo: "972694736222",
      orderDate: "14-7-2024 19:45",
      totalProducts: 12,
      totalAmount: 210.30,
      status: "Accepted",
    ),
    OrderItem(
      orderId: "367402",
      storeName: "Robert Davis", // This will be displayed as Customer Name
      phoneNo: "972694735333",
      orderDate: "14-7-2024 20:15",
      totalProducts: 6,
      totalAmount: 98.50,
      status: "Declined",
    ),
    OrderItem(
      orderId: "367403",
      storeName: "Patricia Brown", // This will be displayed as Customer Name
      phoneNo: "972694734444",
      orderDate: "15-7-2024 09:20",
      totalProducts: 15,
      totalAmount: 275.90,
      status: "Awaiting",
    ),
    OrderItem(
      orderId: "367404",
      storeName: "James Wilson", // This will be displayed as Customer Name
      phoneNo: "972694733555",
      orderDate: "15-7-2024 10:40",
      totalProducts: 10,
      totalAmount: 180.25,
      status: "Accepted",
    ),
  ];

  // Get the active orders list based on mode
  List<OrderItem> get _activeOrdersList {
    return _isSupplierMode ? _supplierOrders : _customerOrders;
  }

  // Compute counts based on orders list.
  int get totalOrdersCount => _activeOrdersList.length;
  int get activeCount =>
      _activeOrdersList.where((o) => o.status == "Awaiting").length;
  int get completedCount =>
      _activeOrdersList.where((o) => o.status == "Accepted").length;
  int get cancelledCount =>
      _activeOrdersList.where((o) => o.status == "Declined").length;

  // Build card data dynamically.
  List<_OrderCardData> get _ordersData {
    return [
      _OrderCardData(
        svgIconPath: 'assets/images/totalorders.svg',
        title: 'Total Orders',
        count: totalOrdersCount.toString(),
        percentage: 1.0, // Always full for Total Orders.
        circleColor: const Color.fromARGB(255, 0, 196, 255), // cyan
      ),
      _OrderCardData(
        svgIconPath: 'assets/images/Activeorders.svg',
        title: 'Active Orders',
        count: activeCount.toString(),
        percentage: totalOrdersCount > 0 ? activeCount / totalOrdersCount : 0.0,
        circleColor: const Color.fromARGB(255, 255, 232, 29), // purple
      ),
      _OrderCardData(
        svgIconPath: 'assets/images/completedOrders.svg',
        title: 'Completed Orders',
        count: completedCount.toString(),
        percentage:
            totalOrdersCount > 0 ? completedCount / totalOrdersCount : 0.0,
        circleColor: const Color.fromARGB(255, 0, 224, 116), // green
      ),
      _OrderCardData(
        svgIconPath: 'assets/images/cancorders.svg',
        title: 'Cancelled Orders',
        count: cancelledCount.toString(),
        percentage:
            totalOrdersCount > 0 ? cancelledCount / totalOrdersCount : 0.0,
        circleColor: const Color.fromARGB(255, 255, 62, 142), // pink
      ),
    ];
  }

  // When a card is tapped update the filter.
  void _onCardTap(int index) {
    setState(() {
      _selectedCardIndex = index;
      if (index == 0) {
        _selectedFilter = "Total";
      } else if (index == 1) {
        _selectedFilter = "Active";
      } else if (index == 2) {
        _selectedFilter = "Completed";
      } else if (index == 3) {
        _selectedFilter = "Cancelled";
      }
    });
  }

  // Toggle between supplier and customer mode
  void _toggleOrderMode(bool isSupplier) {
    if (isSupplier != _isSupplierMode) {
      setState(() {
        _isSupplierMode = isSupplier;
      });
    }
  }

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const DashboardScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
        break;
      case 1:
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Productsscreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
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
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
        break;
      case 3:
        // Current Orders screen.
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(left: 45.w, top: 20.h, right: 45.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top header row with added filter
              Row(
                children: [
                  Text(
                    _isSupplierMode ? "Supplier Orders" : "Customer Orders",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 35.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 20.w),
                  // Add filter toggle
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
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: _isSupplierMode
                                  ? const Color.fromARGB(255, 105, 65, 198)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20.r),
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
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: !_isSupplierMode
                                  ? const Color.fromARGB(255, 105, 65, 198)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20.r),
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
                  // Show "Order From Supplier" button only in supplier mode
                  if (_isSupplierMode)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 105, 65, 198),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        fixedSize: Size(250.w, 50.h),
                        elevation: 1,
                      ),
                      onPressed: () {
                        showSupplierOrderPopup(context);
                      },
                      child: Text(
                        'Order From Supplier',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
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
                  final cardWidth =
                      (availableWidth - ((numberOfCards - 1) * spacing)) /
                          numberOfCards;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: 20,
                    children: List.generate(_ordersData.length, (index) {
                      final bool isSelected = (_selectedCardIndex == index);
                      final data = _ordersData[index];
                      return GestureDetector(
                        onTap: () => _onCardTap(index),
                        child: SizedBox(
                          width: cardWidth,
                          child: OrdersCard(
                            svgIconPath: data.svgIconPath,
                            title: data.title,
                            count: data.count,
                            percentage: data.percentage,
                            circleColor: data.circleColor,
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              SizedBox(height: 40.h),
              // Row with title and search box.
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
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
                        // Using an icon here; you may swap with your SVG.
                        SvgPicture.asset(
                          'assets/images/search.svg',
                          width: 20.w,
                          height: 20.h,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25.w),
              // Modified Order table: pass mode, orders list, filter, and search query
              Ordertable(
                orders: _activeOrdersList,
                filter: _selectedFilter,
                searchQuery: _searchQuery,
                isSupplierMode: _isSupplierMode, // Pass the mode to table
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple model for the card data.
class _OrderCardData {
  final String svgIconPath;
  final String title;
  final String count;
  final double percentage;
  final Color circleColor;
  const _OrderCardData({
    required this.svgIconPath,
    required this.title,
    required this.count,
    required this.percentage,
    required this.circleColor,
  });
}
