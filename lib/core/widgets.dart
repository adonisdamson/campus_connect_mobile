import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'brand.dart';
import 'haptics.dart';
import 'theme.dart';

// ─────────────────────────────────────────────────────────────────────────
// BUTTONS
// ─────────────────────────────────────────────────────────────────────────

enum CCVariant { primary, secondary, ghost, danger, success }

/// The one button. Variants cover every CTA in the app; press = 140ms dip +
/// haptic + Material ripple. Back-compat: `outlined: true` maps to secondary.
class CCButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool outlined; // legacy → secondary
  final IconData? icon;
  final CCVariant? variant;
  final bool expand; // stretch to full width
  final bool small;

  const CCButton(
    this.label, {
    super.key,
    this.onTap,
    this.loading = false,
    this.outlined = false,
    this.icon,
    this.variant,
    this.expand = true,
    this.small = false,
  });

  CCVariant get _v => variant ?? (outlined ? CCVariant.secondary : CCVariant.primary);

  @override
  State<CCButton> createState() => _CCButtonState();
}

class _CCButtonState extends State<CCButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final v = widget._v;
    final disabled = widget.onTap == null || widget.loading;

    final (Color fill, Color fg, Color? border) = switch (v) {
      CCVariant.primary => (CC.accent, CC.onAccent, null),
      CCVariant.secondary => (Colors.transparent, CC.text, CC.line),
      CCVariant.ghost => (Colors.transparent, CC.textDim, null),
      CCVariant.danger => (CC.danger, Colors.white, null),
      CCVariant.success => (CC.success, CC.ink, null),
    };
    final h = widget.small ? 48.0 : 54.0; // 48px min touch target (a11y)
    final r = widget.small ? CC.radiusSm : CC.radiusMd;

    final child = AnimatedScale(
      scale: _down ? 0.975 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Opacity(
        opacity: disabled && !widget.loading ? 0.45 : 1,
        child: Material(
          color: fill,
          borderRadius: BorderRadius.circular(r),
          child: InkWell(
            borderRadius: BorderRadius.circular(r),
            splashColor: fg.withValues(alpha: 0.10),
            highlightColor: fg.withValues(alpha: 0.05),
            onHighlightChanged: (d) => setState(() => _down = d && !disabled),
            onTap: disabled ? null : () { Haptics.tap(); widget.onTap!(); },
            child: Container(
              height: h,
              padding: EdgeInsets.symmetric(horizontal: widget.small ? 18 : 24),
              alignment: Alignment.center,
              decoration: border == null
                  ? null
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(r),
                      border: Border.all(color: border, width: 1.4),
                    ),
              child: widget.loading
                  ? SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: v == CCVariant.secondary || v == CCVariant.ghost ? CC.accent : fg))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 20, color: fg),
                          const SizedBox(width: 9),
                        ],
                        Flexible(
                          child: Text(widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: widget.small ? 14.5 : 15.5, color: fg)),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.loading ? 'Loading' : widget.label,
      child: widget.expand ? SizedBox(width: double.infinity, child: child) : IntrinsicWidth(child: child),
    );
  }
}

