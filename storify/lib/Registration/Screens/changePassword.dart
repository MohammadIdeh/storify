import 'dart:async';
import 'dart:convert'; // For JSON encoding
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/Registration/Widgets/animation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class Changepassword extends StatefulWidget {
  final String email;
  final String code;

  const Changepassword({super.key, required this.email, required this.code});

  @override
  State<Changepassword> createState() => _ChangepasswordState();
}

class _ChangepasswordState extends State<Changepassword> {
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Controllers for the password fields.
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Color forgotPasswordTextColor = const Color.fromARGB(255, 105, 65, 198);
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePassword2 = true;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  Future<void> _performLogin() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all the fields")),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://finalproject-a5ls.onrender.com/auth/resetPassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": widget.email,
          "code": widget.code,
          "newPassword": newPassword,
        }),
      );

      if (response.statusCode == 200) {
        // ✅ UPDATED: Use named route for clean navigation to success screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/changed-thanks',
          (route) => false, // Clear navigation stack
        );
      } else {
        // If the API call fails, show an error message.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to update password. Please try again.")),
        );
      }
    } catch (error) {
      // Display any errors.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $error")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                    // Left side - Form
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 40.w, right: 40.w, bottom: 140.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/changePassword.svg',
                              height: 100.h,
                              width: 100.w,
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              l10n.setNewPassword,
                              style: _getTextStyle(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              textAlign: TextAlign.center,
                              l10n.newPasswordDifferent,
                              style: _getTextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                                color: const Color.fromARGB(255, 212, 212, 212),
                              ),
                            ),
                            SizedBox(height: 70.h),
                            Padding(
                              padding: EdgeInsets.only(
                                  right: isRtl ? 0 : 255.w,
                                  left: isRtl ? 230.w : 0),
                              child: Text(
                                l10n.newPassword,
                                style: _getTextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      const Color.fromARGB(255, 180, 180, 180),
                                ),
                              ),
                            ),
                            SizedBox(height: 5.h),
                            SizedBox(
                              width: 370.w,
                              height: 65.h,
                              child: TextField(
                                controller: _newPasswordController,
                                obscureText: _obscurePassword,
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
                                  hintText: l10n.enterNewPassword,
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
                            SizedBox(height: 15.h),
                            Padding(
                              padding: EdgeInsets.only(
                                  right: isRtl ? 0 : 230.w,
                                  left: isRtl ? 230.w : 0),
                              child: Text(
                                l10n.confirmPassword,
                                style: _getTextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      const Color.fromARGB(255, 180, 180, 180),
                                ),
                              ),
                            ),
                            SizedBox(height: 5.h),
                            SizedBox(
                              width: 370.w,
                              height: 65.h,
                              child: TextField(
                                controller: _confirmPasswordController,
                                obscureText: _obscurePassword2,
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
                                  hintText: l10n.confirmNewPassword,
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
                                      _obscurePassword2
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword2 = !_obscurePassword2;
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
                            SizedBox(height: 35.h),
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
                                          l10n.change,
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
                    // Right side - Side container with image (if screen width allows)
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
