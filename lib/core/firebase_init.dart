import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initialise Firebase from the bundled per-flavor `google-services.json`.
/// Guarded so a missing / misconfigured Firebase project never blocks app
/// start-up — Google sign-in simply stays unavailable until it's set up.
Future<void> initFirebaseSafe() async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[Firebase] init skipped: $e');
  }
}
