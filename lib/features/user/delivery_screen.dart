import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/api.dart';
import '../../core/haptics.dart';
import '../../core/live_map.dart';
import '../../core/location.dart';
import '../../core/payment_picker.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../shared/place_picker.dart';
import 'order_tracking_screen.dart';

class DeliveryScreen extends StatefulWidget {
  /// One of PARCEL | SHOPPING | GAS. Null lets the user pick.
  final String? initialType;
  const DeliveryScreen({super.key, this.initialType});
  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  static const _types = [
    ('PARCEL', 'Parcel', 'Send a package', PhosphorIconsFill.package),
    ('SHOPPING', 'Shopping', 'We buy & bring it', PhosphorIconsFill.shoppingBag),
    ('GAS', 'Gas refill', 'LPG cylinder swap', PhosphorIconsFill.flame),
  ];

  late String _type = widget.initialType ?? 'PARCEL';
  String _payment = 'CASH';
  final _desc = TextEditingController();
  ({double lat, double lng, String name})? _pickup;
  ({double lat, double lng, String name})? _dropoff;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _resolvePickup();
  }

  Future<void> _resolvePickup() async {
    final pos = await LocationService.current();
    if (!mounted) return;
    setState(() => _pickup = pos != null
        ? (lat: pos.latitude, lng: pos.longitude, name: 'Current location')
        : (lat: defaultCenter.lat, lng: defaultCenter.lng, name: 'Set pickup'));
  }

  Future<void> _editLocation(bool pickup) async {
    final p = await pickPlace(context, title: pickup ? 'Pickup point' : 'Drop-off');
    if (p == null || !mounted) return;
    setState(() {
      if (pickup) {
        _pickup = (lat: p.lat, lng: p.lng, name: p.name);
      } else {
        _dropoff = (lat: p.lat, lng: p.lng, name: p.name);
      }
    });
  }

  Future<void> _place() async {
    if (_pickup == null || _dropoff == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Set both pickup and drop-off')));
      return;
    }
    if (_desc.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a short description')));
      return;
    }
    final method = await pickPayment(context, selected: _payment);
    if (method == null) return;
    _payment = method;
    setState(() => _placing = true);
    try {
      final res = await Api.instance.post('/orders', {
        'type': _type,
        'parcelDescription': _desc.text.trim(),
        'pickup': {'address': _pickup!.name, 'lat': _pickup!.lat, 'lng': _pickup!.lng},
        'dropoff': {'address': _dropoff!.name, 'lat': _dropoff!.lat, 'lng': _dropoff!.lng},
        'paymentMethod': _payment,
      });
      final id = res['order']['id'];
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(id)));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _placing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
      }
    }
  }

  Widget _locTile(IconData icon, Color c, String label, String value, VoidCallback onTap) {
    return Material(
      color: CC.surfaceHi,
      borderRadius: BorderRadius.circular(CC.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(CC.radiusSm),
        onTap: () { Haptics.tap(); onTap(); },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: CC.textDim, fontSize: 11)),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            ])),
            const Icon(PhosphorIconsRegular.pencilSimple, size: 14, color: CC.textFaint),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('What are we moving?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: _types.map((t) {
              final sel = t.$1 == _type;
              return Expanded(
                child: GestureDetector(
                  onTap: () { Haptics.select(); setState(() => _type = t.$1); },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: sel ? CC.accent.withValues(alpha: 0.12) : CC.surface,
                      borderRadius: BorderRadius.circular(CC.radiusSm),
                      border: Border.all(color: sel ? CC.accent : CC.line, width: 1.3),
                    ),
                    child: Column(children: [
                      Icon(t.$4, color: sel ? CC.accent : CC.textDim, size: 24),
                      const SizedBox(height: 8),
                      Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text('Details', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          CCField(_type == 'SHOPPING' ? 'What should we buy?' : 'Describe the item', _desc, icon: PhosphorIconsRegular.note),
          const SizedBox(height: 20),
          const Text('Route', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _locTile(PhosphorIconsFill.circle, CC.lime, 'Pickup', _pickup?.name ?? 'Locating…', () => _editLocation(true)),
          const SizedBox(height: 10),
          _locTile(PhosphorIconsFill.mapPin, CC.danger, 'Drop-off', _dropoff?.name ?? 'Choose drop-off', () => _editLocation(false)),
          const SizedBox(height: 16),
          const CCCard(
            color: CC.surfaceHi,
            child: Row(children: [
              Icon(PhosphorIconsRegular.info, size: 18, color: CC.textDim),
              SizedBox(width: 10),
              Expanded(child: Text('Fee is calculated from distance and confirmed before a rider is assigned.', style: TextStyle(color: CC.textDim, fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 24),
          CCButton('Request delivery', icon: PhosphorIconsFill.paperPlaneTilt, loading: _placing, onTap: _place),
        ],
      ),
    );
  }
}
