import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _performLogin() async {
    // Hide keyboard
    _dismissKeyboard();

    // Clear previous errors
    _safeSetState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      print('Starting login process...');
      final success = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Check if widget is still mounted before proceeding
      if (!mounted || _isDisposed) {
        print('Widget disposed during login, aborting navigation');
        return;
      }

      if (success) {
        print('Login successful, navigating to home screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        print('Login failed: ${authService.lastError}');
        _safeSetState(() {
          _errorMessage = authService.lastError ??
              'Invalid credentials or you are not authorized as a delivery person.';
        });
      }
    } catch (e, stackTrace) {
      print('Login error caught in UI: $e');
      print('Stack trace: $stackTrace');

      // Handle any unexpected errors
      _safeSetState(() {
        _errorMessage = 'An error occurred during login. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF1D2939),
          body: GestureDetector(
            onTap: _dismissKeyboard, // Dismiss keyboard when tapping outside
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo container
                        SvgPicture.asset(
                          'assets/images/logo.svg',
                          width: 110,
                          height: 110,
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Delivery Login',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        Text(
                          'Login to access your delivery assignments',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xAAFFFFFF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Error message if any
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.redAccent),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Email field
                        CustomTextField(
                          label: 'Email',
                          controller: _emailController,
                          hintText: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          focusNode: _emailFocusNode,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                          onSubmitted: (_) {
                            FocusScope.of(context)
                                .requestFocus(_passwordFocusNode);
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password field
                        CustomTextField(
                          label: 'Password',
                          controller: _passwordController,
                          hintText: 'Enter your password',
                          obscureText: _obscurePassword,
                          focusNode: _passwordFocusNode,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              _safeSetState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          onSubmitted: (_) => _performLogin(),
                        ),
                        const SizedBox(height: 32),

                        // Login button
                        CustomButton(
                          text: 'Log In',
                          onPressed: _performLogin,
                          isLoading: authService.isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
