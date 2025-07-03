// lib/main.dart
// Fixed version with proper authentication persistence on web refresh
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/orders.dart';
import 'package:storify/customer/screens/orderScreenCustomer.dart';
import 'package:storify/employee/screens/orders_screen.dart';
import 'package:storify/supplier/screens/ordersScreensSupplier.dart';
import 'package:storify/utilis/firebase_options.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/utilis/notification_service.dart';

// This must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🚀 Starting Storify app...');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Give SharedPreferences time to load properly on web
    await Future.delayed(const Duration(milliseconds: 100));

    final isLoggedIn = await AuthService.isLoggedIn();
    final currentRole = await AuthService.getCurrentRole();
    print('✅ Auth check completed: loggedIn=$isLoggedIn, role=$currentRole');

    runApp(MyApp(isLoggedIn: isLoggedIn, currentRole: currentRole));
    print('✅ App started successfully');

    _initializeNotificationsLater();
  } catch (e) {
    print('❌ Error in main: $e');
    runApp(MyApp(isLoggedIn: false, currentRole: null));
  }
}

void _initializeNotificationsLater() {
  Future.delayed(Duration(seconds: 2), () async {
    try {
      print('🔔 Starting background notification initialization...');

      await NotificationService.initialize();

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Foreground message received: ${message.messageId}");
      });

      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        if (message != null) {
          print("App opened from terminated state by notification");
          Future.delayed(Duration(seconds: 1), () {
            handleNotificationNavigation(message.data);
          });
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("App opened from background state by notification");
        handleNotificationNavigation(message.data);
      });

      NotificationService().processBackgroundNotifications();
      NotificationService().loadNotificationsFromFirestore();

      print('✅ Notifications initialized in background');
    } catch (e) {
      print('❌ Error initializing notifications (non-critical): $e');
    }
  });
}

void handleNotificationNavigation(Map<String, dynamic> data) {
  final notificationType = data['type'] as String?;
  final orderId = data['orderId'] as String?;
  print("Should navigate to: type=$notificationType, orderId=$orderId");
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? currentRole;

  const MyApp({super.key, required this.isLoggedIn, this.currentRole});

  @override
  Widget build(BuildContext context) {
    print(
        '🎨 Building MyApp widget with auth state: $isLoggedIn, role: $currentRole');

    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Storify',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),

        // FIXED: Define routes without conflicting with home
        routes: {
          '/login': (context) => const LoginScreen(),
          '/admin': (context) => const DashboardScreen(),
          '/supplier': (context) => const SupplierOrders(),
          '/customer': (context) => const CustomerOrders(),
          '/warehouse': (context) => const Orders_employee(),
        },

        // FIXED: Remove initialRoute to avoid conflicts with home
        // Let the home property handle the initial routing based on auth state

        // FIXED: Use only home property for initial routing
        home: _getHomeScreen(),

        // FIXED: Handle named routes properly
        onGenerateRoute: (RouteSettings settings) {
          print('🔄 Generating route: ${settings.name}');

          // Handle named routes when navigating programmatically
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(
                builder: (_) => const LoginScreen(),
                settings: settings,
              );
            case '/admin':
              return MaterialPageRoute(
                builder: (_) => const DashboardScreen(),
                settings: settings,
              );
            case '/supplier':
              return MaterialPageRoute(
                builder: (_) => const SupplierOrders(),
                settings: settings,
              );
            case '/customer':
              return MaterialPageRoute(
                builder: (_) => const CustomerOrders(),
                settings: settings,
              );
            case '/warehouse':
              return MaterialPageRoute(
                builder: (_) => const Orders_employee(),
                settings: settings,
              );
            case '/delivery':
              // Placeholder for delivery employee
              return MaterialPageRoute(
                builder: (_) => const LoginScreen(),
                settings: settings,
              );
            default:
              print('⚠️ Unknown route: ${settings.name}, handling gracefully');
              // Don't redirect to login for unknown routes, let the home handle it
              return null;
          }
        },

        // FIXED: Better error handling
        builder: (context, widget) {
          if (widget == null) {
            print('❌ Widget is null, showing appropriate screen');
            return _getHomeScreen();
          }
          return widget;
        },

        // FIXED: Handle unknown routes gracefully
        onUnknownRoute: (RouteSettings settings) {
          print('❌ Unknown route: ${settings.name}, staying on current screen');
          // Return the appropriate home screen instead of forcing login
          return MaterialPageRoute(
            builder: (_) => _getHomeScreen(),
            settings: const RouteSettings(name: '/'),
          );
        },
      ),
    );
  }

  Widget _getHomeScreen() {
    print(
        '🏠 Getting home screen for logged in: $isLoggedIn, role: $currentRole');

    try {
      // FIXED: Always check authentication state, don't default to login
      if (!isLoggedIn || currentRole == null) {
        print('🔐 No valid authentication, showing LoginScreen');
        return const LoginScreen();
      }

      // FIXED: Route based on valid role
      switch (currentRole) {
        case 'Admin':
          print('👑 Showing DashboardScreen for Admin');
          return const DashboardScreen();
        case 'Supplier':
          print('🏪 Showing SupplierOrders for Supplier');
          return const SupplierOrders();
        case 'Customer':
          print('🛒 Showing CustomerOrders for Customer');
          return const CustomerOrders();
        case 'WareHouseEmployee':
          print('📦 Showing Orders_employee for WareHouseEmployee');
          return const Orders_employee();
        case 'DeliveryEmployee':
        case 'DeliveryMan':
          print(
              '🚚 Showing LoginScreen for DeliveryEmployee (not implemented yet)');
          return const LoginScreen();
        default:
          print('❓ Unknown role: $currentRole, showing LoginScreen');
          return const LoginScreen();
      }
    } catch (e) {
      print('❌ Error in _getHomeScreen: $e');
      return const LoginScreen();
    }
  }
}

// Test credentials (remove in production)
// admin - hamode.sh889@gmail.com - 123123 - id: 84
// supplier ahmad - hamode.sh334@gmail.com - yism5huFJGy6SfI- - id: 4
// customer - momoideh.123@yahoo.com - dHaeo_HFzzUEcYFH
// warehouse worker - mohammad.shaheen0808@gmail.com - 0S_1NPyVo-CQ5-EO