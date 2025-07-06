// lib/admin/screens/orders.dart (Updated with Localization)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// Localization imports
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
// Ensure these imports point to your local files.
import 'package:storify/admin/widgets/navigationBar.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/orderCards.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/orderModel.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/orderTable.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/supplierOrderPopUp.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/assignOrderPopup.dart';
// New low stock imports
import 'package:storify/admin/widgets/OrderSupplierWidgets/low_stock_service.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/low_stock_models.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/low_stock_popup.dart';
import 'package:storify/admin/widgets/OrderSupplierWidgets/customer_history_popup.dart';
import 'package:storify/utilis/notification_service.dart';
import 'package:storify/utilis/notificationModel.dart';

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

  // Added loading state
  bool _isLoading = true;

  // Error message for failed API calls
  String? _errorMessage;

  // Lists for orders from API
  List<OrderItem> _supplierOrders = [];
  List<OrderItem> _customerOrders = [];

  // NEW: Active status filter for customer orders
  String? _selectedActiveStatus;
  final List<String> _activeStatusOptions = [
    'Accepted',
    'Assigned',
    'Preparing',
    'Prepared',
    'on_theway'
  ];

  // NEW: Low stock related variables
  bool _isCheckingLowStock = false;
  bool _hasCheckedLowStock = false;
  List<LowStockItem> _lowStockItems = [];
  bool _shouldShowLowStockButton = false; // Add this flag

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _fetchOrders();
    // Check for low stock items when screen loads
    _checkLowStockItems();

    // Register for handling low stock notifications
    _registerLowStockNotificationHandler();
  }

  @override
  void dispose() {
    // Reset notification status when leaving the screen
    LowStockService.resetNotificationStatus();
    super.dispose();
  }

  // NEW: Register to handle low stock notifications from navbar
  void _registerLowStockNotificationHandler() {
    // This will be called when a low stock notification is tapped from navbar
    NotificationService()
        .registerLowStockNotificationHandler(_handleLowStockNotificationTap);
  }

  // NEW: Handle low stock notification taps
  Future<void> _handleLowStockNotificationTap() async {
    debugPrint(
        '🔔 Low stock notification tapped, fetching current low stock items...');

    try {
      final response = await LowStockService.getLowStockItems();

      if (response != null && response.lowStockItems.isNotEmpty && mounted) {
        debugPrint(
            '✅ Found ${response.lowStockItems.length} current low stock items');

        // Show the popup with current low stock items
        showLowStockPopup(
          context,
          response.lowStockItems,
          onOrdersGenerated: () {
            // Refresh orders when new orders are generated
            _fetchOrders();
            // Refresh low stock check
            _checkLowStockItems();
          },
        );
      } else {
        debugPrint('❌ No current low stock items found');
        if (mounted) {
          final l10n =
              Localizations.of<AppLocalizations>(context, AppLocalizations)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.noLowStockItemsFound),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('💥 Error fetching current low stock items: $e');
      if (mounted) {
        final l10n =
            Localizations.of<AppLocalizations>(context, AppLocalizations)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorFetchingLowStock}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NEW: Check for low stock items - Enhanced with better debugging
  Future<void> _checkLowStockItems() async {
    debugPrint('🔍 Starting low stock check...');
    debugPrint('🐛 DEBUG: _isSupplierMode = $_isSupplierMode');
    debugPrint(
        '🐛 DEBUG: _shouldShowLowStockButton = $_shouldShowLowStockButton');

    setState(() {
      _isCheckingLowStock = true;
    });

    try {
      debugPrint('🌐 Calling low stock API...');
      final response = await LowStockService.getLowStockItems();

      debugPrint('📊 API Response: ${response?.message}');
      debugPrint(
          '📦 Low stock items count: ${response?.lowStockItems.length ?? 0}');

      // DEBUG: Add more detailed checks
      debugPrint('🐛 DEBUG: response != null: ${response != null}');
      debugPrint(
          '🐛 DEBUG: response.lowStockItems.isNotEmpty: ${response?.lowStockItems.isNotEmpty}');
      debugPrint('🐛 DEBUG: mounted: $mounted');

      if (response != null && response.lowStockItems.isNotEmpty && mounted) {
        debugPrint('✅ Found ${response.lowStockItems.length} low stock items');

        debugPrint('🐛 DEBUG: About to setState...');
        setState(() {
          _lowStockItems = response.lowStockItems;
          _hasCheckedLowStock = true;
          _shouldShowLowStockButton = true; // Set the flag to show button
        });

        debugPrint('🐛 DEBUG: After setState:');
        debugPrint(
            '🐛 DEBUG: _lowStockItems.length = ${_lowStockItems.length}');
        debugPrint('🐛 DEBUG: _hasCheckedLowStock = $_hasCheckedLowStock');
        debugPrint(
            '🐛 DEBUG: _shouldShowLowStockButton = $_shouldShowLowStockButton');

        // Check if we should show notification
        final shouldShow = await LowStockService.shouldShowNotification();
        debugPrint('📋 Should show notification: $shouldShow');

        if (shouldShow) {
          // Show notification
          debugPrint('🔔 Creating notification...');
          await _showLowStockNotification(response.lowStockItems);

          // Mark that we've shown the notification
          await LowStockService.markNotificationShown();

          debugPrint('✅ Notification created and marked as shown');
        } else {
          debugPrint('🚫 Notification already shown today, skipping');
        }
      } else {
        debugPrint('❌ No low stock items found or response is null');
        debugPrint('🐛 DEBUG: About to setState (no items)...');
        setState(() {
          _hasCheckedLowStock = true;
          _shouldShowLowStockButton = false; // Don't show button if no items
          _lowStockItems.clear();
        });
        debugPrint('🐛 DEBUG: After setState (no items):');
        debugPrint(
            '🐛 DEBUG: _shouldShowLowStockButton = $_shouldShowLowStockButton');
      }
    } catch (e) {
      debugPrint('💥 Error checking low stock items: $e');
      debugPrint('📍 Stack trace: ${StackTrace.current}');
      setState(() {
        _hasCheckedLowStock = true;
        _shouldShowLowStockButton = false;
        _lowStockItems.clear();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingLowStock = false;
        });
        debugPrint('🐛 DEBUG: Final state:');
        debugPrint('🐛 DEBUG: _isSupplierMode = $_isSupplierMode');
        debugPrint(
            '🐛 DEBUG: _shouldShowLowStockButton = $_shouldShowLowStockButton');
        debugPrint(
            '🐛 DEBUG: _lowStockItems.length = ${_lowStockItems.length}');
      }
    }
  }

  // NEW: Show low stock notification - Enhanced to not use onTap callback
  Future<void> _showLowStockNotification(List<LowStockItem> items) async {
    try {
      final message = LowStockService.getNotificationMessage(items);
      final hasCritical = LowStockService.hasCriticalItems(items);
      final l10n =
          Localizations.of<AppLocalizations>(context, AppLocalizations)!;

      final notification = NotificationItem(
        id: 'low_stock_${DateTime.now().millisecondsSinceEpoch}',
        title: hasCritical ? l10n.criticalStockAlert : l10n.lowStockAlert,
        message: message,
        timeAgo: l10n.justNow,
        isRead: false,
        icon: hasCritical ? Icons.error : Icons.warning_amber_rounded,
        iconBackgroundColor: hasCritical ? Colors.red : Colors.orange,
        // Don't set onTap here - it will be handled by notification type detection
      );

      // Add to notification service with special type
      await NotificationService().saveLowStockNotification(notification);

      debugPrint('Added low stock notification: ${notification.title}');
    } catch (e) {
      debugPrint('Error showing low stock notification: $e');
    }
  }

  // NEW: Show low stock popup
  void _showLowStockPopupDialog() {
    if (_lowStockItems.isNotEmpty) {
      showLowStockPopup(
        context,
        _lowStockItems,
        onOrdersGenerated: () {
          // Refresh orders when new orders are generated
          _fetchOrders();
          // Reset low stock check so it can check again next time
          setState(() {
            _hasCheckedLowStock = false;
            _lowStockItems.clear();
            _shouldShowLowStockButton = false;
          });
          // Re-check for low stock
          _checkLowStockItems();
        },
      );
    }
  }

  // Fetch orders from the API
  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get auth headers
      final headers = await AuthService.getAuthHeaders();

      // Fetch supplier orders
      final supplierResponse = await http.get(
        Uri.parse('https://finalproject-a5ls.onrender.com/supplierOrders/'),
        headers: headers,
      );

      // Fetch customer orders
      final customerResponse = await http.get(
        Uri.parse('https://finalproject-a5ls.onrender.com/customer-order/'),
        headers: headers,
      );

      // Process supplier orders
      if (supplierResponse.statusCode == 200) {
        final data = json.decode(supplierResponse.body);

        if (data['message'] == 'Orders retrieved successfully') {
          final List<dynamic> ordersJson = data['orders'];

          setState(() {
            _supplierOrders = ordersJson
                .map((orderJson) => OrderItem.fromJson(orderJson))
                .toList();
          });
        } else {
          debugPrint('Failed to load supplier orders: ${data['message']}');
        }
      } else {
        debugPrint(
            'Failed to load supplier orders. Status code: ${supplierResponse.statusCode}');
      }

      // Process customer orders - FIX THE JSON PARSING HERE
      if (customerResponse.statusCode == 200) {
        final data = json.decode(customerResponse.body);

        // Check if data is a map with 'orders' key or directly a list
        if (data is Map && data.containsKey('orders')) {
          // If it's a map with 'orders' key
          final List<dynamic> ordersJson = data['orders'];
          setState(() {
            _customerOrders = ordersJson
                .map((orderJson) => OrderItem.fromCustomerJson(orderJson))
                .toList();
          });
        } else if (data is List) {
          // If it's directly a list
          setState(() {
            _customerOrders = (data as List)
                .map((orderJson) => OrderItem.fromCustomerJson(orderJson))
                .toList();
          });
        } else {
          // If it's neither a list nor a map with 'orders' key
          final l10n =
              Localizations.of<AppLocalizations>(context, AppLocalizations)!;
          setState(() {
            _errorMessage = l10n.unexpectedCustomerOrdersFormat;
          });
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        debugPrint(
            'Failed to load customer orders. Status code: ${customerResponse.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      final l10n =
          Localizations.of<AppLocalizations>(context, AppLocalizations)!;
      setState(() {
        _errorMessage = '${l10n.errorFetchingOrders}: $e';
        _isLoading = false;
      });
    }
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

  // Get the active orders list based on mode
  List<OrderItem> get _activeOrdersList {
    return _isSupplierMode ? _supplierOrders : _customerOrders;
  }

  // NEW: Updated active count to consider the selected active status
  int get activeCount {
    if (_isSupplierMode) {
      return _supplierOrders
          .where((o) =>
              o.status == "Accepted" ||
              o.status == "Pending" ||
              o.status == "Prepared" ||
              o.status == "on_theway")
          .length;
    } else {
      // For customer orders, if a specific active status is selected, count only those
      if (_selectedActiveStatus != null) {
        return _customerOrders
            .where((o) => o.status == _selectedActiveStatus)
            .length;
      }
      // Otherwise count all active statuses
      return _customerOrders
          .where((o) =>
              o.status == "Accepted" ||
              o.status == "Assigned" ||
              o.status == "Preparing" ||
              o.status == "Prepared" ||
              o.status == "on_theway")
          .length;
    }
  }

  // Compute counts based on orders list with new status mappings
  int get totalOrdersCount => _activeOrdersList.length;

  int get completedCount => _activeOrdersList
      .where((o) => o.status == "Delivered" || o.status == "Shipped")
      .length;

  int get cancelledCount => _activeOrdersList
      .where((o) => o.status == "Declined" || o.status == "Rejected")
      .length;

  // Build card data dynamically.
  List<_OrderCardData> _buildOrdersData(AppLocalizations l10n) {
    return [
      _OrderCardData(
        svgIconPath: 'assets/images/totalorders.svg',
        title: l10n.totalOrders,
        count: totalOrdersCount.toString(),
        percentage: 1.0, // Always full for Total Orders.
        circleColor: const Color.fromARGB(255, 0, 196, 255), // cyan
        hasDropdown: false,
      ),
      _OrderCardData(
        svgIconPath: 'assets/images/Activeorders.svg',
        title: l10n.activeOrders,
        count: activeCount.toString(),
        percentage: totalOrdersCount > 0 ? activeCount / totalOrdersCount : 0.0,
        circleColor: const Color.fromARGB(255, 255, 232, 29), // yellow
        hasDropdown: !_isSupplierMode, // Only show dropdown for customer mode
      ),
      _OrderCardData(
        svgIconPath: 'assets/images/completedOrders.svg',
        title: l10n.completedOrders,
        count: completedCount.toString(),
        percentage:
            totalOrdersCount > 0 ? completedCount / totalOrdersCount : 0.0,
        circleColor: const Color.fromARGB(255, 0, 224, 116), // green
        hasDropdown: false,
      ),
      _OrderCardData(
        svgIconPath: 'assets/images/cancorders.svg',
        title: l10n.cancelledOrders,
        count: cancelledCount.toString(),
        percentage:
            totalOrdersCount > 0 ? cancelledCount / totalOrdersCount : 0.0,
        circleColor: const Color.fromARGB(255, 255, 62, 142), // pink
        hasDropdown: false,
      ),
    ];
  }

  // When a card is tapped update the filter with the new status mappings.
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

  // NEW: Handle active status dropdown selection
  void _onActiveStatusSelected(String? status) {
    setState(() {
      _selectedActiveStatus = status;
    });
  }

  // NEW: Show assign orders popup
  void _showAssignOrdersPopup() async {
    final shouldRefresh =
        await showAssignOrderPopup(context, existingOrders: _customerOrders);
    if (shouldRefresh == true) {
      _fetchOrders(); // Refresh orders after assignment
    }
  }

  // Toggle between supplier and customer mode
  void _toggleOrderMode(bool isSupplier) {
    if (isSupplier != _isSupplierMode) {
      setState(() {
        _isSupplierMode = isSupplier;
        _selectedActiveStatus =
            null; // Reset active status filter when switching modes
      });
    }
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
        // Current Orders screen - no navigation needed
        break;
      case 4:
        Navigator.pushNamed(context, '/admin/roles');
        break;
      case 5:
        Navigator.pushNamed(context, '/admin/tracking');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Localization setup
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

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
          padding: EdgeInsets.only(
            left: isRtl ? 45.w : 45.w,
            top: 20.h,
            right: isRtl ? 45.w : 45.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top header row with added filter
              Row(
                children: [
                  Text(
                    _isSupplierMode ? l10n.supplierOrders : l10n.customerOrders,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 35.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
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
                                l10n.suppliers,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      )
                                    : GoogleFonts.spaceGrotesk(
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
                                l10n.customers,
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      )
                                    : GoogleFonts.spaceGrotesk(
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
                      onPressed: () async {
                        // Show the popup and wait for the result
                        final shouldRefresh =
                            await showSupplierOrderPopup(context);

                        // If orders were placed, refresh the orders list
                        if (shouldRefresh) {
                          _fetchOrders(); // Refresh orders list immediately
                        }
                      },
                      child: Text(
                        l10n.orderFromSupplier,
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )
                            : GoogleFonts.spaceGrotesk(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                      ),
                    ),

                  // Show "Customer Orders History" button only in customer mode
                  if (!_isSupplierMode)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 150, 136),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        fixedSize: Size(250.w, 50.h),
                        elevation: 1,
                      ),
                      onPressed: () async {
                        // Show the customer history popup
                        await showCustomerHistoryPopup(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            l10n.customerHistory,
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                    ),

                  // NEW: Low Stock Alert Button - Fixed condition
                  if (_isSupplierMode && _shouldShowLowStockButton) ...[
                    SizedBox(width: 16.w),
                    Builder(
                      builder: (context) {
                        debugPrint(
                            '🐛 BUILD DEBUG: Low stock button is being built!');
                        debugPrint(
                            '🐛 BUILD DEBUG: _lowStockItems.length = ${_lowStockItems.length}');
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                LowStockService.hasCriticalItems(_lowStockItems)
                                    ? Colors.red
                                    : Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            fixedSize: Size(195.w, 50.h),
                            elevation: 1,
                          ),
                          onPressed: () {
                            debugPrint('🔔 Low stock button pressed!');
                            _showLowStockPopupDialog();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LowStockService.hasCriticalItems(_lowStockItems)
                                    ? Icons.error
                                    : Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '${l10n.lowStock} (${_lowStockItems.length})',
                                style: isArabic
                                    ? GoogleFonts.cairo(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      )
                                    : GoogleFonts.spaceGrotesk(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  // Add refresh button
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                    onPressed: () {
                      _fetchOrders();
                      // Also recheck low stock when refreshing
                      setState(() {
                        _hasCheckedLowStock = false;
                        _shouldShowLowStockButton = false;
                      });
                      _checkLowStockItems();
                    },
                  ),
                ],
              ),
              SizedBox(height: 40.h),

              // NEW: Show low stock checking indicator
              if (_isCheckingLowStock)
                Container(
                  margin: EdgeInsets.only(bottom: 20.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 36, 50, 69),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          color: Colors.orange,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        l10n.checkingLowStockItems,
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 14.sp,
                                color: Colors.white70,
                              )
                            : GoogleFonts.spaceGrotesk(
                                fontSize: 14.sp,
                                color: Colors.white70,
                              ),
                      ),
                    ],
                  ),
                ),

              // Filter Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  const numberOfCards = 4;
                  const spacing = 40.0;
                  final cardWidth =
                      (availableWidth - ((numberOfCards - 1) * spacing)) /
                          numberOfCards;
                  final ordersData = _buildOrdersData(l10n);
                  return Wrap(
                    spacing: spacing,
                    runSpacing: 20,
                    children: List.generate(ordersData.length, (index) {
                      final bool isSelected = (_selectedCardIndex == index);
                      final data = ordersData[index];
                      return GestureDetector(
                        onTap: () => _onCardTap(index),
                        child: SizedBox(
                          width: cardWidth,
                          child: Stack(
                            children: [
                              OrdersCard(
                                svgIconPath: data.svgIconPath,
                                title: data.title,
                                count: data.count,
                                percentage: data.percentage,
                                circleColor: data.circleColor,
                                isSelected: isSelected,
                              ),
                              // NEW: Add dropdown for Active Orders card in customer mode
                              if (data.hasDropdown && index == 1 && isSelected)
                                Positioned(
                                  top: 55.h,
                                  right: isRtl ? null : 12.w,
                                  left: isRtl ? 12.w : null,
                                  child: Container(
                                    width: 140.w,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color.fromARGB(255, 60, 75, 95),
                                          const Color.fromARGB(255, 45, 60, 80),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                                255, 105, 65, 198)
                                            .withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        canvasColor: const Color.fromARGB(
                                            255, 45, 60, 80),
                                        // Remove all splash and highlight effects
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedActiveStatus,
                                          hint: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical: 8.h),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.filter_list_rounded,
                                                  color: Colors.white70,
                                                  size: 16.sp,
                                                ),
                                                SizedBox(width: 6.w),
                                                Text(
                                                  l10n.allStatus,
                                                  style: isArabic
                                                      ? GoogleFonts.cairo(
                                                          fontSize: 12.sp,
                                                          color: Colors.white70,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        )
                                                      : GoogleFonts
                                                          .spaceGrotesk(
                                                          fontSize: 12.sp,
                                                          color: Colors.white70,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          selectedItemBuilder:
                                              (BuildContext context) {
                                            return [
                                              null, // for the "All" option
                                              ..._activeStatusOptions,
                                            ].map<Widget>((String? status) {
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 12.w,
                                                    vertical: 8.h),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.filter_list_rounded,
                                                      color:
                                                          const Color.fromARGB(
                                                              255,
                                                              105,
                                                              65,
                                                              198),
                                                      size: 16.sp,
                                                    ),
                                                    SizedBox(width: 6.w),
                                                    Flexible(
                                                      child: Text(
                                                        status == null
                                                            ? l10n.allStatus
                                                            : _getStatusDisplayName(
                                                                status, l10n),
                                                        style: isArabic
                                                            ? GoogleFonts.cairo(
                                                                fontSize: 12.sp,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              )
                                                            : GoogleFonts
                                                                .spaceGrotesk(
                                                                fontSize: 12.sp,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList();
                                          },
                                          dropdownColor: const Color.fromARGB(
                                              255, 45, 60, 80),
                                          style: isArabic
                                              ? GoogleFonts.cairo(
                                                  fontSize: 12.sp,
                                                  color: Colors.white,
                                                )
                                              : GoogleFonts.spaceGrotesk(
                                                  fontSize: 12.sp,
                                                  color: Colors.white,
                                                ),
                                          icon: Padding(
                                            padding:
                                                EdgeInsets.only(right: 8.w),
                                            child: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Colors.white70,
                                              size: 20.sp,
                                            ),
                                          ),
                                          isExpanded: true,
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                          elevation: 8,
                                          // Remove dropdown button splash effects
                                          focusColor: Colors.transparent,
                                          items: [
                                            DropdownMenuItem<String>(
                                              value: null,
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  // Remove all splash effects
                                                  splashColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  hoverColor:
                                                      Colors.transparent,
                                                  focusColor:
                                                      Colors.transparent,
                                                  overlayColor:
                                                      MaterialStateProperty.all(
                                                          Colors.transparent),
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 12.w,
                                                            vertical: 10.h),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.r),
                                                      color:
                                                          _selectedActiveStatus ==
                                                                  null
                                                              ? const Color
                                                                      .fromARGB(
                                                                      255,
                                                                      105,
                                                                      65,
                                                                      198)
                                                                  .withOpacity(
                                                                      0.1)
                                                              : Colors
                                                                  .transparent,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .all_inclusive_rounded,
                                                          color:
                                                              _selectedActiveStatus ==
                                                                      null
                                                                  ? const Color
                                                                      .fromARGB(
                                                                      255,
                                                                      105,
                                                                      65,
                                                                      198)
                                                                  : Colors
                                                                      .white70,
                                                          size: 16.sp,
                                                        ),
                                                        SizedBox(width: 8.w),
                                                        Text(
                                                          l10n.allStatus,
                                                          style: isArabic
                                                              ? GoogleFonts
                                                                  .cairo(
                                                                  fontSize:
                                                                      12.sp,
                                                                  color: _selectedActiveStatus ==
                                                                          null
                                                                      ? const Color
                                                                          .fromARGB(
                                                                          255,
                                                                          105,
                                                                          65,
                                                                          198)
                                                                      : Colors
                                                                          .white,
                                                                  fontWeight: _selectedActiveStatus == null
                                                                      ? FontWeight
                                                                          .w600
                                                                      : FontWeight
                                                                          .w500,
                                                                )
                                                              : GoogleFonts
                                                                  .spaceGrotesk(
                                                                  fontSize:
                                                                      12.sp,
                                                                  color: _selectedActiveStatus ==
                                                                          null
                                                                      ? const Color
                                                                          .fromARGB(
                                                                          255,
                                                                          105,
                                                                          65,
                                                                          198)
                                                                      : Colors
                                                                          .white,
                                                                  fontWeight: _selectedActiveStatus == null
                                                                      ? FontWeight
                                                                          .w600
                                                                      : FontWeight
                                                                          .w500,
                                                                ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            ..._activeStatusOptions
                                                .map((String status) {
                                              final isSelected =
                                                  _selectedActiveStatus ==
                                                      status;
                                              return DropdownMenuItem<String>(
                                                value: status,
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    // Remove all splash effects
                                                    splashColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    hoverColor:
                                                        Colors.transparent,
                                                    focusColor:
                                                        Colors.transparent,
                                                    overlayColor:
                                                        MaterialStateProperty
                                                            .all(Colors
                                                                .transparent),
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 12.w,
                                                              vertical: 10.h),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.r),
                                                        color: isSelected
                                                            ? const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    105,
                                                                    65,
                                                                    198)
                                                                .withOpacity(
                                                                    0.1)
                                                            : Colors
                                                                .transparent,
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 8.w,
                                                            height: 8.h,
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color:
                                                                  _getStatusColor(
                                                                      status),
                                                            ),
                                                          ),
                                                          SizedBox(width: 8.w),
                                                          Flexible(
                                                            child: Text(
                                                              _getStatusDisplayName(
                                                                  status, l10n),
                                                              style: isArabic
                                                                  ? GoogleFonts
                                                                      .cairo(
                                                                      fontSize:
                                                                          12.sp,
                                                                      color: isSelected
                                                                          ? const Color
                                                                              .fromARGB(
                                                                              255,
                                                                              105,
                                                                              65,
                                                                              198)
                                                                          : Colors
                                                                              .white,
                                                                      fontWeight: isSelected
                                                                          ? FontWeight
                                                                              .w600
                                                                          : FontWeight
                                                                              .w500,
                                                                    )
                                                                  : GoogleFonts
                                                                      .spaceGrotesk(
                                                                      fontSize:
                                                                          12.sp,
                                                                      color: isSelected
                                                                          ? const Color
                                                                              .fromARGB(
                                                                              255,
                                                                              105,
                                                                              65,
                                                                              198)
                                                                          : Colors
                                                                              .white,
                                                                      fontWeight: isSelected
                                                                          ? FontWeight
                                                                              .w600
                                                                          : FontWeight
                                                                              .w500,
                                                                    ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                          onChanged: _onActiveStatusSelected,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
                        ? l10n.allOrders
                        : _selectedFilter == "Active"
                            ? l10n.activeOrders
                            : _selectedFilter == "Completed"
                                ? l10n.completedOrders
                                : l10n.cancelledOrders,
                    style: isArabic
                        ? GoogleFonts.cairo(
                            fontSize: 30.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )
                        : GoogleFonts.spaceGrotesk(
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

                  // NEW: Show Assign button when in customer mode, Active filter, and Prepared status
                  if (!_isSupplierMode &&
                      _selectedFilter == "Active" &&
                      _selectedActiveStatus == "Prepared") ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 150, 136),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        fixedSize: Size(120.w, 50.h),
                        elevation: 1,
                      ),
                      onPressed: _showAssignOrdersPopup,
                      child: Text(
                        l10n.assign,
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )
                            : GoogleFonts.spaceGrotesk(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                  ],

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
                            style: isArabic
                                ? GoogleFonts.cairo(
                                    color: Colors.white,
                                  )
                                : GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                  ),
                            decoration: InputDecoration(
                              hintText: l10n.searchId,
                              hintStyle: isArabic
                                  ? GoogleFonts.cairo(
                                      color: Colors.white70,
                                    )
                                  : GoogleFonts.spaceGrotesk(
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

              // Loading indicator or error message
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(
                    color: const Color.fromARGB(255, 105, 65, 198),
                  ),
                )
              else if (_errorMessage != null)
                Center(
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
                        style: isArabic
                            ? GoogleFonts.cairo(
                                fontSize: 16.sp,
                                color: Colors.white,
                              )
                            : GoogleFonts.spaceGrotesk(
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
                          l10n.retry,
                          style: isArabic
                              ? GoogleFonts.cairo(
                                  color: Colors.white,
                                )
                              : GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Modified Order table: pass mode, orders list, filter, search query, and active status
                Ordertable(
                  orders: _activeOrdersList,
                  filter: _selectedFilter,
                  searchQuery: _searchQuery,
                  isSupplierMode: _isSupplierMode,
                  selectedActiveStatus: _selectedActiveStatus, // NEW parameter
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
  final bool hasDropdown; // NEW property

  const _OrderCardData({
    required this.svgIconPath,
    required this.title,
    required this.count,
    required this.percentage,
    required this.circleColor,
    this.hasDropdown = false,
  });
}

// Helper function to convert status values to display names
String _getStatusDisplayName(String status, AppLocalizations l10n) {
  switch (status) {
    case 'Accepted':
      return l10n.statusAccepted;
    case 'Assigned':
      return l10n.statusAssigned;
    case 'Preparing':
      return l10n.statusPreparing;
    case 'Prepared':
      return l10n.statusPrepared;
    case 'on_theway':
      return l10n.statusOnTheWay;
    default:
      return status;
  }
}

// Helper function to get status indicator colors
Color _getStatusColor(String status) {
  switch (status) {
    case 'Accepted':
      return Colors.blue;
    case 'Assigned':
      return Colors.cyan;
    case 'Preparing':
      return Colors.orange;
    case 'Prepared':
      return Colors.green;
    case 'on_theway':
      return Colors.purple;
    default:
      return Colors.grey;
  }
}
