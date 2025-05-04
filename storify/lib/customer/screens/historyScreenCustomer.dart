// lib/customer/screens/historyScreenCustomer.dart
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
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const CustomerOrders(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
        break;
      case 1:
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
                                    const SizedBox(height: 30),

                                    // Order items table
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
                                          // Table header
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey[800]!,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 5,
                                                  child: Text(
                                                    "Product",
                                                    style: GoogleFonts
                                                        .spaceGrotesk(
                                                      color: Colors.grey[400],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    "Price",
                                                    style: GoogleFonts
                                                        .spaceGrotesk(
                                                      color: Colors.grey[400],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    "Quantity",
                                                    style: GoogleFonts
                                                        .spaceGrotesk(
                                                      color: Colors.grey[400],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    "Total",
                                                    style: GoogleFonts
                                                        .spaceGrotesk(
                                                      color: Colors.grey[400],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Table rows
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

                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: Colors.grey[800]!,
                                                      width: 1,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // Product with image
                                                    Expanded(
                                                      flex: 5,
                                                      child: Row(
                                                        children: [
                                                          // Product image
                                                          Container(
                                                            width: 50,
                                                            height: 50,
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
                                                                imageUrl:
                                                                    product[
                                                                        'image'],
                                                                fit: BoxFit
                                                                    .cover,
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
                                                                    (context,
                                                                            url,
                                                                            error) =>
                                                                        Icon(
                                                                  Icons
                                                                      .image_not_supported,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),

                                                          // Product details
                                                          Expanded(
                                                            child: Text(
                                                              product['name'],
                                                              style: GoogleFonts
                                                                  .spaceGrotesk(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    // Price
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(
                                                        "\$${price.toStringAsFixed(2)}",
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          color: Colors.white,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),

                                                    // Quantity
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(
                                                        quantity.toString(),
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          color: Colors.white,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),

                                                    // Total
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(
                                                        "\$${subtotal.toStringAsFixed(2)}",
                                                        style: GoogleFonts
                                                            .spaceGrotesk(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        textAlign:
                                                            TextAlign.right,
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
