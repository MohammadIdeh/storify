// lib/customer/widgets/navbarCus.dart
// Enhanced version with notification integration
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/GeneralWidgets/profilePopUp.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/GeneralWidgets/NotificationPopup.dart';
import 'package:storify/utilis/notification_service.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/services/user_profile_service.dart';
import 'package:storify/customer/widgets/CustomerOrderService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationBarCustomer extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? profilePictureUrl;

  const NavigationBarCustomer({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.profilePictureUrl,
  });

  @override
  State<NavigationBarCustomer> createState() => _NavigationBarCustomerState();
}

class _NavigationBarCustomerState extends State<NavigationBarCustomer> {
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;
  bool _isDisposed = false;

  // Notification variables
  OverlayEntry? _notificationOverlayEntry;
  bool _isNotificationMenuOpen = false;
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;

  // Customer notification initialization
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use post frame callback to avoid initState issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCustomerNotifications();
      _loadNotifications();
      _setupNotificationCallbacks();
    });
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing NavigationBarCustomer...');
    _isDisposed = true;
    _unregisterNotificationCallbacks();
    _removeAllOverlays();
    super.dispose();
  }

  // Initialize customer-specific notifications
  Future<void> _initializeCustomerNotifications() async {
    if (_notificationsInitialized) return;

    try {
      debugPrint('🔔 Initializing customer notifications...');

      // Initialize the notification service
      await CustomerOrderService.initializeCustomerNotifications();

      // Register customer-specific handlers
      NotificationService().registerCustomerNotificationHandler((notification) {
        debugPrint('🛒 Customer notification received: ${notification.title}');
        _handleCustomerNotification(notification);
      });

      // Register order status update handler
      NotificationService().registerOrderStatusUpdateHandler((orderId) {
        debugPrint('📦 Order status update for order: $orderId');
        _handleOrderStatusUpdate(orderId);
      });

      // Register low stock notification handler
      NotificationService().registerLowStockNotificationHandler(() {
        debugPrint('📦 Low stock notification - navigating to orders');
        _handleLowStockNotification();
      });

      _notificationsInitialized = true;
      debugPrint('✅ Customer notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing customer notifications: $e');
    }
  }

  // Handle customer-specific notifications
  void _handleCustomerNotification(NotificationItem notification) {
    if (!mounted || _isDisposed) return;

    // Update UI immediately
    setState(() {
      _unreadCount = NotificationService().getUnreadCount();
    });

    // Show toast notification for important events
    if (notification.type?.contains('order') == true) {
      _showToastNotification(notification);
    }
  }

  // Handle order status updates
  void _handleOrderStatusUpdate(String orderId) {
    if (!mounted || _isDisposed) return;

    debugPrint('📦 Handling order status update for order: $orderId');

    // Could navigate to order history or show specific order details
    // For now, just refresh the notification count
    setState(() {
      _unreadCount = NotificationService().getUnreadCount();
    });
  }

  // Handle low stock notifications
  void _handleLowStockNotification() {
    if (!mounted || _isDisposed) return;

    debugPrint('📦 Handling low stock notification');

    // Navigate to orders screen where customer can see available products
    if (widget.currentIndex != 0) {
      widget.onTap(0); // Navigate to orders screen
    }

    // Show a brief message
    _showLowStockMessage();
  }

  // Show toast notification for important events
  void _showToastNotification(NotificationItem notification) {
    if (!mounted || _isDisposed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              notification.icon ?? Icons.notifications,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    notification.message,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor:
            notification.iconBackgroundColor ?? const Color(0xFF7B5CFA),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            _toggleNotificationMenu();
          },
        ),
      ),
    );
  }

  // Show low stock message
  void _showLowStockMessage() {
    if (!mounted || _isDisposed) return;

    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.inventory_2, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Some items are running low in stock. Check available products!',
                style:
                    isArabic ? GoogleFonts.cairo() : GoogleFonts.spaceGrotesk(),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Setup notification callbacks
  void _setupNotificationCallbacks() {
    NotificationService()
        .registerNotificationsListChangedCallback(_onNotificationsChanged);
    NotificationService().registerNewNotificationCallback(_onNewNotification);
  }

  // Unregister notification callbacks
  void _unregisterNotificationCallbacks() {
    NotificationService()
        .unregisterNotificationsListChangedCallback(_onNotificationsChanged);
    NotificationService().unregisterNewNotificationCallback(_onNewNotification);
    NotificationService().unregisterCustomerNotificationHandler();
    NotificationService().unregisterOrderStatusUpdateHandler();
    NotificationService().unregisterLowStockNotificationHandler();
  }

  void _removeAllOverlays() {
    try {
      if (_overlayEntry != null) {
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
      if (_notificationOverlayEntry != null) {
        _notificationOverlayEntry!.remove();
        _notificationOverlayEntry = null;
      }
    } catch (e) {
      debugPrint('⚠️ Error removing overlays: $e');
    }
  }

  void _loadNotifications() {
    if (mounted) {
      _notifications = NotificationService().getNotifications();
      _unreadCount = NotificationService().getUnreadCount();
      setState(() {});
    }
  }

  void _onNotificationsChanged(List<NotificationItem> notifications) {
    if (mounted && !_isDisposed) {
      setState(() {
        _notifications = notifications;
        _unreadCount = NotificationService().getUnreadCount();
      });
    }
  }

  void _onNewNotification(NotificationItem notification) {
    if (mounted && !_isDisposed) {
      setState(() {
        _notifications = NotificationService().getNotifications();
        _unreadCount = NotificationService().getUnreadCount();
      });

      // Show toast for new notifications
      _showToastNotification(notification);
    }
  }

  void _toggleProfileMenu() {
    if (_isDisposed) return;

    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (_isDisposed) return;

    if (_isNotificationMenuOpen) {
      _closeNotificationMenu();
    }

    final isRtl = LocalizationHelper.isRTL(context);

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeMenu,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
            PositionedDirectional(
              end: 40,
              top: 100,
              child: Material(
                color: Colors.transparent,
                child: Profilepopup(
                  onCloseMenu: _closeMenu,
                  onLogout: _handleCompleteLogout,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (mounted && !_isDisposed) {
      Overlay.of(context).insert(_overlayEntry!);
      setState(() {
        _isMenuOpen = true;
      });
    }
  }

  void _closeMenu() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (e) {
        debugPrint('⚠️ Error removing overlay: $e');
      }
      _overlayEntry = null;
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _isMenuOpen = false;
      });
    }
  }

  // Simplified logout for customer
  Future<void> _handleCompleteLogout() async {
    debugPrint('🚪 === CLEAN CUSTOMER LOGOUT ===');

    try {
      _removeAllOverlays();
      _unregisterNotificationCallbacks();
      _isDisposed = true;

      await AuthService.logoutFromAllRoles();
      await UserProfileService.clearAllRoleData();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      debugPrint('✅ Customer data cleared');

      // ✅ CLEAN NAVIGATION: Clear all history including customer screens
      if (mounted && context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false, // Remove ALL previous routes
        );
        debugPrint('✅ Customer logout navigation completed');
      }
    } catch (e) {
      debugPrint('❌ Error during customer logout: $e');

      if (mounted && context.mounted) {
        try {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false, // Clear history even in emergency
          );
        } catch (navError) {
          debugPrint('💥 Emergency navigation failed: $navError');
        }
      }
    }
  }

  void _toggleNotificationMenu() {
    if (_isDisposed) return;

    if (_isNotificationMenuOpen) {
      _closeNotificationMenu();
    } else {
      _openNotificationMenu();
    }
  }

  void _openNotificationMenu() {
    if (_isDisposed) return;

    if (_isMenuOpen) {
      _closeMenu();
    }

    final isRtl = LocalizationHelper.isRTL(context);

    _notificationOverlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeNotificationMenu,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
            PositionedDirectional(
              end: 100,
              top: 100,
              child: Material(
                color: Colors.transparent,
                child: NotificationPopup(
                  onCloseMenu: _closeNotificationMenu,
                  notifications: _notifications,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (mounted && !_isDisposed) {
      Overlay.of(context).insert(_notificationOverlayEntry!);
      setState(() {
        _isNotificationMenuOpen = true;
      });
    }
  }

  void _closeNotificationMenu() {
    if (_notificationOverlayEntry != null) {
      try {
        _notificationOverlayEntry!.remove();
      } catch (e) {
        debugPrint('⚠️ Error removing notification overlay: $e');
      }
      _notificationOverlayEntry = null;
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _isNotificationMenuOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);
    final isRtl = LocalizationHelper.isRTL(context);

    if (_isDisposed) {
      return Container(
        height: 90.h,
        color: const Color.fromARGB(255, 29, 41, 57),
        child: Center(
          child: CircularProgressIndicator(
            color: const Color.fromARGB(255, 105, 65, 198),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        margin: EdgeInsets.only(top: 10.h),
        width: double.infinity,
        height: 90.h,
        color: const Color.fromARGB(255, 29, 41, 57),
        padding: EdgeInsetsDirectional.only(start: 45, end: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Logo + Title
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 35.w,
                  height: 35.h,
                ),
                SizedBox(width: 12.w),
                Text(
                  l10n.navbarAppName,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                ),
              ],
            ),

            // Middle: Navigation Items
            Row(
              children: _buildNavItems(),
            ),

            // Right side: Notifications and Profile
            Row(
              children: [
                // Notifications with enhanced indicator
                InkWell(
                  onTap: _isDisposed ? null : _toggleNotificationMenu,
                  child: Container(
                    width: 52.w,
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 36, 50, 69),
                      borderRadius: BorderRadius.circular(16),
                      border: _isNotificationMenuOpen
                          ? Border.all(
                              color: const Color.fromARGB(255, 105, 65, 198),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/noti.svg',
                            color: _isNotificationMenuOpen
                                ? const Color.fromARGB(255, 105, 65, 198)
                                : const Color.fromARGB(255, 105, 123, 123),
                          ),
                        ),
                        if (_unreadCount > 0)
                          PositionedDirectional(
                            top: 8,
                            end: 8,
                            child: Container(
                              width: _unreadCount > 9 ? 18.w : 12.w,
                              height: 12.h,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: _unreadCount > 9
                                  ? Center(
                                      child: Text(
                                        '9+',
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        _unreadCount.toString(),
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white,
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 14.w),

                // Profile + Arrow
                InkWell(
                  onTap: _isDisposed ? null : _toggleProfileMenu,
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: _isMenuOpen
                              ? Border.all(
                                  color:
                                      const Color.fromARGB(255, 105, 65, 198),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: widget.profilePictureUrl != null &&
                                  widget.profilePictureUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.profilePictureUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color:
                                        const Color.fromARGB(255, 36, 50, 69),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: const Color.fromARGB(
                                              255, 105, 65, 198),
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    debugPrint(
                                        'Error loading profile image: $error from URL: $url');
                                    return Image.asset('assets/images/me.png',
                                        fit: BoxFit.cover);
                                  },
                                )
                              : Image.asset('assets/images/me.png',
                                  fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _isMenuOpen
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        size: 35,
                        color: _isMenuOpen
                            ? const Color.fromARGB(255, 105, 65, 198)
                            : const Color.fromARGB(255, 105, 123, 123),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNavItems() {
    if (_isDisposed) return [];

    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    final List<String> navItems = [
      l10n.navbarOrders,
      l10n.navbarHistory,
    ];
    final List<String?> navIcons = [
      'assets/images/orders.svg',
      'assets/images/history.svg'
    ];

    return navItems.asMap().entries.map((entry) {
      final index = entry.key;
      final text = entry.value;
      final bool isSelected = (index == widget.currentIndex);

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _isDisposed ? null : () => widget.onTap(index),
          child: Container(
            margin: EdgeInsetsDirectional.only(start: 24.w),
            padding: EdgeInsetsDirectional.symmetric(
                horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color.fromARGB(255, 105, 65, 198)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : const Color.fromARGB(255, 34, 53, 62),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Row(
              children: [
                if (navIcons[index] != null && navIcons[index]!.isNotEmpty)
                  SvgPicture.asset(
                    navIcons[index]!,
                    width: 24.w,
                    height: 24.h,
                    // ignore: deprecated_member_use
                    color: isSelected
                        ? Colors.white
                        : const Color.fromARGB(255, 105, 123, 123),
                  ),
                if (navIcons[index] != null && navIcons[index]!.isNotEmpty)
                  SizedBox(width: 9.w),
                Text(
                  text,
                  style: isArabic
                      ? GoogleFonts.cairo(
                          fontSize: 15.sp,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : const Color.fromARGB(255, 105, 123, 123),
                        )
                      : GoogleFonts.spaceGrotesk(
                          fontSize: 15.sp,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : const Color.fromARGB(255, 105, 123, 123),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
