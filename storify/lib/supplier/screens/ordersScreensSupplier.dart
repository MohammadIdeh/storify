// lib/supplier/screens/ordersScreensSupplier.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
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
  bool _isRefreshing = false; // Add refresh loading state
  int _selectedFilterIndex = 0;
  String _searchQuery = "";

  // Selected order for details
  Order? _selectedOrder;
  Order? _orderDetails;

  // Filter options - will be localized in build method
  List<String> _filterOptions = [];

  // Flag to prevent multiple calls
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture(); // Safe to call in initState as it doesn't use localization
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only run once and only after the localization context is available
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initializeFilterOptions();
      _loadOrders();
    }
  }

  void _initializeFilterOptions() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    _filterOptions = [
      l10n.totalOrders,
      l10n.activeOrders,
      l10n.completedOrders,
      l10n.cancelledOrders
    ];
  }

  Future<void> _loadProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
    });
  }

  // Load orders from API
  Future<void> _loadOrders() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

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
              content: Text(l10n.authenticationError),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: l10n.loginButton,
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
              content: Text('${l10n.failedToLoadOrders}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Manual refresh method for the refresh icon
  Future<void> _manualRefreshOrders() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final orders = await _apiService.fetchSupplierOrders();
      setState(() {
        _orders = orders;
        _isRefreshing = false;
        // Clear selection when refreshing
        _selectedOrder = null;
        _orderDetails = null;
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.failedToRefreshOrders}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        // Navigate to supplier products with URL change
        Navigator.pushNamed(context, '/supplier/products');
        break;
    }
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  // Handle order selection
  void _handleOrderSelected(Order? order) {
    setState(() {
      _selectedOrder = order;
      _orderDetails =
          order; // Just use the order directly, no conversion needed
    });
  }

  // Refresh orders after status update
  void _refreshOrders() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

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
          content: Text('${l10n.failedToRefreshOrders}: $e'),
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
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
                  l10n.orderManagement,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 34.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 34.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                ),
                SizedBox(height: 24.h),

                // Filter and Search Row with Refresh Icon
                Row(
                  children: [
                    Text(
                      l10n.ordersList,
                      style: isArabic
                          ? GoogleFonts.cairo(
                              fontSize: 25.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            )
                          : GoogleFonts.spaceGrotesk(
                              fontSize: 25.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                    ),
                    SizedBox(width: 10.w),
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
                            padding: EdgeInsets.only(
                              left: isRtl ? 8.w : 0,
                              right: isRtl ? 0 : 8.w,
                            ),
                            child:
                                _buildFilterChip(_filterOptions[index], index),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w), // Add some spacing

                    // Refresh Icon Button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 36, 50, 69),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: IconButton(
                        onPressed: _isRefreshing || _isLoading
                            ? null
                            : _manualRefreshOrders,
                        icon: _isRefreshing
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color:
                                      const Color.fromARGB(255, 105, 65, 198),
                                ),
                              )
                            : Icon(
                                Icons.refresh,
                                color: _isLoading
                                    ? Colors.white30
                                    : const Color.fromARGB(255, 105, 65, 198),
                                size: 24.sp,
                              ),
                        // tooltip: l10n.refreshOrders ?? 'Refresh Orders',
                      ),
                    ),

                    const Spacer(),
                    Container(
                      width: 300.w,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 36, 50, 69),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: TextField(
                        style: isArabic
                            ? GoogleFonts.cairo(color: Colors.white70)
                            : GoogleFonts.spaceGrotesk(color: Colors.white70),
                        textDirection:
                            isRtl ? TextDirection.rtl : TextDirection.ltr,
                        decoration: InputDecoration(
                          hintText: l10n.searchOrderId,
                          hintStyle: isArabic
                              ? GoogleFonts.cairo(color: Colors.white30)
                              : GoogleFonts.spaceGrotesk(color: Colors.white30),
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
                        filter: _filterOptions.isNotEmpty
                            ? _filterOptions[_selectedFilterIndex]
                            : l10n.totalOrders,
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
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final bool isSelected = _selectedFilterIndex == index;
    final isArabic = LocalizationHelper.isArabic(context);

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
          style: isArabic
              ? GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : const Color.fromARGB(255, 230, 230, 230),
                )
              : GoogleFonts.spaceGrotesk(
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
