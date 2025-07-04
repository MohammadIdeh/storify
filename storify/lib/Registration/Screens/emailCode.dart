import 'dart:async';
import 'dart:convert'; // For JSON encoding
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/GeneralWidgets/snackBar.dart';
import 'package:storify/Registration/Widgets/animation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:storify/Registration/Widgets/buildCodeInputField.dart';
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class Emailcode extends StatefulWidget {
  const Emailcode({super.key});

  @override
  State<Emailcode> createState() => _EmailcodeState();
}

class _EmailcodeState extends State<Emailcode> {
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;

  // Controllers for the 5 code input fields
  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  final TextEditingController _controller3 = TextEditingController();
  final TextEditingController _controller4 = TextEditingController();
  final TextEditingController _controller5 = TextEditingController();

  Color resendCodeColor = const Color.fromARGB(255, 105, 65, 198);
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();
  final FocusNode _focusNode4 = FocusNode();
  final FocusNode _focusNode5 = FocusNode();

  // For demonstration we hardcode the email.
  // In production, pass the email from the previous screen.
  final String email = "momoideh.123@yahoo.com";

  @override
  void initState() {
    super.initState();
    _focusNode1.addListener(() => setState(() {}));
    _focusNode2.addListener(() => setState(() {}));
    _focusNode3.addListener(() => setState(() {}));
    _focusNode4.addListener(() => setState(() {}));
    _focusNode5.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _controller4.dispose();
    _controller5.dispose();
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

  void moveFocus(FocusNode nextFocusNode) {
    FocusScope.of(context).requestFocus(nextFocusNode);
  }

  /// API call: POST email and code to the API.
  Future<void> _performLogin() async {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;

    // Combine all individual code fields into a single code string.
    final String code = _controller1.text +
        _controller2.text +
        _controller3.text +
        _controller4.text +
        _controller5.text;

    if (code.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the complete code")),
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
          "email": email,
          "code": code,
        }),
      );

      if (response.statusCode == 200) {
        // ✅ UPDATED: Use named route with parameters for clean navigation
        Navigator.pushNamed(
          context,
          '/change-password',
          arguments: {
            'email': email,
            'code': code,
          },
        );
      } else {
        // If the API call fails, show an error message.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid code, please try again.")),
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
                              'assets/images/emailcheck.svg',
                              height: 100.h,
                              width: 100.w,
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              l10n.checkEmail,
                              style: _getTextStyle(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: _getTextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.grey,
                                ),
                                children: [
                                  TextSpan(text: l10n.resetCodeSent),
                                  TextSpan(
                                    text: '  ',
                                    style: _getTextStyle(
                                      fontSize: 16.sp,
                                      color: const Color.fromARGB(
                                          255, 105, 65, 198),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 70.h),

                            // Create 5 input boxes for the code
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                buildCodeInputField(
                                  controller: _controller1,
                                  focusNode: _focusNode1,
                                  context: context,
                                  onChanged: () {
                                    moveFocus(_focusNode2);
                                  },
                                ),
                                SizedBox(width: 10.w),
                                buildCodeInputField(
                                  controller: _controller2,
                                  focusNode: _focusNode2,
                                  context: context,
                                  onChanged: () {
                                    moveFocus(_focusNode3);
                                  },
                                ),
                                SizedBox(width: 10.w),
                                buildCodeInputField(
                                  controller: _controller3,
                                  focusNode: _focusNode3,
                                  context: context,
                                  onChanged: () {
                                    moveFocus(_focusNode4);
                                  },
                                ),
                                SizedBox(width: 10.w),
                                buildCodeInputField(
                                  controller: _controller4,
                                  focusNode: _focusNode4,
                                  context: context,
                                  onChanged: () {
                                    moveFocus(_focusNode5);
                                  },
                                ),
                                SizedBox(width: 10.w),
                                buildCodeInputField(
                                  controller: _controller5,
                                  focusNode: _focusNode5,
                                  context: context,
                                  onChanged: () {
                                    // Last field; no focus shift.
                                  },
                                ),
                              ],
                            ),

                            SizedBox(height: 20.h),

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
                                          l10n.check,
                                          style: _getTextStyle(
                                            fontSize: 16.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(height: 35.h),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: _getTextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.grey,
                                ),
                                children: [
                                  TextSpan(text: l10n.didntReceiveCode),
                                  const TextSpan(text: " "),
                                  TextSpan(
                                    text: l10n.resend,
                                    style: _getTextStyle(
                                      fontSize: 16.sp,
                                      color: resendCodeColor,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTapDown = (_) {
                                        showCustomSnackBar(
                                          context,
                                          'Code resent successfully!',
                                          'assets/images/emailSnack.svg',
                                        );
                                        setState(() {
                                          resendCodeColor =
                                              const Color.fromARGB(
                                                  255, 179, 179, 179);
                                        });
                                      }
                                      ..onTapUp = (_) {
                                        setState(() {
                                          resendCodeColor =
                                              const Color.fromARGB(
                                                  255, 105, 65, 198);
                                        });
                                      }
                                      ..onTapCancel = () {
                                        setState(() {
                                          resendCodeColor =
                                              const Color.fromARGB(
                                                  255, 105, 65, 198);
                                        });
                                      },
                                  ),
                                ],
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
