import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'dart:convert';
import 'package:storify/admin/widgets/navigationBar.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/Categories.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/screens/orders.dart';
import 'package:storify/admin/screens/roleManegment.dart';
import 'package:storify/admin/widgets/trackingWidgets/cards.dart';
import 'package:storify/admin/widgets/trackingWidgets/advanced_tracking_map.dart';

class Track extends StatefulWidget {
  const Track({super.key});

  @override
  State<Track> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<Track> {
  int _currentIndex = 5;
  String? profilePictureUrl;
  List<Map<String, String>> _trackData = [];
  List<dynamic> _allOrders = [];
  bool _isLoading = true;
  bool _isLoadingOrders = false;
  String? _errorMessage;
  String? _ordersErrorMessage;

  // Filter and pagination for orders history
  String _orderStatusFilter = 'all';
  int _currentPage = 1;
  final int _ordersPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _fetchTrackingData();
    _fetchAllOrders();
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  Future<void> _fetchTrackingData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final headers = await AuthService.getAuthHeaders(role: 'Admin');

      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/dashboard/tracking-cards'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _trackData = [
            {
              'title': 'Total Shipment',
              'value': data['totalShipment'].toString(),
            },
            {
              'title': 'Completed',
              'value': data['completed'].toString(),
            },
            {
              'title': 'Pending',
              'value': data['pending'].toString(),
            },
          ];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Authentication failed. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load tracking data: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching tracking data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAllOrders() async {
    try {
      setState(() {
        _isLoadingOrders = true;
        _ordersErrorMessage = null;
      });

      final headers = await AuthService.getAuthHeaders(role: 'Admin');

      final response = await http.get(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/customer-order/all-orders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _allOrders = data['orders'] ?? [];
          _isLoadingOrders = false;
        });
      } else {
        setState(() {
          _ordersErrorMessage = 'Failed to load orders: ${response.statusCode}';
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      setState(() {
        _ordersErrorMessage = 'Error fetching orders: $e';
        _isLoadingOrders = false;
      });
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    try {
      // Show confirmation dialog
      final shouldCancel = await _showCancelConfirmation(orderId);
      if (!shouldCancel) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color.fromARGB(255, 36, 50, 69),
          content: Row(
            children: [
              CircularProgressIndicator(
                color: const Color.fromARGB(255, 99, 102, 241),
              ),
              SizedBox(width: 16.w),
              Text(
                'Canceling order...',
                style: GoogleFonts.spaceGrotesk(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      final headers = await AuthService.getAuthHeaders(role: 'Admin');

      // Add Content-Type for JSON body
      headers['Content-Type'] = 'application/json';

      // Required request body
      final requestBody = json.encode({"reason": "administrative_decision"});

      final response = await http.post(
        Uri.parse(
            'https://finalproject-a5ls.onrender.com/customer-order/$orderId/cancel'),
        headers: headers,
        body: requestBody,
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        // Show success message
        _showSuccessMessage('Order #$orderId has been canceled successfully');

        // Refresh data
        await _fetchTrackingData();
        await _fetchAllOrders();
      } else {
        final errorData =
            response.body.isNotEmpty ? json.decode(response.body) : {};
        final errorMessage = errorData['message'] ??
            'Failed to cancel order: ${response.statusCode}';
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if still open
      _showErrorMessage('Error canceling order: $e');
    }
  }

  Future<bool> _showCancelConfirmation(int orderId) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 36, 50, 69),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Cancel Order',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Are you sure you want to cancel Order #$orderId? This action cannot be undone.',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Keep Order',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(
                  'Cancel Order',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.spaceGrotesk(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 36, 50, 69),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.spaceGrotesk(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 36, 50, 69),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Future<void> _refreshTrackingData() async {
    await Future.wait([
      _fetchTrackingData(),
      _fetchAllOrders(),
    ]);
  }

  void _onNavItemTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/admin/dashboard');
        break;
      case 1:
        Navigator.pushNamed(context, '/admin/products');
        break;
      case 2:
        Navigator.pushNamed(context, '/admin/categories');
        break;
      case 3:
        Navigator.pushNamed(context, '/admin/orders');
        break;
      case 4:
        Navigator.pushNamed(context, '/admin/roles');
        break;
      case 5:
        // Current Track screen - no navigation needed
        break;
    }
  }

  Widget _buildTrackingCards() {
    if (_isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 99, 102, 241),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 50, 69),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color.fromARGB(255, 46, 57, 84),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40.sp,
              ),
              SizedBox(height: 10.h),
              Text(
                'Failed to load tracking data',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14.sp,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 10.h),
              ElevatedButton(
                onPressed: _refreshTrackingData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 99, 102, 241),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final numberOfCards = _trackData.length;
        const spacing = 40.0;
        final cardWidth =
            (availableWidth - ((numberOfCards - 1) * spacing)) / numberOfCards;

        return Wrap(
          spacing: spacing,
          runSpacing: 20,
          children: List.generate(_trackData.length, (index) {
            final data = _trackData[index];
            return SizedBox(
              width: cardWidth,
              child: TrackCards(
                title: data['title'] ?? '',
                value: data['value'] ?? '',
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildOrdersHistorySection() {
    return Container(
      margin: EdgeInsets.only(top: 40.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: const Color.fromARGB(255, 46, 57, 84),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: const Color.fromARGB(255, 99, 102, 241),
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Orders History',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Filter dropdown
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 46, 57, 84),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: DropdownButton<String>(
                    value: _orderStatusFilter,
                    dropdownColor: const Color.fromARGB(255, 46, 57, 84),
                    underline: Container(),
                    style: GoogleFonts.spaceGrotesk(color: Colors.white),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('All Orders')),
                      DropdownMenuItem(
                          value: 'on_theway', child: Text('On The Way')),
                      DropdownMenuItem(
                          value: 'Shipped', child: Text('Shipped')),
                      DropdownMenuItem(
                          value: 'Cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _orderStatusFilter = value!;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16.w),
                IconButton(
                  onPressed: _fetchAllOrders,
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.white70,
                    size: 24.sp,
                  ),
                ),
              ],
            ),
          ),

          // Orders content
          if (_isLoadingOrders)
            Container(
              height: 200.h,
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color.fromARGB(255, 99, 102, 241),
                ),
              ),
            )
          else if (_ordersErrorMessage != null)
            Container(
              height: 200.h,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 32.sp),
                    SizedBox(height: 8.h),
                    Text(
                      _ordersErrorMessage!,
                      style: GoogleFonts.spaceGrotesk(color: Colors.white70),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: _fetchAllOrders,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildOrdersTable(),
        ],
      ),
    );
  }

  Widget _buildOrdersTable() {
    final filteredOrders = _allOrders.where((order) {
      if (_orderStatusFilter == 'all') return true;
      return order['status'] == _orderStatusFilter;
    }).toList();

    final totalPages = (filteredOrders.length / _ordersPerPage).ceil();
    final startIndex = (_currentPage - 1) * _ordersPerPage;
    final endIndex =
        (startIndex + _ordersPerPage).clamp(0, filteredOrders.length);
    final paginatedOrders = filteredOrders.sublist(startIndex, endIndex);

    if (filteredOrders.isEmpty) {
      return Container(
        height: 200.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48.sp,
                color: Colors.white54,
              ),
              SizedBox(height: 16.h),
              Text(
                'No orders found',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Table headers
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 46, 57, 84),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  'Order ID',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Customer',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Status',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Total',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Date',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Actions',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Table rows
        ...paginatedOrders.asMap().entries.map((entry) {
          final index = entry.key;
          final order = entry.value;
          return _buildOrderRow(order, index);
        }).toList(),

        // Pagination
        if (totalPages > 1) _buildPagination(totalPages),
      ],
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order, int index) {
    final isEven = index % 2 == 0;
    final status = order['status'] ?? 'Unknown';
    final customerName = order['customer']?['user']?['name'] ?? 'Unknown';
    final totalCost = order['totalCost'] ?? 0;
    final createdAt = order['createdAt'] ?? '';
    final orderId = order['id'] ?? 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isEven
            ? const Color.fromARGB(255, 29, 41, 57)
            : const Color.fromARGB(255, 36, 50, 69),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '#$orderId',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              customerName,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(status),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Add cancellation indicator for cancelled orders
                if (status == 'Cancelled' &&
                    order['cancelledByUser'] != null) ...[
                  SizedBox(width: 4.w),
                  Tooltip(
                    message:
                        'Cancelled by ${order['cancelledByUser']['name']}\nClick "View Details" for more info',
                    child: Icon(
                      Icons.info_outline,
                      size: 14.sp,
                      color: Colors.red.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '\$${totalCost.toString()}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 16, 185, 129),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(createdAt),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14.sp,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                if (status == 'on_theway') ...[
                  IconButton(
                    onPressed: () {
                      print(
                          '🔧 DEBUG: Cancel button clicked for order $orderId');
                    },
                    icon: Icon(
                      Icons.cancel,
                      color: Colors.red,
                      size: 20.sp,
                    ),
                    tooltip: 'Cancel Order',
                  ),
                ],
                IconButton(
                  onPressed: () => _showOrderDetails(order),
                  icon: Icon(
                    Icons.visibility,
                    color: const Color.fromARGB(255, 99, 102, 241),
                    size: 20.sp,
                  ),
                  tooltip: 'View Details',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 46, 57, 84),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $_currentPage of $totalPages',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14.sp,
              color: Colors.white70,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                icon: Icon(
                  Icons.chevron_left,
                  color: _currentPage > 1 ? Colors.white : Colors.white38,
                ),
              ),
              ...List.generate(
                totalPages.clamp(0, 5),
                (index) {
                  final page = index + 1;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: TextButton(
                      onPressed: () => setState(() => _currentPage = page),
                      style: TextButton.styleFrom(
                        backgroundColor: _currentPage == page
                            ? const Color.fromARGB(255, 99, 102, 241)
                            : Colors.transparent,
                        minimumSize: Size(40.w, 40.h),
                      ),
                      child: Text(
                        page.toString(),
                        style: GoogleFonts.spaceGrotesk(
                          color: _currentPage == page
                              ? Colors.white
                              : Colors.white70,
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                icon: Icon(
                  Icons.chevron_right,
                  color:
                      _currentPage < totalPages ? Colors.white : Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on_theway':
        return Colors.orange;
      case 'shipped':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  String _formatCancellationReason(String reason) {
    switch (reason) {
      case 'administrative_decision':
        return 'Administrative Decision';
      case 'customer_request':
        return 'Customer Request';
      case 'inventory_issue':
        return 'Inventory Issue';
      case 'delivery_problem':
        return 'Delivery Problem';
      case 'payment_issue':
        return 'Payment Issue';
      case 'system_error':
        return 'System Error';
      default:
        return reason
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : word)
            .join(' ');
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 36, 50, 69),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Order #${order['id']} Details',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem('Status', order['status'] ?? 'Unknown'),
              _buildDetailItem(
                  'Customer', order['customer']?['user']?['name'] ?? 'Unknown'),
              _buildDetailItem(
                  'Email', order['customer']?['user']?['email'] ?? 'Unknown'),
              _buildDetailItem(
                  'Address', order['customer']?['address'] ?? 'Unknown'),
              _buildDetailItem('Total Cost', '\$${order['totalCost'] ?? 0}'),
              _buildDetailItem(
                  'Payment Method', order['paymentMethod'] ?? 'Not specified'),
              if (order['deliveryEmployee'] != null)
                _buildDetailItem('Delivery Person',
                    order['deliveryEmployee']['user']['name'] ?? 'Unknown'),
              _buildDetailItem(
                  'Created', _formatDate(order['createdAt'] ?? '')),
              // Show cancellation reason for cancelled orders
              if (order['status'] == 'Cancelled' &&
                  order['cancellationReason'] != null) ...[
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Cancellation Details',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      _buildDetailItem(
                          'Reason',
                          _formatCancellationReason(
                              order['cancellationReason'])),
                      if (order['cancelledAt'] != null)
                        _buildDetailItem(
                            'Cancelled At', _formatDate(order['cancelledAt'])),

                      // Show admin details who cancelled the order
                      if (order['cancelledByUser'] != null) ...[
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings,
                                    color: Colors.red,
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Cancelled by Administrator',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              _buildDetailItem(
                                  'Admin Name',
                                  order['cancelledByUser']['name'] ??
                                      'Unknown Admin'),
                              _buildDetailItem(
                                  'Admin Email',
                                  order['cancelledByUser']['email'] ??
                                      'No email'),
                              _buildDetailItem('Admin ID',
                                  '#${order['cancelledByUser']['userId'] ?? 'Unknown'}'),
                            ],
                          ),
                        ),
                      ] else if (order['cancelledBy'] != null) ...[
                        // Fallback to old format if new format not available
                        _buildDetailItem('Cancelled By',
                            'Admin ID: ${order['cancelledBy']}'),
                      ],
                    ],
                  ),
                ),
              ],

              if (order['items'] != null && order['items'].isNotEmpty) ...[
                SizedBox(height: 16.h),
                Text(
                  'Items:',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                ...order['items']
                    .map<Widget>((item) => Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 46, 57, 84),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['product']?['name'] ?? 'Unknown Product',
                                  style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white),
                                ),
                              ),
                              Text(
                                'Qty: ${item['quantity']} × ${item['Price']}',
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white70),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ],
            ],
          ),
        ),
        actions: [
          if (order['status'] == 'on_theway') ...[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                print('🔧 DEBUG: Cancel button in details dialog clicked');
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
              ),
              child: Text(
                'Cancel Order',
                style: GoogleFonts.spaceGrotesk(color: Colors.red),
              ),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.spaceGrotesk(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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
        onRefresh: _refreshTrackingData,
        color: const Color.fromARGB(255, 99, 102, 241),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(left: 45.w, top: 20.h, right: 45.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// --- Dashboard Title ---
                  Row(
                    children: [
                      Text(
                        "Tracking",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 35.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(255, 246, 246, 246),
                        ),
                      ),
                      const Spacer(),
                      // Add refresh button
                      IconButton(
                        onPressed: _refreshTrackingData,
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.white70,
                          size: 24.sp,
                        ),
                      ),
                    ],
                  ),

                  /// --- Tracking Cards ---
                  const SizedBox(height: 20),
                  _buildTrackingCards(),

                  /// --- Advanced Map Section ---
                  const SizedBox(height: 40),
                  AdvancedTrackingMap(
                    onOrderCancel: _cancelOrder,
                  ),

                  /// --- Orders History Section ---
                  _buildOrdersHistorySection(),

                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
