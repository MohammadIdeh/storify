import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyD8vlQPEkPL5BgZbYpJw7qXQm5kJnKddZs",
    authDomain: "flutter-notifications01-c1b4a.firebaseapp.com",
    projectId: "flutter-notifications01-c1b4a",
    storageBucket: "flutter-notifications01-c1b4a.firebasestorage.app",
    messagingSenderId: "286672759586",
    appId: "1:286672759586:web:8bf79a23956b0c35c0137b",
    measurementId: "G-9480RWV50L",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyD8vlQPEkPL5BgZbYpJw7qXQm5kJnKddZs",
    authDomain: "flutter-notifications01-c1b4a.firebaseapp.com",
    projectId: "flutter-notifications01-c1b4a",
    storageBucket: "flutter-notifications01-c1b4a.firebasestorage.app",
    messagingSenderId: "286672759586",
    appId: "1:286672759586:web:8bf79a23956b0c35c0137b",
    measurementId: "G-9480RWV50L",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyD8vlQPEkPL5BgZbYpJw7qXQm5kJnKddZs",
    authDomain: "flutter-notifications01-c1b4a.firebaseapp.com",
    projectId: "flutter-notifications01-c1b4a",
    storageBucket: "flutter-notifications01-c1b4a.firebasestorage.app",
    messagingSenderId: "286672759586",
    appId: "1:286672759586:web:8bf79a23956b0c35c0137b",
    measurementId: "G-9480RWV50L",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyD8vlQPEkPL5BgZbYpJw7qXQm5kJnKddZs",
    authDomain: "flutter-notifications01-c1b4a.firebaseapp.com",
    projectId: "flutter-notifications01-c1b4a",
    storageBucket: "flutter-notifications01-c1b4a.firebasestorage.app",
    messagingSenderId: "286672759586",
    appId: "1:286672759586:web:8bf79a23956b0c35c0137b",
    measurementId: "G-9480RWV50L",
  );
}