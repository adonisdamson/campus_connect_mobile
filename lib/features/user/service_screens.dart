import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/api.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;
  const ServiceDetailScreen(this.serviceId, {super.key});
  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  Map? _s;
  List _reviews = [];
  bool _loading = true, _booking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Api.instance.get('/services/${widget.serviceId}');
      _s = res['service'];
      _reviews = res['reviews'] as List? ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _book() async {
    final notes = await showModalBottomSheet<String>(
      context: context, backgroundColor: CC.surface, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _BookSheet(),
    );
    if (notes == null) return;
    setState(() => _booking = true);
    try {
      await Api.instance.post('/services/${widget.serviceId}/book', {'notes': notes});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent — the provider will confirm')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_s == null) return const Scaffold(body: CCEmpty(icon: PhosphorIconsRegular.warning, title: 'Not found', subtitle: 'This service is unavailable.'));
    final provider = _s!['provider'] ?? {};
    final providerUser = provider['user'] ?? {};
    return Scaffold(
      appBar: AppBar(title: const Text('Service')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CCButton('Book  •  GHC ${_s!['basePrice']}', icon: PhosphorIconsFill.calendarCheck, loading: _booking, onTap: _book),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 150, width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(CC.radius), gradient: const LinearGradient(colors: [CC.surfaceHi, CC.surface])),
            child: const Center(child: Icon(PhosphorIconsFill.sparkle, size: 44, color: CC.lime)),
          ),
          const SizedBox(height: 18),
          Text('${_s!['title']}', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Row(children: [
            Text('GHC ${_s!['basePrice']}', style: AppTheme.mono(size: 20, color: CC.accent)),
            Text('  ${(_s!['priceType'] ?? '').toString().replaceAll('_', ' ').toLowerCase()}', style: const TextStyle(color: CC.textDim)),
            const Spacer(),
            const Icon(PhosphorIconsFill.star, size: 15, color: CC.warning),
            const SizedBox(width: 4),
            Text('${_s!['ratingAvg']}', style: AppTheme.mono(size: 13)),
          ]),
          const SizedBox(height: 16),
          Text('${_s!['description']}', style: const TextStyle(color: CC.textDim, height: 1.5)),
          const Divider(color: CC.line, height: 36),
          Row(children: [
            CCAvatar((providerUser['fullName'] ?? 'P').toString().substring(0, 1)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(providerUser['fullName'] ?? 'Provider', style: const TextStyle(fontWeight: FontWeight.w700)),
              const Text('Verified campus provider', style: TextStyle(color: CC.textDim, fontSize: 12)),
            ]),
          ]),
          if (_reviews.isNotEmpty) ...[
            const Divider(color: CC.line, height: 36),
            const Text('Reviews', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            ..._reviews.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(PhosphorIconsFill.star, size: 14, color: CC.warning),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${r['comment'] ?? 'Great service'}', style: const TextStyle(color: CC.textDim))),
                  ]),
                )),
          ],
        ],
      ),
    );
  }
}

class _BookSheet extends StatefulWidget {
  const _BookSheet();
  @override
  State<_BookSheet> createState() => _BookSheetState();
}

class _BookSheetState extends State<_BookSheet> {
  final _notes = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: CC.line, borderRadius: BorderRadius.circular(4)))),
        const SizedBox(height: 18),
        const Text('Booking details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 14),
        CCField('Anything the provider should know?', _notes, icon: PhosphorIconsRegular.note),
        const SizedBox(height: 18),
        CCButton('Send request', onTap: () => Navigator.pop(context, _notes.text.trim())),
      ]),
    );
  }
}
