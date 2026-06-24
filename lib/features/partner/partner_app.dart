import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/api.dart';
import '../../core/haptics.dart';
import '../../core/live_map.dart';
import '../../core/location.dart';
import '../../core/routing.dart';
import '../../core/skeletons.dart';
import '../../core/socket.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../auth/auth_provider.dart';
import '../shared/verification_screen.dart';
import '../user/notifications_screen.dart';
import 'partner_extras.dart';

class PartnerShell extends StatefulWidget {
  const PartnerShell({super.key});
  @override
  State<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends State<PartnerShell> {
  int _i = 0;
  final _pages = const [_PartnerHome(), PartnerJobsScreen(), _PartnerAccount()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: CC.surface,
        height: 66,
        selectedIndex: _i,
        onDestinationSelected: (v) { Haptics.select(); setState(() => _i = v); },
        destinations: const [
          NavigationDestination(icon: Icon(PhosphorIconsRegular.steeringWheel), selectedIcon: Icon(PhosphorIconsFill.steeringWheel, color: CC.amber), label: 'Drive'),
          NavigationDestination(icon: Icon(PhosphorIconsRegular.listChecks), selectedIcon: Icon(PhosphorIconsFill.listChecks, color: CC.amber), label: 'Jobs'),
          NavigationDestination(icon: Icon(PhosphorIconsRegular.user), selectedIcon: Icon(PhosphorIconsFill.user, color: CC.amber), label: 'You'),
        ],
      ),
    );
  }
}

// ── Home: map + earnings + online toggle + incoming request ──
class _PartnerHome extends StatefulWidget {
  const _PartnerHome();
  @override
  State<_PartnerHome> createState() => _PartnerHomeState();
}

class _PartnerHomeState extends State<_PartnerHome> {
  bool _online = false;
  Map? _request;
  Map<String, dynamic>? _dash;

  @override
  void initState() {
    super.initState();
    _loadDash();
    SocketService.instance.on('trip:new-request', (data) {
      if (mounted) setState(() => _request = data);
    });
    SocketService.instance.on('order:new-request', (data) {
      if (mounted) setState(() => _request = {...data, '_order': true});
    });
  }

  @override
  void dispose() {
    SocketService.instance.off('trip:new-request');
    SocketService.instance.off('order:new-request');
    super.dispose();
  }

  Future<void> _loadDash() async {
    try {
      final res = await Api.instance.get('/drivers/dashboard');
      if (mounted) setState(() => _dash = res);
    } catch (_) {}
  }

  Future<void> _toggleOnline() async {
    final next = !_online;
    try {
      Map<String, dynamic>? body;
      if (next) {
        // Use the driver's real position so dispatch can match nearby jobs.
        final pos = await LocationService.current();
        if (pos == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Turn on location to go online'), backgroundColor: CC.danger));
          }
          return;
        }
        body = {'lat': pos.latitude, 'lng': pos.longitude};
      }
      await Api.instance.post(next ? '/drivers/online' : '/drivers/offline', body);
      SocketService.instance.emit(next ? 'driver:go-online' : 'driver:go-offline', body ?? {});
      setState(() => _online = next);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  Future<void> _accept() async {
    final isOrder = _request!['_order'] == true;
    final id = isOrder ? _request!['orderId'] : _request!['tripId'];
    try {
      await Api.instance.post(isOrder ? '/orders/$id/accept' : '/trips/$id/accept');
      setState(() => _request = null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accepted — see it under Jobs')));
      _loadDash();
    } on ApiException catch (e) {
      setState(() => _request = null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _dash?['earnings'] ?? {};
    final p = _dash?['profile'] ?? {};
    return Stack(children: [
      const Positioned.fill(child: LiveMap(interactive: true)),
      SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CCCard(child: Row(children: [
              Expanded(child: _stat('Today', 'GHC ${(e['today'] ?? 0)}')),
              Container(width: 1, height: 34, color: CC.line),
              Expanded(child: _stat('Week', 'GHC ${(e['week'] ?? 0)}')),
              Container(width: 1, height: 34, color: CC.line),
              Expanded(child: _stat('Rating', '${(p['ratingAvg'] ?? 5.0)}')),
            ])),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: () { Haptics.success(); _toggleOnline(); },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: _online ? CC.success : CC.surfaceHi,
                  borderRadius: BorderRadius.circular(CC.radiusSm),
                  border: Border.all(color: _online ? CC.success : CC.line),
                ),
                alignment: Alignment.center,
                child: Text(_online ? "You're online — waiting for jobs" : 'Go online',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _online ? CC.ink : CC.text)),
              ),
            ),
          ),
        ]),
      ),
      if (_request != null) _RequestCard(req: _request!, onAccept: _accept, onReject: () => setState(() => _request = null)),
    ]);
  }

  Widget _stat(String label, String value) => Column(children: [
        Text(value, style: AppTheme.mono(size: 15, color: CC.amber)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: CC.textDim, fontSize: 11.5)),
      ]);
}

