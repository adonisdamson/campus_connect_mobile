import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'theme.dart';

/// Network image with memory + disk caching, a branded placeholder, and a
/// graceful error fallback. Use everywhere instead of raw `Image.network` so
/// listing photos / avatars don't re-download on every rebuild or scroll.
class CCImage extends StatelessWidget {
  final String? url;
  final double? width, height;
  final BoxFit fit;
  final IconData fallbackIcon;

  const CCImage(this.url, {super.key, this.width, this.height, this.fit = BoxFit.cover, this.fallbackIcon = PhosphorIconsFill.image});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _fallback();
    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      // Cap decoded resolution to the display size to save memory on grids.
      memCacheWidth: width != null && width!.isFinite ? (width! * 2).round() : null,
      placeholder: (_, __) => Container(color: CC.surfaceHi, width: width, height: height),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => Container(
        width: width,
        height: height,
        color: CC.surfaceHi,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: CC.textFaint, size: 26),
      );
}
