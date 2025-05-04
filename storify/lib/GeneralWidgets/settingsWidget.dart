// lib/customer/widgets/settings_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:storify/customer/widgets/mapPopUp.dart';

class SettingsWidget extends StatefulWidget {
  final VoidCallback onClose;

  const SettingsWidget({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? userRole;
  bool _darkMode = true;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Arabic', 'Spanish', 'French'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('currentRole');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLocationSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationSelectionPopup(
        onLocationSaved: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Container(
        width: 800.w,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1D2939),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with title and close button
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Settings",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Tabs for different settings categories
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[800]!,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF7B5CFA),
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[400],
                labelStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                ),
                tabs: [
                  Tab(
                    icon: Icon(Icons.person, size: 24.sp),
                    text: "Profile",
                  ),
                  Tab(
                    icon: Icon(Icons.palette, size: 24.sp),
                    text: "Appearance",
                  ),
                  Tab(
                    icon: Icon(Icons.notifications, size: 24.sp),
                    text: "Notifications",
                  ),
                  Tab(
                    icon: Icon(Icons.help_outline, size: 24.sp),
                    text: "About",
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Profile Settings
                  SingleChildScrollView(
                    child: _buildProfileSettings(),
                  ),

                  // Appearance Settings
                  SingleChildScrollView(
                    child: _buildAppearanceSettings(),
                  ),

                  // Notification Settings
                  SingleChildScrollView(
                    child: _buildNotificationSettings(),
                  ),

                  // About/Help
                  SingleChildScrollView(
                    child: _buildAboutSection(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Profile settings section
  Widget _buildProfileSettings() {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile info card
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: const Color(0xFF283548),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 80.w,
                      height: 80.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7B5CFA).withOpacity(0.2),
                        border: Border.all(
                          color: const Color(0xFF7B5CFA),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          color: const Color(0xFF7B5CFA),
                          size: 40.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Profile Picture",
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "Upload a new profile picture or avatar",
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.grey[400],
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7B5CFA),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 12.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: Text(
                                  "Upload Photo",
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  "Remove",
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Account information form
          Text(
            "Account Information",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          // Form fields
          _buildSettingsTextField("Full Name", "John Doe"),
          SizedBox(height: 16.h),
          _buildSettingsTextField("Email", "john.doe@example.com"),
          SizedBox(height: 16.h),
          _buildSettingsTextField("Phone Number", "+1 123 456 7890"),

          SizedBox(height: 24.h),

          // Password section
          Text(
            "Password",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          _buildSettingsTextField("Current Password", "••••••••",
              isPassword: true),
          SizedBox(height: 16.h),
          _buildSettingsTextField("New Password", "••••••••", isPassword: true),
          SizedBox(height: 16.h),
          _buildSettingsTextField("Confirm New Password", "••••••••",
              isPassword: true),

          SizedBox(height: 24.h),

          // Location section (only for customers)
          if (userRole == 'Customer') ...[
            Text(
              "Delivery Location",
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: const Color(0xFF283548),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: const Color(0xFF7B5CFA),
                    size: 32.sp,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your Delivery Address",
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Your current location is set for deliveries",
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16.w),
                  ElevatedButton(
                    onPressed: _showLocationSelectionDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B5CFA),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      "Change Location",
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Save button
          SizedBox(height: 32.h),
          Center(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5CFA),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 40.w,
                  vertical: 16.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                "Save Changes",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Appearance settings section
  Widget _buildAppearanceSettings() {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Theme",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          // Theme selector
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: const Color(0xFF283548),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dark Mode",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Use dark theme throughout the app",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.grey[400],
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() {
                      _darkMode = value;
                    });
                  },
                  activeColor: const Color(0xFF7B5CFA),
                  activeTrackColor: const Color(0xFF7B5CFA).withOpacity(0.3),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Language settings
          Text(
            "Language",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: const Color(0xFF283548),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Language",
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2939),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.grey[700]!,
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1D2939),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey[400],
                      ),
                      items: _languages.map((String language) {
                        return DropdownMenuItem<String>(
                          value: language,
                          child: Text(
                            language,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 16.sp,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedLanguage = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Color scheme options (just for show)
          SizedBox(height: 24.h),
          Text(
            "Accent Color",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: const Color(0xFF283548),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Choose Accent Color",
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildColorOption(const Color(0xFF7B5CFA),
                        isSelected: true),
                    _buildColorOption(Colors.blue),
                    _buildColorOption(Colors.teal),
                    _buildColorOption(Colors.amber),
                    _buildColorOption(Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),

          // Save button
          SizedBox(height: 32.h),
          Center(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5CFA),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 40.w,
                  vertical: 16.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                "Apply Changes",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Notification settings section
  Widget _buildNotificationSettings() {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Notification Settings",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          // Enable/disable all notifications
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: const Color(0xFF283548),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enable Notifications",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Receive notifications for orders and updates",
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.grey[400],
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                  activeColor: const Color(0xFF7B5CFA),
                  activeTrackColor: const Color(0xFF7B5CFA).withOpacity(0.3),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Specific notification types
          Text(
            "Notification Types",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          _buildNotificationTypeSwitch(
            "Order Updates",
            "Get notified about status changes to your orders",
            true,
          ),

          SizedBox(height: 12.h),
          _buildNotificationTypeSwitch(
            "Promotions & Discounts",
            "Receive notifications about special offers",
            true,
          ),

          SizedBox(height: 12.h),
          _buildNotificationTypeSwitch(
            "New Products",
            "Be the first to know about new products",
            false,
          ),

          SizedBox(height: 12.h),
          _buildNotificationTypeSwitch(
            "Delivery Updates",
            "Track your orders in real-time",
            true,
          ),

          // Email notification preferences
          SizedBox(height: 24.h),
          Text(
            "Email Notifications",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          _buildNotificationTypeSwitch(
            "Order Confirmations",
            "Receive email confirmations for your orders",
            true,
          ),

          SizedBox(height: 12.h),
          _buildNotificationTypeSwitch(
            "Newsletter",
            "Stay updated with our monthly newsletter",
            false,
          ),

          // Save button
          SizedBox(height: 32.h),
          Center(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5CFA),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 40.w,
                  vertical: 16.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                "Save Preferences",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // About/Help section
  Widget _buildAboutSection() {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About Storify",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: const Color(0xFF283548),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7B5CFA).withOpacity(0.2),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shopping_cart,
                      color: const Color(0xFF7B5CFA),
                      size: 40.sp,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  "Storify",
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Version 1.0.0",
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.grey[400],
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  "Storify is an e-commerce platform that connects customers with suppliers for a seamless shopping experience.",
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Help & Support section
          Text(
            "Help & Support",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          _buildSupportOption(
            "FAQs",
            "Find answers to frequently asked questions",
            Icons.question_answer,
          ),

          SizedBox(height: 12.h),
          _buildSupportOption(
            "Contact Support",
            "Get help from our support team",
            Icons.headset_mic,
          ),

          SizedBox(height: 12.h),
          _buildSupportOption(
            "Report a Bug",
            "Help us improve by reporting issues",
            Icons.bug_report,
          ),

          SizedBox(height: 12.h),
          _buildSupportOption(
            "Privacy Policy",
            "Read our privacy policy",
            Icons.privacy_tip,
          ),

          SizedBox(height: 12.h),
          _buildSupportOption(
            "Terms of Service",
            "View our terms of service",
            Icons.description,
          ),
        ],
      ),
    );
  }

  // Helper method to build text fields
  Widget _buildSettingsTextField(String label, String initialValue,
      {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.grey[400],
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          obscureText: isPassword,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF283548),
            hintText: initialValue,
            hintStyle: GoogleFonts.spaceGrotesk(
              color: Colors.grey[600],
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[700]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[700]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: const Color(0xFF7B5CFA),
                width: 2,
              ),
            ),
            suffixIcon: isPassword
                ? Icon(
                    Icons.visibility,
                    color: Colors.grey[400],
                  )
                : null,
          ),
        ),
      ],
    );
  }

  // Helper method to build notification type switches
  Widget _buildNotificationTypeSwitch(
      String title, String description, bool initialValue) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF283548),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.grey[400],
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: initialValue,
            onChanged: (value) {
              // Just for UI demonstration, not storing the value
              setState(() {});
            },
            activeColor: const Color(0xFF7B5CFA),
            activeTrackColor: const Color(0xFF7B5CFA).withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  // Helper method to build color option selector
  Widget _buildColorOption(Color color, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        // Just for UI demonstration
      },
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: Colors.white,
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20.sp,
                ),
              )
            : null,
      ),
    );
  }

  // Helper method to build support option items
  Widget _buildSupportOption(String title, String description, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF283548),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: const Color(0xFF7B5CFA).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Icon(
                icon,
                color: const Color(0xFF7B5CFA),
                size: 24.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.grey[400],
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
            size: 24.sp,
          ),
        ],
      ),
    );
  }
}
