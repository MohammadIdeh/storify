import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/admin/screens/dashboard.dart';
import 'package:storify/customer/screens/orderScreenCustomer.dart';
import 'package:storify/supplier/screens/ordersScreensSupplier.dart';
import 'package:storify/supplier/screens/productScreenSupplier.dart';
import 'package:storify/utilis/fire_base.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/utilis/notification_service.dart'; // Add NotificationModel import

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
  // This will be processed when the app is opened
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

  // Set up background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize our NotificationService which will handle permissions, etc.
  await NotificationService.initialize();

  // Set up foreground message handler through NotificationService
  // We're removing the direct handler since NotificationService will handle it
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground message received: ${message.messageId}");

    // The actual handling is done inside NotificationService
    // It's registered during NotificationService.initialize()

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

  // We'll implement navigation logic when we have a global navigator key
  // or through state management like Provider/Bloc

  print("Should navigate to: type=$notificationType, orderId=$orderId");

  // Example:
  // if (notificationType == 'new_order' && navigatorKey.currentContext != null) {
  //   Navigator.of(navigatorKey.currentContext!).pushNamed(
  //     '/supplier/orders',
  //     arguments: {'orderId': orderId},
  //   );
  // }
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
// admin
// hamode.sh889@gmail.com
// o83KUqRz-UIroMoI
// id: 84

// supplier
// hamode.sh334@gmail.com
// yism5huFJGy6SfI-
//

// customer
// momoideh.123@yahoo.com
// dHaeo_HFzzUEcYFH
///////////////
// momoideh@yahoo.com
// moQErFtTIHODBayH
