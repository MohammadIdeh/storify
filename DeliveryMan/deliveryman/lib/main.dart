import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/order_service.dart';
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
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('Starting app initialization...');
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final orderService = Provider.of<OrderService>(context, listen: false);
      final locationService = Provider.of<LocationService>(context, listen: false);
      
      // Initialize auth service first
      await authService.init();
      print('Auth service initialized. Logged in: ${authService.isLoggedIn}');
      
      // If user is logged in, set up other services
      if (authService.isLoggedIn && authService.token != null) {
        print('User is logged in, setting up services...');
        
        // Set token for other services
        orderService.updateToken(authService.token);
        locationService.updateToken(authService.token);
        
        // Initialize location service
        final hasLocationPermission = await locationService.requestPermission();
        if (hasLocationPermission) {
          await locationService.getCurrentLocation();
          print('Location service initialized successfully');
        } else {
          print('Location permission denied');
        }
        
        // Fetch initial orders
        try {
          await orderService.fetchAssignedOrders();
          print('Initial orders fetched successfully');
        } catch (e) {
          print('Error fetching initial orders: $e');
          // Don't treat this as a fatal error, user can try again
        }
      }
      
      setState(() {
        _isInitialized = true;
      });
      
      print('App initialization completed successfully');
      
    } catch (error, stackTrace) {
      print('Error during app initialization: $error');
      print('Stack trace: $stackTrace');
      
      setState(() {
        _isInitialized = true;
        _initializationError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery App',
      theme: AppTheme.darkTheme,
      home: _buildHomeWidget(),
    );
  }

  Widget _buildHomeWidget() {
    if (!_isInitialized) {
      return const SplashScreen();
    }
    
    if (_initializationError != null) {
      return InitializationErrorScreen(
        error: _initializationError!,
        onRetry: () {
          setState(() {
            _isInitialized = false;
            _initializationError = null;
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
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D2939),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add your logo here if you have one
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
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6941C6)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading Delivery App...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
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
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
            ],
          ),
        ),
      ),
    );
  }
}