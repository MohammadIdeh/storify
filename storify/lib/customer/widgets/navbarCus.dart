// lib/customer/widgets/navbarCus.dart
// Fixed version with simplified logout and proper role separation
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/GeneralWidgets/profilePopUp.dart';
import 'package:storify/supplier/widgets/SupplierNotificationPopup.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/utilis/notification_service.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/services/user_profile_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    NotificationService()
        .registerNotificationsListChangedCallback(_onNotificationsChanged);
    NotificationService().registerNewNotificationCallback(_onNewNotification);
  }

  @override
  void dispose() {
    print('🧹 Disposing NavigationBarCustomer...');
    _isDisposed = true;
    NotificationService()
        .unregisterNotificationsListChangedCallback(_onNotificationsChanged);
    NotificationService().unregisterNewNotificationCallback(_onNewNotification);
    _removeAllOverlays();
    super.dispose();
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
      print('⚠️ Error removing overlays: $e');
    }
  }

  void _loadNotifications() {
    _notifications = NotificationService().getNotifications();
    _unreadCount = NotificationService().getUnreadCount();
    if (mounted) setState(() {});
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
            Positioned(
              right: 40,
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
        print('⚠️ Error removing overlay: $e');
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
    print('🚪 === CLEAN CUSTOMER LOGOUT ===');

    try {
      _removeAllOverlays();
      _isDisposed = true;

      await AuthService.logoutFromAllRoles();
      await UserProfileService.clearAllRoleData();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      print('✅ Customer data cleared');

      // ✅ CLEAN NAVIGATION: Clear all history including customer screens
      if (mounted && context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false, // Remove ALL previous routes
        );
        print('✅ Customer logout navigation completed');
      }
    } catch (e) {
      print('❌ Error during customer logout: $e');

      if (mounted && context.mounted) {
        try {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false, // Clear history even in emergency
          );
        } catch (navError) {
          print('💥 Emergency navigation failed: $navError');
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
            Positioned(
              right: 100,
              top: 100,
              child: Material(
                color: Colors.transparent,
                child: SupplierNotificationPopup(
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
        print('⚠️ Error removing notification overlay: $e');
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

    return Container(
      margin: EdgeInsets.only(top: 10.h),
      width: double.infinity,
      height: 90.h,
      color: const Color.fromARGB(255, 29, 41, 57),
      padding: EdgeInsets.only(left: 45, right: 30),
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
                'Storify',
                style: GoogleFonts.spaceGrotesk(
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
              // Notifications
              InkWell(
                onTap: _isDisposed ? null : _toggleNotificationMenu,
                child: Container(
                  width: 52.w,
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 36, 50, 69),
                    borderRadius: BorderRadius.circular(16),
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
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 10.w,
                            height: 10.h,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
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
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: widget.profilePictureUrl != null &&
                                widget.profilePictureUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.profilePictureUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: const Color.fromARGB(255, 36, 50, 69),
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
                                  print(
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
                      _isMenuOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      size: 35,
                      color: const Color.fromARGB(255, 105, 123, 123),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavItems() {
    if (_isDisposed) return [];

    final List<String> navItems = ['Orders', 'History'];
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
            margin: EdgeInsets.only(left: 24.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w700,
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
