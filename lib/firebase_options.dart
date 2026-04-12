// ============================================================
// IMPORTANT: This is a PLACEHOLDER file.
// You MUST regenerate this file by running:
//
//   flutterfire configure
//
// This will connect your app to your Firebase project and
// generate the correct configuration for all platforms.
// ============================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Replace this file by running `flutterfire configure`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAnLTxsxkuE8X2EqUuSwz7fUV6JwDgKtRk',
    appId: '1:208488933623:android:f3ffdb1b30d51bacaa4bf2',
    messagingSenderId: '208488933623',
    projectId: 'gatment-f2b4e',
    storageBucket: 'gatment-f2b4e.firebasestorage.app',
  );

  // TODO: Replace with your actual Firebase config from flutterfire configure

  // TODO: Replace with your actual Firebase config from flutterfire configure
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-API-KEY',
    appId: 'YOUR-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'YOUR-PROJECT-ID',
    storageBucket: 'YOUR-STORAGE-BUCKET',
    iosBundleId: 'com.siddhivinayakgarments.app',
  );
}