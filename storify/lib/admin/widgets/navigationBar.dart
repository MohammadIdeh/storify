import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/GeneralWidgets/profilePopUp.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/utilis/notificationPopUpAdmin.dart';

class MyNavigationBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? profilePictureUrl;

  const MyNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.profilePictureUrl,
  }) : super(key: key);

  @override
  State<MyNavigationBar> createState() => _MyNavigationBarState();
}

class _MyNavigationBarState extends State<MyNavigationBar> {
  // Instance variables to prevent conflicts
  OverlayEntry? _notificationOverlayEntry;
  bool _isNotificationMenuOpen = false;
  List<NotificationItem> _notifications = [];

  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;
  bool _isDisposing = false;
  bool _logoutInProgress = false; // New flag for logout state

  void _toggleProfileMenu() {
    if (_isDisposing || _logoutInProgress) return;

    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (_isDisposing || _logoutInProgress) return;

    // Ensure any existing overlay is closed first
    if (_overlayEntry != null) {
      _closeMenu();
      // Add a small delay to ensure cleanup
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && !_isMenuOpen && !_isDisposing && !_logoutInProgress) {
          _createAndShowOverlay();
        }
      });
    } else {
      _createAndShowOverlay();
    }
  }

  // CRITICAL: Completely isolated logout method
  Future<void> _handleLogout() async {
    if (_logoutInProgress || _isDisposing) return;

    print('🚪 === STARTING COMPLETE LOGOUT ISOLATION ===');

    try {
      // Step 1: Set all isolation flags immediately
      _logoutInProgress = true;
      _isDisposing = true;

      // Step 2: IMMEDIATELY remove all overlays without setState
      _forceRemoveAllOverlays();

      // Step 3: Clear all state flags directly (no setState)
      _isMenuOpen = false;
      _isNotificationMenuOpen = false;

      // Step 4: Prevent any further operations
      if (!mounted) return;

      print('🧹 All UI components isolated');

      // Step 5: Wait for UI to settle
      await Future.delayed(const Duration(milliseconds: 200));

      // Step 6: Perform data cleanup
      await AuthService.logoutFromAllRoles();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      print('✅ Data cleared');

      // Step 7: Navigate using the safest possible method
      if (mounted && context.mounted) {
        // Use pushNamedAndRemoveUntil for the cleanest navigation
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );

        // If named routes don't work, fallback to regular navigation
        if (!context.mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
            settings: const RouteSettings(name: '/login'),
          ),
          (route) => false,
        );
      }

      print('🔄 Navigation completed');
    } catch (e) {
      print('❌ Critical error in logout: $e');

      // Emergency fallback - force navigation no matter what
      try {
        if (mounted && context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (navError) {
        print('💥 Emergency navigation failed: $navError');
        // Last resort - restart the app
        _emergencyRestart();
      }
    }
  }

  // Emergency method to force app restart
  void _emergencyRestart() {
    print('🆘 EMERGENCY RESTART');
    // This will cause the app to restart
    runApp(MaterialApp(
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    ));
  }

  // Force remove overlays without setState
  void _forceRemoveAllOverlays() {
    try {
      if (_overlayEntry != null) {
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
    } catch (e) {
      print('⚠️ Error removing profile overlay: $e');
      _overlayEntry = null; // Force null even if removal failed
    }

    try {
      if (_notificationOverlayEntry != null) {
        _notificationOverlayEntry!.remove();
        _notificationOverlayEntry = null;
      }
    } catch (e) {
      print('⚠️ Error removing notification overlay: $e');
      _notificationOverlayEntry = null; // Force null even if removal failed
    }

    print('🧹 All overlays forcefully removed');
  }

  void _createAndShowOverlay() {
    if (_isDisposing || !mounted || _logoutInProgress) return;

    try {
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
                    onLogout: _handleLogout,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (mounted && context.mounted && !_isDisposing && !_logoutInProgress) {
        Overlay.of(context).insert(_overlayEntry!);
        if (mounted && !_logoutInProgress) {
          setState(() {
            _isMenuOpen = true;
          });
        }
      }
    } catch (e) {
      print('❌ Error creating overlay: $e');
      _overlayEntry = null;
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

    if (mounted && !_isDisposing && !_logoutInProgress) {
      setState(() {
        _isMenuOpen = false;
      });
    }
  }

  void _toggleNotificationMenu() {
    if (_isDisposing || _logoutInProgress) return;

    if (_isNotificationMenuOpen) {
      _closeNotificationMenu();
    } else {
      _openNotificationMenu();
    }
  }

  void _openNotificationMenu() {
    if (_isDisposing || _logoutInProgress) return;

    // Close profile menu if open
    if (_isMenuOpen) {
      _closeMenu();
    }

    try {
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

      if (mounted && context.mounted && !_isDisposing && !_logoutInProgress) {
        Overlay.of(context).insert(_notificationOverlayEntry!);
        if (mounted && !_logoutInProgress) {
          setState(() {
            _isNotificationMenuOpen = true;
          });
        }
      }
    } catch (e) {
      print('❌ Error creating notification overlay: $e');
      _notificationOverlayEntry = null;
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

    if (mounted && !_isDisposing && !_logoutInProgress) {
      setState(() {
        _isNotificationMenuOpen = false;
      });
    }
  }

  @override
  void dispose() {
    print('🧹 Disposing MyNavigationBar...');

    // Set all disposal flags
    _isDisposing = true;
    _logoutInProgress = true;

    // Force cleanup without setState
    _forceRemoveAllOverlays();

    // Clear all collections
    _notifications.clear();

    super.dispose();
    print('✅ MyNavigationBar disposed');
  }

  @override
  Widget build(BuildContext context) {
    // Return minimal widget if disposing or logging out
    if (_isDisposing || _logoutInProgress) {
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

          // Right side: Search, Notifications, Profile
          Row(
            children: [
              SizedBox(width: 14.w),

              // Notifications
              InkWell(
                onTap: (_isDisposing || _logoutInProgress)
                    ? null
                    : _toggleNotificationMenu,
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
              InkWell(
                onTap: (_isDisposing || _logoutInProgress)
                    ? null
                    : _toggleProfileMenu,
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
    if (_isDisposing || _logoutInProgress) return [];

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
          onTap: (_isDisposing || _logoutInProgress)
              ? null
              : () => widget.onTap(index),
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
