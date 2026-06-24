import 'package:dio/dio.dart';
import 'config.dart';

/// A searchable place: display name + coordinates.
class Place {
  final String name;
  final double lat, lng;
  const Place(this.name, this.lat, this.lng);
}

/// Address search / geocoding for destinations.
/// Provider chain: TomTom Search (keyed, accurate, typo-tolerant) → Photon
/// (free, keyless) → a curated pilot-campus list (offline fallback). Results are
/// biased toward the user's current campus centre.
class PlacesService {
  // Search is always available now (TomTom or the keyless Photon endpoint).
  static bool get enabled => true;
  static bool get usingTomTom => AppConfig.tomtomEnabled;

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static Future<List<Place>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return _campus;
    if (AppConfig.tomtomEnabled) {
      try {
        final r = await _tomtom(q);
        if (r.isNotEmpty) return r;
      } catch (_) {/* fall through to Photon */}
    }
    try {
      final r = await _photon(q);
      if (r.isNotEmpty) return r;
    } catch (_) {/* fall through to local */}
    final lc = q.toLowerCase();
    return _campus.where((p) => p.name.toLowerCase().contains(lc)).toList();
  }

  // TomTom Fuzzy Search — biased to a 50km radius around campus, Ghana only.
  static Future<List<Place>> _tomtom(String q) async {
    final url = 'https://api.tomtom.com/search/2/search/${Uri.encodeComponent(q)}.json';
    final res = await _dio.get(url, queryParameters: {
      'key': AppConfig.tomtomKey,
      'limit': 8,
      'countrySet': 'GH',
      'lat': AppConfig.campusLat,
      'lon': AppConfig.campusLng,
      'radius': 50000,
    });
    final results = (res.data['results'] as List?) ?? [];
    return results.map<Place>((r) {
      final pos = r['position'];
      final poi = r['poi']?['name'];
      final addr = r['address']?['freeformAddress'];
      final name = poi != null ? '$poi — ${addr ?? ''}'.trim() : (addr ?? 'Unknown place');
      return Place(name, (pos['lat'] as num).toDouble(), (pos['lon'] as num).toDouble());
    }).toList();
  }

  // Photon (komoot) — free OpenStreetMap geocoder, no key required.
  static Future<List<Place>> _photon(String q) async {
    final res = await _dio.get('https://photon.komoot.io/api/', queryParameters: {
      'q': q,
      'limit': 8,
      'lat': AppConfig.campusLat,
      'lon': AppConfig.campusLng,
    });
    final feats = (res.data['features'] as List?) ?? [];
    return feats.map<Place>((f) {
      final c = f['geometry']['coordinates'] as List; // [lng, lat]
      final p = f['properties'] ?? {};
      final name = [p['name'], p['street'], p['city'], p['country']]
          .where((x) => x != null && '$x'.isNotEmpty)
          .join(', ');
      return Place(name.isEmpty ? 'Location' : name, (c[1] as num).toDouble(), (c[0] as num).toDouble());
    }).toList();
  }

  // Pilot-campus (UMaT, Tarkwa) — shown when the query is empty and as the
  // last-resort offline fallback.
  static const _campus = <Place>[
    Place('UMaT Main Gate', 5.301, -1.996),
    Place('UMaT Library', 5.300, -1.994),
    Place('UMaT Engineering Block', 5.303, -1.997),
    Place('Hostel Block A', 5.299, -1.992),
    Place('Hostel Block C', 5.298, -1.991),
    Place('Tarkwa Market', 5.315, -2.001),
    Place('Tarkwa Town Junction', 5.310, -1.998),
    Place('Tarkwa Station', 5.312, -2.003),
    Place('Goldfields Hospital', 5.308, -1.990),
  ];
}
