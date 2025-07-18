// lib/employee/widgets/navbar_employee.dart
// Fixed version with simplified logout, proper role separation, and localization
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/GeneralWidgets/NotificationPopup.dart';
import 'package:storify/GeneralWidgets/profilePopUp.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/utilis/notification_service.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class NavigationBarEmployee extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? profilePictureUrl;

  const NavigationBarEmployee({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.profilePictureUrl,
  });

  @override
  State<NavigationBarEmployee> createState() => _NavigationBarEmployeeState();
}

class _NavigationBarEmployeeState extends State<NavigationBarEmployee> {
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
    debugPrint('🧹 Disposing NavigationBarEmployee...');
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
      debugPrint('⚠️ Error removing overlays: $e');
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

    final isRtl = LocalizationHelper.isRTL(context);

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
              right: isRtl ? null : 40,
              left: isRtl ? 40 : null,
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

  // Simplified logout for employee
  Future<void> _handleCompleteLogout() async {
    debugPrint('🚪 === STARTING EMPLOYEE LOGOUT ===');

    try {
      _removeAllOverlays();
      _isDisposed = true;

      await AuthService.logoutFromAllRoles();
      await UserProfileService.clearAllRoleData();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      debugPrint('✅ Employee data cleared');

      if (mounted && context.mounted) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error during employee logout: $e');

      if (mounted && context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
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

    final isRtl = LocalizationHelper.isRTL(context);

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
              right: isRtl ? null : 100,
              left: isRtl ? 100 : null,
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
        padding: EdgeInsets.only(
          left: isRtl ? 30 : 45,
          right: isRtl ? 45 : 30,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Logo + Title (or right side in RTL)
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

            // Right side: Notifications and Profile (or left side in RTL)
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
                            right: isRtl ? null : 10,
                            left: isRtl ? 10 : null,
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
                            ? (isRtl
                                ? Icons.arrow_drop_down
                                : Icons.arrow_drop_up)
                            : (isRtl
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down),
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
      ),
    );
  }

  List<Widget> _buildNavItems() {
    if (_isDisposed) return [];

    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = LocalizationHelper.isArabic(context);

    final List<String> navItems = [
      l10n.navBarOrders,
      l10n.navBarHistory,
    ];
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
