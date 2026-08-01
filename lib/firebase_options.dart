// GENERATED PLACEHOLDER — bu faylni o'zingiz sozlashingiz kerak.
//
// Eng oson yo'l: terminalda quyidagini ishga tushiring, u sizning Firebase
// loyihangizga ulanib, shu faylni to'g'ri qiymatlar bilan avtomatik
// qayta yozadi:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Agar buni qo'lda to'ldirmoqchi bo'lsangiz, quyidagi qiymatlarni Firebase
// konsolidan oling: Project settings > General > Your apps > Android app
// (SDK setup and configuration).
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions bu platforma uchun sozlanmagan: $defaultTargetPlatform. '
          '"flutterfire configure" buyrug\'ini ishga tushiring.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBlawaH_vvwOAfUbYxlJWrmQJ19wehbpF0',
    appId: '1:551812341031:android:48b4e803b69e9af0cadd02',
    messagingSenderId: '551812341031',
    projectId: 'uztomicsms',
    storageBucket: 'uztomicsms.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME.appspot.com',
    iosBundleId: 'com.example.smstomic',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCAcymtpAbnwexaepRmC205Kfoo4ZDTw5I',
    appId: '1:551812341031:web:09aeddafd9f66058cadd02',
    messagingSenderId: '551812341031',
    projectId: 'uztomicsms',
    authDomain: 'uztomicsms.firebaseapp.com',
    storageBucket: 'uztomicsms.firebasestorage.app',
  );
}
