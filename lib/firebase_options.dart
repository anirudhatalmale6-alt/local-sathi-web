import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB8rbRBZodVqfGT3OeiXsIjsB5BOUtKG_4',
    appId: '1:342397239071:web:05ecc60d93da1966883a2a',
    messagingSenderId: '342397239071',
    projectId: 'local-sathi-eced8',
    authDomain: 'local-sathi-eced8.firebaseapp.com',
    storageBucket: 'local-sathi-eced8.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDNOCIYHqUr-D3qX0Hk5on8dykkvrhB5tY',
    appId: '1:342397239071:android:bce1b31740039b24883a2a',
    messagingSenderId: '342397239071',
    projectId: 'local-sathi-eced8',
    storageBucket: 'local-sathi-eced8.firebasestorage.app',
  );

  // TODO: Add iOS config when iOS app is registered in Firebase
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDNOCIYHqUr-D3qX0Hk5on8dykkvrhB5tY',
    appId: '1:342397239071:android:17b8b78306d5bfdd883a2a',
    messagingSenderId: '342397239071',
    projectId: 'local-sathi-eced8',
    storageBucket: 'local-sathi-eced8.firebasestorage.app',
    iosBundleId: 'com.localsathi.app',
  );
}
