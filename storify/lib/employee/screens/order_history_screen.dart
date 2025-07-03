// lib/employee/screens/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/employee/screens/orders_screen.dart';
import 'package:storify/employee/widgets/navbar_employee.dart';
import 'package:storify/employee/widgets/orderServiceEmp.dart';

// OrderHistory model updated to match API response
class OrderHistory {
  final int id;
  final int userId;
  final String orderType; // "customer" or "supplier"
  final int orderId;
  final String action;
  final String previousStatus;
  final String newStatus;
  final String? note;
  final String createdAt;
  final String name; // Employee name
  final double? totalCost;
  final String? customerName;

  OrderHistory({
    required this.id,
    required this.userId,
    required this.orderType,
    required this.orderId,
    required this.action,
    required this.previousStatus,
    required this.newStatus,
    this.note,
    required this.createdAt,
    required this.name,
    this.totalCost,
    this.customerName,
  });

  // Factory constructor to create OrderHistory from API JSON
  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String customerName = '';
    double? totalCost;

    if (json['orderDetails'] != null) {
      totalCost = json['orderDetails']['totalCost'] != null
          ? (json['orderDetails']['totalCost'] as num).toDouble()
          : null;

      if (json['orderDetails']['customer'] != null &&
          json['orderDetails']['customer']['user'] != null) {
        customerName = json['orderDetails']['customer']['user']['name'] ?? '';
      }
    }

    // Format date (from 2025-05-17T19:00:54.000Z to more readable format)
    final DateTime dateTime = DateTime.parse(json['createdAt']);
    final String formattedDate =
        '${dateTime.month}-${dateTime.day}-${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