// ── Jobs tab ──
class PartnerJobsScreen extends StatefulWidget {
  const PartnerJobsScreen({super.key});
  @override
  State<PartnerJobsScreen> createState() => _PartnerJobsScreenState();
}

class _PartnerJobsScreenState extends State<PartnerJobsScreen> {
  List _trips = [], _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Api.instance.get('/drivers/jobs', query: {'status': 'active'});
      _trips = res['trips'] as List? ?? [];
      _orders = res['orders'] as List? ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final empty = _trips.isEmpty && _orders.isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Active jobs'), actions: [IconButton(onPressed: _load, icon: const Icon(PhosphorIconsRegular.arrowsClockwise))]),
      body: _loading
          ? Skeletons.list()
          : empty
              ? const CCEmpty(illustration: 'empty_orders', title: 'No active jobs', subtitle: 'Go online and accept a request to start earning.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    ..._trips.map((t) => _jobCard(t, false).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeOut)),
                    ..._orders.map((o) => _jobCard(o, true).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeOut)),
                  ]),
                ),
    );
  }

  Widget _jobCard(Map job, bool isOrder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CCCard(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveJobScreen(job: job, isOrder: isOrder)));
          _load();
        },
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: CC.amber.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(isOrder ? PhosphorIconsFill.package : PhosphorIconsFill.car, color: CC.amber),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isOrder ? 'Delivery • ${job['type']}' : 'Ride • ${job['rideClass']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${job['dropoffAddress'] ?? job['status']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CC.textDim, fontSize: 13)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.circular(8)),
            child: Text('${job['status']}'.replaceAll('_', ' '), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: CC.amber)),
          ),
        ]),
      ),
    );
  }
}

// ── Active job: advance status + stream location for live tracking ──
class ActiveJobScreen extends StatefulWidget {
  final Map job;
  final bool isOrder;
  const ActiveJobScreen({super.key, required this.job, required this.isOrder});
  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  late String _status = widget.job['status'];
  StreamSubscription<Position>? _posSub;
  MapLibreMapController? _map;
  final _route = RouteLine();

  Future<void> _drawRoute() async {
    if (_map == null) return;
    final j = widget.job;
    if (j['pickupLat'] == null || j['dropoffLat'] == null) return;
    final r = await RoutingService.route(
      LatLng((j['pickupLat'] as num).toDouble(), (j['pickupLng'] as num).toDouble()),
      LatLng((j['dropoffLat'] as num).toDouble(), (j['dropoffLng'] as num).toDouble()));
    if (mounted) await _route.draw(_map!, r.points, color: '#FFB020');
  }

  static const _tripFlow = ['ARRIVING', 'ARRIVED', 'IN_PROGRESS', 'COMPLETED'];
  static const _orderFlow = ['PICKED_UP', 'IN_TRANSIT', 'DELIVERED'];

  List<String> get _flow => widget.isOrder ? _orderFlow : _tripFlow;
  String get _id => widget.job['id'];

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  // Stream the driver's REAL GPS to the customer for the duration of the job.
  Future<void> _startTracking() async {
    if (!await LocationService.ensurePermission()) return;
    _posSub = LocationService.stream().listen((pos) {
      SocketService.instance.emit('driver:location', {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'bearing': pos.heading,
        if (widget.isOrder) 'orderId': _id else 'tripId': _id,
      });
    });
  }

