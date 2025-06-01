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
      child: Consumer<AuthService>(
        builder: (ctx, authService, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Delivery App',
            theme: AppTheme.darkTheme,
            home: FutureBuilder(
              future: _initializeApp(authService),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return authService.isLoggedIn
                    ? const HomeScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _initializeApp(AuthService authService) async {
    await authService.init();
  }
}

//  "email": "mohammad.shaheen080599@gmail.com",
////   "password": "7QkOCS2CP1UC1kbb"
//
