import 'package:flutter/foundation.dart';

/// The three Campus Connect apps share one codebase via a flavor switch.
enum AppFlavor { user, partner, admin }

class AppConfig {
  static AppFlavor flavor = AppFlavor.user;

  static bool get isUser => flavor == AppFlavor.user;
  static bool get isPartner => flavor == AppFlavor.partner;
  static bool get isAdmin => flavor == AppFlavor.admin;

  static String get appName => switch (flavor) {
        AppFlavor.user => 'Campus Connect',
        AppFlavor.partner => 'Campus Connect Partner',
        AppFlavor.admin => 'Campus Connect Admin',
      };

  /// API base. Android emulator reaches host via 10.0.2.2; override at build
  /// time with --dart-define=API_BASE_URL=...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kReleaseMode
        ? 'https://campus-connect-api.up.railway.app/api/v1'
        : 'http://10.0.2.2:3000/api/v1',
  );

  static String get socketUrl =>
      apiBaseUrl.replaceAll('/api/v1', '');

  /// TomTom key for Search (geocoding/autocomplete) and Routing (ETAs/polylines).
  /// Free tier: 2,500 requests/day, no card, hard-stops instead of billing.
  /// NOTE: client keys ship in the app binary — rotate for production and prefer
  /// overriding via --dart-define=TOMTOM_API_KEY=... Map *tiles* deliberately do
  /// NOT use this key (tiles are high-volume and would exhaust the daily cap);
  /// the basemap uses keyless CARTO dark tiles instead.
  static const tomtomKey = String.fromEnvironment(
    'TOMTOM_API_KEY',
    defaultValue: 'XWHzpOp5QSlVqt5yRA6IYulWTvRjeieo',
  );
  static bool get tomtomEnabled => tomtomKey.isNotEmpty;

  /// Pilot campus (UMaT, Tarkwa) — the launch campus.
  static const double pilotLat = 5.301;
  static const double pilotLng = -1.996;

  /// Current campus centre — the user's selected university. Defaults to the
  /// pilot; updated when a campus is chosen. Used as the map fallback until GPS
  /// resolves. (Real device GPS still takes priority for live location.)
  static double campusLat = pilotLat;
  static double campusLng = pilotLng;
}
