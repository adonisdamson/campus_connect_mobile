import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/api.dart';
import '../../core/haptics.dart';
import '../../core/live_map.dart';
import '../../core/location.dart';
import '../../core/payment_picker.dart';
import '../../core/receipt.dart';
import '../../core/routing.dart';
import '../../core/socket.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models.dart';
import '../shared/place_picker.dart';
import '../shared/rate_sheet.dart';

class RideScreen extends StatefulWidget {
  const RideScreen({super.key});
  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  ({double lat, double lng, String name})? _pickup; // resolved from device GPS
  ({double lat, double lng, String name})? _dropoff; // chosen by the rider

  List<RideEstimate> _estimates = [];
  int _selected = 0;
  String _payment = 'CASH'; // remembered between requests
  String? _tripStatus;
  String? _tripId;
  Map? _driver;
  MapLibreMapController? _map;
  final _driverMarker = MapMarker();
  final _route = RouteLine();
  RouteResult? _routeInfo;

  @override
  void initState() {
    super.initState();
    _resolvePickup();
  }

  @override
  void dispose() {
    SocketService.instance.off('trip:status-changed');
    SocketService.instance.off('trip:driver-location');
    super.dispose();
  }

  // Pickup auto-fills from the device's real GPS (falls back to map centre).
  Future<void> _resolvePickup() async {
    final pos = await LocationService.current();
    if (!mounted) return;
    setState(() => _pickup = pos != null
        ? (lat: pos.latitude, lng: pos.longitude, name: 'Current location')
        : (lat: defaultCenter.lat, lng: defaultCenter.lng, name: 'Set pickup'));
    _refresh();
  }

  Future<void> _editLocation(bool pickup) async {
    final p = await pickPlace(context, title: pickup ? 'Pickup point' : 'Where to?');
    if (p == null || !mounted) return;
    setState(() {
      if (pickup) {
        _pickup = (lat: p.lat, lng: p.lng, name: p.name);
      } else {
        _dropoff = (lat: p.lat, lng: p.lng, name: p.name);
      }
    });
    _refresh();
  }

  // Re-estimate + redraw whenever both ends are known.
  Future<void> _refresh() async {
    await _fetchEstimates();
    await _drawRoute();
  }

