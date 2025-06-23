// lib/GeneralWidgets/profilePopUp.dart
// ignore: file_names
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
  final Future<void> Function()? onLogout; // Add logout callback

  const Profilepopup({
    super.key,
    required this.onCloseMenu,
    this.onLogout, // Make it optional for backwards compatibility
  });
  @override
  State<Profilepopup> createState() => _ProfilepopupState();
}

class _ProfilepopupState extends State<Profilepopup> {
  String? profilePictureUrl;
  String? userName;
  String? userRole;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      // First try to load from local storage for immediate display
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        profilePictureUrl = prefs.getString('profilePicture');
        userName = prefs.getString('name');
        userRole = prefs.getString('currentRole');
      });

      // Then try to refresh from API in the background
      final profileData = await UserProfileService.getUserProfile();
      if (profileData != null && mounted) {
        setState(() {
          profilePictureUrl = profileData['profilePicture'];
          userName = profileData['name'];
          userRole = profileData['roleName'];
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Fallback to local data if API fails
      final localData = await UserProfileService.getLocalProfileData();
      if (mounted) {
        setState(() {
          profilePictureUrl = localData['profilePicture'];
          userName = localData['name'];
          userRole = localData['currentRole'];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  // Handle logout - moved inside class and improved
// lib/GeneralWidgets/profilePopUp.dart
// Enhanced logout method with comprehensive error handling

  Future<void> _logout(BuildContext context) async {
    try {
      if (widget.onLogout != null) {
        // Use the callback provided by parent
        await widget.onLogout!();
      } else {
        // Fallback to old method if no callback provided
        await _logoutFallback(context);
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  // Fallback logout method (old approach)
  Future<void> _logoutFallback(BuildContext context) async {
    if (!mounted || !context.mounted) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);

    await AuthService.logoutFromAllRoles();
    final prefs = await SharedPreferences.getInstance();

    // Clear data
    await prefs.remove('profilePicture');
    await prefs.remove('name');
    await prefs.remove('currentRole');
    await prefs.remove('email');
    await prefs.remove('phoneNumber');
    await prefs.remove('userId');
    await prefs.remove('isActive');
    await prefs.remove('registrationDate');
    await prefs.remove('token');
    await prefs.remove('supplierId');
    await prefs.remove('latitude');
    await prefs.remove('longitude');
    await prefs.remove('locationSet');

    rootNavigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );

    widget.onCloseMenu();
  }

  @override
  Widget build(BuildContext context) {
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
                                print('Error loading profile image: $error');
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
          Padding(
            padding: EdgeInsets.only(left: 40.0.w),
            child: InkWell(
              onTap: () {
                // Close the profile popup first
                widget.onCloseMenu();

                // Then show the settings dialog
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext context) {
                    return SettingsWidget(
                      onClose: () {
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              },
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
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.only(left: 40.0.w),
            child: InkWell(
              onTap: () => _logout(context),
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
                        color: Colors.white,
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
