import 'api.dart';
import 'config.dart';

/// A searchable place: display name + coordinates.
class Place {
  final String name;
  final double lat, lng;
  const Place(this.name, this.lat, this.lng);
}

/// Address search / geocoding. Calls our backend's `/geo/search`, which proxies
/// TomTom (→ Photon) server-side so no map key ever ships in the app. Falls back
/// to a curated pilot-campus list when offline or empty.
class PlacesService {
  static Future<List<Place>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return _campus;
    try {
      final res = await Api.instance.get('/geo/search', query: {
        'q': q,
        'lat': AppConfig.campusLat,
        'lng': AppConfig.campusLng,
      });
      final places = ((res['places'] as List?) ?? [])
          .map((p) => Place('${p['name'] ?? 'Location'}', (p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
          .toList();
      if (places.isNotEmpty) return places;
    } catch (_) {/* fall through to campus fallback */}
    final lc = q.toLowerCase();
    return _campus.where((p) => p.name.toLowerCase().contains(lc)).toList();
  }

  // Pilot-campus (UMaT, Tarkwa) — shown for an empty query and as offline fallback.
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
