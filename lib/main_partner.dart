import 'package:flutter/material.dart';
import 'app.dart';
import 'core/config.dart';
import 'core/firebase_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.flavor = AppFlavor.partner;
  await initFirebaseSafe();
  runApp(const CampusConnectApp());
}
