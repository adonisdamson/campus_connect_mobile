import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'config.dart';
import 'theme.dart';

/// Campus Connect brand assets.
///
/// - [appIcon] is the real "pulse" launcher mark, flavor-aware (green / amber /
///   blue) — use it anywhere the product identity appears.
/// - [logo] is a code-rendered lockup (icon + wordmark in Plus Jakarta) that
///   adapts to the dark canvas; preferred over the raster lockup on dark UI.
/// - [illustration] serves the imported WebP art (with the legacy SVGs as a
///   fallback); [anim] serves the Lottie set.
class Brand {
  // ── Logo ──────────────────────────────────────────────────────────────
  static String _iconAsset([AppFlavor? flavor]) {
    switch (flavor ?? AppConfig.flavor) {
      case AppFlavor.partner:
        return 'assets/logo/app_icon_partner.png';
      case AppFlavor.admin:
        return 'assets/logo/app_icon_admin.png';
      case AppFlavor.user:
        return 'assets/logo/app_icon.png';
    }
  }

  /// The real flavor-aware app icon (rounded-square pulse mark).
  static Widget appIcon({double size = 56, AppFlavor? flavor, double radius = 0}) {
    final img = Image.asset(_iconAsset(flavor), width: size, height: size, fit: BoxFit.contain);
    if (radius <= 0) return img;
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: img);
  }

  /// Legacy single-colour geometric mark (tintable). Kept for back-compat.
  static Widget mark({double size = 40, Color? color}) => SvgPicture.asset(
        'assets/brand/mark.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color ?? CC.accent, BlendMode.srcIn),
      );

  /// Icon + wordmark lockup rendered in Plus Jakarta — adapts to dark UI.
  static Widget logo({double iconSize = 40, double textSize = 22, Color? accent}) {
    final c = accent ?? CC.accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        appIcon(size: iconSize, radius: iconSize * 0.26),
        SizedBox(width: iconSize * 0.34),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campus',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: textSize, height: 1.0, color: CC.text, letterSpacing: -0.6)),
            Text('Connect',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: textSize, height: 1.0, color: c, letterSpacing: -0.6)),
          ],
        ),
      ],
    );
  }

  /// Vector horizontal lockup — designed for LIGHT surfaces (dark wordmark).
  static Widget lockupVector({double height = 40}) =>
      SvgPicture.asset('assets/logo/lockup.svg', height: height);

  /// Full-bleed vector splash mark (dark canvas + pulse + wordmark, 1:1).
  static Widget splashVector({double size = 240}) =>
      SvgPicture.asset('assets/logo/splash.svg', width: size, height: size);

  // ── Illustrations ─────────────────────────────────────────────────────
  /// Names backed by imported WebP art. Anything else falls back to an SVG of
  /// the same name under assets/illustrations (legacy empty states).
  static const _raster = <String>{
    'onboard_community', 'onboard_connect', 'onboard_explore', 'empty_notifications',
    'ride_rating', 'ride_economy', 'ride_car', 'empty_location', 'ride_waiting',
    'driver_navigation', 'ride_pickup', 'driver_arrived', 'delivery_tracking',
    'ride_cancelled', 'order_confirmed', 'shopping_bag', 'delivery_success',
    'delivery_bike', 'empty_marketplace', 'empty_search', 'success_check',
    'empty_favorites', 'sell_upload', 'empty_map', 'admin_overview',
    'rewards_stars', 'empty_wallet', 'payment_card', 'reward_trophy',
    'ride_night', 'ride_hailing', 'ride_chat', 'earnings_growth',
    'analytics_growth', 'app_in_hand', 'verification_pending', 'verified_shield',
  };

  /// An on-brand illustration. [width] caps the size; height follows aspect.
  static Widget illustration(String name, {double size = 160, double? width}) {
    if (_raster.contains(name)) {
      return Image.asset('assets/illustrations/$name.webp', width: width ?? size, fit: BoxFit.contain);
    }
    return SvgPicture.asset('assets/illustrations/$name.svg', width: width ?? size, height: width ?? size);
  }

  // ── Lottie ────────────────────────────────────────────────────────────
  /// Available: loading · success · wallet · notifications.
  static Widget anim(String name,
          {double? size, bool repeat = true, BoxFit fit = BoxFit.contain}) =>
      Lottie.asset('assets/lottie/$name.json', width: size, height: size, repeat: repeat, fit: fit);
}
