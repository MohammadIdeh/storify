// lib/supplier/widgets/SupplierOrders.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/supplier/screens/productScreenSupplier.dart';
import 'package:storify/supplier/widgets/orderwidgets/OrderDetailsWidget.dart';
import 'package:storify/supplier/widgets/orderwidgets/OrderDetails_Model.dart';
import 'package:storify/supplier/widgets/orderwidgets/apiService.dart';
import 'package:storify/supplier/widgets/navbar.dart';
import 'package:storify/supplier/widgets/orderwidgets/suuplierOrdertable.dart';

class SupplierOrders extends StatefulWidget {
  const SupplierOrders({super.key});

  @override
  State<SupplierOrders> createState() => _SupplierOrdersState();
}

class _SupplierOrdersState extends State<SupplierOrders> {
  // API Service
  final ApiService _apiService = ApiService();

  // Bottom navigation index.
  int _currentIndex = 0;
  String? profilePictureUrl;

  // Orders state
  List<Order> _orders = [];
  bool _isLoading = true;
  int _selectedFilterIndex = 0;
  String _searchQuery = "";

  // Selected order for details
  Order? _selectedOrder;
  Order? _orderDetails;

  // Filter options
  final List<String> _filterOptions = [
    "Total",
    "Active",
    "Completed",
    "Cancelled"
  ];

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _loadOrders();
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  // Load orders from API
// Update _loadOrders method in SupplierOrders class
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await _apiService.fetchSupplierOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Check if error is authentication related
      String errorMsg = e.toString();
      if (errorMsg.contains('Authentication failed') ||
          errorMsg.contains('must be logged in')) {
        // Show auth error and navigate to login if needed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Login',
                onPressed: () {
                  // Navigate to login screen
                  // Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ),
          );
        }
      } else {
        // Show general error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load orders: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
                const SupplierProducts(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
        break;
    }
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  // Handle order selection
// In SupplierOrders.dart
  void _handleOrderSelected(Order? order) {
    setState(() {
      _selectedOrder = order;
      _orderDetails =
          order; // Just use the order directly, no conversion needed
    });
  }

  // Refresh orders after status update
// Refresh orders after status update
  void _refreshOrders() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final orders = await _apiService.fetchSupplierOrders();

      // Update state with new orders
      setState(() {
        _orders = orders;
        _isLoading = false;
        // Clear selection to avoid stale data
        _selectedOrder = null;
        _orderDetails = null;
      });

      // Show refresh success message
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh orders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Close order details
  void _closeOrderDetails() {
    setState(() {
      _selectedOrder = null;
      _orderDetails = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(250),
        child: NavigationBarSupplier(
          currentIndex: _currentIndex,
          onTap: _onNavItemTap,
          profilePictureUrl: profilePictureUrl,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(30.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Orders Header
              Text(
                "Order Management",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 34.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24.h),

              // Filter and Search Row
              Row(
                children: [
                  Text(
                    "Orders list",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: 10.w,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 36, 50, 69),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    child: Row(
                      children: List.generate(
                        _filterOptions.length,
                        (index) => Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: _buildFilterChip(_filterOptions[index], index),
                        ),
                      ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    width: 300.w,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 36, 50, 69),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: TextField(
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search ID",
                        hintStyle: GoogleFonts.spaceGrotesk(
                          color: Colors.white30,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white30,
                          size: 20.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onChanged: _updateSearchQuery,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Orders Table or loading indicator
              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: const Color.fromARGB(255, 105, 65, 198),
                      ),
                    )
                  : SupplierOrderTable(
                      orders: _orders,
                      filter: _filterOptions[_selectedFilterIndex],
                      searchQuery: _searchQuery,
                      onOrderSelected: _handleOrderSelected,
                      selectedOrder: _selectedOrder,
                    ),

              // Order Details Widget (only shown when an order is selected)
              if (_selectedOrder != null && _orderDetails != null)
                OrderDetailsWidget(
                  orderDetails: _orderDetails!,
                  onClose: _closeOrderDetails,
                  onStatusUpdate: _refreshOrders,
                  apiService: _apiService,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final bool isSelected = _selectedFilterIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
          // Clear selection when changing filters
          _selectedOrder = null;
          _orderDetails = null;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 105, 65, 198)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : const Color.fromARGB(255, 230, 230, 230),
          ),
        ),
      ),
    );
  }
}
