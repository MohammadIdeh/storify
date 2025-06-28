// lib/admin/widgets/navigationBar.dart
// Ultra Clean Version - Eliminates all red errors and conflicts
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/GeneralWidgets/profilePopUp.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
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
  OverlayEntry? _notificationOverlayEntry;
  bool _isNotificationMenuOpen = false;
  List<NotificationItem> _notifications = [];

  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;
  bool _isDisposed = false;
  bool _isNavigating = false; // Prevent navigation conflicts

  @override
  void dispose() {
    print('🧹 Disposing MyNavigationBar...');
    _isDisposed = true;
    _forceCleanupOverlays();
    super.dispose();
  }

  // Force cleanup without errors
  void _forceCleanupOverlays() {
    try {
      _overlayEntry?.remove();
    } catch (e) {
      // Silently ignore
    }
    _overlayEntry = null;

    try {
      _notificationOverlayEntry?.remove();
    } catch (e) {
      // Silently ignore
    }
    _notificationOverlayEntry = null;

    _isMenuOpen = false;
    _isNotificationMenuOpen = false;
  }

  void _toggleProfileMenu() {
    if (_isDisposed || _isNavigating) return;

    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (_isDisposed || _isNavigating) return;

    // Close notification menu if open
    if (_isNotificationMenuOpen) {
      _closeNotificationMenu();
    }

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
                    onLogout: _handleUltraCleanLogout,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (mounted && !_isDisposed && !_isNavigating) {
        Overlay.of(context).insert(_overlayEntry!);
        if (mounted) {
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
    if (_isDisposed) return;

    try {
      _overlayEntry?.remove();
    } catch (e) {
      // Silently ignore
    }
    _overlayEntry = null;

    if (mounted && !_isDisposed) {
      setState(() {
        _isMenuOpen = false;
      });
    }
  }

  // Ultra-clean logout that prevents ALL widget conflicts
  Future<void> _handleUltraCleanLogout() async {
    if (_isDisposed || _isNavigating) return;

    print('🚪 === ULTRA CLEAN NAVBAR LOGOUT ===');

    // Set navigation flag to prevent any further operations
    _isNavigating = true;

    try {
      // Force cleanup ALL overlays immediately
      _forceCleanupOverlays();

      // Mark as disposed to prevent rebuilds
      _isDisposed = true;

      // Small delay to let everything settle
      await Future.delayed(const Duration(milliseconds: 50));

      // Navigate with maximum safety
      if (mounted && context.mounted) {
        print('🔄 Ultra clean navigation...');

        try {
          // Try named route first
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
          print('✅ Ultra clean navigation successful');
        } catch (e) {
          print('❌ Named route failed, trying direct: $e');

          // Fallback to direct route
          try {
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
                settings: const RouteSettings(name: '/login'),
              ),
              (route) => false,
            );
            print('✅ Direct navigation successful');
          } catch (e2) {
            print('💥 All navigation failed: $e2');
          }
        }
      }
    } catch (e) {
      print('❌ Ultra clean logout error: $e');
    }
    // Don't reset _isNavigating - leave it true to prevent further operations
  }

  void _toggleNotificationMenu() {
    if (_isDisposed || _isNavigating) return;

    if (_isNotificationMenuOpen) {
      _closeNotificationMenu();
    } else {
      _openNotificationMenu();
    }
  }

  void _openNotificationMenu() {
    if (_isDisposed || _isNavigating) return;

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

      if (mounted && !_isDisposed && !_isNavigating) {
        Overlay.of(context).insert(_notificationOverlayEntry!);
        if (mounted) {
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
    if (_isDisposed) return;

    try {
      _notificationOverlayEntry?.remove();
    } catch (e) {
      // Silently ignore
    }
    _notificationOverlayEntry = null;

    if (mounted && !_isDisposed) {
      setState(() {
        _isNotificationMenuOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return clean loading state if disposed or navigating
    if (_isDisposed || _isNavigating) {
      return Container(
        height: 90.h,
        color: const Color.fromARGB(255, 29, 41, 57),
        child: Center(
          child: Text(
            'Logging out...',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 16.sp,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(top: 10.h),
      width: double.infinity,
      height: 90.h,
      color: const Color.fromARGB(255, 29, 41, 57),
      padding: const EdgeInsets.only(left: 45, right: 30),
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
              SizedBox(width: 14.w),

              // Notifications
              InkWell(
                onTap: (_isDisposed || _isNavigating)
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
                onTap:
                    (_isDisposed || _isNavigating) ? null : _toggleProfileMenu,
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
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
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            Color.fromARGB(255, 105, 65, 198),
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

  List<Widget> _buildNavItems() {
    if (_isDisposed || _isNavigating) return [];

    final List<String> navItems = [
      'Dashboard',
      'Products',
      'Category',
      'Orders',
      "Role Management",
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
          onTap:
              (_isDisposed || _isNavigating) ? null : () => widget.onTap(index),
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
