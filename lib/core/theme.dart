import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config.dart';

/// Campus Connect design system — V4.
///
/// One main tone (warm near-black canvas), one sharp accent per flavor, generous
/// negative space. Plus Jakarta Sans throughout (weights 500/600/700). Token
/// NAMES are stable across the app; only values evolve here.
class CC {
  // ── Canvas (dark ramp — never pure black) ─────────────────────────────
  static const ink = Color(0xFF0B0D10); // base scaffold
  static const ink2 = Color(0xFF111318); // sections / sheets
  static const ink3 = Color(0xFF17191E); // deeper inset panels
  static const surface = Color(0xFF1A1D23); // cards
  static const surfaceHi = Color(0xFF21242B); // raised cards / inputs
  static const line = Color(0xFF262A33); // hairline borders
  static const hair = Color(0xFF1E222A); // ultra-subtle separators

  // ── Text ──────────────────────────────────────────────────────────────
  static const text = Color(0xFFF4F5F7); // soft white
  static const textDim = Color(0xFF9DA1AD);
  static const textFaint = Color(0xFF6A6E7A);

  // ── Accents (the per-flavor differentiation anchor) ───────────────────
  static const lime = Color(0xFF00C853); // user — Campus Connect brand green (matches logo)
  static const amber = Color(0xFFFFB020); // partner — driver amber
  static const aqua = Color(0xFF31D0E6); // admin — aqua blue (Linear/Stripe)
  static const violet = Color(0xFF8B7CFF); // legacy alias (kept for back-compat)

  // ── Semantic ───────────────────────────────────────────────────────────
  static const success = Color(0xFF35D07F);
  static const warning = Color(0xFFFFB020);
  static const danger = Color(0xFFFF5A5A);

  // ── Rider operational status ──────────────────────────────────────────
  static const statusOnline = Color(0xFF35D07F);
  static const statusBusy = Color(0xFFFF9F1C);
  static const statusOffline = Color(0xFF6A6E7A);

  static Color get accent => switch (AppConfig.flavor) {
        AppFlavor.user => lime,
        AppFlavor.partner => amber,
        AppFlavor.admin => aqua,
      };

  /// Legible text/icon colour on top of the accent fill (all accents are bright
  /// → ink reads best).
  static Color get onAccent => ink;

  /// Accent at low opacity — for subtle tints (nav active, chips, avatars).
  static Color tint(double a) => accent.withValues(alpha: a);

  // ── Radii scale (no single "everything is a big pill" radius) ─────────
  static const radiusXs = 10.0;
  static const radiusSm = 14.0;
  static const radiusMd = 18.0;
  static const radius = 22.0;
  static const radiusLg = 28.0;
  static const pill = 999.0;

  // ── Spacing rhythm ─────────────────────────────────────────────────────
  static const gap = 16.0; // base unit
  static const gapLg = 24.0;
  static const screenPad = EdgeInsets.symmetric(horizontal: 20);
}

class AppTheme {
  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    TextStyle jakarta(double size, FontWeight w,
            {Color? color, double height = 1.2, double ls = 0}) =>
        GoogleFonts.plusJakartaSans(
            fontSize: size, fontWeight: w, color: color ?? CC.text, height: height, letterSpacing: ls);

    return base.copyWith(
      scaffoldBackgroundColor: CC.ink,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CC.accent,
        brightness: Brightness.dark,
        surface: CC.surface,
      ).copyWith(primary: CC.accent, surface: CC.surface, surfaceTint: Colors.transparent),
      splashColor: CC.accent.withValues(alpha: 0.10),
      highlightColor: CC.accent.withValues(alpha: 0.06),
      textTheme: TextTheme(
        displayLarge: jakarta(40, FontWeight.w700, height: 1.04, ls: -1.0),
        displayMedium: jakarta(34, FontWeight.w700, height: 1.05, ls: -0.8),
        displaySmall: jakarta(28, FontWeight.w700, height: 1.08, ls: -0.6),
        headlineMedium: jakarta(23, FontWeight.w700, ls: -0.4),
        titleLarge: jakarta(19, FontWeight.w700, ls: -0.2),
        titleMedium: jakarta(16, FontWeight.w600),
        bodyLarge: jakarta(15.5, FontWeight.w500, color: CC.text, height: 1.45),
        bodyMedium: jakarta(14, FontWeight.w500, color: CC.textDim, height: 1.45),
        labelLarge: jakarta(14, FontWeight.w600, ls: 0.1),
        labelMedium: jakarta(13, FontWeight.w600, color: CC.textDim),
        labelSmall: jakarta(12.5, FontWeight.w500, color: CC.textFaint, ls: 0.2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: CC.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: jakarta(20, FontWeight.w700, ls: -0.3),
        iconTheme: const IconThemeData(color: CC.text),
      ),
      dividerColor: CC.hair,
      dividerTheme: const DividerThemeData(color: CC.hair, thickness: 1, space: 1),
    );
  }

  /// Numerals (prices, IDs, counts) — Plus Jakarta with tabular figures so
  /// columns align. Single type family per the V4 spec.
  static TextStyle mono({double size = 14, FontWeight weight = FontWeight.w600, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color ?? CC.text,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: 0.2,
      );
}