    return OrderHistory(
      id: json['id'],
      userId: json['userId'],
      orderType: json['orderType'],
      orderId: json['orderId'],
      action: json['action'],
      previousStatus: json['previousStatus'],
      newStatus: json['newStatus'],
      note: json['note'],
      createdAt: formattedDate,
      name: user['name'],
      totalCost: totalCost,
      customerName: customerName,
    );
  }
}

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _currentIndex = 1;
  String? profilePictureUrl;
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedTypeFilter = "All"; // "All", "customer", "supplier"
  String _selectedActionFilter = "All"; // "All", "Accepted", "Rejected", etc.
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 10; // Match API's default limit
  List<OrderHistory> _orderHistory = [];
  String? _errorMessage;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _fetchOrderHistory();
  }

  // Fetch order history from API
  Future<void> _fetchOrderHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await OrderService.getOrderHistory(
        page: _currentPage,
        limit: _itemsPerPage,
      );

      // Parse response
      final activityLogs = response['activityLogs'] as List;
      final List<OrderHistory> logs =
          activityLogs.map((log) => OrderHistory.fromJson(log)).toList();

      // Update state with results
      setState(() {
        _orderHistory = logs;
        _totalItems = response['total'];
        _totalPages = response['totalPages'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load order history: $e';
        _isLoading = false;
      });
    }
  }

  // Load profile picture
  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        // Navigate to employee orders with URL change
        Navigator.pushNamed(context, '/warehouse/orders');
        break;
      case 1:
        // Stay on current screen
        break;
    }
  }

  // Apply filters
  List<OrderHistory> get _filteredHistory {
    List<OrderHistory> filtered = _orderHistory;

    // Apply type filter
    if (_selectedTypeFilter != "All") {
      filtered = filtered
          .where((item) => item.orderType == _selectedTypeFilter)
          .toList();
    }

    // Apply action filter - search in the action field
    if (_selectedActionFilter != "All") {
      filtered = filtered
          .where((item) => item.action
              .toLowerCase()
              .contains(_selectedActionFilter.toLowerCase()))
          .toList();
    }

    // Apply search query on orderId
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((item) => item.orderId.toString().contains(_searchQuery))
          .toList();
    }

    return filtered;
  }

  // Change page and fetch new data
  void _changePage(int page) {
    if (page < 1 || page > _totalPages) return;

    setState(() {
      _currentPage = page;
    });

    _fetchOrderHistory();
  }

  // Build a status pill widget
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
      case "Rejected":
      case "Declined":
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

  // Build a filter chip widget
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 105, 65, 198)
              : const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 105, 65, 198)
                : const Color.fromARGB(255, 47, 71, 82),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate statistics for summary cards
    int supplierCount =
        _orderHistory.where((item) => item.orderType == "supplier").length;
    int customerCount =
        _orderHistory.where((item) => item.orderType == "customer").length;

    // Count different actions
    int viewedCount =
        _orderHistory.where((item) => item.action.contains("Viewed")).length;
    int updatedCount =
        _orderHistory.where((item) => item.action.contains("Updated")).length;

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
                        onPressed: _fetchOrderHistory,
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
                        // Top header with title
                        Row(
                          children: [
                            Text(
                              "Order History",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 35.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
                              onPressed: _fetchOrderHistory,
                            ),
                          ],
                        ),
                        SizedBox(height: 25.h),

                        // Summary cards
                        Row(
                          children: [
                            // Total Processed card
                            Expanded(
                              child: _buildSummaryCard(
                                title: "Total Activity",
                                count: _totalItems.toString(),
                                iconData: Icons.history,
                                color: const Color.fromARGB(255, 0, 196, 255),
                              ),
                            ),
                            SizedBox(width: 20.w),
                            // Supplier Orders card
                            Expanded(
                              child: _buildSummaryCard(
                                title: "Supplier Orders",
                                count: supplierCount.toString(),
                                iconData: Icons.inventory_2,
                                color: const Color.fromARGB(255, 255, 150, 30),
                              ),
                            ),
                            SizedBox(width: 20.w),
                            // Customer Orders card
                            Expanded(
                              child: _buildSummaryCard(
                                title: "Customer Orders",
                                count: customerCount.toString(),
                                iconData: Icons.people,
                                color: const Color.fromARGB(255, 130, 80, 223),
                              ),
                            ),
                            SizedBox(width: 20.w),
                            // Viewed Actions card
                            Expanded(
                              child: _buildSummaryCard(
                                title: "Viewed",
                                count: viewedCount.toString(),
                                iconData: Icons.visibility,
                                color: const Color.fromARGB(178, 0, 224, 116),
                              ),
                            ),
                            SizedBox(width: 20.w),
                            // Updated Actions card
                            Expanded(
                              child: _buildSummaryCard(
                                title: "Updated",
                                count: updatedCount.toString(),
                                iconData: Icons.update,
                                color: const Color.fromARGB(255, 229, 62, 62),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 30.h),

                        // Filters and search
                        Row(
                          children: [
                            Text(
                              "Order Type:",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 15.w),
                            // Type filter chips
                            _buildFilterChip(
                              label: "All",
                              isSelected: _selectedTypeFilter == "All",
                              onTap: () {
                                setState(() {
                                  _selectedTypeFilter = "All";
                                });
                              },
                            ),
                            SizedBox(width: 10.w),
                            _buildFilterChip(
                              label: "Supplier",
                              isSelected: _selectedTypeFilter == "supplier",
                              onTap: () {
                                setState(() {
                                  _selectedTypeFilter = "supplier";
                                });
                              },
                            ),
                            SizedBox(width: 10.w),
                            _buildFilterChip(
                              label: "Customer",
                              isSelected: _selectedTypeFilter == "customer",
                              onTap: () {
                                setState(() {
                                  _selectedTypeFilter = "customer";
                                });
                              },
                            ),
                            SizedBox(width: 30.w),
                            Text(
                              "Action:",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 15.w),
                            // Action filter chips
                            _buildFilterChip(
                              label: "All",
                              isSelected: _selectedActionFilter == "All",
                              onTap: () {
                                setState(() {
                                  _selectedActionFilter = "All";
                                });
                              },
                            ),
                            SizedBox(width: 10.w),
                            _buildFilterChip(
                              label: "Viewed",
                              isSelected: _selectedActionFilter == "Viewed",
                              onTap: () {
                                setState(() {
                                  _selectedActionFilter = "Viewed";
                                });
                              },
                            ),
                            SizedBox(width: 10.w),
                            _buildFilterChip(
                              label: "Updated",
                              isSelected: _selectedActionFilter == "Updated",
                              onTap: () {
                                setState(() {
                                  _selectedActionFilter = "Updated";
                                });
                              },
                            ),

                            const Spacer(),

                            // Search box
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
                                        hintText: 'Search Order ID',
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

                        SizedBox(height: 25.h),

                        // History table and pagination
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
                                  // Empty state for no history
                                  if (_filteredHistory.isEmpty)
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
                                              Icons.history_outlined,
                                              size: 64.sp,
                                              color:
                                                  Colors.white.withOpacity(0.3),
                                            ),
                                            SizedBox(height: 16.h),
                                            Text(
                                              'No order history found',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            SizedBox(height: 8.h),
                                            Text(
                                              'There are no processed orders to display',
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
                                                  label: Text("Time")),
                                              const DataColumn(
                                                  label: Text("Order ID")),
                                              const DataColumn(
                                                  label: Text("Type")),
                                              const DataColumn(
                                                  label: Text("Action")),
                                              const DataColumn(
                                                  label: Text("Before Status")),
                                              const DataColumn(
                                                  label: Text("After Status")),
                                              const DataColumn(
                                                  label: Text("Employee")),
                                              const DataColumn(
                                                  label: Text("Note")),
                                            ],
                                            rows: _filteredHistory.map((item) {
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                      Text(item.createdAt)),
                                                  DataCell(Text(
                                                      item.orderId.toString())),
                                                  DataCell(
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 10.w,
                                                              vertical: 4.h),
                                                      decoration: BoxDecoration(
                                                        color: item.orderType ==
                                                                "supplier"
                                                            ? const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    255,
                                                                    150,
                                                                    30)
                                                                .withOpacity(
                                                                    0.15)
                                                            : const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    130,
                                                                    80,
                                                                    223)
                                                                .withOpacity(
                                                                    0.15),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12.r),
                                                      ),
                                                      child: Text(
                                                        item.orderType
                                                            .capitalize(),
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          fontSize: 12.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              item.orderType ==
                                                                      "supplier"
                                                                  ? const Color
                                                                      .fromARGB(
                                                                      255,
                                                                      255,
                                                                      150,
                                                                      30)
                                                                  : const Color
                                                                      .fromARGB(
                                                                      255,
                                                                      130,
                                                                      80,
                                                                      223),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(Text(item.action)),
                                                  DataCell(_buildStatusPill(
                                                      item.previousStatus)),
                                                  DataCell(_buildStatusPill(
                                                      item.newStatus)),
                                                  DataCell(Text(item.name)),
                                                  DataCell(
                                                      Text(item.note ?? "-")),
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

                            // Pagination Row
                            if (_filteredHistory.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 16.h, right: 8.w),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Total $_totalItems Records",
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
                                          ? () => _changePage(_currentPage - 1)
                                          : null,
                                    ),
                                    // Page buttons - limited to 5 pages max shown
                                    Row(
                                      children: _buildPageButtons(),
                                    ),
                                    // Right arrow button
                                    IconButton(
                                      icon: Icon(Icons.arrow_forward,
                                          size: 20.sp, color: Colors.white70),
                                      onPressed: _currentPage < _totalPages
                                          ? () => _changePage(_currentPage + 1)
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

  // Build pagination buttons
  List<Widget> _buildPageButtons() {
    // Limit the number of visible buttons to 5
    int startPage = 1;
    int endPage = _totalPages;

    if (_totalPages > 5) {
      if (_currentPage <= 3) {
        endPage = 5;
      } else if (_currentPage >= _totalPages - 2) {
        startPage = _totalPages - 4;
      } else {
        startPage = _currentPage - 2;
        endPage = _currentPage + 2;
      }
    }

    List<Widget> buttons = [];

    // Add "First" button if we're not at the start
    if (startPage > 1) {
      buttons.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: BorderSide(
                color: const Color.fromARGB(255, 34, 53, 62),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            ),
            onPressed: () => _changePage(1),
            child: Text(
              "1...",
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    // Add page buttons
    for (int i = startPage; i <= endPage; i++) {
      final bool isSelected = (i == _currentPage);
      buttons.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: isSelected
                  ? const Color.fromARGB(255, 105, 65, 198)
                  : Colors.transparent,
              side: BorderSide(
                color: const Color.fromARGB(255, 34, 53, 62),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            ),
            onPressed: () => _changePage(i),
            child: Text(
              "$i",
              style: GoogleFonts.spaceGrotesk(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    // Add "Last" button if we're not at the end
    if (endPage < _totalPages) {
      buttons.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: BorderSide(
                color: const Color.fromARGB(255, 34, 53, 62),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            ),
            onPressed: () => _changePage(_totalPages),
            child: Text(
              "...$_totalPages",
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  // Helper method to build summary cards
  Widget _buildSummaryCard({
    required String title,
    required String count,
    required IconData iconData,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Icon(
                iconData,
                color: color,
                size: 28.sp,
              ),
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  count,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return this.isEmpty ? this : "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
