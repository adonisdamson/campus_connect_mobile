import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Canonical icon registry. ONE family (Phosphor), and every category resolves
/// to its OWN icon — no shared sparkles, no repeats. Resolution is by keyword
/// so it tolerates backend slugs ("hair_braiding", "Hair Braiding", "phones").
class CCIcons {
  /// Distinct icon per known keyword. Order matters: first match wins.
  static const _map = <String, IconData>{
    // ── Services ──
    'braid': PhosphorIconsRegular.hairDryer,
    'hair': PhosphorIconsRegular.hairDryer,
    'barber': PhosphorIconsRegular.scissors,
    'nail': PhosphorIconsRegular.paintBrush,
    'makeup': PhosphorIconsRegular.palette,
    'beauty': PhosphorIconsRegular.palette,
    'print': PhosphorIconsRegular.printer,
    'laundry': PhosphorIconsRegular.washingMachine,
    'wash': PhosphorIconsRegular.washingMachine,
    'photo': PhosphorIconsRegular.camera,
    'tutor': PhosphorIconsRegular.graduationCap,
    'class': PhosphorIconsRegular.graduationCap,
    'repair': PhosphorIconsRegular.wrench,
    'fix': PhosphorIconsRegular.wrench,
    'clean': PhosphorIconsRegular.broom,

    // ── Rides ──
    'economy': PhosphorIconsRegular.car,
    'premium': PhosphorIconsRegular.crown,
    'bike': PhosphorIconsRegular.motorcycle,
    'okada': PhosphorIconsRegular.motorcycle,
    'shared': PhosphorIconsRegular.usersThree,
    'pool': PhosphorIconsRegular.usersThree,
    'ride': PhosphorIconsRegular.carProfile,

    // ── Delivery ──
    'food': PhosphorIconsRegular.forkKnife,
    'parcel': PhosphorIconsRegular.package,
    'shopping': PhosphorIconsRegular.basket,
    'grocery': PhosphorIconsRegular.basket,
    'gas': PhosphorIconsRegular.gasCan,
    'courier': PhosphorIconsRegular.scooter,
    'delivery': PhosphorIconsRegular.scooter,

    // ── Marketplace ──
    'phone': PhosphorIconsRegular.deviceMobile,
    'laptop': PhosphorIconsRegular.laptop,
    'computer': PhosphorIconsRegular.desktop,
    'electronic': PhosphorIconsRegular.plug,
    'fashion': PhosphorIconsRegular.tShirt,
    'cloth': PhosphorIconsRegular.tShirt,
    'dress': PhosphorIconsRegular.dress,
    'shoe': PhosphorIconsRegular.sneaker,
    'sneaker': PhosphorIconsRegular.sneaker,
    'book': PhosphorIconsRegular.books,
    'furniture': PhosphorIconsRegular.couch,
    'gaming': PhosphorIconsRegular.gameController,
    'game': PhosphorIconsRegular.gameController,
    'watch': PhosphorIconsRegular.watch,
    'bag': PhosphorIconsRegular.handbag,
    'accessor': PhosphorIconsRegular.watch,
    'gift': PhosphorIconsRegular.gift,
  };

  static const fallback = PhosphorIconsRegular.tag;

  /// Resolve any category name / slug to its distinct icon.
  static IconData of(String? key) {
    if (key == null || key.isEmpty) return fallback;
    final k = key.toLowerCase();
    for (final e in _map.entries) {
      if (k.contains(e.key)) return e.value;
    }
    return fallback;
  }
}
