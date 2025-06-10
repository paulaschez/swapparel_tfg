// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return windows;
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
    apiKey: 'AIzaSyCEj3VfNTjmNoTU_CnbY6pFJdYrcjRO0RI',
    appId: '1:121307270557:web:6d5f9c5ad1157cdbd03374',
    messagingSenderId: '121307270557',
    projectId: 'swapparel-v1',
    authDomain: 'swapparel-v1.firebaseapp.com',
    storageBucket: 'swapparel-v1.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA8lxJ87nymk_3riPwqcGFOuJKH4lHQWPI',
    appId: '1:121307270557:android:1f72b464b6b31269d03374',
    messagingSenderId: '121307270557',
    projectId: 'swapparel-v1',
    storageBucket: 'swapparel-v1.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCEj3VfNTjmNoTU_CnbY6pFJdYrcjRO0RI',
    appId: '1:121307270557:web:7740e132e7e9fe6cd03374',
    messagingSenderId: '121307270557',
    projectId: 'swapparel-v1',
    authDomain: 'swapparel-v1.firebaseapp.com',
    storageBucket: 'swapparel-v1.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB0XSRy1B1Pkp_RwCPCnhNaQVi7gcv-sFA',
    appId: '1:121307270557:ios:d51df9983ec44e4ad03374',
    messagingSenderId: '121307270557',
    projectId: 'swapparel-v1',
    storageBucket: 'swapparel-v1.firebasestorage.app',
    iosBundleId: 'com.example.chatApp',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB0XSRy1B1Pkp_RwCPCnhNaQVi7gcv-sFA',
    appId: '1:121307270557:ios:9b053639bde1deead03374',
    messagingSenderId: '121307270557',
    projectId: 'swapparel-v1',
    storageBucket: 'swapparel-v1.firebasestorage.app',
    iosBundleId: 'com.example.swapparel',
  );

}