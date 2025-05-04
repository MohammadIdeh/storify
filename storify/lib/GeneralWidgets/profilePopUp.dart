// ignore: file_names
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/GeneralWidgets/settingsWidget.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';

class Profilepopup extends StatefulWidget {
  final VoidCallback onCloseMenu;

  const Profilepopup({super.key, required this.onCloseMenu});

  @override
  State<Profilepopup> createState() => _ProfilepopupState();
}

class _ProfilepopupState extends State<Profilepopup> {
  String? profilePictureUrl;
  String? userName;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      profilePictureUrl = prefs.getString('profilePicture');
      userName = prefs.getString('name');
      userRole = prefs.getString('currentRole');
    });
  }

  // Handle logout - moved inside class and improved
  Future<void> _logout(BuildContext context) async {
    // First call the callback to close the popup
    widget.onCloseMenu();

    try {
      // Use AuthService to logout from all roles
      await AuthService.logoutFromAllRoles();

      // Clear ALL shared preferences data
      final prefs = await SharedPreferences.getInstance();

      // Clear profile data
      await prefs.remove('profilePicture');
      await prefs.remove('name');
      await prefs.remove('currentRole');

      // Clear auth data
      await prefs.remove('token');
      await prefs.remove('supplierId');

      // Clear location data
      await prefs.remove('latitude');
      await prefs.remove('longitude');
      await prefs.remove('locationSet');

      // Optional: clear all data with clear() instead of individual removes
      // await prefs.clear();

      // Navigate to login screen and prevent going back with the back button
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      // Show error message if logout fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: profilePictureUrl != null &&
                        profilePictureUrl!.isNotEmpty
                    ? NetworkImage(profilePictureUrl!)
                    : const AssetImage('assets/images/me.png') as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            userName ?? 'User',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            userRole ?? 'Guest',
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
}
