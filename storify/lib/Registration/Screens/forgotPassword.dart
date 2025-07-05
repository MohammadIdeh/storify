import 'dart:async';
import 'dart:convert'; // For JSON encoding
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/Registration/Widgets/animation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http; // For making http requests
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class Forgotpassword extends StatefulWidget {
  const Forgotpassword({super.key});

  @override
  State<Forgotpassword> createState() => _ForgotpasswordState();
}

class _ForgotpasswordState extends State<Forgotpassword> {
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  // Controller for email TextField.
  final TextEditingController _emailController = TextEditingController();

  Color forgotPasswordTextColor = const Color.fromARGB(255, 105, 65, 198);
  bool _isRemembered = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

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
    _emailController.dispose();
    super.dispose();
  }

  // Helper function to get appropriate text style based on language
  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final l10n = AppLocalizations.of(context);
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

  /// Connect the API to send a reset code.
  Future<void> _performLogin() async {
    final l10n = AppLocalizations.of(context);

    // Validate that the email field is not empty.
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter your email")),
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
          "email": _emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        // ✅ UPDATED: Use named route for email code verification
        Navigator.pushNamed(context, '/email-code');
      } else {
        // If the API call fails, show an error message.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to send reset code. Please try again.")),
        );
      }
    } catch (error) {
      // Handle exceptions and show an error message.
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
    final l10n = AppLocalizations.of(context);
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
                              'assets/images/changePass.svg',
                              height: 100.h,
                              width: 100.w,
                            ),
                            SizedBox(height: 20),
                            Text(
                              l10n.forgotPassword,
                              style: _getTextStyle(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              l10n.noWorries,
                              style: _getTextStyle(
                                fontSize: 16.sp,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 70.h),
                            Padding(
                              padding: EdgeInsets.only(
                                  right: isRtl ? 0 : 330.w,
                                  left: isRtl ? 265.w : 0),
                              child: Text(
                                l10n.email,
                                style: _getTextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white60,
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
                            SizedBox(height: 10.h),
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
                                          l10n.send,
                                          style: _getTextStyle(
                                            fontSize: 16.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(height: 35.h),
                            InkWell(
                              hoverColor: const Color.fromARGB(0, 0, 0, 0),
                              splashColor: const Color.fromARGB(0, 0, 0, 0),
                              highlightColor: const Color.fromARGB(0, 0, 0, 0),
                              onTap: () {
                                // ✅ UPDATED: Use named route for clean navigation back to login
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                );
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isRtl
                                        ? Icons.arrow_forward
                                        : Icons.arrow_back,
                                    color: Colors.white,
                                    size: 22.w,
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    l10n.backToLogin,
                                    style: _getTextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
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
