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
import 'package:storify/admin/widgets/OrderWidgets/orderCards.dart';
import 'package:storify/admin/widgets/OrderWidgets/orderModel.dart';
import 'package:storify/admin/widgets/OrderWidgets/orderTable.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  // Bottom navigation index.
  int _currentIndex = 3;
  String? profilePictureUrl;

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

  // Fake order list (shared as the single data source).
  final List<OrderItem> _orders = [
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
    OrderItem(
      orderId: "267402",
      storeName: "momo ideh",
      phoneNo: "972694737544",
      orderDate: "12-7-2024 22:16",
      totalProducts: 15,
      totalAmount: 278.20,
      status: "Declined",
    ),
    OrderItem(
      orderId: "267403",
      storeName: "Ralph Edwards",
      phoneNo: "972694737544",
      orderDate: "12-7-2024 22:16",
      totalProducts: 10,
      totalAmount: 100.99,
      status: "Declined",
    ),
    OrderItem(
      orderId: "267404",
      storeName: "Ralph Edwards",
      phoneNo: "972694737544",
      orderDate: "12-7-2024 22:16",
      totalProducts: 20,
      totalAmount: 328.85,
      status: "Declined",
    ),
    OrderItem(
      orderId: "267405",
      storeName: "Ralph Edwards",
      phoneNo: "972694737544",
      orderDate: "12-7-2024 22:16",
      totalProducts: 3,
      totalAmount: 79.99,
      status: "Accepted",
    ),
    OrderItem(
      orderId: "267406",
      storeName: "Ralph Edwards",
      phoneNo: "972694737544",
      orderDate: "12-7-2024 22:16",
      totalProducts: 12,
      totalAmount: 230.45,
      status: "Declined",
    ),
    OrderItem(
      orderId: "267407",
      storeName: "Ralph Edwards",
      phoneNo: "972694737544",
      orderDate: "12-7-2024 22:16",
      totalProducts: 13,
      totalAmount: 185.35,
      status: "Declined",
    ),
    OrderItem(
      orderId: "267408",
      storeName: "Ralph Edwards",
      phoneNo: "972694737544",
      orderDate: "12-7-2024 22:16",
      totalProducts: 22,
      totalAmount: 442.45,
      status: "Awaiting",
    ),
  ];

  // Compute counts based on orders list.
  int get totalOrdersCount => _orders.length;
  int get activeCount => _orders.where((o) => o.status == "Awaiting").length;
  int get completedCount => _orders.where((o) => o.status == "Accepted").length;
  int get cancelledCount => _orders.where((o) => o.status == "Declined").length;

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

  // Navigation using bottom nav bar.
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
        child: Padding(
          padding: EdgeInsets.only(left: 45.w, top: 20.h, right: 45.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top header row.
              Row(
                children: [
                  Text(
                    "Orders",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      fixedSize: Size(250.w, 50.h),
                      elevation: 1,
                    ),
                    onPressed: () {},
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
              // Order table: pass the orders list, the current filter, and search query.
              Ordertable(
                orders: _orders,
                filter: _selectedFilter,
                searchQuery: _searchQuery,
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
