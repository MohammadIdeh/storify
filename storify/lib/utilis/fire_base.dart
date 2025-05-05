import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
      apiKey: "AIzaSyD8vlQPEkPL5BgZbYpJw7qXQm5kJnKddZs",
      authDomain: "flutter-notifications01-c1b4a.firebaseapp.com",
      projectId: "flutter-notifications01-c1b4a",
      storageBucket: "flutter-notifications01-c1b4a.firebasestorage.app",
      messagingSenderId: "286672759586",
      appId: "1:286672759586:web:8bf79a23956b0c35c0137b",
      measurementId: "G-9480RWV50L");
}