  Future<void> _fetchEstimates() async {
    if (_pickup == null || _dropoff == null) return;
    try {
      final res = await Api.instance.post('/trips/estimate', {
        'pickupLat': _pickup!.lat, 'pickupLng': _pickup!.lng,
        'dropoffLat': _dropoff!.lat, 'dropoffLng': _dropoff!.lng,
      });
      _estimates = (res['estimates'] as List).map((e) => RideEstimate.fromJson(e)).toList();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _drawRoute() async {
    if (_map == null || _pickup == null || _dropoff == null) return;
    final r = await RoutingService.route(
      LatLng(_pickup!.lat, _pickup!.lng), LatLng(_dropoff!.lat, _dropoff!.lng));
    if (!mounted) return;
    await _route.draw(_map!, r.points);
    setState(() => _routeInfo = r);
  }

  Future<void> _request() async {
    if (_pickup == null || _dropoff == null || _estimates.isEmpty) return;
    final cls = _estimates[_selected];
    // Let the rider choose how to pay before we search for a driver.
    final method = await pickPayment(context, selected: _payment);
    if (method == null) return;
    _payment = method;
    setState(() => _tripStatus = 'SEARCHING');
    SocketService.instance.on('trip:status-changed', (data) {
      if (!mounted) return;
      setState(() {
        _tripStatus = data['status'];
        if (data['driver'] != null) _driver = data['driver'];
      });
    });
    SocketService.instance.on('trip:driver-location', (d) {
      if (_map != null && d['lat'] != null) {
        _driverMarker.setPosition(_map!, (d['lat'] as num).toDouble(), (d['lng'] as num).toDouble());
      }
    });
    try {
      final res = await Api.instance.post('/trips', {
        'rideClass': cls.rideClass,
        'pickupAddress': _pickup!.name, 'pickupLat': _pickup!.lat, 'pickupLng': _pickup!.lng,
        'dropoffAddress': _dropoff!.name, 'dropoffLat': _dropoff!.lat, 'dropoffLng': _dropoff!.lng,
        'paymentMethod': _payment,
      });
      _tripId = res['trip']?['id'] as String?;
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _tripStatus = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
      }
    }
  }

  Future<void> _cancelTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CC.surface,
        title: const Text('Cancel ride?'),
        content: const Text('You won\'t be charged for cancelling before pickup.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep looking')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel ride', style: TextStyle(color: CC.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (_tripId != null) {
      try {
        await Api.instance.post('/trips/$_tripId/cancel', {'reason': 'Rider cancelled'});
      } catch (_) {}
    }
    if (mounted) setState(() { _tripStatus = null; _tripId = null; });
  }

  // Dependency-free safety toolkit: emergency numbers + shareable trip details.
  void _safety() {
    Haptics.tap();
    showModalBottomSheet(
      context: context,
      backgroundColor: CC.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(PhosphorIconsFill.shieldCheck, color: CC.danger),
              SizedBox(width: 10),
              Text('Safety', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ]),
            const SizedBox(height: 16),
            _safetyTile(PhosphorIconsFill.phoneCall, 'Police emergency', 'Call 191', () => _dial('191')),
            _safetyTile(PhosphorIconsFill.ambulance, 'Ambulance', 'Call 193', () => _dial('193')),
            _safetyTile(PhosphorIconsFill.shareNetwork, 'Share trip with a friend', 'Copy live trip details', _shareTrip),
          ]),
        ),
      ),
    );
  }

  Widget _safetyTile(IconData icon, String title, String sub, VoidCallback onTap) => InkWell(
        onTap: () { Navigator.pop(context); onTap(); },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: CC.danger, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(sub, style: const TextStyle(color: CC.textDim, fontSize: 12.5)),
            ])),
          ]),
        ),
      );

  Future<void> _dial(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      // Fall back to clipboard on devices without a dialer (e.g. tablets).
      Clipboard.setData(ClipboardData(text: number));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied $number')));
    }
  }

  void _shareTrip() {
    final driver = _driver?['fullName'] ?? 'driver';
    final details = 'I\'m on a Campus Connect ride.\n'
        'From: ${_pickup?.name ?? '-'}\nTo: ${_dropoff?.name ?? '-'}\n'
        'Driver: $driver\nTrip: ${_tripId ?? '-'}';
    Clipboard.setData(ClipboardData(text: details));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip details copied — paste to a friend')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: LiveMap(
              centerLat: _pickup?.lat,
              centerLng: _pickup?.lng,
              interactive: true,
              locateButton: true,
              onReady: (c) { _map = c; _drawRoute(); },
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CircleAvatar(
                  backgroundColor: CC.surface,
                  child: IconButton(icon: const Icon(PhosphorIconsBold.arrowLeft, size: 18), onPressed: () => Navigator.pop(context)),
                ),
              ),
            ),
          ),
          Align(alignment: Alignment.bottomCenter, child: _sheet()),
        ],
      ),
    );
  }

  Widget _sheet() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: CC.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: _tripStatus != null ? _statusView() : _pickerView(),
    );
  }

  Widget _pickerView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: CC.line, borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 16),
        _routeRow(PhosphorIconsFill.circle, _pickup?.name ?? 'Locating you…', CC.lime, onTap: () => _editLocation(true)),
        const Padding(padding: EdgeInsets.only(left: 9), child: SizedBox(height: 14, child: VerticalDivider(color: CC.line, width: 2))),
        _routeRow(PhosphorIconsFill.mapPin, _dropoff?.name ?? 'Where to?', CC.danger, onTap: () => _editLocation(false)),
        if (_routeInfo != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Icon(PhosphorIconsFill.path, size: 14, color: CC.textDim),
            const SizedBox(width: 8),
            Text('${_routeInfo!.minutes} min  •  ${_routeInfo!.km.toStringAsFixed(1)} km',
                style: AppTheme.mono(size: 12.5, color: CC.textDim)),
          ]),
        ],
        const SizedBox(height: 18),
        if (_dropoff == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(child: TextButton.icon(
              onPressed: () => _editLocation(false),
              icon: Icon(PhosphorIconsFill.magnifyingGlass, color: CC.accent, size: 18),
              label: const Text('Choose your destination', style: TextStyle(color: CC.text, fontWeight: FontWeight.w700)),
            )),
          )
        else if (_estimates.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
        else
          ...List.generate(_estimates.length, (i) => _classTile(_estimates[i], i)),
        const SizedBox(height: 16),
        CCButton(
          _dropoff == null ? 'Set destination' : 'Request ${_estimates.isNotEmpty ? _estimates[_selected].label : ''}',
          icon: PhosphorIconsFill.lightning,
          onTap: (_dropoff == null || _estimates.isEmpty) ? null : _request,
        ),
      ],
    );
  }

  Widget _routeRow(IconData icon, String text, Color c, {VoidCallback? onTap}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 12),
            Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
            if (onTap != null) const Icon(PhosphorIconsRegular.pencilSimple, size: 14, color: CC.textFaint),
          ]),
        ),
      );

  Widget _classTile(RideEstimate e, int i) {
    final sel = i == _selected;
    return GestureDetector(
      onTap: () { Haptics.select(); setState(() => _selected = i); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? CC.accent.withValues(alpha: 0.12) : CC.surfaceHi,
          borderRadius: BorderRadius.circular(CC.radiusSm),
          border: Border.all(color: sel ? CC.accent : Colors.transparent, width: 1.4),
        ),
        child: Row(
          children: [
            Icon(e.rideClass == 'BIKE' ? PhosphorIconsFill.motorcycle : PhosphorIconsFill.car, color: sel ? CC.accent : CC.textDim),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${e.minutes} min away', style: const TextStyle(color: CC.textDim, fontSize: 12.5)),
                ],
              ),
            ),
            Text('GHS ${e.fareEstimate.toStringAsFixed(2)}', style: AppTheme.mono(weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _statusView() {
    const activeStates = {'ACCEPTED', 'ARRIVING', 'ARRIVED', 'IN_PROGRESS', 'ON_THE_WAY'};
    final active = activeStates.contains(_tripStatus);
    final unassigned = _tripStatus == 'UNASSIGNED';
    final completed = _tripStatus == 'COMPLETED';
    final searching = !active && !unassigned && !completed;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        if (searching) ...[
          const SizedBox(width: 30, height: 30, child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          const Text('Finding you a driver…', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 6),
          const Text('Matching with the nearest partner on campus', style: TextStyle(color: CC.textDim), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          CCButton('Cancel ride', outlined: true, onTap: _cancelTrip),
        ],
        if (active) ...[
          Row(children: [
            CCAvatar((_driver?['fullName'] ?? 'D').toString().substring(0, 1)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_driver?['fullName'] ?? 'Your driver', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Row(children: [
                  const Icon(PhosphorIconsFill.star, size: 13, color: CC.warning),
                  const SizedBox(width: 4),
                  Text('${(_driver?['rating'] ?? 5.0)}', style: AppTheme.mono(size: 12.5)),
                  const Text('  •  on the way', style: TextStyle(color: CC.textDim, fontSize: 12.5)),
                ]),
              ]),
            ),
            CircleAvatar(backgroundColor: CC.accent, child: const Icon(PhosphorIconsFill.phone, color: CC.ink, size: 18)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: CCButton('Safety', outlined: true, icon: PhosphorIconsFill.shieldCheck, onTap: _safety)),
            const SizedBox(width: 10),
            Expanded(child: CCButton('Cancel', outlined: true, icon: PhosphorIconsRegular.xCircle, onTap: _cancelTrip)),
          ]),
        ],
        if (unassigned) ...[
          const Icon(PhosphorIconsRegular.carProfile, size: 40, color: CC.textFaint),
          const SizedBox(height: 12),
          const Text('No drivers available', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Try again in a moment', style: TextStyle(color: CC.textDim)),
          const SizedBox(height: 16),
          CCButton('Back', outlined: true, onTap: () => setState(() => _tripStatus = null)),
        ],
        if (completed) ...[
          const Icon(PhosphorIconsFill.checkCircle, size: 40, color: CC.success),
          const SizedBox(height: 12),
          const Text('Trip complete', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: CCButton('Receipt', outlined: true, icon: PhosphorIconsRegular.downloadSimple, onTap: _receipt)),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: CCButton('Rate & finish', onTap: _finish)),
          ]),
        ],
      ],
    );
  }

  Future<void> _finish() async {
    final driverId = _driver?['id'];
    await showRateSheet(context, subjectType: 'DRIVER', subjectId: '$driverId', targetUserId: driverId, title: 'Rate your driver');
    if (mounted) Navigator.pop(context);
  }

  Future<void> _receipt() async {
    final e = _estimates.isNotEmpty ? _estimates[_selected] : null;
    await shareReceipt(
      title: 'Trip receipt',
      reference: DateTime.now().millisecondsSinceEpoch.toString().substring(7),
      rows: [
        (label: 'From', value: _pickup?.name ?? ''),
        (label: 'To', value: _dropoff?.name ?? ''),
        if (e != null) (label: 'Class', value: e.label),
        if (e != null) (label: 'Distance', value: '${(e.distanceMeters / 1000).toStringAsFixed(1)} km'),
      ],
      total: e?.fareEstimate ?? 0,
    );
  }
}
