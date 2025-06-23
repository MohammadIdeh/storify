// lib/GeneralWidgets/profilePopUp.dart
// Ultra-defensive version that prevents all framework assertions
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
  bool _canUpdate = true; // Flag to prevent updates

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    print('🧹 Disposing ProfilePopup...');
    _isDisposed = true;
    _canUpdate = false;
    super.dispose();
  }

  // Safe setState that checks all conditions
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted && _canUpdate && !_isLoggingOut) {
      try {
        setState(fn);
      } catch (e) {
        print('⚠️ setState failed safely: $e');
      }
    }
  }

  Future<void> _loadUserData() async {
    if (_isDisposed || !_canUpdate) return;

    _safeSetState(() {
      _isLoadingProfile = true;
    });

    try {
      // First try to load from local storage for immediate display
      final prefs = await SharedPreferences.getInstance();
      if (_canUpdate && !_isDisposed && mounted) {
        _safeSetState(() {
          profilePictureUrl = prefs.getString('profilePicture');
          userName = prefs.getString('name');
          userRole = prefs.getString('currentRole');
        });
      }

      // Skip API call if already disposing
      if (!_canUpdate || _isDisposed) return;

      // Then try to refresh from API in the background
      final profileData = await UserProfileService.getUserProfile();
      if (profileData != null && _canUpdate && !_isDisposed && mounted) {
        _safeSetState(() {
          profilePictureUrl = profileData['profilePicture'];
          userName = profileData['name'];
          userRole = profileData['roleName'];
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Fallback to local data if API fails
      if (_canUpdate && !_isDisposed) {
        try {
          final localData = await UserProfileService.getLocalProfileData();
          if (_canUpdate && !_isDisposed && mounted) {
            _safeSetState(() {
              profilePictureUrl = localData['profilePicture'];
              userName = localData['name'];
              userRole = localData['currentRole'];
            });
          }
        } catch (localError) {
          print('Error loading local data: $localError');
        }
      }
    } finally {
      if (_canUpdate && !_isDisposed && mounted) {
        _safeSetState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    if (_isDisposed || _isLoggingOut || !_canUpdate) return;

    print('🚪 ProfilePopup: Starting logout...');

    // Immediately prevent any further updates
    _canUpdate = false;

    _safeSetState(() {
      _isLoggingOut = true;
    });

    try {
      // Close this popup immediately
      widget.onCloseMenu();

      // Small delay to ensure popup is closed
      await Future.delayed(const Duration(milliseconds: 50));

      if (widget.onLogout != null) {
        // Use the callback provided by parent
        await widget.onLogout!();
      } else {
        // Fallback to old method if no callback provided
        await _logoutFallback(context);
      }
    } catch (e) {
      print('❌ Error during logout from popup: $e');

      // Only show error if we're still alive and not disposed
      if (!_isDisposed && mounted && context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (snackError) {
          print('⚠️ Could not show snackbar: $snackError');
        }
      }

      // Re-enable updates only if logout failed
      _canUpdate = true;

      if (!_isDisposed && mounted) {
        _safeSetState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  // Fallback logout method (old approach)
  Future<void> _logoutFallback(BuildContext context) async {
    if (_isDisposed || !mounted || !context.mounted) return;

    try {
      print('🚪 Using fallback logout...');

      await AuthService.logoutFromAllRoles();
      final prefs = await SharedPreferences.getInstance();

      // Clear data
      await prefs.clear();

      if (!_isDisposed && context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Error in logout fallback: $e');

      // Emergency navigation
      try {
        if (!_isDisposed && context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (navError) {
        print('💥 Emergency navigation failed: $navError');
      }
    }
  }

  void _openSettings() {
    if (_isDisposed || _isLoggingOut || !_canUpdate) return;

    // Close the profile popup first
    widget.onCloseMenu();

    // Small delay to ensure popup is closed
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_isDisposed && mounted && context.mounted && _canUpdate) {
        try {
          // Then show the settings dialog
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext context) {
              return SettingsWidget(
                onClose: () {
                  try {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    print('⚠️ Error closing settings: $e');
                  }
                },
              );
            },
          );
        } catch (e) {
          print('❌ Error showing settings dialog: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Return minimal widget if disposed or logging out
    if (_isDisposed || _isLoggingOut || !_canUpdate) {
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
                _isLoggingOut ? 'Logging out...' : 'Loading...',
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
          // Profile Image, Name, Role, etc.
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
              onTap: _canUpdate ? _openSettings : null,
              child: Opacity(
                opacity: _canUpdate ? 1.0 : 0.5,
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
              onTap: _canUpdate ? () => _logout(context) : null,
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
                        color: _canUpdate ? Colors.white : Colors.white70,
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

  // Helper method to format role names for display
  String? _formatRoleName(String? role) {
    if (role == null) return null;

    switch (role) {
      case 'DeliveryEmployee':
        return 'Delivery Employee';
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
