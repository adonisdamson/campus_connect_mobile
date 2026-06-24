import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'config.dart';
import 'location.dart';
import 'theme.dart';

/// Keyless dark raster basemap (CARTO dark tiles) — fits the neon aesthetic and
/// needs no API token. Swap for a vector style + key in production.
const String campusMapStyle = '''
{
  "version": 8,
  "sources": {
    "carto-dark": {
      "type": "raster",
      "tiles": [
        "https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png",
        "https://b.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png"
      ],
      "tileSize": 256,
      "attribution": "© OpenStreetMap contributors, © CARTO"
    }
  },
  "layers": [
    { "id": "bg", "type": "background", "paint": { "background-color": "#0E0F12" } },
    { "id": "carto-dark", "type": "raster", "source": "carto-dark" }
  ]
}
''';

/// Fallback centre = the user's selected campus (until device GPS resolves).
({double lat, double lng}) get defaultCenter => (lat: AppConfig.campusLat, lng: AppConfig.campusLng);

/// A real MapLibre map with the neon pulse anchor. [onReady] hands back the
/// controller so callers can drop live driver/courier circles on it.
/// When [locateButton] is true it shows the device's location and a recenter FAB.
class LiveMap extends StatefulWidget {
  final double? centerLat, centerLng;
  final double zoom;
  final bool interactive, showPulse, locateButton;
  final void Function(MapLibreMapController controller)? onReady;
  final Widget? overlay;

  const LiveMap({
    super.key,
    this.centerLat,
    this.centerLng,
    this.zoom = 14,
    this.interactive = true,
    this.showPulse = true,
    this.locateButton = false,
    this.onReady,
    this.overlay,
  });

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<LiveMap> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  MapLibreMapController? _controller;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _locateMe() async {
    final pos = await LocationService.current();
    if (pos != null && _controller != null) {
      await _controller!.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MapLibreMap(
          styleString: campusMapStyle,
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.centerLat ?? defaultCenter.lat, widget.centerLng ?? defaultCenter.lng),
            zoom: widget.zoom,
          ),
          onMapCreated: (c) {
            _controller = c;
            widget.onReady?.call(c);
          },
          compassEnabled: false,
          rotateGesturesEnabled: widget.interactive,
          scrollGesturesEnabled: widget.interactive,
          zoomGesturesEnabled: widget.interactive,
          tiltGesturesEnabled: false,
          dragEnabled: widget.interactive,
          myLocationEnabled: false,
        ),
        if (widget.showPulse) Center(child: _Pulse(_pulse)),
        if (widget.locateButton)
          Positioned(
            right: 14,
            bottom: 24,
            child: FloatingActionButton.small(
              heroTag: null,
              backgroundColor: CC.surface,
              onPressed: _locateMe,
              child: Icon(PhosphorIconsFill.crosshair, color: CC.accent),
            ),
          ),
        if (widget.overlay != null) widget.overlay!,
      ],
    );
  }
}

class _Pulse extends StatelessWidget {
  final AnimationController c;
  const _Pulse(this.c);
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) => SizedBox(
        width: 90,
        height: 90,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 30 + c.value * 56,
              height: 30 + c.value * 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CC.accent.withValues(alpha: (1 - c.value) * 0.6)),
              ),
            ),
            Icon(PhosphorIconsFill.navigationArrow, color: CC.accent, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Lightweight, NON-native map preview for use *inside scroll views* (e.g. the
/// home hero). Embedding the real MapLibre platform view in a scrollable can
/// drop frames on Android, so scrollable contexts use this decorative version;
/// the real interactive [LiveMap] is reserved for full-screen, non-scrolling
/// screens (ride, tracking, partner).
class StaticMapPreview extends StatefulWidget {
  final Widget? overlay;
  const StaticMapPreview({super.key, this.overlay});
  @override
  State<StaticMapPreview> createState() => _StaticMapPreviewState();
}

class _StaticMapPreviewState extends State<StaticMapPreview> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF11131A), Color(0xFF0B0C10)]),
        ),
      ),
      CustomPaint(painter: _GridPainter(), size: Size.infinite),
      Center(child: _Pulse(_c)),
      if (widget.overlay != null) widget.overlay!,
    ]);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = CC.line.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    const gap = 38.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Draws / replaces a route polyline on a map controller, then frames it.
class RouteLine {
  Future<void> draw(MapLibreMapController c, List<LatLng> points, {String color = '#CBFF3C', bool fit = true}) async {
    if (points.length < 2) return;
    await c.clearLines();
    await c.addLine(LineOptions(geometry: points, lineColor: color, lineWidth: 5, lineOpacity: 0.9));
    if (fit) await fitToPoints(c, points);
  }
}

/// Animate the camera to frame a set of points with padding.
Future<void> fitToPoints(MapLibreMapController c, List<LatLng> points, {double pad = 70}) async {
  if (points.isEmpty) return;
  var minLat = points.first.latitude, maxLat = points.first.latitude;
  var minLng = points.first.longitude, maxLng = points.first.longitude;
  for (final p in points) {
    minLat = p.latitude < minLat ? p.latitude : minLat;
    maxLat = p.latitude > maxLat ? p.latitude : maxLat;
    minLng = p.longitude < minLng ? p.longitude : minLng;
    maxLng = p.longitude > maxLng ? p.longitude : maxLng;
  }
  final bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  await c.animateCamera(CameraUpdate.newLatLngBounds(bounds, left: pad, right: pad, top: pad, bottom: pad * 3));
}

/// Helper to drop/update a coloured driver/courier dot on a controller.
class MapMarker {
  Circle? _circle;
  Future<void> setPosition(MapLibreMapController c, double lat, double lng, {String color = '#FFB020'}) async {
    final geo = LatLng(lat, lng);
    if (_circle == null) {
      _circle = await c.addCircle(CircleOptions(
        geometry: geo, circleRadius: 9, circleColor: color,
        circleStrokeColor: '#0E0F12', circleStrokeWidth: 3,
      ));
    } else {
      await c.updateCircle(_circle!, CircleOptions(geometry: geo));
    }
  }
}
