import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import 'home_screen.dart';
import 'more_screens.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});
  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _i = 0;
  final _pages = const [HomeScreen(), MarketplaceScreen(), ServicesScreen(), WalletScreen(), AccountScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: CC.surface,
          indicatorColor: CC.accent.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        ),
        child: NavigationBar(
          height: 66,
          selectedIndex: _i,
          onDestinationSelected: (v) { Haptics.select(); setState(() => _i = v); },
          destinations: const [
            NavigationDestination(icon: Icon(PhosphorIconsRegular.house), selectedIcon: Icon(PhosphorIconsFill.house, color: CC.lime), label: 'Home'),
            NavigationDestination(icon: Icon(PhosphorIconsRegular.storefront), selectedIcon: Icon(PhosphorIconsFill.storefront, color: CC.lime), label: 'Market'),
            NavigationDestination(icon: Icon(PhosphorIconsRegular.sparkle), selectedIcon: Icon(PhosphorIconsFill.sparkle, color: CC.lime), label: 'Services'),
            NavigationDestination(icon: Icon(PhosphorIconsRegular.wallet), selectedIcon: Icon(PhosphorIconsFill.wallet, color: CC.lime), label: 'Wallet'),
            NavigationDestination(icon: Icon(PhosphorIconsRegular.user), selectedIcon: Icon(PhosphorIconsFill.user, color: CC.lime), label: 'You'),
          ],
        ),
      ),
    );
  }
}
