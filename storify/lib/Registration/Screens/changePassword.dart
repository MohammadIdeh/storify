import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/Registration/Screens/changedThanks.dart';
import 'package:storify/Registration/Screens/forgotPassword.dart';
import 'package:storify/Registration/Widgets/animation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Add this import

class Changepassword extends StatefulWidget {
  const Changepassword({super.key});

  @override
  State<Changepassword> createState() => _ChangepasswordState();
}

class _ChangepasswordState extends State<Changepassword> {
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
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
    super.dispose();
  }

  /// Simulate your API call. Notice that the button remains active,
  /// but we prevent multiple calls by checking _isLoading.
  Future<void> _performLogin() async {
    setState(() {
      _isLoading = true;
    });
    // Simulate API call delay. Replace with your actual API call.
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const Changedthanks (),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(
            milliseconds: 600), // Set longer duration here  Color
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              padding: EdgeInsets.all(20.w), // Scaling padding with ScreenUtil
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 27.w, // Scaled width
                    height: 27.h, // Scaled height
                  ),
                  SizedBox(width: 10.w), // Scaled spacing
                  Text(
                    "Storify",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 25.sp, // Scaled font size
                      fontWeight: FontWeight.w500,
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
                            left: 40.w,
                            right: 40.w,
                            bottom: 140.h), // Scaled padding
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/changePassword.svg',
                              height: 100.h,
                              width: 100.w,
                            ),
                            SizedBox(
                              height: 20.h,
                            ),
                            Text(
                              "Set new password",
                              style: GoogleFonts.inter(
                                fontSize: 30.sp, // Scaled font size
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              textAlign: TextAlign.center,
                              "Your new password must be different to\npreviously used passwords.",
                              style: GoogleFonts.inter(
                                fontSize: 16.sp, // Scaled font size
                                fontWeight: FontWeight.w400,
                                color: const Color.fromARGB(255, 212, 212, 212),
                              ),
                            ),
                            SizedBox(height: 70.h), // Scaled spacing
                            Padding(
                              padding: EdgeInsets.only(
                                  right: 255.w), // Scaled padding
                              child: Text(
                                "New Password",
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp, // Scaled font size
                                  fontWeight: FontWeight.w500,
                                  color:
                                      const Color.fromARGB(255, 180, 180, 180),
                                ),
                              ),
                            ),
                            SizedBox(height: 5.h),
                            SizedBox(
                              width: 370.w, // Scaled width
                              height: 65.h, // Scaled height
                              child: TextField(
                                obscureText: _obscurePassword,
                                focusNode: _emailFocusNode,
                                cursorColor:
                                    const Color.fromARGB(255, 173, 170, 170),
                                cursorWidth: 1.2,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(255, 48, 60, 80),
                                  hintText: "Enter your New Password",
                                  hintStyle: GoogleFonts.inter(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w400),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        8.r), // Scaled radius
                                    borderSide: BorderSide(
                                      color: _emailFocusNode.hasFocus
                                          ? const Color.fromARGB(
                                              255, 66, 74, 86)
                                          : const Color.fromARGB(
                                              255, 66, 74, 86),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        8.r), // Scaled radius
                                    borderSide: const BorderSide(
                                      color: Color.fromARGB(255, 141, 150, 158),
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        8.r), // Scaled radius
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
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),
                            SizedBox(height: 15.h),
                            // Password label and text field
                            Padding(
                              padding: EdgeInsets.only(
                                  right: 230.w), // Scaled padding
                              child: Text(
                                "Confirm Password",
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp, // Scaled font size
                                  fontWeight: FontWeight.w500,
                                  color:
                                      const Color.fromARGB(255, 180, 180, 180),
                                ),
                              ),
                            ),
                            SizedBox(height: 5.h),
                            SizedBox(
                              width: 370.w, // Scaled width
                              height: 65.h, // Scaled height
                              child: TextField(
                                obscureText: _obscurePassword2,
                                focusNode: _passwordFocusNode,
                                cursorColor:
                                    const Color.fromARGB(255, 173, 170, 170),
                                cursorWidth: 1.2,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(255, 48, 60, 80),
                                  hintText: "Confirm your New Password",
                                  hintStyle: GoogleFonts.inter(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        8.r), // Scaled radius
                                    borderSide: BorderSide(
                                      color: _passwordFocusNode.hasFocus
                                          ? const Color.fromARGB(
                                              255, 66, 74, 86)
                                          : const Color.fromARGB(
                                              255, 66, 74, 86),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        8.r), // Scaled radius
                                    borderSide: const BorderSide(
                                      color: Color.fromARGB(255, 141, 150, 158),
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        8.r), // Scaled radius
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
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),

                            SizedBox(height: 35.h),
                            // Updated login button using flutter_spinkit for loading animation.
                            SizedBox(
                              height: 55.h, // Scaled height
                              width: 370.w, // Scaled width
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_isLoading) return;
                                  await _performLogin();
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: ContinuousRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        20.r), // Scaled radius
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
                                          "Change",
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize:
                                                  16.sp), // Scaled font size
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
                          padding: EdgeInsets.all(25.w), // Scaled padding
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(39.r), // Scaled radius
                              color: const Color.fromARGB(255, 41, 52, 68),
                            ),
                            child: Center(
                              child: Container(
                                width: 450, // Scaled width
                                height: 450, // Scaled height
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color.fromARGB(255, 124, 102, 185),
                                ),
                                child: ClipOval(
                                  child: SvgPicture.asset(
                                    'assets/images/logo.svg',
                                    width: 450, // Scaled width
                                    height: 450, // Scaled height
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
