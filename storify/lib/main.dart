import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/supplier/screens/productScreenSupplier.dart';
import 'package:storify/utilis/fire_base.dart';

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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request permission for notifications (important for web & iOS)
  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  // Set up foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground message received: ${message.messageId}");
    print("Message data: ${message.data}");

    if (message.notification != null) {
      print("Message notification title: ${message.notification!.title}");
      print("Message notification body: ${message.notification!.body}");

      // Here you could show a custom in-app notification
      // For example with a custom dialog or a snackbar
    }
  });

  // Handle notification clicks when app was terminated
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print("App opened from terminated state by notification");
      // You could navigate to a specific screen based on the notification data
      // For example: Navigator.pushNamed(context, '/notification_details', arguments: message.data);
    }
  });

  // Handle notification clicks when app was in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("App opened from background state by notification");
    // You could navigate to a specific screen based on the notification data
    // For example: Navigator.pushNamed(context, '/notification_details', arguments: message.data);
  });

  // Get FCM token (you'll later send this to your backend)
  String? token = await FirebaseMessaging.instance.getToken();
  print("🔔 FCM Token: $token");

  // Optional: Set up token refresh listener
  FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
    print("🔔 FCM Token refreshed: $newToken");
    // Here you would send the new token to your backend
  });

  // Optional: Subscribe to topics
  // await FirebaseMessaging.instance.subscribeToTopic('general');

  final isLoggedIn = await AuthService.isLoggedIn();
  final currentRole = await AuthService.getCurrentRole();

  runApp(MyApp(isLoggedIn: isLoggedIn, currentRole: currentRole));
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
        return const SupplierProducts();
      case 'Customer':
      case 'Employee':
      case 'DeliveryMan':
        return const LoginScreen(); // placeholder
      default:
        return const LoginScreen();
    }
  }
}

//admin
// hamode.sh889@gmail.com
// o83KUqRz-UIroMoI
// id: 84

//supplier
// hamode.sh334@gmail.com
// yism5huFJGy6SfI-
// GET    https://finalproject-a5ls.onrender.com/request-product/
