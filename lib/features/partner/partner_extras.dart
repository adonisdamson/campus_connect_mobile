import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/api.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

// ── Earnings + payout ──
class PartnerEarningsScreen extends StatefulWidget {
  const PartnerEarningsScreen({super.key});
  @override
  State<PartnerEarningsScreen> createState() => _PartnerEarningsScreenState();
}

class _PartnerEarningsScreenState extends State<PartnerEarningsScreen> {
  Map _earn = {};
  double _balance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Api.instance.get('/drivers/dashboard');
      _earn = res['earnings'] ?? {};
      _balance = (res['balance'] as num?)?.toDouble() ?? 0;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _payout() async {
    final number = TextEditingController();
    final amount = TextEditingController(text: _balance.toStringAsFixed(0));
    final go = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, backgroundColor: CC.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Cash out', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 14),
          CCField('Amount (GHC)', amount, icon: PhosphorIconsRegular.currencyDollar, keyboard: TextInputType.number),
          const SizedBox(height: 12),
          CCField('Mobile money number', number, icon: PhosphorIconsRegular.phone, keyboard: TextInputType.phone),
          const SizedBox(height: 18),
          CCButton('Request payout', onTap: () => Navigator.pop(context, true)),
        ]),
      ),
    );
    if (go != true) return;
    try {
      await Api.instance.post('/wallet/payout', {
        'amount': double.tryParse(amount.text) ?? 0, 'momoNumber': number.text.trim(), 'network': 'MTN',
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout requested — processed within 24h')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(CC.radius), gradient: const LinearGradient(colors: [CC.amber, Color(0xFFE08E00)])),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AVAILABLE BALANCE', style: TextStyle(color: CC.ink.withValues(alpha: 0.7), fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text('GHC ${_balance.toStringAsFixed(2)}', style: AppTheme.mono(size: 32, weight: FontWeight.w500, color: CC.ink)),
                  const SizedBox(height: 16),
                  GestureDetector(onTap: _payout, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: CC.ink, borderRadius: BorderRadius.circular(12)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(PhosphorIconsBold.arrowUp, size: 15, color: CC.amber),
                      SizedBox(width: 6),
                      Text('Cash out', style: TextStyle(color: CC.amber, fontWeight: FontWeight.w700)),
                    ]),
                  )),
                ]),
              ),
              const SizedBox(height: 20),
              Row(children: [
                _card('Today', _earn['today']),
                const SizedBox(width: 12),
                _card('This week', _earn['week']),
                const SizedBox(width: 12),
                _card('This month', _earn['month']),
              ]),
            ]),
    );
  }

  Widget _card(String label, dynamic v) => Expanded(child: CCCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('GHC ${v ?? 0}', style: AppTheme.mono(size: 16, color: CC.amber)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: CC.textDim, fontSize: 11.5)),
        ]),
      ));
}

// ── Vehicle editor ──
class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});
  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  String _type = 'CAR';
  final _plate = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _color = TextEditingController();
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Api.instance.get('/drivers/vehicle');
      final v = res['vehicle'];
      if (v != null) {
        _type = v['type'] ?? 'CAR';
        _plate.text = v['plate'] ?? '';
        _make.text = v['make'] ?? '';
        _model.text = v['model'] ?? '';
        _color.text = v['color'] ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_plate.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plate number is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      await Api.instance.put('/drivers/vehicle', {
        'type': _type, 'plate': _plate.text.trim(), 'make': _make.text.trim(),
        'model': _model.text.trim(), 'color': _color.text.trim(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle saved')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Row(children: [
          _typeChip('CAR', 'Car', PhosphorIconsFill.car),
          const SizedBox(width: 12),
          _typeChip('MOTORCYCLE', 'Motorcycle', PhosphorIconsFill.motorcycle),
        ]),
        const SizedBox(height: 18),
        CCField('Plate number', _plate, icon: PhosphorIconsRegular.identificationCard),
        const SizedBox(height: 14),
        CCField('Make (e.g. Toyota)', _make, icon: PhosphorIconsRegular.car),
        const SizedBox(height: 14),
        CCField('Model', _model, icon: PhosphorIconsRegular.car),
        const SizedBox(height: 14),
        CCField('Colour', _color, icon: PhosphorIconsRegular.palette),
        const SizedBox(height: 28),
        CCButton('Save vehicle', loading: _saving, onTap: _save),
      ]),
    );
  }

  Widget _typeChip(String value, String label, IconData icon) {
    final sel = _type == value;
    return Expanded(child: GestureDetector(
      onTap: () { Haptics.select(); setState(() => _type = value); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: sel ? CC.amber.withValues(alpha: 0.14) : CC.surface,
          borderRadius: BorderRadius.circular(CC.radiusSm),
          border: Border.all(color: sel ? CC.amber : CC.line, width: 1.3),
        ),
        child: Column(children: [
          Icon(icon, color: sel ? CC.amber : CC.textDim, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    ));
  }
}
