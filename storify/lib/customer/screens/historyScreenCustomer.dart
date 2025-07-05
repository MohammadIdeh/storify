// lib/customer/screens/historyScreenCustomer.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/customer/screens/orderScreenCustomer.dart';
import 'package:storify/customer/widgets/CustomerOrderService.dart';
import 'package:storify/customer/widgets/navbarCus.dart';

import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreenCustomer extends StatefulWidget {
  const HistoryScreenCustomer({super.key});

  @override
  State<HistoryScreenCustomer> createState() => _HistoryScreenCustomerState();
}

class _HistoryScreenCustomerState extends State<HistoryScreenCustomer> {
  int _currentIndex = 1;
  String? profilePictureUrl;

  // Date range filter
  DateTime? _startDate;
  DateTime? _endDate;

  // Selected order for details view
  Map<String, dynamic>? _selectedOrder;

  // Orders data
  List<dynamic> _orders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _loadOrderHistory();
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  Future<void> _loadOrderHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await CustomerOrderService.getOrderHistory();
      setState(() {
        _orders = orders;
        _filteredOrders = orders; // Initialize filtered orders with all orders
        if (orders.isNotEmpty) {
          _selectedOrder = orders[0];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar("Failed to load order history: $e");
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
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
        // Navigate to orders with URL change
        Navigator.pushNamed(context, '/customer/orders');
        break;
      case 1:
        // Current History screen - no navigation needed
        break;
    }
  }

  void _selectOrder(Map<String, dynamic> order) {
    setState(() {
      _selectedOrder = order;
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM, yyyy').format(date);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMM, yyyy HH:mm').format(date);
  }

  // Apply date filter
  void _applyDateFilter() {
    setState(() {
      if (_startDate == null && _endDate == null) {
        // No filter applied, show all orders
        _filteredOrders = _orders;
      } else {
        _filteredOrders = _orders.where((order) {
          final orderDate = DateTime.parse(order['createdAt']);

          // Check start date
          if (_startDate != null && orderDate.isBefore(_startDate!)) {
            return false;
          }

          // Check end date (include orders from the entire end date)
          if (_endDate != null) {
            final endDatePlusOne = _endDate!.add(const Duration(days: 1));
            if (orderDate.isAfter(endDatePlusOne)) {
              return false;
            }
          }

          return true;
        }).toList();
      }

      // Update selected order if filtered list isn't empty
      if (_filteredOrders.isNotEmpty) {
        _selectedOrder = _filteredOrders[0];
      } else {
        _selectedOrder = null;
      }
    });
  }

  // Clear date filter
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _filteredOrders = _orders;
      if (_filteredOrders.isNotEmpty) {
        _selectedOrder = _filteredOrders[0];
      }
    });
  }

  // Show date picker and set date
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startDate ?? DateTime.now()
          : _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7B5CFA),
              onPrimary: Colors.white,
              surface: Color(0xFF283548),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1D2939),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
            textTheme: Theme.of(context).textTheme.apply(
                  fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before start date, reset end date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
          // If start date is after end date, reset start date
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = null;
          }
        }
      });
      _applyDateFilter();
    }
  }

  Widget _buildOrderStatusBadge(String status) {
    Color badgeColor;
    final lowerStatus = status.toLowerCase();

    switch (lowerStatus) {
      case "delivered":
        badgeColor = Colors.green;
        break;
      case "pending":
        badgeColor = Colors.orange;
        break;
      case "prepared":
        badgeColor = Colors.blue;
        break;
      case "cancelled":
        badgeColor = Colors.red;
        break;
      case "rejected":
        badgeColor = Colors.red;
        break;
      case "accepted":
        badgeColor = Colors.green;
        break;
      default:
        badgeColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Calculate order subtotal from items
  double _calculateSubtotal(List<dynamic> items) {
    double subtotal = 0;
    for (var item in items) {
      subtotal += (item['subtotal'] ?? 0).toDouble();
    }
    return subtotal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: NavigationBarCustomer(
          currentIndex: _currentIndex,
          onTap: _onNavItemTap,
          profilePictureUrl: profilePictureUrl,
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF7B5CFA),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Order History List
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Order History",
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: _loadOrderHistory,
                              icon: Icon(
                                Icons.refresh,
                                color: Colors.white70,
                                size: 28,
                              ),
                              tooltip: "Refresh",
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Date Range Filter
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF283548),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Filter by Date Range",
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _selectDate(context, true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D2939),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.grey[700]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today,
                                                size: 16,
                                                color: Colors.grey[400]),
                                            const SizedBox(width: 8),
                                            Text(
                                              _startDate == null
                                                  ? "Start Date"
                                                  : _formatDate(_startDate!),
                                              style: GoogleFonts.spaceGrotesk(
                                                color: _startDate == null
                                                    ? Colors.grey[400]
                                                    : Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _selectDate(context, false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D2939),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.grey[700]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today,
                                                size: 16,
                                                color: Colors.grey[400]),
                                            const SizedBox(width: 8),
                                            Text(
                                              _endDate == null
                                                  ? "End Date"
                                                  : _formatDate(_endDate!),
                                              style: GoogleFonts.spaceGrotesk(
                                                color: _endDate == null
                                                    ? Colors.grey[400]
                                                    : Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _applyDateFilter,
                                      icon: const Icon(Icons.filter_list),
                                      label: Text(
                                        "Apply Filter",
                                        style: GoogleFonts.spaceGrotesk(),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF7B5CFA),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _clearDateFilter,
                                    icon: const Icon(Icons.clear),
                                    label: Text(
                                      "Clear",
                                      style: GoogleFonts.spaceGrotesk(),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[800],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Orders list
                        Expanded(
                          child: _filteredOrders.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "No orders found",
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.grey[400],
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Try adjusting your filter criteria",
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _filteredOrders.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    final order = _filteredOrders[index];
                                    final isSelected = _selectedOrder != null &&
                                        _selectedOrder!['id'] == order['id'];

                                    return GestureDetector(
                                      onTap: () => _selectOrder(order),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF7B5CFA)
                                                  .withOpacity(0.2)
                                              : const Color(0xFF283548),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                          border: isSelected
                                              ? Border.all(
                                                  color:
                                                      const Color(0xFF7B5CFA),
                                                  width: 2)
                                              : null,
                                        ),
                                        child: Column(
                                          children: [
                                            // Order header
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "Order #${order['id']}",
                                                      style: GoogleFonts
                                                          .spaceGrotesk(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      "Date: ${_formatDate(DateTime.parse(order['createdAt']))}",
                                                      style: GoogleFonts
                                                          .spaceGrotesk(
                                                        color: Colors.grey[400],
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  "\$${order['totalCost'].toStringAsFixed(2)}",
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),

                                            // Order details
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "${order['items'].length} items",
                                                  style:
                                                      GoogleFonts.spaceGrotesk(
                                                    color: Colors.grey[400],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                _buildOrderStatusBadge(
                                                    order['status']),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right side - Order Details
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 24.0, right: 24.0, bottom: 24.0),
                    child: _selectedOrder == null
                        ? Center(
                            child: Text(
                              "Select an order to view details",
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.grey[400],
                                fontSize: 18,
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF222E41),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Order Details Header
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Order Details",
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            _buildOrderStatusBadge(
                                                _selectedOrder!['status']),
                                            const SizedBox(width: 16),
                                            ElevatedButton.icon(
                                              onPressed: () {},
                                              icon: const Icon(Icons.print),
                                              label: Text(
                                                "Print Invoice",
                                                style:
                                                    GoogleFonts.spaceGrotesk(),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF7B5CFA),
                                                foregroundColor: Colors.white,
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 30),

                                    // Order ID and Date
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _detailItem("Order ID",
                                              "#${_selectedOrder!['id']}",
                                              icon: Icons.receipt),
                                        ),
                                        Expanded(
                                          child: _detailItem(
                                              "Order Date",
                                              _formatDate(DateTime.parse(
                                                  _selectedOrder![
                                                      'createdAt'])),
                                              icon: Icons.calendar_today),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Preparation timing (if available)
                                    if (_selectedOrder![
                                                'preparationStartedAt'] !=
                                            null ||
                                        _selectedOrder![
                                                'preparationCompletedAt'] !=
                                            null) ...[
                                      Row(
                                        children: [
                                          if (_selectedOrder![
                                                  'preparationStartedAt'] !=
                                              null)
                                            Expanded(
                                              child: _detailItem(
                                                "Preparation Started",
                                                _formatDateTime(DateTime.parse(
                                                    _selectedOrder![
                                                        'preparationStartedAt'])),
                                                icon: Icons.play_circle,
                                              ),
                                            ),
                                          if (_selectedOrder![
                                                  'preparationCompletedAt'] !=
                                              null)
                                            Expanded(
                                              child: _detailItem(
                                                "Preparation Completed",
                                                _formatDateTime(DateTime.parse(
                                                    _selectedOrder![
                                                        'preparationCompletedAt'])),
                                                icon: Icons.check_circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                    ],

                                    // Order items table with batch details
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF283548),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Order Items",
                                            style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 20),

                                          // Items with batch details
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount:
                                                _selectedOrder!['items'].length,
                                            itemBuilder: (context, index) {
                                              final item =
                                                  _selectedOrder!['items']
                                                      [index];
                                              final product = item['product'];
                                              final quantity = item['quantity'];
                                              final price =
                                                  item['Price'].toDouble();
                                              final subtotal =
                                                  item['subtotal'].toDouble();

                                              // Parse batch details with comprehensive debugging
                                              List<dynamic> batchDetails = [];

                                              debugPrint(
                                                  '🔍 RAW ITEM DATA: ${item.toString()}');
                                              debugPrint(
                                                  '🔍 Item ${product['name']} - Raw batchDetails: ${item['batchDetails']}');
                                              debugPrint(
                                                  '🔍 batchDetails type: ${item['batchDetails'].runtimeType}');

                                              // Handle batch details parsing
                                              if (item['batchDetails'] !=
                                                  null) {
                                                var rawBatchDetails =
                                                    item['batchDetails'];

                                                if (rawBatchDetails is List) {
                                                  batchDetails =
                                                      rawBatchDetails;
                                                  debugPrint(
                                                      '✅ Found List batchDetails: $batchDetails');
                                                } else if (rawBatchDetails
                                                    is String) {
                                                  // Try to parse if it's a JSON string
                                                  try {
                                                    var parsedData = jsonDecode(
                                                        rawBatchDetails);
                                                    if (parsedData is List) {
                                                      batchDetails = parsedData;
                                                      debugPrint(
                                                          '✅ Parsed String to List batchDetails: $batchDetails');
                                                    }
                                                  } catch (e) {
                                                    debugPrint(
                                                        '❌ Failed to parse batchDetails string: $e');
                                                  }
                                                } else {
                                                  debugPrint(
                                                      '❌ Unexpected batchDetails type: ${rawBatchDetails.runtimeType}');
                                                }
                                              } else {
                                                debugPrint(
                                                    '❌ batchDetails is null');
                                              }

                                              debugPrint(
                                                  '🎯 Final batchDetails: $batchDetails (length: ${batchDetails.length})');

                                              return Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 16),
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF1D2939),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFF283548),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Product info row
                                                    Row(
                                                      children: [
                                                        // Product image
                                                        Container(
                                                          width: 60,
                                                          height: 60,
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            child:
                                                                CachedNetworkImage(
                                                              imageUrl: product[
                                                                  'image'],
                                                              fit: BoxFit.cover,
                                                              placeholder:
                                                                  (context,
                                                                          url) =>
                                                                      Center(
                                                                child:
                                                                    CircularProgressIndicator(
                                                                  color: const Color(
                                                                      0xFF7B5CFA),
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                              ),
                                                              errorWidget:
                                                                  (context, url,
                                                                          error) =>
                                                                      Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 16),

                                                        // Product details
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                product['name'],
                                                                style: GoogleFonts
                                                                    .spaceGrotesk(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                "Unit Price: ${price.toStringAsFixed(2)}",
                                                                style: GoogleFonts
                                                                    .spaceGrotesk(
                                                                  color: Colors
                                                                          .grey[
                                                                      400],
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        // Quantity and total
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Text(
                                                              "Total Qty: $quantity",
                                                              style: GoogleFonts
                                                                  .spaceGrotesk(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 4),
                                                            Text(
                                                              "${subtotal.toStringAsFixed(2)}",
                                                              style: GoogleFonts
                                                                  .spaceGrotesk(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),

                                                    // Always show batch section for better visibility
                                                    const SizedBox(height: 16),
                                                    Container(
                                                      width: double.infinity,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFF283548),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        border: Border.all(
                                                          color: const Color(
                                                                  0xFF7B5CFA)
                                                              .withOpacity(0.3),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .inventory_2,
                                                                color: const Color(
                                                                    0xFF7B5CFA),
                                                                size: 18,
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                "Product Batch Information",
                                                                style: GoogleFonts
                                                                    .spaceGrotesk(
                                                                  color: const Color(
                                                                      0xFF7B5CFA),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 12),
                                                          if (batchDetails
                                                              .isNotEmpty) ...[
                                                            Text(
                                                              "This order contains products from ${batchDetails.length} different batch${batchDetails.length > 1 ? 'es' : ''}:",
                                                              style: GoogleFonts
                                                                  .spaceGrotesk(
                                                                color: Colors
                                                                    .grey[300],
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 12),

                                                            // Display each batch as a card
                                                            ...batchDetails
                                                                .asMap()
                                                                .entries
                                                                .map((entry) {
                                                              final batchIndex =
                                                                  entry.key;
                                                              final batch =
                                                                  entry.value;

                                                              debugPrint(
                                                                  '🎨 Rendering batch $batchIndex: $batch');

                                                              return Container(
                                                                margin: EdgeInsets.only(
                                                                    bottom: batchIndex ==
                                                                            batchDetails.length -
                                                                                1
                                                                        ? 0
                                                                        : 12),
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        12),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: const Color(
                                                                      0xFF1D2939),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  border: Border
                                                                      .all(
                                                                    color: const Color(
                                                                            0xFF7B5CFA)
                                                                        .withOpacity(
                                                                            0.2),
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceBetween,
                                                                      children: [
                                                                        Container(
                                                                          padding: const EdgeInsets
                                                                              .symmetric(
                                                                              horizontal: 10,
                                                                              vertical: 6),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                const Color(0xFF7B5CFA),
                                                                            borderRadius:
                                                                                BorderRadius.circular(6),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            "Batch #${batch['batchId'] ?? 'Unknown'}",
                                                                            style:
                                                                                GoogleFonts.spaceGrotesk(
                                                                              color: Colors.white,
                                                                              fontSize: 14,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Container(
                                                                          padding: const EdgeInsets
                                                                              .symmetric(
                                                                              horizontal: 10,
                                                                              vertical: 6),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                Colors.orange.withOpacity(0.2),
                                                                            borderRadius:
                                                                                BorderRadius.circular(6),
                                                                            border:
                                                                                Border.all(color: Colors.orange, width: 1),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            "Qty: ${batch['quantity'] ?? 'Unknown'}",
                                                                            style:
                                                                                GoogleFonts.spaceGrotesk(
                                                                              color: Colors.orange,
                                                                              fontSize: 14,
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            12),
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Row(
                                                                                children: [
                                                                                  Icon(
                                                                                    Icons.calendar_today,
                                                                                    color: Colors.green,
                                                                                    size: 16,
                                                                                  ),
                                                                                  const SizedBox(width: 6),
                                                                                  Text(
                                                                                    "Production Date",
                                                                                    style: GoogleFonts.spaceGrotesk(
                                                                                      color: Colors.grey[400],
                                                                                      fontSize: 12,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(height: 4),
                                                                              Text(
                                                                                batch['prodDate'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(batch['prodDate'])) : "Unknown",
                                                                                style: GoogleFonts.spaceGrotesk(
                                                                                  color: Colors.green,
                                                                                  fontSize: 14,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                16),
                                                                        Expanded(
                                                                          child:
                                                                              Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Row(
                                                                                children: [
                                                                                  Icon(
                                                                                    Icons.schedule,
                                                                                    color: Colors.red,
                                                                                    size: 16,
                                                                                  ),
                                                                                  const SizedBox(width: 6),
                                                                                  Text(
                                                                                    "Expiration Date",
                                                                                    style: GoogleFonts.spaceGrotesk(
                                                                                      color: Colors.grey[400],
                                                                                      fontSize: 12,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(height: 4),
                                                                              Text(
                                                                                batch['expDate'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(batch['expDate'])) : "Unknown",
                                                                                style: GoogleFonts.spaceGrotesk(
                                                                                  color: Colors.red,
                                                                                  fontSize: 14,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }).toList(),
                                                          ] else ...[
                                                            // Show debugging info when no batch details are available
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .warning_amber,
                                                                      color: Colors
                                                                          .orange,
                                                                      size: 18,
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            8),
                                                                    Text(
                                                                      "Batch information not found",
                                                                      style: GoogleFonts
                                                                          .spaceGrotesk(
                                                                        color: Colors
                                                                            .orange,
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 8),
                                                                Text(
                                                                  "Check console logs for debugging information.",
                                                                  style: GoogleFonts
                                                                      .spaceGrotesk(
                                                                    color: Colors
                                                                            .grey[
                                                                        400],
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 8),
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          8),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: const Color(
                                                                        0xFF1D2939),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(4),
                                                                  ),
                                                                  child: Text(
                                                                    "Raw data: ${item['batchDetails']}",
                                                                    style: GoogleFonts
                                                                        .spaceGrotesk(
                                                                      color: Colors
                                                                              .grey[
                                                                          500],
                                                                      fontSize:
                                                                          10,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),

                                          // Order summary
                                          const SizedBox(height: 20),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1D2939),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "Subtotal",
                                                      style: GoogleFonts
                                                          .spaceGrotesk(
                                                        color: Colors.grey[300],
                                                      ),
                                                    ),
                                                    Text(
                                                      "\$${_calculateSubtotal(_selectedOrder!['items']).toStringAsFixed(2)}",
                                                      style: GoogleFonts
                                                          .spaceGrotesk(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (_selectedOrder![
                                                        'discount'] >
                                                    0) ...[
                                                  SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        "Discount",
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          color:
                                                              Colors.grey[300],
                                                        ),
                                                      ),
                                                      Text(
                                                        "\$${_selectedOrder!['discount'].toStringAsFixed(2)}",
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                SizedBox(height: 8),
                                                Divider(
                                                    color: Colors.grey[800]),
                                                SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      "Total",
                                                      style: GoogleFonts
                                                          .spaceGrotesk(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Text(
                                                      "\$${_selectedOrder!['totalCost'].toStringAsFixed(2)}",
                                                      style: GoogleFonts
                                                          .spaceGrotesk(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (_selectedOrder![
                                                        'amountPaid'] >
                                                    0) ...[
                                                  SizedBox(height: 16),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        "Amount Paid",
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          color:
                                                              Colors.grey[300],
                                                        ),
                                                      ),
                                                      Text(
                                                        "\$${_selectedOrder!['amountPaid'].toStringAsFixed(2)}",
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          color: Colors.green,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Payment Method
                                    const SizedBox(height: 30),
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF283548),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _infoItem(
                                              "Payment Method",
                                              _selectedOrder![
                                                      'paymentMethod'] ??
                                                  "Not specified",
                                              icon: Icons.payment,
                                            ),
                                          ),
                                          Expanded(
                                            child: _infoItem(
                                              "Payment Status",
                                              _selectedOrder!['amountPaid'] > 0
                                                  ? "Paid"
                                                  : "Pending",
                                              icon: Icons.check_circle,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Note if available
                                    if (_selectedOrder!['note'] != null) ...[
                                      const SizedBox(height: 30),
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF283548),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Order Note",
                                              style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              _selectedOrder!['note'],
                                              style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _detailItem(String label, String value, {IconData? icon}) {
    return Card(
      color: const Color(0xFF283548),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: const Color(0xFF7B5CFA),
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14,
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
