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
    apiKey: 'AIzaSyDlDlnG_03TqqjNr-bZB9QTAkin1L6F2-8',
    appId: '1:236339805910:web:15f97918bb5385c1b09377',
    messagingSenderId: '236339805910',
    projectId: 'storify-32241',
    authDomain: 'storify-32241.firebaseapp.com',
    storageBucket: 'storify-32241.firebasestorage.app',
    measurementId: 'G-PN0H7TT9PS',
  );
}
