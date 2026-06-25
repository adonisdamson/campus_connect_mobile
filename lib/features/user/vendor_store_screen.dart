import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/api.dart';
import '../../core/haptics.dart';
import '../../core/skeletons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class VendorStoreScreen extends StatefulWidget {
  const VendorStoreScreen({super.key});
  @override
  State<VendorStoreScreen> createState() => _VendorStoreScreenState();
}

class _VendorStoreScreenState extends State<VendorStoreScreen> {
  List _orders = [];
  bool _loading = true;
  bool _needsStore = false;

  static const _advance = {
    'PENDING': 'CONFIRMED',
    'CONFIRMED': 'PREPARING',
    'PREPARING': 'READY',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Api.instance.get('/vendors/me/orders');
      _orders = res['orders'] as List? ?? [];
      _needsStore = false;
    } on ApiException catch (e) {
      if (e.status == 403) _needsStore = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await Api.instance.patch('/orders/$id/status', {'status': status});
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My store'), actions: [
        if (!_needsStore) IconButton(onPressed: _load, icon: const Icon(PhosphorIconsRegular.arrowsClockwise)),
      ]),
      body: _loading
          ? Skeletons.list()
          : _needsStore
              ? _OpenStoreForm(onCreated: _load)
              : _orders.isEmpty
                  ? const CCEmpty(icon: PhosphorIconsRegular.receipt, title: 'No orders yet', subtitle: 'New food orders will appear here to accept and prepare.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _orderCard(_orders[i]),
                      ),
                    ),
    );
  }

  Widget _orderCard(Map o) {
    final items = (o['items'] as List?) ?? [];
    final next = _advance[o['status']];
    return CCCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.circular(8)),
            child: Text('${o['status']}'.replaceAll('_', ' '), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CC.lime)),
          ),
          const Spacer(),
          Text('GHS ${o['total']}', style: AppTheme.mono(color: CC.accent)),
        ]),
        const SizedBox(height: 10),
        ...items.map((it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Text('${it['quantity']}×', style: AppTheme.mono(size: 12, color: CC.textDim)),
                const SizedBox(width: 8),
                Expanded(child: Text('${it['name']}', style: const TextStyle(fontSize: 13.5))),
              ]),
            )),
        if (next != null) ...[
          const SizedBox(height: 12),
          CCButton('Mark ${next.toLowerCase()}', onTap: () => _setStatus(o['id'], next)),
        ] else if (o['status'] == 'READY') ...[
          const SizedBox(height: 10),
          const Text('Waiting for a courier to pick up…', style: TextStyle(color: CC.textDim, fontSize: 12.5)),
        ],
      ]),
    );
  }
}

class _OpenStoreForm extends StatefulWidget {
  final VoidCallback onCreated;
  const _OpenStoreForm({required this.onCreated});
  @override
  State<_OpenStoreForm> createState() => _OpenStoreFormState();
}

class _OpenStoreFormState extends State<_OpenStoreForm> {
  final _name = TextEditingController();
  final _address = TextEditingController(text: 'Main Campus');
  String _category = 'RESTAURANT';
  bool _saving = false;

  static const _cats = ['RESTAURANT', 'FAST_FOOD', 'GROCERY', 'PHARMACY', 'CONVENIENCE', 'BAKERY'];

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Give your store a name')));
      return;
    }
    setState(() => _saving = true);
    try {
      await Api.instance.post('/profile/become-vendor', {
        'name': _name.text.trim(), 'category': _category,
        'address': _address.text.trim(), 'lat': 5.301, 'lng': -1.996,
      });
      widget.onCreated();
    } on ApiException catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Open your store', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 6),
      const Text('Start selling food on campus. Pending admin approval before you go live.', style: TextStyle(color: CC.textDim)),
      const SizedBox(height: 24),
      CCField('Store name', _name, icon: PhosphorIconsRegular.storefront),
      const SizedBox(height: 14),
      CCField('Address', _address, icon: PhosphorIconsRegular.mapPin),
      const SizedBox(height: 18),
      const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: _cats.map((c) {
        final sel = c == _category;
        return ChoiceChip(
          label: Text(c.replaceAll('_', ' ')), selected: sel,
          onSelected: (_) { Haptics.select(); setState(() => _category = c); },
          backgroundColor: CC.surfaceHi, selectedColor: CC.accent,
          labelStyle: TextStyle(color: sel ? CC.ink : CC.text, fontWeight: FontWeight.w600, fontSize: 12.5),
        );
      }).toList()),
      const SizedBox(height: 28),
      CCButton('Create store', loading: _saving, onTap: _create),
    ]);
  }
}
