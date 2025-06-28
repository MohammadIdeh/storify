// lib/GeneralWidgets/profilePopUp.dart
// FINAL VERSION - Fix silent navigation failure
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:storify/GeneralWidgets/settingsWidget.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/services/user_profile_service.dart';

class Profilepopup extends StatefulWidget {
  final VoidCallback onCloseMenu;
  final Future<void> Function()? onLogout;

  const Profilepopup({
    super.key,
    required this.onCloseMenu,
    this.onLogout,
  });

  @override
  State<Profilepopup> createState() => _ProfilepopupState();
}

class _ProfilepopupState extends State<Profilepopup> {
  String? profilePictureUrl;
  String? userName;
  String? userRole;
  bool _isLoadingProfile = false;
  bool _isLoggingOut = false;
  bool _isDisposed = false;
  bool _canUpdate = true;

  // Prevent multiple logout attempts
  static bool _logoutInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    print('🧹 Disposing ProfilePopup...');

    // Set all flags to prevent any further operations
    _isDisposed = true;
    _canUpdate = false;
    _isLoggingOut = true;

    // Call super dispose
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    // Extra defensive checks to prevent build errors
    if (_isDisposed ||
        !mounted ||
        !_canUpdate ||
        _isLoggingOut ||
        _logoutInProgress) {
      print('⚠️ Skipping setState - widget not ready');
      return;
    }

    // try {
    //   // Check if we're in a build phase
    //   if (WidgetsBinding.instance.debugDoingBuild) {
    //     print('⚠️ Skipping setState during build');
    //     return;
    //   }

    //   setState(fn);
    // } catch (e) {
    //   print('⚠️ setState failed safely: $e');
    // }
  }

  Future<void> _loadUserData() async {
    if (_isDisposed || !_canUpdate) return;

    _safeSetState(() {
      _isLoadingProfile = true;
    });

    try {
      final currentRole = await AuthService.getCurrentRole();
      if (currentRole == null) return;

      final profileData =
          await UserProfileService.getRoleSpecificProfile(currentRole);

      if (profileData != null && _canUpdate && !_isDisposed && mounted) {
        _safeSetState(() {
          profilePictureUrl = profileData['profilePicture'];
          userName = profileData['name'];
          userRole = currentRole;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (_canUpdate && !_isDisposed && mounted) {
        _safeSetState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  // FIXED: Non-async logout to prevent disposal conflicts
  void _logout() {
    if (_isDisposed || _isLoggingOut || !_canUpdate || _logoutInProgress) {
      print('🚪 Logout blocked - already in progress');
      return;
    }

    print('🚪 === STARTING CLEAN LOGOUT ===');

    // Set flags immediately to prevent rebuild
    _logoutInProgress = true;
    _isLoggingOut = true;
    _canUpdate = false;

    // Close popup immediately
    widget.onCloseMenu();

    // Do cleanup and navigation in separate async call
    _performLogoutAsync();
  }

  // Separate async method to avoid disposal conflicts
  Future<void> _performLogoutAsync() async {
    try {
      // Clear data
      print('🧹 Clearing data...');
      await AuthService.logoutFromAllRoles();
      await UserProfileService.clearAllRoleData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ Data cleared');

      // Use parent callback for navigation
      if (widget.onLogout != null) {
        print('🔄 Using parent logout callback...');
        await widget.onLogout!();
        print('✅ Parent logout completed');
      }
    } catch (e) {
      print('❌ Logout error: $e');
    } finally {
      // Reset flags after delay
      Future.delayed(const Duration(seconds: 2), () {
        _logoutInProgress = false;
      });
    }
  }

  // Settings method (working fine)
  void _openSettings() {
    if (_isDisposed || _isLoggingOut || !_canUpdate) {
      print('⚠️ Cannot open settings - invalid state');
      return;
    }

    print('⚙️ Opening settings...');

    // Get root context BEFORE closing
    final BuildContext rootContext =
        Navigator.of(context, rootNavigator: true).context;

    // Close popup
    widget.onCloseMenu();

    // Show settings
    Future.delayed(const Duration(milliseconds: 100), () {
      if (rootContext.mounted) {
        showDialog<void>(
          context: rootContext,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            return SettingsWidget(
              onClose: () {
                Navigator.of(dialogContext).pop();
              },
            );
          },
        ).then((_) {
          print('⚙️ Settings dialog closed');
        }).catchError((error) {
          print('❌ Settings error: $error');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Return empty container if disposed or in bad state
    if (_isDisposed || (_isLoggingOut && _logoutInProgress)) {
      return SizedBox.shrink();
    }

    // Show loading state if logging out
    if (_isLoggingOut) {
      return Container(
        width: 220.w,
        height: 290.h,
        padding: EdgeInsets.all(16.0.w),
        decoration: BoxDecoration(
          color: const Color(0xFF2D3C4E),
          borderRadius: BorderRadius.circular(16.0.w),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: const Color(0xFF7B5CFA),
              ),
              SizedBox(height: 12.h),
              Text(
                'Logging out...',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal popup
    return Container(
      width: 220.w,
      height: 290.h,
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3C4E),
        borderRadius: BorderRadius.circular(16.0.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile Image
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child:
                      profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: profilePictureUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFF7B5CFA).withOpacity(0.2),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: const Color(0xFF7B5CFA),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                return Image.asset(
                                  'assets/images/me.png',
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              'assets/images/me.png',
                              fit: BoxFit.cover,
                            ),
                ),
              ),
              if (_isLoadingProfile)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF7B5CFA),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // User Info
          Text(
            userName ?? 'Loading...',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _formatRoleName(userRole) ?? 'Guest',
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 15.sp,
                fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 30.h),

          // Settings button
          Padding(
            padding: EdgeInsets.only(left: 40.0.w),
            child: InkWell(
              onTap: (_canUpdate && !_isLoggingOut && !_logoutInProgress)
                  ? _openSettings
                  : null,
              child: Opacity(
                opacity: (_canUpdate && !_isLoggingOut && !_logoutInProgress)
                    ? 1.0
                    : 0.5,
                child: Row(
                  children: [
                    SizedBox(width: 8.w),
                    SvgPicture.asset(
                      'assets/images/settings2.svg',
                      width: 24.w,
                      height: 24.h,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Settings',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // Logout button
          Padding(
            padding: EdgeInsets.only(left: 40.0.w),
            child: InkWell(
              onTap: (_canUpdate && !_isLoggingOut && !_logoutInProgress)
                  ? _logout
                  : null,
              child: Row(
                children: [
                  SizedBox(width: 8.w),
                  SvgPicture.asset(
                    'assets/images/logout.svg',
                    width: 24.w,
                    height: 24.h,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Log Out',
                    style: GoogleFonts.spaceGrotesk(
                        color:
                            (_canUpdate && !_isLoggingOut && !_logoutInProgress)
                                ? Colors.white
                                : Colors.white70,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatRoleName(String? role) {
    if (role == null) return null;

    switch (role) {
      case 'DeliveryEmployee':
        return 'Delivery Employee';
      case 'WareHouseEmployee':
        return 'Warehouse Employee';
      case 'Customer':
        return 'Customer';
      case 'Supplier':
        return 'Supplier';
      case 'Admin':
        return 'Admin';
      default:
        return role;
    }
  }
}
