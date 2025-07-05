// lib/admin/widgets/navigationBar.dart
// FIXED VERSION - Simplified admin logout to prevent widget tree errors with localization
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/GeneralWidgets/profilePopUp.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/utilis/notificationPopUpAdmin.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

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
  bool _isLoggingOut = false; // Single logout flag

  @override
  void dispose() {
    debugPrint('🧹 Disposing MyNavigationBar...');
    _isDisposed = true;
    _cleanupOverlays();
    super.dispose();
  }

  void _cleanupOverlays() {
    try {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _notificationOverlayEntry?.remove();
      _notificationOverlayEntry = null;
    } catch (e) {
      debugPrint('⚠️ Error cleaning overlays: $e');
    }
    _isMenuOpen = false;
    _isNotificationMenuOpen = false;
  }

  void _toggleProfileMenu() {
    if (_isDisposed || _isLoggingOut) return;

    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (_isDisposed || _isLoggingOut) return;
    final isRtl = LocalizationHelper.isRTL(context);

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
                right: isRtl ? null : 40,
                left: isRtl ? 40 : null,
                top: 100,
                child: Material(
                  color: Colors.transparent,
                  child: Profilepopup(
                    onCloseMenu: _closeMenu,
                    onLogout: _handleSimpleLogout,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (mounted && !_isDisposed && !_isLoggingOut) {
        Overlay.of(context).insert(_overlayEntry!);
        if (mounted) {
          setState(() {
            _isMenuOpen = true;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error creating overlay: $e');
      _overlayEntry = null;
    }
  }

  void _closeMenu() {
    if (_isDisposed) return;

    try {
      _overlayEntry?.remove();
    } catch (e) {
      debugPrint('⚠️ Error removing menu overlay: $e');
    }
    _overlayEntry = null;

    if (mounted && !_isDisposed) {
      setState(() {
        _isMenuOpen = false;
      });
    }
  }

  // SIMPLIFIED ADMIN LOGOUT - No multiple cleanup processes
  Future<void> _handleSimpleLogout() async {
    if (_isDisposed || _isLoggingOut) return;

    debugPrint('🚪 === CLEAN ADMIN LOGOUT ===');

    // Set logout flag
    _isLoggingOut = true;

    try {
      // Clean overlays first
      _cleanupOverlays();

      // Small delay to let UI settle
      await Future.delayed(const Duration(milliseconds: 100));

      // Clear data
      await AuthService.logoutFromAllRoles();
      await UserProfileService.clearAllRoleData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      debugPrint('✅ Admin data cleared');

      // ✅ CLEAN NAVIGATION: Clear all history including admin dashboard
      if (mounted && context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false, // Remove ALL previous routes
        );
        debugPrint('✅ Admin logout navigation completed');
      }
    } catch (e) {
      debugPrint('❌ Admin logout error: $e');

      // Emergency navigation
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
    if (_isDisposed || _isLoggingOut) return;

    if (_isNotificationMenuOpen) {
      _closeNotificationMenu();
    } else {
      _openNotificationMenu();
    }
  }

  void _openNotificationMenu() {
    if (_isDisposed || _isLoggingOut) return;

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

      if (mounted && !_isDisposed && !_isLoggingOut) {
        Overlay.of(context).insert(_notificationOverlayEntry!);
        if (mounted) {
          setState(() {
            _isNotificationMenuOpen = true;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error creating notification overlay: $e');
      _notificationOverlayEntry = null;
    }
  }

  void _closeNotificationMenu() {
    if (_isDisposed) return;

    try {
      _notificationOverlayEntry?.remove();
    } catch (e) {
      debugPrint('⚠️ Error removing notification overlay: $e');
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isRtl = LocalizationHelper.isRTL(context);

    // Clean loading state if logging out
    if (_isDisposed || _isLoggingOut) {
      return Container(
        height: 90.h,
        color: const Color.fromARGB(255, 29, 41, 57),
        child: Center(
          child: Text(
            l10n.loggingOut,
            style: LocalizationHelper.isArabic(context)
                ? GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 16.sp,
                  )
                : GoogleFonts.spaceGrotesk(
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
      padding: EdgeInsets.only(
        left: isRtl ? 30 : 45,
        right: isRtl ? 45 : 30,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          // Left side: Logo + Title
          Row(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              SvgPicture.asset(
                'assets/images/logo.svg',
                width: 35.w,
                height: 35.h,
              ),
              SizedBox(width: 12.w),
              Text(
                l10n.appTitle,
                style: LocalizationHelper.isArabic(context)
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
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: _buildNavItems(),
          ),

          // Right side: Notifications and Profile
          Row(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              SizedBox(width: 14.w),

              // Notifications
              InkWell(
                onTap: (_isDisposed || _isLoggingOut)
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
                    (_isDisposed || _isLoggingOut) ? null : _toggleProfileMenu,
                child: Row(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isRtl = LocalizationHelper.isRTL(context);

    if (_isDisposed || _isLoggingOut) return [];

    final List<String> navItems = [
      l10n.dashboard,
      l10n.products,
      l10n.category,
      l10n.orders,
      l10n.roleManagement,
      l10n.tracking,
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
              (_isDisposed || _isLoggingOut) ? null : () => widget.onTap(index),
          child: Container(
            margin: EdgeInsets.only(
              left: isRtl ? 0 : 24.w,
              right: isRtl ? 24.w : 0,
            ),
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
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
                  style: LocalizationHelper.isArabic(context)
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
