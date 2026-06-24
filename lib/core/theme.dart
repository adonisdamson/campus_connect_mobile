import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config.dart';

/// Campus Connect — "Campus Neon Editorial".
/// Warm off-black canvas, one electric accent per flavor, oversized display
/// type (Plus Jakarta Sans) over DM Sans body, DM Mono for numbers.
class CC {
  // Canvas
  static const ink = Color(0xFF0E0F12); // darkest background
  static const surface = Color(0xFF17181E); // cards
  static const surfaceHi = Color(0xFF202128); // raised cards / inputs
  static const line = Color(0xFF2C2E37); // hairlines

  // Text
  static const text = Color(0xFFF4F5F7);
  static const textDim = Color(0xFF9DA1AD);
  static const textFaint = Color(0xFF6A6E7A);

  // Per-flavor accent (the differentiation anchor)
  static const lime = Color(0xFFCBFF3C); // user — electric lime
  static const amber = Color(0xFFFFB020); // partner — driver amber (Bolt-style)
  static const violet = Color(0xFF8B7CFF); // admin — control violet

  // Semantic
  static const success = Color(0xFF35D07F);
  static const warning = Color(0xFFFFB020);
  static const danger = Color(0xFFFF5A5A);

  static Color get accent => switch (AppConfig.flavor) {
        AppFlavor.user => lime,
        AppFlavor.partner => amber,
        AppFlavor.admin => violet,
      };

  /// Text that sits legibly on the accent fill.
  static Color get onAccent => AppConfig.isUser ? ink : ink;

  static const radius = 22.0;
  static const radiusSm = 14.0;
}

class AppTheme {
  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    const display = GoogleFonts.plusJakartaSans;
    const body = GoogleFonts.dmSans;

    return base.copyWith(
      scaffoldBackgroundColor: CC.ink,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CC.accent,
        brightness: Brightness.dark,
        surface: CC.surface,
      ).copyWith(primary: CC.accent, secondary: CC.accent, surface: CC.surface),
      textTheme: TextTheme(
        displayLarge: display(fontSize: 40, fontWeight: FontWeight.w800, color: CC.text, height: 1.02, letterSpacing: -1),
        displaySmall: display(fontSize: 30, fontWeight: FontWeight.w800, color: CC.text, height: 1.05, letterSpacing: -0.5),
        headlineMedium: display(fontSize: 24, fontWeight: FontWeight.w700, color: CC.text),
        titleLarge: display(fontSize: 19, fontWeight: FontWeight.w700, color: CC.text),
        titleMedium: display(fontSize: 16, fontWeight: FontWeight.w700, color: CC.text),
        bodyLarge: body(fontSize: 15.5, color: CC.text, height: 1.4),
        bodyMedium: body(fontSize: 14, color: CC.textDim, height: 1.4),
        labelLarge: display(fontSize: 14, fontWeight: FontWeight.w700, color: CC.text, letterSpacing: 0.3),
        labelSmall: body(fontSize: 12, color: CC.textFaint, letterSpacing: 0.4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: CC.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: display(fontSize: 20, fontWeight: FontWeight.w800, color: CC.text),
        iconTheme: const IconThemeData(color: CC.text),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: CC.surface,
        selectedItemColor: CC.text,
        unselectedItemColor: CC.textFaint,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      dividerColor: CC.line,
    );
  }

  /// DM Mono for prices, IDs, counts.
  static TextStyle mono({double size = 14, FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.dmMono(fontSize: size, fontWeight: weight, color: color ?? CC.text);
}
