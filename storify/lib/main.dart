import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/customer/screens/orderScreenCustomer.dart';
import 'package:storify/supplier/screens/ordersScreensSupplier.dart';
import 'package:storify/utilis/firebase_options.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/utilis/notification_service.dart';

// This must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling background message: ${message.messageId}");
  print("Background message data: ${message.data}");
  if (message.notification != null) {
    print("Background notification title: ${message.notification!.title}");
    print("Background notification body: ${message.notification!.body}");
  }

  // Store notification for later processing
  final notification = NotificationItem.fromFirebaseMessage(message);
  // We can't directly access NotificationService's instance methods here
  // The storage will happen in NotificationService.initialize() when app starts
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Firebase initialized successfully');

  // Set up background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize our NotificationService which will handle permissions, etc.
  await NotificationService.initialize();
  
  // Process any background notifications
  await NotificationService().processBackgroundNotifications();
  
  // Force load notifications from Firestore
  await NotificationService().loadNotificationsFromFirestore();

  // Set up foreground message handler through NotificationService
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground message received: ${message.messageId}");

    // For debugging:
    print("Message data: ${message.data}");
    if (message.notification != null) {
      print("Message notification title: ${message.notification!.title}");
      print("Message notification body: ${message.notification!.body}");
    }
  });

  // Handle notification clicks using our NotificationService
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print("App opened from terminated state by notification");
      // Create notification item from the message
      final notification = NotificationItem.fromFirebaseMessage(message);

      // Process notification - this will happen after UI is initialized
      Future.delayed(Duration(seconds: 1), () {
        handleNotificationNavigation(message.data);
      });
    }
  });

  // Handle notification clicks when app was in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("App opened from background state by notification");
    // Navigate based on notification data
    handleNotificationNavigation(message.data);
  });

  final isLoggedIn = await AuthService.isLoggedIn();
  final currentRole = await AuthService.getCurrentRole();

  runApp(MyApp(isLoggedIn: isLoggedIn, currentRole: currentRole));
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
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _getHomeScreen(),
      ),
    );
  }

  Widget _getHomeScreen() {
    if (!isLoggedIn) {
      return const LoginScreen();
    }

    switch (currentRole) {
      case 'Admin':
        return const DashboardScreen();
      case 'Supplier':
        return const SupplierOrders();
      case 'Customer':
        return const CustomerOrders();
      case 'Employee':
        return const LoginScreen(); // placeholder
      case 'DeliveryMan':
        return const LoginScreen(); // placeholder
      default:
        return const LoginScreen();
    }
  }
}