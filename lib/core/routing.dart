import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'config.dart';

/// A computed route: the polyline points plus distance & duration.
class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  const RouteResult(this.points, this.distanceMeters, this.durationSeconds);

  int get minutes => (durationSeconds / 60).round();
  double get km => distanceMeters / 1000;
}

/// Turn-by-turn polylines + ETAs for the MapLibre frontend.
/// Provider chain: TomTom (when TOMTOM_API_KEY is set) → OSRM (free) → straight line.
class RoutingService {
  static String get _tomtomKey => AppConfig.tomtomKey;
  static bool get tomtomEnabled => AppConfig.tomtomEnabled;

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static Future<RouteResult> route(LatLng a, LatLng b) async {
    if (tomtomEnabled) {
      try {
        return await _tomtom(a, b);
      } catch (_) {/* fall through to OSRM */}
    }
    try {
      return await _osrm(a, b);
    } catch (_) {
      return _straightLine(a, b);
    }
  }

  // TomTom Routing API — calculateRoute with full point geometry.
  static Future<RouteResult> _tomtom(LatLng a, LatLng b) async {
    final url =
        'https://api.tomtom.com/routing/1/calculateRoute/${a.latitude},${a.longitude}:${b.latitude},${b.longitude}/json';
    final res = await _dio.get(url, queryParameters: {'key': _tomtomKey, 'travelMode': 'car', 'routeType': 'fastest'});
    final route = res.data['routes'][0];
    final summary = route['summary'];
    final points = <LatLng>[];
    for (final leg in route['legs']) {
      for (final p in leg['points']) {
        points.add(LatLng((p['latitude'] as num).toDouble(), (p['longitude'] as num).toDouble()));
      }
    }
    return RouteResult(points, (summary['lengthInMeters'] as num).toDouble(), (summary['travelTimeInSeconds'] as num).toDouble());
  }

  // OSRM public server — free, no key. GeoJSON geometry.
  static Future<RouteResult> _osrm(LatLng a, LatLng b) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/${a.longitude},${a.latitude};${b.longitude},${b.latitude}';
    final res = await _dio.get(url, queryParameters: {'overview': 'full', 'geometries': 'geojson'});
    final route = res.data['routes'][0];
    final coords = route['geometry']['coordinates'] as List;
    final points = coords.map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
    return RouteResult(points, (route['distance'] as num).toDouble(), (route['duration'] as num).toDouble());
  }

  // Last-resort straight line with a rough campus-speed ETA (~22 km/h).
  static RouteResult _straightLine(LatLng a, LatLng b) {
    final meters = _haversine(a, b);
    return RouteResult([a, b], meters, meters / 6.1);
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
