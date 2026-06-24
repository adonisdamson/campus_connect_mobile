import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/api.dart';
import '../../core/skeletons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'order_tracking_screen.dart';

/// Unified history — rides, deliveries and service bookings.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  List _trips = [], _orders = [], _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        Api.instance.get('/trips'),
        Api.instance.get('/orders'),
        Api.instance.get('/services/bookings/mine'),
      ]);
      _trips = results[0]['trips'] as List? ?? [];
      _orders = results[1]['orders'] as List? ?? [];
      _bookings = results[2]['bookings'] as List? ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your activity'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: CC.accent,
          labelColor: CC.text,
          unselectedLabelColor: CC.textFaint,
          tabs: const [Tab(text: 'Rides'), Tab(text: 'Deliveries'), Tab(text: 'Services')],
        ),
      ),
      body: _loading
          ? Skeletons.list()
          : TabBarView(controller: _tabs, children: [
              _rides(), _deliveries(), _services(),
            ]),
    );
  }

  Widget _rides() => _list(_trips, PhosphorIconsRegular.car, 'No rides yet', (t) => CCCard(
        child: Row(children: [
          _icon(PhosphorIconsFill.car),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${t['pickupAddress']} → ${t['dropoffAddress']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text('${t['status']}'.replaceAll('_', ' '), style: const TextStyle(color: CC.textDim, fontSize: 12.5)),
          ])),
          Text('GHC ${t['fareFinal'] ?? t['fareEstimate']}', style: AppTheme.mono(color: CC.accent)),
        ]),
      ));

  Widget _deliveries() => _list(_orders, PhosphorIconsRegular.package, 'No deliveries yet', (o) => CCCard(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(o['id']))),
        child: Row(children: [
          _icon(PhosphorIconsFill.package),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${o['type']} • ${o['vendor']?['name'] ?? o['dropoffAddress'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text('${o['status']}'.replaceAll('_', ' '), style: const TextStyle(color: CC.textDim, fontSize: 12.5)),
          ])),
          Text('GHC ${o['total']}', style: AppTheme.mono(color: CC.accent)),
        ]),
      ));

  Widget _services() => _list(_bookings, PhosphorIconsRegular.sparkle, 'No bookings yet', (b) => CCCard(
        child: Row(children: [
          _icon(PhosphorIconsFill.sparkle),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${b['service']?['title'] ?? 'Service'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text('${b['status']}'.replaceAll('_', ' '), style: const TextStyle(color: CC.textDim, fontSize: 12.5)),
          ])),
          Text('GHC ${b['agreedPrice'] ?? ''}', style: AppTheme.mono(color: CC.accent)),
        ]),
      ));

  Widget _icon(IconData i) => Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: CC.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
        child: Icon(i, color: CC.lime, size: 20),
      );

  Widget _list(List items, IconData icon, String empty, Widget Function(Map) builder) {
    if (items.isEmpty) return CCEmpty(illustration: 'empty_orders', title: empty, subtitle: 'Your history will appear here.');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => builder(items[i]),
      ),
    );
  }
}
