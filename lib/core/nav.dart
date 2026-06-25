import 'package:flutter/material.dart';
import 'haptics.dart';
import 'theme.dart';

class CCNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const CCNavItem(this.icon, this.activeIcon, this.label);
}

/// Bottom navigation — Uber/Bolt/Airbnb feel. Hairline top, no background
/// indicator pill or glow: the active tab is conveyed by a filled accent icon,
/// an accent label, and a short 3px accent rule. Everything animates ~200ms.
class CCBottomNav extends StatelessWidget {
  final List<CCNavItem> items;
  final int index;
  final ValueChanged<int> onChanged;
  const CCBottomNav({super.key, required this.items, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CC.ink2,
        border: Border(top: BorderSide(color: CC.hair, width: 1)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        height: 62,
        child: Row(
          children: List.generate(items.length, (i) {
            final it = items[i];
            final active = i == index;
            return Expanded(
              child: InkWell(
                onTap: () { if (i != index) Haptics.select(); onChanged(i); },
                splashColor: CC.tint(0.08),
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 3,
                      width: active ? 18 : 0,
                      margin: const EdgeInsets.only(bottom: 7),
                      decoration: BoxDecoration(color: CC.accent, borderRadius: BorderRadius.circular(CC.pill)),
                    ),
                    AnimatedScale(
                      scale: active ? 1.0 : 0.96,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Icon(active ? it.activeIcon : it.icon,
                          size: 24, color: active ? CC.accent : CC.textFaint),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                        color: active ? CC.accent : CC.textFaint,
                      ),
                      child: Text(it.label),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
