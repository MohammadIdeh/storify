import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/GeneralWidgets/profilePopUp.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/utilis/notificationPopUpAdmin.dart';

class MyNavigationBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? profilePictureUrl; // Add this parameter

  const MyNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.profilePictureUrl, // Initialize it as optional
  }) : super(key: key);

  @override
  State<MyNavigationBar> createState() => _MyNavigationBarState();
}

OverlayEntry? _notificationOverlayEntry;
bool _isNotificationMenuOpen = false;
List<NotificationItem> _notifications =
    []; // This will store your notifications

class _MyNavigationBarState extends State<MyNavigationBar> {
  // (Optional) Key for the profile section
  final GlobalKey _profileKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;

  void _toggleProfileMenu() {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
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
              // Search
              InkWell(
                onTap: () {
                  // Handle search
                },
                child: Container(
                  width: 50.w,
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 36, 50, 69),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(13.0),
                    child: SvgPicture.asset('assets/images/search.svg'),
                  ),
                ),
              ),
              SizedBox(width: 14.w),

              // Notifications
              InkWell(
                onTap: _toggleNotificationMenu,
                child: Container(
                  width: 50.w,
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 36, 50, 69),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: SvgPicture.asset(
                          'assets/images/noti.svg',
                          width: 20.w,
                          height: 20.h,
                          color: _isNotificationMenuOpen
                              ? const Color.fromARGB(255, 105, 65, 198)
                              : const Color.fromARGB(255, 105, 123, 123),
                        ),
                      ),
                      if (_notifications.where((n) => !n.isRead).isNotEmpty)
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
    final List<String> navItems = [
      'Dashboard',
      'Products',
      'Category',
      'Orders',
      "Role Managment",
      'Tracking',
    ];

    final List<String?> navIcons = [
      'assets/images/home.svg',
      'assets/images/products.svg',
      'assets/images/category.svg',
      'assets/images/orders.svg',
      'assets/images/Managment.svg',
      'assets/images/map.svg',
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
}
