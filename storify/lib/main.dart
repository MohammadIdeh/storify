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
  // Just store the message, don't do anything heavy here
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🚀 Starting Storify app...');

    // Only initialize Firebase - nothing else that could block
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // Set up background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get auth status quickly
    final isLoggedIn = await AuthService.isLoggedIn();
    final currentRole = await AuthService.getCurrentRole();
    print('✅ Auth check completed');

    // Start the app IMMEDIATELY - no notification setup yet
    runApp(MyApp(isLoggedIn: isLoggedIn, currentRole: currentRole));
    print('✅ App started successfully');

    // Initialize notifications AFTER the app is running (completely non-blocking)
    _initializeNotificationsLater();
  } catch (e) {
    print('❌ Error in main: $e');

    // Even if there's an error, try to start the app
    runApp(MyApp(isLoggedIn: false, currentRole: null));
  }
}

// Initialize notifications completely in the background after app is running
void _initializeNotificationsLater() {
  // Wait a bit for the app to fully load, then initialize notifications
  Future.delayed(Duration(seconds: 2), () async {
    try {
      print('🔔 Starting background notification initialization...');

      // Quick, non-blocking notification setup
      await NotificationService.initialize();

      // Set up message handlers
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Foreground message received: ${message.messageId}");
        // Handle the message through NotificationService
      });

      // Handle notification clicks
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

      // Load existing notifications
      NotificationService().processBackgroundNotifications();
      NotificationService().loadNotificationsFromFirestore();

      print('✅ Notifications initialized in background');
    } catch (e) {
      print('❌ Error initializing notifications (non-critical): $e');
      // Don't throw - notifications are not critical for app function
    }
  });
}

// Helper function to handle navigation based on notification data
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
        home: _getHomeScreen(),
        // Add error handling
        builder: (context, widget) {
          return widget ??
              Container(
                color: Colors.white,
                child: Center(
                  child: Text('Loading...', style: TextStyle(fontSize: 18)),
                ),
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
          return const Orders();
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
      // Fallback to login screen if there's any error
      return const LoginScreen();
    }
  }
}

// Test credentials (remove in production)
// admin - hamode.sh889@gmail.com - 123456 - id: 84
// supplier ahmad - hamode.sh334@gmail.com - yism5huFJGy6SfI- - id: 4
// customer - momoideh.123@yahoo.com - dHaeo_HFzzUEcYFH
// warehouse worker - mohammad.shaheen0808@gmail.com - 0S_1NPyVo-CQ5-EO
