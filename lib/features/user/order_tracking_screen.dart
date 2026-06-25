import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/api.dart';
import '../../core/live_map.dart';
import '../../core/receipt.dart';
import '../../core/routing.dart';
import '../../core/socket.dart';
import '../../core/theme.dart';
import '../shared/rate_sheet.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen(this.orderId, {super.key});
  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  static const _steps = ['PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'COURIER_ASSIGNED', 'PICKED_UP', 'IN_TRANSIT', 'DELIVERED'];
  static const _labels = {
    'PENDING': 'Order placed', 'CONFIRMED': 'Confirmed', 'PREPARING': 'Being prepared',
    'READY': 'Ready for pickup', 'COURIER_ASSIGNED': 'Courier assigned', 'PICKED_UP': 'Picked up',
    'IN_TRANSIT': 'On the way', 'DELIVERED': 'Delivered', 'CANCELLED': 'Cancelled',
  };

  String _status = 'PENDING';
  Map? _order;
  MapLibreMapController? _map;
  final _courier = MapMarker();
  final _route = RouteLine();

  Future<void> _maybeRoute() async {
    if (_map == null || _order == null) return;
    final o = _order!;
    if (o['pickupLat'] == null || o['dropoffLat'] == null) return;
    final r = await RoutingService.route(
      LatLng((o['pickupLat'] as num).toDouble(), (o['pickupLng'] as num).toDouble()),
      LatLng((o['dropoffLat'] as num).toDouble(), (o['dropoffLng'] as num).toDouble()));
    if (mounted) await _route.draw(_map!, r.points);
  }

  @override
  void initState() {
    super.initState();
    _load();
    SocketService.instance.on('order:status-changed', (d) {
      if (mounted && d['orderId'] == widget.orderId) setState(() => _status = d['status']);
    });
    SocketService.instance.on('order:courier-location', (d) {
      if (d['orderId'] == widget.orderId && _map != null) {
        _courier.setPosition(_map!, (d['lat'] as num).toDouble(), (d['lng'] as num).toDouble());
      }
    });
  }

  @override
  void dispose() {
    SocketService.instance.off('order:status-changed');
    SocketService.instance.off('order:courier-location');
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await Api.instance.get('/orders/${widget.orderId}');
      if (mounted) {
        setState(() {
          _order = res['order'];
          _status = _order!['status'];
        });
        _maybeRoute();
      }
    } catch (_) {}
  }

  int get _stepIndex => _steps.indexOf(_status).clamp(0, _steps.length - 1);

  // A customer can cancel only before the order is picked up.
  bool get _cancellable => ['PENDING', 'CONFIRMED', 'PREPARING'].contains(_status);

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CC.surface,
        title: const Text('Cancel this order?'),
        content: const Text('You won\'t be charged. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep order')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel order', style: TextStyle(color: CC.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Api.instance.patch('/orders/${widget.orderId}/status', {'status': 'CANCELLED'});
      if (!mounted) return;
      setState(() => _status = 'CANCELLED');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled')));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  Future<void> _finish() async {
    await showRateSheet(context, subjectType: 'ORDER', subjectId: widget.orderId, title: 'Rate your delivery');
    if (mounted) Navigator.pop(context);
  }

  Future<void> _receipt() async {
    final o = _order ?? {};
    final items = (o['items'] as List?) ?? [];
    final rows = <ReceiptRow>[
      (label: 'Type', value: '${o['type'] ?? 'Delivery'}'),
      for (final it in items) (label: '${it['quantity']}× ${it['name']}', value: 'GHS ${it['lineTotal']}'),
      (label: 'Delivery fee', value: 'GHS ${o['deliveryFee'] ?? 0}'),
      (label: 'Service fee', value: 'GHS ${o['serviceFee'] ?? 0}'),
    ];
    await shareReceipt(
      title: 'Delivery receipt',
      reference: widget.orderId.substring(0, 8).toUpperCase(),
      rows: rows,
      total: double.tryParse('${o['total'] ?? 0}') ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final delivered = _status == 'DELIVERED';
    final cancelled = _status == 'CANCELLED';
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: LiveMap(interactive: true, showPulse: false, onReady: (c) { _map = c; _maybeRoute(); })),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircleAvatar(backgroundColor: CC.surface, child: IconButton(icon: const Icon(PhosphorIconsBold.arrowLeft, size: 18), onPressed: () => Navigator.pop(context))),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: CC.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(
                    cancelled ? PhosphorIconsFill.xCircle : delivered ? PhosphorIconsFill.checkCircle : PhosphorIconsFill.cookingPot,
                    color: cancelled ? CC.danger : delivered ? CC.success : CC.accent, size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_labels[_status] ?? _status, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19))),
                ]),
                const SizedBox(height: 16),
                // Progress bar across the 8 steps
                Row(children: List.generate(_steps.length, (i) {
                  final done = i <= _stepIndex;
                  return Expanded(child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 5,
                    decoration: BoxDecoration(color: done ? CC.accent : CC.line, borderRadius: BorderRadius.circular(4)),
                  ));
                })),
                const SizedBox(height: 14),
                if (_order?['vendor'] != null)
                  Text('${_order!['vendor']['name'] ?? ''} • ${(_order!['items'] as List?)?.length ?? 0} item(s)', style: const TextStyle(color: CC.textDim)),
                if (_order?['courier'] != null) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    const CircleAvatar(backgroundColor: CC.surfaceHi, child: Icon(PhosphorIconsFill.scooter, color: CC.lime, size: 18)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_order!['courier']['fullName'] ?? 'Courier', style: const TextStyle(fontWeight: FontWeight.w700))),
                    CircleAvatar(backgroundColor: CC.accent, child: const Icon(PhosphorIconsFill.phone, color: CC.ink, size: 18)),
                  ]),
                ],
                if (_cancellable) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(PhosphorIconsRegular.xCircle, size: 18, color: CC.danger),
                    label: const Text('Cancel order', style: TextStyle(color: CC.danger, fontWeight: FontWeight.w700)),
                    onPressed: _cancel,
                  ),
                ],
                if (delivered) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: CC.line), padding: const EdgeInsets.symmetric(vertical: 13)),
                      icon: const Icon(PhosphorIconsRegular.downloadSimple, size: 18, color: CC.text),
                      label: const Text('Receipt', style: TextStyle(color: CC.text, fontWeight: FontWeight.w700)),
                      onPressed: _receipt,
                    )),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: CC.accent, foregroundColor: CC.ink, padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: _finish,
                      child: const Text('Rate & finish', style: TextStyle(fontWeight: FontWeight.w800)),
                    )),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