  Future<void> _advance(String next) async {
    try {
      final path = widget.isOrder ? '/orders/$_id/status' : '/trips/$_id/status';
      await Api.instance.patch(path, {'status': next});
      setState(() => _status = next);
      if (next == 'COMPLETED' || next == 'DELIVERED') {
        _posSub?.cancel();
        if (mounted) Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  String? get _next {
    final idx = _flow.indexOf(_status);
    if (idx == -1) return _flow.first; // not yet started
    if (idx + 1 < _flow.length) return _flow[idx + 1];
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: LiveMap(
          centerLat: (j['pickupLat'] as num?)?.toDouble() ?? 5.301,
          centerLng: (j['pickupLng'] as num?)?.toDouble() ?? -1.996,
          interactive: true,
          onReady: (c) { _map = c; _drawRoute(); },
        )),
        SafeArea(child: Padding(
          padding: const EdgeInsets.all(12),
          child: CircleAvatar(backgroundColor: CC.surface, child: IconButton(icon: const Icon(PhosphorIconsBold.arrowLeft, size: 18), onPressed: () => Navigator.pop(context))),
        )),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: CC.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(widget.isOrder ? PhosphorIconsFill.package : PhosphorIconsFill.car, color: CC.amber),
                const SizedBox(width: 10),
                Text(widget.isOrder ? 'Delivery' : 'Ride', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const Spacer(),
                Text(_status.replaceAll('_', ' '), style: AppTheme.mono(size: 12, color: CC.amber)),
              ]),
              const SizedBox(height: 12),
              _leg(PhosphorIconsFill.circle, j['pickupAddress'] ?? 'Pickup', CC.success),
              const SizedBox(height: 6),
              _leg(PhosphorIconsFill.mapPin, j['dropoffAddress'] ?? 'Drop-off', CC.danger),
              const SizedBox(height: 18),
              if (_next != null)
                CCButton('Mark ${_next!.replaceAll('_', ' ').toLowerCase()}', onTap: () => _advance(_next!))
              else
                const Text('Complete this job from the last step.', style: TextStyle(color: CC.textDim)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _leg(IconData i, String t, Color c) => Row(children: [
        Icon(i, size: 13, color: c),
        const SizedBox(width: 10),
        Expanded(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]);
}

// ── Account ──
class _PartnerAccount extends StatelessWidget {
  const _PartnerAccount();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Row(children: [
          CCAvatar(user?.initials ?? 'P', size: 60),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user?.fullName ?? 'Partner', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(user?.email ?? '', style: const TextStyle(color: CC.textDim)),
          ])),
        ]),
        const SizedBox(height: 26),
        _row(context, PhosphorIconsRegular.wallet, 'Earnings & payout', const PartnerEarningsScreen()),
        _row(context, PhosphorIconsRegular.car, 'Vehicle details', const VehicleScreen()),
        _row(context, PhosphorIconsRegular.sealCheck, 'Verification', const VerificationScreen(type: 'DRIVER')),
        _row(context, PhosphorIconsRegular.bell, 'Notifications', const NotificationsScreen()),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(PhosphorIconsRegular.signOut, color: CC.danger),
          title: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w600, color: CC.danger)),
          onTap: () => auth.signOut(),
        ),
      ]),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, Widget screen) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: CC.text),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(PhosphorIconsRegular.caretRight, size: 16, color: CC.textFaint),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      );
}

class _RequestCard extends StatefulWidget {
  final Map req;
  final VoidCallback onAccept, onReject;
  const _RequestCard({required this.req, required this.onAccept, required this.onReject});
  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 30))..forward();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onReject();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOrder = widget.req['_order'] == true;
    final pickup = widget.req['pickup'] ?? {};
    final dropoff = widget.req['dropoff'] ?? {};
    final money = isOrder ? widget.req['payout'] : widget.req['fareEstimate'];
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: CC.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: CC.amber, width: 1.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text(isOrder ? 'New delivery' : 'New ride request', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const Spacer(),
            Text('GHC $money', style: AppTheme.mono(size: 17, color: CC.amber)),
          ]),
          const SizedBox(height: 14),
          _row(PhosphorIconsFill.circle, pickup['address'] ?? '—', CC.success),
          const SizedBox(height: 6),
          _row(PhosphorIconsFill.mapPin, dropoff['address'] ?? '—', CC.danger),
          const SizedBox(height: 16),
          AnimatedBuilder(animation: _c, builder: (_, __) => LinearProgressIndicator(value: 1 - _c.value, color: CC.amber, backgroundColor: CC.line)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: CCButton('Decline', outlined: true, onTap: widget.onReject)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: CCButton('Accept', icon: PhosphorIconsFill.check, onTap: widget.onAccept)),
          ]),
        ]),
      ),
    );
  }

  Widget _row(IconData i, String t, Color c) => Row(children: [
        Icon(i, size: 13, color: c),
        const SizedBox(width: 10),
        Expanded(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]);
}
