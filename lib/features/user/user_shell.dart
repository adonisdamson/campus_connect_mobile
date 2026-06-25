import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/nav.dart';
import 'home_screen.dart';
import 'more_screens.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});
  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _i = 0;

  void _goTab(int i) {
    if (i == _i) return;
    setState(() => _i = i);
  }

  static const _items = [
    CCNavItem(PhosphorIconsRegular.house, PhosphorIconsFill.house, 'Home'),
    CCNavItem(PhosphorIconsRegular.storefront, PhosphorIconsFill.storefront, 'Market'),
    CCNavItem(PhosphorIconsRegular.squaresFour, PhosphorIconsFill.squaresFour, 'Services'),
    CCNavItem(PhosphorIconsRegular.wallet, PhosphorIconsFill.wallet, 'Wallet'),
    CCNavItem(PhosphorIconsRegular.user, PhosphorIconsFill.user, 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigateTab: _goTab),
      const MarketplaceScreen(),
      const ServicesScreen(),
      const WalletScreen(),
      const AccountScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _i, children: pages),
      bottomNavigationBar: CCBottomNav(items: _items, index: _i, onChanged: _goTab),
    );
  }
}
