import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/build_config.dart';
import '../firebase_options.dart';

/// Firebase etkin mi (başarılı init sonrası true).
bool firebaseEnabled = false;

Future<void> initFirebaseIfConfigured() async {
  if (!kIsWeb && !kFirebaseNativeReady) {
    firebaseEnabled = false;
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseEnabled = Firebase.apps.isNotEmpty;
  } catch (_) {
    firebaseEnabled = false;
  }
}
