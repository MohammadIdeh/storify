// lib/Registration/Screens/loginScreen.dart
// ✅ UPDATED WITH ANIMATED LANGUAGE SWITCHER WITH FLAGS AND RTL POSITIONING

import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/Registration/Screens/forgotPassword.dart';
import 'package:storify/Registration/Widgets/animation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/customer/widgets/mapPopUp.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';
import 'package:provider/provider.dart';
import 'package:storify/providers/LocaleProvider.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Color forgotPasswordTextColor = const Color.fromARGB(255, 105, 65, 198);
  bool _isRemembered = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));

    // ✅ CHECK IF USER IS ALREADY AUTHENTICATED
    _checkAuthenticationStatus();
  }

  // Helper function to get appropriate text style based on language
  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isArabic = l10n.localeName == 'ar';

    if (isArabic) {
      return GoogleFonts.cairo(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    } else {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }

  // ✅ NEW: Auto-redirect if user is already authenticated
  Future<void> _checkAuthenticationStatus() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      final currentRole = await AuthService.getCurrentRole();

      if (isLoggedIn && currentRole != null && mounted) {
        debugPrint(
            '🔄 User already authenticated as $currentRole, redirecting...');

        // Redirect to appropriate dashboard based on role
        String targetRoute = _getRouteForRole(currentRole);

        // Use pushReplacementNamed to avoid back-to-login issue
        Navigator.pushReplacementNamed(context, targetRoute);
      }
    } catch (e) {
      debugPrint('⚠️ Error checking auth status: $e');
      // Continue to show login screen if there's an error
    }
  }

  // ✅ NEW: Helper to get route based on role
  String _getRouteForRole(String role) {
    switch (role) {
      case 'Admin':
        return '/admin';
      case 'Customer':
        return '/customer';
      case 'Supplier':
        return '/supplier';
      case 'WareHouseEmployee':
        return '/warehouse';
      default:
        return '/login';
    }
  }

  /// ✅ UPDATED: Clean navigation with URL routing
  Future<void> _performLogin() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter email and password')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Map<String, String> loginData = {
      'email': email,
      'password': password,
    };

    try {
      final response = await http.post(
        Uri.parse('https://finalproject-a5ls.onrender.com/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(loginData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('Login Successful: $responseData');

        // Extract user data
        String token = responseData['token'];
        String roleName = responseData['user']['roleName'];
        String profilePicture = responseData['user']['profilePicture'] ?? '';
        String userName = responseData['user']['name'] ?? '';

        // Handle Supplier ID if applicable
        if (roleName == 'Supplier' &&
            responseData['user']['supplierId'] != null) {
          int supplierId = responseData['user']['supplierId'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('supplierId', supplierId);
          debugPrint('📦 stored supplierId = "$supplierId"');
        }

        // Save authentication data
        await AuthService.saveToken(token, roleName);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profilePicture', profilePicture);
        await prefs.setString('name', userName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Successful as a $roleName')),
        );

        // ✅ NAVIGATE WITH CLEAN URL ROUTING AND CLEAR HISTORY
        await _handleLoginSuccess(roleName, responseData);
      } else {
        final responseData = json.decode(response.body);
        String errorMessage = 'Login failed';
        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Error during login: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✅ NEW: Clean login success handling with URL routing
  Future<void> _handleLoginSuccess(
      String roleName, Map<String, dynamic> responseData) async {
    try {
      setState(() {
        _isLoading = false;
      });

      if (roleName == 'Admin') {
        debugPrint('🗝️ Navigating to Admin Dashboard');

        // ✅ CLEAN NAVIGATION: Remove all previous routes including login
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/admin',
          (route) => false, // Clear ALL navigation history
        );
      } else if (roleName == 'Supplier') {
        debugPrint('🔄 Navigating to Supplier Dashboard');

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/supplier',
          (route) => false, // Clear ALL navigation history
        );
      } else if (roleName == 'WareHouseEmployee') {
        debugPrint('📦 Navigating to Warehouse Dashboard');

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/warehouse',
          (route) => false, // Clear ALL navigation history
        );
      } else if (roleName == 'Customer') {
        debugPrint('🛒 Navigating to Customer Dashboard');

        // Check if location is set
        final latitude = responseData['user']['latitude'];
        final longitude = responseData['user']['longitude'];
        final bool isLocationSet = latitude != null && longitude != null;

        // Navigate to customer dashboard first
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/customer',
          (route) => false, // Clear ALL navigation history
        );

        // Show location popup if needed (after navigation completes)
        if (!isLocationSet) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => LocationSelectionPopup(
                  onLocationSaved: () {
                    // Customer is already on the correct screen
                  },
                ),
              );
            }
          });
        }
      } else if (roleName == 'Delivery') {
        // Handle Delivery role when implemented
        debugPrint('🚚 Delivery role navigation not implemented yet');
      } else {
        // Unknown role, stay on login
        debugPrint('❓ Unknown role: $roleName');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error in navigation: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✅ UPDATED: Language switcher widget with flags
  // ✅ ALTERNATIVE: Custom language switcher if package doesn't support icons
// ✅ ULTRA-MODERN LANGUAGE SWITCHER WITH PARTICLE EFFECTS AND ADVANCED ANIMATIONS
  // ✅ SIMPLE LANGUAGE SWITCHER - WHITE SHADOW ONLY FOR SELECTED FLAG
  Widget _buildLanguageSwitcher() {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        final isArabic = localeProvider.isArabic;
        final actualIsArabic = localeProvider.locale?.languageCode == 'ar';
        final useArabic = isArabic || actualIsArabic;

        debugPrint('🌐 Switcher rebuild - using: $useArabic');

        return Container(
          key: ValueKey('lang_switcher_$useArabic'),
          width: 140.w,
          height: 60.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(255, 48, 60, 80).withOpacity(0.9),
                const Color.fromARGB(255, 41, 52, 68).withOpacity(0.8),
              ],
            ),
            border: Border.all(
              color: const Color.fromARGB(255, 105, 65, 198).withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              // ENGLISH BUTTON (LEFT SIDE)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      bottomLeft: Radius.circular(30.r),
                    ),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    onTap: () async {
                      debugPrint('🇺🇸 ENGLISH TAPPED!');
                      if (!localeProvider.isLoading && useArabic) {
                        HapticFeedback.lightImpact();
                        await localeProvider.setLocale(const Locale('en'));
                        debugPrint('✅ Switched to English');
                      }
                    },
                    child: Container(
                      height: 60.h,
                      child: Center(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: !useArabic ? 1.15 : 0.9,
                          child: Container(
                            width: 35.w,
                            height: 35.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                              // ✅ ONLY WHITE SHADOW FOR SELECTED FLAG
                              boxShadow: !useArabic
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.4),
                                        blurRadius: 15,
                                        spreadRadius: 3,
                                        offset: const Offset(0, 0),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.r),
                              child: SvgPicture.asset(
                                'assets/images/Flag_of_the_United_States.svg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ARABIC BUTTON (RIGHT SIDE)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(30.r),
                      bottomRight: Radius.circular(30.r),
                    ),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    onTap: () async {
                      debugPrint('🇵🇸 ARABIC TAPPED!');
                      if (!localeProvider.isLoading && !useArabic) {
                        HapticFeedback.lightImpact();
                        await localeProvider.setLocale(const Locale('ar'));
                        debugPrint('✅ Switched to Arabic');
                      }
                    },
                    child: Container(
                      height: 60.h,
                      child: Center(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: useArabic ? 1.15 : 0.9,
                          child: Container(
                            width: 35.w,
                            height: 35.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.r),
                              // ✅ ONLY WHITE SHADOW FOR SELECTED FLAG
                              boxShadow: useArabic
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.4),
                                        blurRadius: 15,
                                        spreadRadius: 3,
                                        offset: const Offset(0, 0),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.r),
                              child: SvgPicture.asset(
                                'assets/images/palestineFlag.svg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ NEW: Dynamic positioning based on language direction
  Widget _buildPositionedLanguageSwitcher() {
    final isRtl = LocalizationHelper.isRTL(context);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 100.h,
      // Dynamic positioning based on RTL
      left: isRtl ? null : 30.w, // Left side for LTR (English)
      right: isRtl ? 30.w : null, // Right side for RTL (Arabic)
      child: _buildLanguageSwitcher(),
    );
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isRtl = LocalizationHelper.isRTL(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      body: Stack(
        children: [
          Positioned.fill(
            child: WaveBackground(child: const SizedBox.shrink()),
          ),

          // ✅ UPDATED: Dynamic Language Switcher positioning
          _buildPositionedLanguageSwitcher(),

          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 27.w,
                    height: 27.h,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    l10n.appTitle,
                    style: _getTextStyle(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Left side - Form.
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 40.w,
                          right: 40.w,
                          bottom: 140.h,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              l10n.loginToAccount,
                              style: _getTextStyle(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              l10n.welcomeBack,
                              style: _getTextStyle(
                                fontSize: 16.sp,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 70.h),
                            Padding(
                              padding: EdgeInsets.only(
                                  right: isRtl ? 0 : 330.w,
                                  left: isRtl ? 272.w : 0),
                              child: Text(
                                l10n.email,
                                style: _getTextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: isRtl ? 15.h : 5.h),
                            SizedBox(
                              width: 370.w,
                              height: 65.h,
                              child: TextField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                textDirection: isRtl
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                cursorColor:
                                    const Color.fromARGB(255, 173, 170, 170),
                                cursorWidth: 1.2,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(255, 48, 60, 80),
                                  hintText: l10n.enterEmail,
                                  hintStyle: _getTextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: BorderSide(
                                      color: _emailFocusNode.hasFocus
                                          ? const Color.fromARGB(
                                              255, 66, 74, 86)
                                          : const Color.fromARGB(
                                              255, 66, 74, 86),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: const BorderSide(
                                      color: Color.fromARGB(255, 141, 150, 158),
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: _getTextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 15.h),
                            Padding(
                              padding: EdgeInsets.only(
                                  right: isRtl ? 0 : 300.w,
                                  left: isRtl ? 300.w : 0),
                              child: Text(
                                l10n.password,
                                style: _getTextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: isRtl ? 15.h : 5.h),
                            SizedBox(
                              width: 370.w,
                              height: 65.h,
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                focusNode: _passwordFocusNode,
                                textDirection: isRtl
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                cursorColor:
                                    const Color.fromARGB(255, 173, 170, 170),
                                cursorWidth: 1.2,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(255, 48, 60, 80),
                                  hintText: l10n.enterPassword,
                                  hintStyle: _getTextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: BorderSide(
                                      color: _passwordFocusNode.hasFocus
                                          ? const Color.fromARGB(
                                              255, 66, 74, 86)
                                          : const Color.fromARGB(
                                              255, 66, 74, 86),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: const BorderSide(
                                      color: Color.fromARGB(255, 141, 150, 158),
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                style: _getTextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 0.h),
                            // Remember me and Forgot Password row.
                            Padding(
                              padding:
                                  EdgeInsets.only(left: 250.w, right: 250.w),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _isRemembered,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _isRemembered = value ?? false;
                                      });
                                    },
                                  ),
                                  Text(
                                    l10n.rememberMe,
                                    style: _getTextStyle(
                                      fontSize: 14.sp,
                                      color: const Color.fromARGB(
                                          178, 255, 255, 255),
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: l10n.forgotPassword,
                                            style: _getTextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w500,
                                              color: forgotPasswordTextColor,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTapDown = (_) {
                                                setState(() {
                                                  forgotPasswordTextColor =
                                                      const Color.fromARGB(
                                                          255, 179, 179, 179);
                                                });
                                              }
                                              ..onTapUp = (_) {
                                                setState(() {
                                                  forgotPasswordTextColor =
                                                      const Color.fromARGB(
                                                          255, 105, 65, 198);
                                                });
                                                // ✅ UPDATED: Use named route for forgot password
                                                Navigator.pushNamed(context,
                                                    '/forgot-password');
                                              }
                                              ..onTapCancel = () {
                                                setState(() {
                                                  forgotPasswordTextColor =
                                                      const Color.fromARGB(
                                                          255, 105, 65, 198);
                                                });
                                              },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 15.h),
                            // Login button.
                            SizedBox(
                              height: 55.h,
                              width: 370.w,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_isLoading) return;
                                  await _performLogin();
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: ContinuousRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 105, 65, 198),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? SpinKitThreeBounce(
                                          color: Colors.white,
                                          size: 20.0,
                                        )
                                      : Text(
                                          l10n.login,
                                          style: _getTextStyle(
                                            fontSize: 16.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right side - Container with image (visible on wider screens).
                    if (constraints.maxWidth > 800)
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.all(25.w),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(39.r),
                              color: const Color.fromARGB(255, 41, 52, 68),
                            ),
                            child: Center(
                              child: Container(
                                width: 450,
                                height: 450,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color.fromARGB(255, 124, 102, 185),
                                ),
                                child: ClipOval(
                                  child: SvgPicture.asset(
                                    'assets/images/logo.svg',
                                    width: 450,
                                    height: 450,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
