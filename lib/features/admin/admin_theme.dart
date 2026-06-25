import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Admin design system — deliberately *different* from the user/partner apps.
///
/// Where the consumer apps are a dark, youthful canvas, the admin console is a
/// light **graphite + aqua** workspace in the spirit of Linear / Stripe /
/// Vercel / Notion: white cards on a soft gray page, crisp hairlines, graphite
/// type, one cool aqua accent. Token NAMES mirror the user app's `CC` so the
/// admin screens read the same, but every value is its own light-mode set.
class AC {
  // ── Canvas (light) ──────────────────────────────────────────────────────
  static const canvas = Color(0xFFF7F8FA); // page background
  static const surface = Color(0xFFFFFFFF); // cards
  static const surfaceHi = Color(0xFFF1F3F6); // inputs, insets, thumbnails
  static const line = Color(0xFFE4E7EC); // hairline borders
  static const hair = Color(0xFFEEF0F3); // ultra-subtle separators

  // `ink` in the admin set is the colour that sits ON the accent (white) — the
  // admin screens use it for text/icons over aqua fills. The dark image
  // lightbox sets its own literal colour.
  static const ink = Color(0xFFFFFFFF);

  // ── Text (graphite) ─────────────────────────────────────────────────────
  static const text = Color(0xFF0F1419);
  static const textDim = Color(0xFF5A6472);
  static const textFaint = Color(0xFF98A1AE);

  // ── Accent (aqua) ───────────────────────────────────────────────────────
  static const accent = Color(0xFF06B6D4);
  static const violet = accent; // alias: admin screens reference `violet`
  static const onAccent = Color(0xFFFFFFFF);
  static Color tint(double a) => accent.withValues(alpha: a);

  // ── Semantic (tuned for a light background) ───────────────────────────────
  static const success = Color(0xFF15A34A);
  static const warning = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);

  // ── Geometry (shared scale) ───────────────────────────────────────────────
  static const radiusXs = 10.0;
  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radius = 18.0;
  static const radiusLg = 24.0;
  static const pill = 999.0;
}

class AdminTheme {
  static ThemeData build() {
    final base = ThemeData.light(useMaterial3: true);
    TextStyle jakarta(double size, FontWeight w, {Color? color, double height = 1.2, double ls = 0}) =>
        GoogleFonts.plusJakartaSans(
            fontSize: size, fontWeight: w, color: color ?? AC.text, height: height, letterSpacing: ls);

    return base.copyWith(
      scaffoldBackgroundColor: AC.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AC.accent,
        brightness: Brightness.light,
        surface: AC.surface,
      ).copyWith(primary: AC.accent, surface: AC.surface, surfaceTint: Colors.transparent),
      splashColor: AC.accent.withValues(alpha: 0.08),
      highlightColor: AC.accent.withValues(alpha: 0.05),
      textTheme: TextTheme(
        displaySmall: jakarta(28, FontWeight.w700, height: 1.08, ls: -0.6),
        headlineMedium: jakarta(23, FontWeight.w700, ls: -0.4),
        titleLarge: jakarta(19, FontWeight.w700, ls: -0.2),
        titleMedium: jakarta(16, FontWeight.w600),
        bodyLarge: jakarta(15, FontWeight.w500, color: AC.text, height: 1.45),
        bodyMedium: jakarta(13.5, FontWeight.w500, color: AC.textDim, height: 1.45),
        labelLarge: jakarta(14, FontWeight.w600, ls: 0.1),
        labelMedium: jakarta(13, FontWeight.w600, color: AC.textDim),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AC.surface,
        foregroundColor: AC.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: jakarta(19, FontWeight.w700, ls: -0.3),
        iconTheme: const IconThemeData(color: AC.text),
        shape: const Border(bottom: BorderSide(color: AC.line, width: 1)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AC.surface,
        indicatorColor: AC.accent.withValues(alpha: 0.14),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(jakarta(12, FontWeight.w600, color: AC.textDim)),
        iconTheme: WidgetStateProperty.resolveWith((s) =>
            IconThemeData(color: s.contains(WidgetState.selected) ? AC.accent : AC.textDim, size: 24)),
      ),
      dividerColor: AC.hair,
      dividerTheme: const DividerThemeData(color: AC.hair, thickness: 1, space: 1),
    );
  }
}
