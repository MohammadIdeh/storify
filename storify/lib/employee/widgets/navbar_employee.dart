// lib/supplier/widgets/navbar.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/GeneralWidgets/profilePopUp.dart';
import 'package:storify/supplier/widgets/SupplierNotificationPopup.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/utilis/notification_service.dart';

class NavigationBarEmployee extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? profilePictureUrl; // Add this parameter

  const NavigationBarEmployee({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.profilePictureUrl, // Initialize it as optional
  });

  @override
  State<NavigationBarEmployee> createState() => _NavigationBarEmployeeState();
}

class _NavigationBarEmployeeState extends State<NavigationBarEmployee> {
  // (Optional) Key for the profile section
  final GlobalKey _profileKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;

  // Notification variables
  OverlayEntry? _notificationOverlayEntry;
  bool _isNotificationMenuOpen = false;
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();

    // Load notifications
    _loadNotifications();

    // Register for notification updates
    NotificationService()
        .registerNotificationsListChangedCallback(_onNotificationsChanged);
    NotificationService().registerNewNotificationCallback(_onNewNotification);
  }

  @override
  void dispose() {
    // Unregister notification callbacks
    NotificationService()
        .unregisterNotificationsListChangedCallback(_onNotificationsChanged);
    NotificationService().unregisterNewNotificationCallback(_onNewNotification);
    super.dispose();
  }

  // Load notifications from service
  void _loadNotifications() {
    _notifications = NotificationService().getNotifications();
    _unreadCount = NotificationService().getUnreadCount();
    if (mounted) setState(() {});
  }

  // Callback for when notification list changes
  void _onNotificationsChanged(List<NotificationItem> notifications) {
    setState(() {
      _notifications = notifications;
      _unreadCount = NotificationService().getUnreadCount();
    });
  }

  // Callback for when a new notification arrives
  void _onNewNotification(NotificationItem notification) {
    setState(() {
      _notifications = NotificationService().getNotifications();
      _unreadCount = NotificationService().getUnreadCount();
    });
  }

  void _toggleProfileMenu() {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    // Close notification menu if open
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
                  onCloseMenu: _closeMenu, // Pass the close menu callback
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isMenuOpen = true;
    });
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isMenuOpen = false;
    });
  }

  void _toggleNotificationMenu() {
    if (_isNotificationMenuOpen) {
      _closeNotificationMenu();
    } else {
      _openNotificationMenu();
    }
  }

  void _openNotificationMenu() {
    // Close profile menu if open
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
              right: 100, // Adjust position as needed
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

    Overlay.of(context).insert(_notificationOverlayEntry!);
    setState(() {
      _isNotificationMenuOpen = true;
    });
  }

  void _closeNotificationMenu() {
    _notificationOverlayEntry?.remove();
    _notificationOverlayEntry = null;
    setState(() {
      _isNotificationMenuOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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

          // Right side: Search, Notifications, Profile
          Row(
            children: [
              // Notifications
              InkWell(
                onTap: _toggleNotificationMenu,
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
                key: _profileKey,
                onTap: _toggleProfileMenu,
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(25), // Make it circular
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

  /// Helper to build the middle navigation items
  List<Widget> _buildNavItems() {
    final List<String> navItems = ['Orders', 'History'];

    final List<String?> navIcons = [
      'assets/images/orders.svg',
      'assets/images/products.svg'
    ];

    return navItems.asMap().entries.map((entry) {
      final index = entry.key;
      final text = entry.value;
      final bool isSelected = (index == widget.currentIndex);

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => widget.onTap(index),
          child: Container(
            margin: EdgeInsets.only(left: 24.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color.fromARGB(255, 105, 65, 198) // Purple
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
