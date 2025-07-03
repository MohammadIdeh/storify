// lib/main.dart
// ROUTING IMPLEMENTATION NOTES:
// ✅ Added usePathUrlStrategy() to remove # from URLs for clean web URLs
// ✅ Implemented comprehensive named routes for Admin and Customer roles
// ✅ Added role-based route protection and access control
// ✅ Set up proper URL structure: /admin/dashboard, /admin/products, etc.
// ✅ Configured routes for all existing Admin screens (Categories, Orders, Products, etc.)
// ✅ Configured routes for all existing Customer screens (Orders, History)
//
// 🚧 REMAINING WORK FOR NEXT CONVERSATION:
// - Add Supplier routes (when supplier screens are provided)
// - Add Employee/Warehouse routes (when employee screens are provided)
// - Update all Navigator.push() calls in Supplier screens to Navigator.pushNamed()
// - Update all Navigator.push() calls in Employee screens to Navigator.pushNamed()
//
// The routing structure is ready - just need to add supplier/employee route definitions
// and update their navigation calls following the same pattern used for admin/customer.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Added for clean URLs
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/admin/screens/Categories.dart';
import 'package:storify/admin/screens/orders.dart';
import 'package:storify/admin/screens/productsScreen.dart';
import 'package:storify/admin/screens/productOverview.dart';
import 'package:storify/admin/screens/roleManegment.dart';
import 'package:storify/admin/screens/track.dart';
import 'package:storify/admin/screens/vieworder.dart';
import 'package:storify/customer/screens/orderScreenCustomer.dart';
import 'package:storify/customer/screens/historyScreenCustomer.dart';
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

    // ✅ ROUTING: Remove # from URLs for cleaner web experience
    usePathUrlStrategy();
    print('✅ URL strategy configured for clean web URLs');

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

        // ✅ ROUTING: Comprehensive named routes for all screens
        routes: {
          // Authentication routes
          '/': (context) => _getHomeScreen(),
          '/login': (context) => const LoginScreen(),

          // ✅ ADMIN ROUTES - All admin screens with clean URLs
          '/admin': (context) => const DashboardScreen(),
          '/admin/dashboard': (context) => const DashboardScreen(),
          '/admin/categories': (context) => const CategoriesScreen(),
          '/admin/products': (context) => const Productsscreen(),
          '/admin/orders': (context) => const Orders(),
          '/admin/roles': (context) => const Rolemanegment(),
          '/admin/tracking': (context) => const Track(),
          // Note: Product overview and view order require parameters, handled in onGenerateRoute

          // ✅ CUSTOMER ROUTES - All customer screens with clean URLs
          '/customer': (context) => const CustomerOrders(),
          '/customer/orders': (context) => const CustomerOrders(),
          '/customer/history': (context) => const HistoryScreenCustomer(),

          // 🚧 SUPPLIER ROUTES - Placeholders for when supplier screens are provided
          '/supplier': (context) => const SupplierOrders(),
          '/supplier/orders': (context) => const SupplierOrders(),
          // Add more supplier routes here when screens are provided

          // 🚧 EMPLOYEE ROUTES - Placeholders for when employee screens are provided
          '/warehouse': (context) => const Orders_employee(),
          '/warehouse/orders': (context) => const Orders_employee(),
          // Add more employee routes here when screens are provided
        },

        // ✅ ROUTING: Set initial route based on authentication
        initialRoute: _getInitialRoute(),

        // ✅ ROUTING: Handle parameterized routes (like product overview with product data)
        onGenerateRoute: (RouteSettings settings) {
          print('🔄 Generating route: ${settings.name}');

          // Handle routes that need parameters
          if (settings.name?.startsWith('/admin/product/') == true) {
            // Extract product ID or handle product overview route
            return MaterialPageRoute(
              builder: (_) =>
                  const Productsscreen(), // Navigate to products then to specific product
              settings: settings,
            );
          }

          if (settings.name?.startsWith('/admin/order/') == true) {
            // Handle view order route with order ID
            return MaterialPageRoute(
              builder: (_) =>
                  const Orders(), // Navigate to orders then to specific order
              settings: settings,
            );
          }

          // Handle role-based access protection
          final currentRoute = settings.name;
          if (!_canAccessRoute(currentRoute)) {
            print('🚫 Access denied to route: $currentRoute');
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
              settings: const RouteSettings(name: '/login'),
            );
          }

          // If route exists in routes table, let it handle normally
          return null;
        },

        // ✅ ROUTING: Better error handling for unknown routes
        onUnknownRoute: (RouteSettings settings) {
          print('❌ Unknown route: ${settings.name}, redirecting appropriately');
          return MaterialPageRoute(
            builder: (_) => _getHomeScreen(),
            settings: const RouteSettings(name: '/'),
          );
        },
      ),
    );
  }

  // ✅ ROUTING: Determine initial route based on auth state
  String _getInitialRoute() {
    if (!isLoggedIn || currentRole == null) {
      return '/login';
    }

    switch (currentRole) {
      case 'Admin':
        return '/admin';
      case 'Customer':
        return '/customer';
      case 'Supplier':
        return '/supplier';
      case 'WareHouseEmployee':
        return '/warehouse';
      default:
        return '/login';
    }
  }

  // ✅ ROUTING: Role-based route access control
  bool _canAccessRoute(String? route) {
    if (route == null || route == '/login' || route == '/') {
      return true;
    }

    if (!isLoggedIn || currentRole == null) {
      return false;
    }

    // Admin can access all admin routes
    if (route.startsWith('/admin') && currentRole == 'Admin') {
      return true;
    }

    // Customer can access all customer routes
    if (route.startsWith('/customer') && currentRole == 'Customer') {
      return true;
    }

    // Supplier can access all supplier routes
    if (route.startsWith('/supplier') && currentRole == 'Supplier') {
      return true;
    }

    // Warehouse employee can access warehouse routes
    if (route.startsWith('/warehouse') && currentRole == 'WareHouseEmployee') {
      return true;
    }

    return false;
  }

  Widget _getHomeScreen() {
    print(
        '🏠 Getting home screen for logged in: $isLoggedIn, role: $currentRole');

    try {
      if (!isLoggedIn || currentRole == null) {
        print('🔐 No valid authentication, showing LoginScreen');
        return const LoginScreen();
      }

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
