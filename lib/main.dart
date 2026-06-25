// Default entrypoint = User app. Build flavors with:
//   flutter run -t lib/main_user.dart
//   flutter run -t lib/main_partner.dart
//   flutter run -t lib/main_admin.dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/config.dart';
import 'core/firebase_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.flavor = AppFlavor.user;
  await initFirebaseSafe();
  runApp(const CampusConnectApp());
}