/// Docked full-width CTA: hairline top + safe-area padding over the canvas.
/// Use at the bottom of checkout / detail screens.
class CCFloatingCTA extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;
  final CCVariant variant;
  final Widget? leading; // e.g. a price block on the left
  const CCFloatingCTA(this.label,
      {super.key, this.onTap, this.loading = false, this.icon, this.variant = CCVariant.primary, this.leading});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CC.ink,
        border: Border(top: BorderSide(color: CC.hair, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(children: [
        if (leading != null) ...[leading!, const SizedBox(width: 16)],
        Expanded(child: CCButton(label, loading: loading, icon: icon, variant: variant, onTap: onTap)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// LAYOUT
// ─────────────────────────────────────────────────────────────────────────

/// Centres + caps content width on tablets / desktop so layouts never stretch
/// into ugly full-bleed rows on large screens.
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

/// Section header: large title + optional trailing action ("See all").
class CCSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;
  const CCSectionHeader(this.title,
      {super.key, this.actionLabel, this.onAction, this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 12)});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (actionLabel != null)
            GestureDetector(
              onTap: () { Haptics.tap(); onAction?.call(); },
              child: Row(children: [
                Text(actionLabel!, style: const TextStyle(color: CC.textDim, fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(width: 2),
                const Icon(PhosphorIconsRegular.caretRight, size: 14, color: CC.textDim),
              ]),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// INPUTS
// ─────────────────────────────────────────────────────────────────────────

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
      style: const TextStyle(color: CC.text, fontSize: 15.5, fontWeight: FontWeight.w500),
      cursorColor: CC.accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: CC.textFaint, fontWeight: FontWeight.w500),
        prefixIcon: icon == null ? null : Icon(icon, color: CC.textFaint, size: 20),
        filled: true,
        fillColor: CC.surfaceHi,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CC.radiusSm), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CC.radiusSm), borderSide: const BorderSide(color: CC.line, width: 1)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CC.radiusSm),
          borderSide: BorderSide(color: CC.accent, width: 1.6),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// SURFACES & MEDIA
// ─────────────────────────────────────────────────────────────────────────

/// Rounded surface card with very subtle elevation (border, no heavy shadow).
class CCCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;
  final double? radius;
  final bool border;
  const CCCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.color,
      this.onTap,
      this.radius,
      this.border = true});

  @override
  Widget build(BuildContext context) {
    final r = radius ?? CC.radius;
    return Material(
      color: color ?? CC.surface,
      borderRadius: BorderRadius.circular(r),
      child: InkWell(
        borderRadius: BorderRadius.circular(r),
        onTap: onTap == null ? null : () { Haptics.tap(); onTap!(); },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            border: border ? Border.all(color: CC.line, width: 1) : null,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Cached network image with a branded placeholder + fallback. Photography is
/// API-driven, so this is the standard way to show any remote photo.
class CCNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  const CCNetworkImage(this.url,
      {super.key, this.width, this.height, this.fit = BoxFit.cover, this.radius = CC.radiusMd});

  Widget _fallback() => Container(
        width: width,
        height: height,
        color: CC.surfaceHi,
        alignment: Alignment.center,
        child: const Icon(PhosphorIconsRegular.image, color: CC.textFaint, size: 26),
      );

  @override
  Widget build(BuildContext context) {
    final has = url != null && url!.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: has
          ? CachedNetworkImage(
              imageUrl: url!,
              width: width,
              height: height,
              fit: fit,
              placeholder: (_, __) => Container(width: width, height: height, color: CC.surfaceHi),
              errorWidget: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }
}

/// Initials avatar (no fake AI faces).
class CCAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final String? imageUrl;
  const CCAvatar(this.initials, {super.key, this.size = 44, this.imageUrl});
  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return ClipOval(child: CCNetworkImage(imageUrl, width: size, height: size, radius: size));
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CC.tint(0.16),
        shape: BoxShape.circle,
        border: Border.all(color: CC.tint(0.38)),
      ),
      child: Text(initials,
          style: TextStyle(color: CC.accent, fontWeight: FontWeight.w700, fontSize: size * 0.36)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// CHIPS & BADGES
// ─────────────────────────────────────────────────────────────────────────

/// Filter / category chip. Selected = subtle accent tint, not a glowing pill.
class CCChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;
  const CCChip(this.label, {super.key, this.selected = false, this.icon, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { Haptics.select(); onTap?.call(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: icon != null ? 12 : 15, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? CC.tint(0.14) : CC.surface,
          borderRadius: BorderRadius.circular(CC.pill),
          border: Border.all(color: selected ? CC.tint(0.55) : CC.line, width: 1.2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: selected ? CC.accent : CC.textDim),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                  color: selected ? CC.text : CC.textDim,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13.5)),
        ]),
      ),
    );
  }
}

enum CCBadgeTone { neutral, accent, success, warning, danger }

/// Compact label — verified, condition, "Fast", ETA, etc.
class CCBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final CCBadgeTone tone;
  const CCBadge(this.label, {super.key, this.icon, this.tone = CCBadgeTone.neutral});
  @override
  Widget build(BuildContext context) {
    final c = switch (tone) {
      CCBadgeTone.neutral => CC.textDim,
      CCBadgeTone.accent => CC.accent,
      CCBadgeTone.success => CC.success,
      CCBadgeTone.warning => CC.warning,
      CCBadgeTone.danger => CC.danger,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon != null ? 8 : 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: tone == CCBadgeTone.neutral ? CC.ink3 : c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(CC.radiusXs),
        border: Border.all(color: tone == CCBadgeTone.neutral ? CC.line : c.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: c), const SizedBox(width: 4)],
        Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 11.5)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// EMPTY / ERROR STATES
// ─────────────────────────────────────────────────────────────────────────

/// Every empty/error screen gets art — never text-only. Provide one of:
/// [anim] (Lottie name), [illustration] (asset name, framed on a light panel),
/// or [icon] as a last resort.
class CCEmpty extends StatelessWidget {
  final IconData? icon;
  final String? illustration;
  final String? anim;
  final String title, subtitle;
  final Widget? action;
  const CCEmpty(
      {super.key,
      this.icon,
      this.illustration,
      this.anim,
      required this.title,
      required this.subtitle,
      this.action})
      : assert(icon != null || illustration != null || anim != null,
            'Provide an icon, illustration, or anim');

  @override
  Widget build(BuildContext context) {
    Widget art;
    if (anim != null) {
      art = Brand.anim(anim!, size: 150);
    } else if (illustration != null) {
      // Illustrations carry a light background → frame them on a soft panel so
      // they read as an intentional sticker on the dark canvas.
      art = Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(CC.radiusLg),
          border: Border.all(color: CC.line),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CC.radiusMd),
          child: Brand.illustration(illustration!, width: 188),
        ),
      );
    } else {
      art = Container(
        width: 76, height: 76,
        decoration: BoxDecoration(color: CC.surface, shape: BoxShape.circle, border: Border.all(color: CC.line)),
        child: Icon(icon, size: 32, color: CC.textFaint),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            art,
            const SizedBox(height: 22),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: CC.textDim, fontSize: 14.5, height: 1.45)),
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    );
  }
}
