import 'package:flutter/material.dart';
import '../../core/haptics.dart';
import 'admin_theme.dart';

/// Admin-native widgets — light graphite/aqua, never the dark user-app cards.

/// White card on the soft page, crisp hairline, no heavy shadow (Linear/Stripe).
class ACard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const ACard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AC.surface,
      borderRadius: BorderRadius.circular(AC.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AC.radius),
        onTap: onTap == null ? null : () { Haptics.tap(); onTap!(); },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AC.radius),
            border: Border.all(color: AC.line, width: 1),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Primary = aqua fill / white text. `outlined` = graphite hairline / graphite
/// text. Mirrors the user `CCButton` call shape so admin screens stay readable.
class AButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  final IconData? icon;
  final bool expand;
  const AButton(this.label, {super.key, this.onTap, this.outlined = false, this.icon, this.expand = true});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final fg = outlined ? AC.text : AC.onAccent;
    final btn = Material(
      color: outlined ? Colors.transparent : AC.accent,
      borderRadius: BorderRadius.circular(AC.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AC.radiusSm),
        onTap: disabled ? null : () { Haptics.tap(); onTap!(); },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AC.radiusSm),
            border: outlined ? Border.all(color: AC.line, width: 1.4) : null,
          ),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
              Flexible(
                child: Text(label,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: fg)),
              ),
            ]),
          ),
        ),
      ),
    );
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: expand ? SizedBox(width: double.infinity, child: btn) : IntrinsicWidth(child: btn),
    );
  }
}

/// Light text field — soft gray fill, hairline border, aqua focus ring.
class AField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType? keyboard;
  final bool obscure;
  const AField(this.hint, this.controller, {super.key, this.icon, this.keyboard, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      style: const TextStyle(color: AC.text, fontSize: 15, fontWeight: FontWeight.w500),
      cursorColor: AC.accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AC.textFaint, fontWeight: FontWeight.w500),
        prefixIcon: icon == null ? null : Icon(icon, color: AC.textFaint, size: 20),
        filled: true,
        fillColor: AC.surfaceHi,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AC.radiusSm), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AC.radiusSm), borderSide: const BorderSide(color: AC.line, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AC.radiusSm), borderSide: const BorderSide(color: AC.accent, width: 1.6)),
      ),
    );
  }
}
