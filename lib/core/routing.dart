import 'dart:math' as math;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'api.dart';

/// A computed route: the polyline points plus distance & duration.
class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  const RouteResult(this.points, this.distanceMeters, this.durationSeconds);

  int get minutes => (durationSeconds / 60).round();
  double get km => distanceMeters / 1000;
}

/// Polylines + ETAs via our backend's `/geo/route`, which proxies TomTom (→ OSRM
/// → straight line) server-side — no map key in the app. Falls back to a local
/// straight line if the backend is unreachable so the map still draws something.
class RoutingService {
  static Future<RouteResult> route(LatLng a, LatLng b) async {
    try {
      final res = await Api.instance.get('/geo/route', query: {
        'fromLat': a.latitude, 'fromLng': a.longitude,
        'toLat': b.latitude, 'toLng': b.longitude,
      });
      final pts = ((res['points'] as List?) ?? [])
          .map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
          .toList();
      if (pts.isNotEmpty) {
        return RouteResult(pts, (res['distanceMeters'] as num).toDouble(), (res['durationSeconds'] as num).toDouble());
      }
    } catch (_) {/* fall through to straight line */}
    return _straightLine(a, b);
  }

  static RouteResult _straightLine(LatLng a, LatLng b) {
    final meters = _haversine(a, b);
    return RouteResult([a, b], meters, meters / 6.1); // ~22 km/h campus speed
  }

  static double _haversine(LatLng a, LatLng b) {
    const earth = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(a.latitude)) * math.cos(rad(b.latitude)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return earth * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }
}
