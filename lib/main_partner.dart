import 'package:flutter/material.dart';
import 'app.dart';
import 'core/config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.flavor = AppFlavor.partner;
  runApp(const CampusConnectApp());
}
