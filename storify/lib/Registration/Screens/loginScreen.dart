import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storify/Registration/Screens/forgotPassword.dart';
import 'package:storify/Registration/Widgets/animation.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/customer/screens/orderScreenCustomer.dart';
import 'package:storify/customer/widgets/LocationService.dart';
import 'package:storify/customer/widgets/mapPopUp.dart';
import 'package:storify/supplier/screens/ordersScreensSupplier.dart';

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

  /// Makes a POST request to the API for login and navigates based on the roleName.
  Future<void> _performLogin() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
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

      // Handle the API response.
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Login Successful: $responseData');

        // Extract token, roleName, and profilePicture
        String token = responseData['token'];
        String roleName = responseData['user']['roleName'];
        String profilePicture = responseData['user']['profilePicture'] ?? '';
        String userName =
            responseData['user']['name'] ?? responseData['user']['name'] ?? '';

        // Extract supplierId if role is Supplier
        if (roleName == 'Supplier' &&
            responseData['user']['supplierId'] != null) {
          int supplierId = responseData['user']['supplierId'];
          // Save supplierId to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('supplierId', supplierId);
          print('📦 stored supplierId = "$supplierId"');
        }

        // Save the token with the role and profilePicture locally
        await AuthService.saveToken(token, roleName);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profilePicture', profilePicture);
        await prefs.setString('name', userName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Successful as a $roleName')),
        );

        // Navigate based on role
        if (roleName == 'Admin') {
          print('🗝️ stored token = "$token" (length ${token.length})');
          print('📷 stored profilePicture = "$profilePicture"');

          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const DashboardScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        } else if (roleName == 'Supplier') {
          // Get the saved supplierId for confirmation
          final prefs = await SharedPreferences.getInstance();
          int? supplierId = prefs.getInt('supplierId');
          print('🔄 using supplierId = "$supplierId" for navigation');

          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const SupplierOrders(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        } else if (roleName == 'Employee') {
          // Handle Employee role
        } else if (roleName == 'Delivery') {
          // Handle Delivery role
        } else if (roleName == 'Customer') {
          // For Customer role, check if they're a new customer who needs to set location
          setState(() {
            _isLoading = false;
          });

          // First navigate to the main Customer screen
          final navigator = Navigator.of(context);
          navigator.push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const CustomerOrders(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );

          // Then check if location needs to be set
          _debugCustomerLocationAPI(context);
        }
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
      print('Error during login: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Check if the customer needs to set their location
// Update this section in your LoginScreen class

  /// Check if the customer needs to set their location
// Updated _checkAndSetCustomerLocation method for LoginScreen
// Make this change to ensure we don't show the popup after logging out and back in

  // Update to the _checkAndSetCustomerLocation method in LoginScreen

// Replace the _checkAndSetCustomerLocation method in LoginScreen

  Future<void> _checkAndSetCustomerLocation(NavigatorState navigator) async {
    try {
      print('Checking if customer location is set...');

      // Add a temporary flag to force popup (for testing)
      // Set this to false when everything is working correctly
      final forcePopup = false;

      // Check the database for location data
      final locationIsSet =
          forcePopup ? false : await LocationService.isLocationSetInDatabase();

      if (!locationIsSet) {
        print('Location is NOT set in database, showing popup');

        // Wait a moment for the main screen to build
        await Future.delayed(const Duration(milliseconds: 300));

        // Show the location selection popup
        if (navigator.context.mounted) {
          showDialog(
            context: navigator.context,
            barrierDismissible: false, // User must interact with the dialog
            builder: (BuildContext context) {
              return const LocationSelectionPopup();
            },
          );
        }
      } else {
        print('Location is already set in database, skipping popup');
      }
    } catch (e) {
      print('Error checking customer location status: $e');
      // If there's an error, we err on the side of not showing the popup
    }
  }

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
    _passwordController.dispose();
    super.dispose();
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
                    "Storify",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 25.sp,
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
                              "Log in to your account",
                              style: GoogleFonts.inter(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "Welcome back! Please enter your details.",
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(height: 70.h),
                            Padding(
                              padding: EdgeInsets.only(right: 330.w),
                              child: Text(
                                "Email",
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 5.h),
                            SizedBox(
                              width: 370.w,
                              height: 65.h,
                              child: TextField(
                                controller: _emailController,
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
                                    fontWeight: FontWeight.w400,
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
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),
                            SizedBox(height: 15.h),
                            Padding(
                              padding: EdgeInsets.only(right: 300.w),
                              child: Text(
                                "Password",
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: 5.h),
                            SizedBox(
                              width: 370.w,
                              height: 65.h,
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
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
                                    fontWeight: FontWeight.w400,
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
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),
                            SizedBox(height: 10.h),
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
                                    "Remember for 30 days",
                                    style: GoogleFonts.inter(
                                      color: const Color.fromARGB(
                                          178, 255, 255, 255),
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "Forgot Password?",
                                            style: GoogleFonts.inter(
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
                                                Navigator.of(context).push(
                                                  PageRouteBuilder(
                                                    pageBuilder: (context,
                                                            animation,
                                                            secondaryAnimation) =>
                                                        const Forgotpassword(),
                                                    transitionsBuilder:
                                                        (context,
                                                            animation,
                                                            secondaryAnimation,
                                                            child) {
                                                      return FadeTransition(
                                                        opacity: animation,
                                                        child: child,
                                                      );
                                                    },
                                                    transitionDuration:
                                                        const Duration(
                                                            milliseconds: 600),
                                                  ),
                                                );
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
                            SizedBox(height: 35.h),
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
                                          "Log In",
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 16.sp),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            // Sign in with Google button.
                            SizedBox(
                              height: 55.h,
                              width: 370.w,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  shape: ContinuousRectangleBorder(
                                    side: const BorderSide(
                                      color: Color.fromARGB(38, 238, 238, 238),
                                    ),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 48, 60, 80),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/google.svg',
                                      width: 25.w,
                                      height: 25.h,
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      "Sign in with Google",
                                      style: GoogleFonts.inter(
                                          color: Colors.white, fontSize: 16.sp),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            // Sign in with Apple button.
                            SizedBox(
                              height: 55.h,
                              width: 370.w,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  shape: ContinuousRectangleBorder(
                                    side: const BorderSide(
                                      color: Color.fromARGB(38, 238, 238, 238),
                                    ),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  backgroundColor:
                                      const Color.fromARGB(255, 48, 60, 80),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/apple.svg',
                                      width: 25.w,
                                      height: 25.h,
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      "Sign in with Apple",
                                      style: GoogleFonts.inter(
                                          color: Colors.white, fontSize: 16.sp),
                                    ),
                                  ],
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

Future<void> _debugCustomerLocationAPI(BuildContext context) async {
  try {
    // Get the auth token
    final token = await AuthService.getToken();
    if (token == null) {
      print('DEBUG: Auth token is null');
      return;
    }

    print('DEBUG: Token exists, length: ${token.length}');

    // Make the API call directly
    final response = await http.get(
      Uri.parse(
          'https://finalproject-a5ls.onrender.com/customer-details/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('DEBUG: API response status: ${response.statusCode}');
    print('DEBUG: API response body: ${response.body}');

    if (response.statusCode == 200) {
      // Parse the response
      final data = json.decode(response.body);
      print('DEBUG: Parsed data: $data');

      // Try to find latitude and longitude values
      var latitude, longitude;

      // Check top level
      if (data['latitude'] != null) {
        latitude = data['latitude'];
        print('DEBUG: Found latitude at top level: $latitude');
      }

      if (data['longitude'] != null) {
        longitude = data['longitude'];
        print('DEBUG: Found longitude at top level: $longitude');
      }

      // Check if customer field exists
      if (data['customer'] != null) {
        final customer = data['customer'];
        print('DEBUG: Found customer object: $customer');

        if (customer['latitude'] != null) {
          latitude = customer['latitude'];
          print('DEBUG: Found latitude in customer: $latitude');
        }

        if (customer['longitude'] != null) {
          longitude = customer['longitude'];
          print('DEBUG: Found longitude in customer: $longitude');
        }
      }

      // Check if user field exists
      if (data['user'] != null) {
        final user = data['user'];
        print('DEBUG: Found user object: $user');

        if (user['latitude'] != null) {
          latitude = user['latitude'];
          print('DEBUG: Found latitude in user: $latitude');
        }

        if (user['longitude'] != null) {
          longitude = user['longitude'];
          print('DEBUG: Found longitude in user: $longitude');
        }
      }

      // Final check
      if (latitude != null && longitude != null) {
        print('DEBUG: Location is set! Lat: $latitude, Lng: $longitude');

        // Don't show popup
        print('DEBUG: Would NOT show popup');
      } else {
        print('DEBUG: Location is NOT set!');

        // Show popup
        print('DEBUG: Would show popup');

        // Show the popup for testing
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return const LocationSelectionPopup();
          },
        );
      }
    } else {
      print('DEBUG: API call failed');
    }
  } catch (e) {
    print('DEBUG: Error during check: $e');
  }
}
