// ignore: file_names
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/utilis/animation.dart';

/// LoginScreen with an animated wave background.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  Color forgotPasswordTextColor = const Color.fromARGB(255, 105, 65, 198);
  bool _isRemembered = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 29, 41, 57),
      body: Stack(
        children: [
          Positioned.fill(
            child: WaveBackground(
              child: const SizedBox.shrink(),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 27,
                    height: 27,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Storify",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 25,
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
                        padding: const EdgeInsets.only(
                            left: 40, right: 40, bottom: 140),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Log in to your account",
                              style: GoogleFonts.inter(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Welcome back! Please enter your details.",
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 70),

                            Padding(
                              padding: const EdgeInsets.only(right: 330.0),
                              child: Text(
                                "Email",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: 370,
                              height: 50,
                              child: TextField(
                                focusNode: _emailFocusNode,
                                cursorColor:
                                    const Color.fromARGB(255, 173, 170, 170),
                                cursorWidth: 1.2,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(255, 48, 60, 80),
                                  hintText: "Enter your email",
                                  hintStyle: GoogleFonts.inter(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w400),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: _emailFocusNode.hasFocus
                                          ? const Color.fromARGB(
                                              255, 66, 74, 86)
                                          : const Color.fromARGB(
                                              255, 66, 74, 86),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color.fromARGB(255, 141, 150, 158),
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Password label and text field
                            Padding(
                              padding: const EdgeInsets.only(right: 300.0),
                              child: Text(
                                "Password",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: 370,
                              height: 50,
                              child: TextField(
                                obscureText: true,
                                focusNode: _passwordFocusNode,
                                cursorColor:
                                    const Color.fromARGB(255, 173, 170, 170),
                                cursorWidth: 1.2,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(255, 48, 60, 80),
                                  hintText: "Password",
                                  hintStyle: GoogleFonts.inter(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w400),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: _passwordFocusNode.hasFocus
                                          ? const Color.fromARGB(
                                              255, 66, 74, 86)
                                          : const Color.fromARGB(
                                              255, 66, 74, 86),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color.fromARGB(255, 141, 150, 158),
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 250.0, right: 250),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _isRemembered,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _isRemembered = value!;
                                      });
                                    },
                                  ),
                                  Text(
                                    "Remember for 30 days",
                                    style: GoogleFonts.inter(
                                      color: const Color.fromARGB(
                                          178, 255, 255, 255),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      // Navigate to forgot password screen
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "Forgot Password?",
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
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
                            const SizedBox(height: 35),
                            SizedBox(
                              height: 45,
                              width: 370,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  shape: ContinuousRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 105, 65, 198),
                                ),
                                child: Text(
                                  "Log In",
                                  style: GoogleFonts.inter(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 45,
                              width: 370,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  shape: ContinuousRectangleBorder(
                                    side: const BorderSide(
                                      color: Color.fromARGB(38, 238, 238, 238),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 48, 60, 80),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/google.svg', // Path to your Google SVG icon
                                      width: 20, // Set the width of the icon
                                      height: 20, // Set the height of the icon
                                    ),
                                    const SizedBox(
                                        width:
                                            10), // Add space between the icon and the text
                                    Text(
                                      "Sign in with Google",
                                      style: GoogleFonts.inter(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 45,
                              width: 370,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  shape: ContinuousRectangleBorder(
                                    side: const BorderSide(
                                      color: Color.fromARGB(38, 238, 238, 238),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 48, 60, 80),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/apple.svg', // Path to your Google SVG icon
                                      width: 22, // Set the width of the icon
                                      height: 22, // Set the height of the icon
                                    ),
                                    const SizedBox(
                                        width:
                                            10), // Add space between the icon and the text
                                    Text(
                                      "Sign in with Apple",
                                      style: GoogleFonts.inter(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right side - Side container with image
                    if (constraints.maxWidth > 800)
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(39),
                              color: const Color.fromARGB(255, 41, 52, 68),
                            ),
                            child: Center(
                              child: Container(
                                width: 500,
                                height: 500,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color.fromARGB(255, 124, 102, 185),
                                ),
                                child: ClipOval(
                                  child: SvgPicture.asset(
                                    'assets/images/logo.svg',
                                    width:
                                        500, // Ensure this matches the container's width
                                    height:
                                        500, // Ensure this matches the container's height
                                    fit: BoxFit
                                        .fill, // This ensures the SVG fills the circle
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
