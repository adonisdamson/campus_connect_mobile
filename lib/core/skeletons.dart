import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'theme.dart';

/// Shimmering placeholders that mirror real content shape — far more premium
/// than a spinner. One Shimmer wraps the whole set for performance.
class Skeletons {
  static Widget _shimmer(Widget child) => Shimmer.fromColors(
        baseColor: CC.surfaceHi,
        highlightColor: CC.line,
        period: const Duration(milliseconds: 1300),
        child: child,
      );

  static Widget _box({double? w, double h = 14, double r = 8}) => Container(
        width: w, height: h,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(r)),
      );

  /// Card list (e.g. vendors, services, jobs).
  static Widget list({int count = 6}) => _shimmer(ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: count,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: CC.surface, borderRadius: BorderRadius.circular(CC.radius)),
          child: Row(children: [
            _box(w: 46, h: 46, r: 12),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(w: 160),
              const SizedBox(height: 8),
              _box(w: 90, h: 11),
            ])),
            _box(w: 48, h: 12),
          ]),
        ),
      ));

  /// Two-line tile rows (e.g. notifications, chats, users).
  static Widget tiles({int count = 8}) => _shimmer(ListView.separated(
        itemCount: count,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const Divider(color: CC.surface, height: 1),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            _box(w: 44, h: 44, r: 22),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(w: 140),
              const SizedBox(height: 8),
              _box(w: 200, h: 11),
            ])),
          ]),
        ),
      ));

  /// Product/listing grid.
  static Widget grid({int count = 6}) => _shimmer(GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 230, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.72),
        itemCount: count,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(color: CC.surface, borderRadius: BorderRadius.circular(CC.radius)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _box(h: double.infinity, r: CC.radius)),
            Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(w: 110),
              const SizedBox(height: 8),
              _box(w: 64, h: 11),
            ])),
          ]),
        ),
      ));
}
