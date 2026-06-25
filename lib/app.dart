import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_screens.dart';
import 'features/user/cart.dart';
import 'features/user/user_shell.dart';
import 'features/partner/partner_app.dart';
import 'features/admin/admin_app.dart';
import 'features/admin/admin_theme.dart';

class CampusConnectApp extends StatelessWidget {
  const CampusConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..bootstrap()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return switch (auth.state) {
      AuthState.unknown => const SplashScreen(),
      AuthState.signedOut => const LoginScreen(),
      AuthState.signedIn => switch (AppConfig.flavor) {
          AppFlavor.user => const UserShell(),
          AppFlavor.partner => const PartnerShell(),
          AppFlavor.admin => Theme(data: AdminTheme.build(), child: const AdminShell()),
        },
    };
  }
}
