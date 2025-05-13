import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  // static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD8vlQPEkPL5BgZbYpJw7qXQm5kJnKddZs",
        authDomain: "flutter-notifications01-c1b4a.firebaseapp.com",
        projectId: "flutter-notifications01-c1b4a",
        storageBucket: "flutter-notifications01-c1b4a.firebasestorage.app",
        messagingSenderId: "286672759586",
        appId: "1:286672759586:web:8bf79a23956b0c35c0137b",
        measurementId: "G-9480RWV50L",
      ),
    );

    // Request permission for notifications
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? token = await messaging.getToken();
    print('FCM Token: $token'); // You can store this token in your backend

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

// This needs to be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}
