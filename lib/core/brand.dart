import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'theme.dart';

/// Campus Connect brand assets. The mark is single-colour SVG so it tints to
/// the active flavour accent (lime / amber / violet). The wordmark is rendered
/// in Plus Jakarta Sans (via the app theme) so it stays crisp at any size.
class Brand {
  /// Just the geometric "connect" mark, tinted to [color] (defaults to accent).
  static Widget mark({double size = 40, Color? color}) {
    return SvgPicture.asset(
      'assets/brand/mark.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color ?? CC.accent, BlendMode.srcIn),
    );
  }

  /// Mark + wordmark lockup, e.g. for auth and headers.
  static Widget logo({double markSize = 40, double textSize = 22, Color? color}) {
    final c = color ?? CC.accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark(size: markSize, color: c),
        SizedBox(width: markSize * 0.32),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Campus',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: textSize, height: 1.0, color: CC.text, letterSpacing: -0.5)),
            Text('Connect',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: textSize, height: 1.0, color: c, letterSpacing: -0.5)),
          ],
        ),
      ],
    );
  }

  /// An on-brand illustration (from assets/illustrations) at [size].
  static Widget illustration(String name, {double size = 132}) {
    return SvgPicture.asset('assets/illustrations/$name.svg', width: size, height: size);
  }
}
