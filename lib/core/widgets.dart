import 'package:flutter/material.dart';
import 'brand.dart';
import 'haptics.dart';
import 'theme.dart';

/// Primary filled button — tactile: dips + haptic on press.
class CCButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading, outlined;
  final IconData? icon;
  const CCButton(this.label, {super.key, this.onTap, this.loading = false, this.outlined = false, this.icon});

  @override
  State<CCButton> createState() => _CCButtonState();
}

class _CCButtonState extends State<CCButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null || widget.loading;
    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.loading ? 'Loading' : widget.label,
      child: Opacity(
      opacity: disabled ? 0.55 : 1,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Material(
          color: widget.outlined ? Colors.transparent : CC.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CC.radiusSm),
            side: widget.outlined ? const BorderSide(color: CC.line) : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(CC.radiusSm),
            onHighlightChanged: (v) => setState(() => _down = v && !disabled),
            onTap: disabled
                ? null
                : () {
                    Haptics.tap();
                    widget.onTap!();
                  },
            child: Container(
              height: 54,
              alignment: Alignment.center,
              child: widget.loading
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: widget.outlined ? CC.accent : CC.ink))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[Icon(widget.icon, size: 19, color: widget.outlined ? CC.text : CC.ink), const SizedBox(width: 9)],
                        Text(widget.label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: widget.outlined ? CC.text : CC.ink)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    ));
  }
}

/// Centres + caps content width on tablets / desktop (admin web) so layouts
/// never stretch into ugly full-bleed rows on large screens.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 640});
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

class CCField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboard;
  final IconData? icon;
  const CCField(this.hint, this.controller, {super.key, this.obscure = false, this.keyboard, this.icon});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: CC.text, fontSize: 15.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: CC.textFaint),
        prefixIcon: icon == null ? null : Icon(icon, color: CC.textFaint, size: 20),
        filled: true,
        fillColor: CC.surfaceHi,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CC.radiusSm), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CC.radiusSm),
          borderSide: BorderSide(color: CC.accent, width: 1.5),
        ),
      ),
    );
  }
}

/// Rounded surface card.
class CCCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;
  const CCCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? CC.surface,
      borderRadius: BorderRadius.circular(CC.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(CC.radius),
        onTap: onTap == null ? null : () { Haptics.tap(); onTap!(); },
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Initials avatar (no fake AI faces).
class CCAvatar extends StatelessWidget {
  final String initials;
  final double size;
  const CCAvatar(this.initials, {super.key, this.size = 44});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CC.accent.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: CC.accent.withValues(alpha: 0.4)),
      ),
      child: Text(initials, style: TextStyle(color: CC.accent, fontWeight: FontWeight.w800, fontSize: size * 0.36)),
    );
  }
}


/// Empty / error state.
class CCEmpty extends StatelessWidget {
  final IconData? icon;
  final String? illustration; // name in assets/illustrations (preferred)
  final String title, subtitle;
  final Widget? action;
  const CCEmpty({super.key, this.icon, this.illustration, required this.title, required this.subtitle, this.action})
      : assert(icon != null || illustration != null, 'Provide an icon or an illustration');
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              Brand.illustration(illustration!, size: 136)
            else
              Icon(icon, size: 48, color: CC.textFaint),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: CC.textDim)),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}
