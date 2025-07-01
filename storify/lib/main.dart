// lib/main.dart
// Fixed version with better route handling and navigation
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
    print('🎨 Building MyApp widget...');

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

        // FIXED: Better route handling
        routes: {
          '/login': (context) => const LoginScreen(),
          '/admin': (context) => const DashboardScreen(),
          '/supplier': (context) => const SupplierOrders(),
          '/customer': (context) => const CustomerOrders(),
          '/warehouse': (context) => const Orders_employee(),
        },

        // FIXED: Always set login as initial route and handle navigation programmatically
        initialRoute: '/login',

        // FIXED: Better home logic
        home: _getHomeScreen(),

        // FIXED: Better error handling and fallback
        onGenerateRoute: (RouteSettings settings) {
          print('🔄 Generating route: ${settings.name}');

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
            default:
              print('❌ Unknown route: ${settings.name}, redirecting to login');
              return MaterialPageRoute(
                builder: (_) => const LoginScreen(),
                settings: const RouteSettings(name: '/login'),
              );
          }
        },

        // FIXED: Better error handling
        builder: (context, widget) {
          if (widget == null) {
            print('❌ Widget is null, showing login screen');
            return const LoginScreen();
          }

          return widget;
        },

        // FIXED: Handle unknown routes
        onUnknownRoute: (RouteSettings settings) {
          print('❌ Unknown route: ${settings.name}, redirecting to login');
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
            settings: const RouteSettings(name: '/login'),
          );
        },
      ),
    );
  }

  Widget _getHomeScreen() {
    print(
        '🏠 Getting home screen for logged in: $isLoggedIn, role: $currentRole');

    try {
      if (!isLoggedIn) {
        print('🔐 Showing LoginScreen');
        return const LoginScreen();
      }

      switch (currentRole) {
        case 'Admin':
          print('👑 Showing DashboardScreen for Admin');
          return const DashboardScreen();
        case 'Supplier':
          print('🏪 Showing SupplierOrders');
          return const SupplierOrders();
        case 'Customer':
          print('🛒 Showing CustomerOrders');
          return const CustomerOrders();
        case 'WareHouseEmployee':
          print('📦 Showing Orders_employee');
          return const Orders_employee();
        case 'DeliveryMan':
          print('🚚 Showing LoginScreen (DeliveryMan placeholder)');
          return const LoginScreen();
        default:
          print('❓ Unknown role, showing LoginScreen');
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
// warehouse worker - mohammad.shaheen0808@gmail.com -  
