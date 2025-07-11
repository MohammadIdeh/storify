import 'dart:async';
import 'package:deliveryman/l10n/app_localizations.dart';
import 'package:deliveryman/services/LanguageService.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/order_service.dart';
import 'services/profile_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageService()..initialize()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => ProfileService()),
      ],
      child: const AppWrapper(),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isInitialized = false;
  String? _initializationError;
  String _initializationStep = 'Starting...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('🚀 Starting app initialization...');

      setState(() {
        _initializationStep = 'Initializing authentication...';
      });

      final authService = Provider.of<AuthService>(context, listen: false);

      // Initialize auth service with timeout
      print('📱 Initializing auth service...');
      await authService.init().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Auth service initialization timed out');
        },
      );

      print('✅ Auth service initialized. Logged in: ${authService.isLoggedIn}');

      // If user is logged in, set up other services
      if (authService.isLoggedIn && authService.token != null) {
        print('👤 User is logged in, setting up additional services...');

        setState(() {
          _initializationStep = 'Setting up services...';
        });

        final orderService = Provider.of<OrderService>(context, listen: false);
        final locationService =
            Provider.of<LocationService>(context, listen: false);
        final profileService =
            Provider.of<ProfileService>(context, listen: false);

        // Set token for other services
        orderService.updateToken(authService.token);
        locationService.updateToken(authService.token);
        profileService.updateToken(authService.token);

        // Initialize location service with timeout
        setState(() {
          _initializationStep = 'Requesting location permission...';
        });

        try {
          print('📍 Requesting location permission...');
          final hasLocationPermission =
              await locationService.requestPermission().timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              print('⚠️ Location permission request timed out');
              return false;
            },
          );

          if (hasLocationPermission) {
            setState(() {
              _initializationStep = 'Getting current location...';
            });

            await locationService.getCurrentLocation().timeout(
              const Duration(seconds: 8),
              onTimeout: () {
                print('⚠️ Get current location timed out');
                return null;
              },
            );
            print('✅ Location service initialized successfully');
          } else {
            print('⚠️ Location permission denied');
          }
        } catch (e) {
          print('⚠️ Location service error (continuing anyway): $e');
        }

        // Fetch initial orders with timeout
        setState(() {
          _initializationStep = 'Loading orders...';
        });

        try {
          print('📦 Fetching initial orders...');
          await orderService.fetchAssignedOrders().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Order fetching timed out');
            },
          );
          print('✅ Initial orders fetched successfully');
        } catch (e) {
          print('⚠️ Error fetching initial orders (continuing anyway): $e');
          // Don't treat this as a fatal error, user can try again
        }

        // Initialize profile (non-blocking)
        setState(() {
          _initializationStep = 'Loading profile...';
        });

        try {
          print('👤 Fetching profile data...');
          await profileService.fetchProfile().timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              print('⚠️ Profile fetch timed out');
              return false;
            },
          );
          print('✅ Profile data fetched successfully');
        } catch (e) {
          print('⚠️ Error fetching profile (continuing anyway): $e');
          // Don't treat this as a fatal error
        }
      } else {
        print('👤 User not logged in, skipping service setup');
      }

      setState(() {
        _isInitialized = true;
        _initializationStep = 'Complete!';
      });

      print('🎉 App initialization completed successfully');
    } catch (error, stackTrace) {
      print('❌ Error during app initialization: $error');
      print('📋 Stack trace: $stackTrace');

      setState(() {
        _isInitialized = true;
        _initializationError = _getReadableError(error);
      });
    }
  }

  String _getReadableError(dynamic error) {
    if (error is TimeoutException) {
      return 'Connection timeout. Please check your internet connection and try again.';
    } else if (error.toString().contains('SocketException')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('Firebase')) {
      return 'Firebase connection error. Please try again.';
    } else {
      return 'Initialization failed: ${error.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Storify Delivery',
          theme: AppTheme.darkTheme,
          locale: languageService.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('ar'), // Arabic
          ],
          home: _buildHomeWidget(),
        );
      },
    );
  }

  Widget _buildHomeWidget() {
    if (!_isInitialized) {
      return SplashScreen(
        initializationStep: _initializationStep,
      );
    }

    if (_initializationError != null) {
      return InitializationErrorScreen(
        error: _initializationError!,
        onRetry: () {
          setState(() {
            _isInitialized = false;
            _initializationError = null;
            _initializationStep = 'Retrying...';
          });
          _initializeApp();
        },
      );
    }

    return Consumer<AuthService>(
      builder: (ctx, authService, _) {
        return authService.isLoggedIn
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  final String initializationStep;

  const SplashScreen({
    Key? key,
    required this.initializationStep,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D2939),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF6941C6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.delivery_dining,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6941C6)),
            ),
            const SizedBox(height: 24),

            // Main loading text
            const Text(
              'Loading Delivery App...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Detailed step text
            Text(
              initializationStep,
              style: const TextStyle(
                color: Color(0xAAFFFFFF),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Debug info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF304050),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6941C6).withOpacity(0.3),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF6941C6),
                    size: 16,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'If this takes more than 30 seconds,\nplease check your internet connection',
                    style: TextStyle(
                      color: Color(0xAAFFFFFF),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InitializationErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const InitializationErrorScreen({
    Key? key,
    required this.error,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D2939),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                'Initialization Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: const TextStyle(
                  color: Color(0xAAFFFFFF),
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Retry button
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6941C6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 16),

              // Skip to login button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Skip to Login',
                  style: TextStyle(
                    color: Color(0xAAFFFFFF),
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Troubleshooting tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF304050),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6941C6).withOpacity(0.3),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Troubleshooting Tips:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Check your internet connection\n'
                      '• Make sure you have network permissions\n'
                      '• Try switching between WiFi and mobile data\n'
                      '• Restart the app if the problem persists',
                      style: TextStyle(
                        color: Color(0xAAFFFFFF),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
