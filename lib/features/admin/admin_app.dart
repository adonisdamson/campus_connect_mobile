import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/api.dart';
import '../../core/haptics.dart';
import '../../core/skeletons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../auth/auth_provider.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _i = 0;
  final _pages = const [_Overview(), _Users(), _Verify(), _Orders(), _Reports()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operations'),
        actions: [IconButton(onPressed: () => context.read<AuthProvider>().signOut(), icon: const Icon(PhosphorIconsRegular.signOut))],
      ),
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: CC.surface,
        height: 66,
        selectedIndex: _i,
        onDestinationSelected: (v) { Haptics.select(); setState(() => _i = v); },
        destinations: const [
          NavigationDestination(icon: Icon(PhosphorIconsRegular.chartBar), selectedIcon: Icon(PhosphorIconsFill.chartBar, color: CC.violet), label: 'Overview'),
          NavigationDestination(icon: Icon(PhosphorIconsRegular.users), selectedIcon: Icon(PhosphorIconsFill.users, color: CC.violet), label: 'Users'),
          NavigationDestination(icon: Icon(PhosphorIconsRegular.sealCheck), selectedIcon: Icon(PhosphorIconsFill.sealCheck, color: CC.violet), label: 'Verify'),
          NavigationDestination(icon: Icon(PhosphorIconsRegular.package), selectedIcon: Icon(PhosphorIconsFill.package, color: CC.violet), label: 'Orders'),
          NavigationDestination(icon: Icon(PhosphorIconsRegular.flag), selectedIcon: Icon(PhosphorIconsFill.flag, color: CC.violet), label: 'Reports'),
        ],
      ),
    );
  }
}

// ── Overview ──
class _Overview extends StatefulWidget {
  const _Overview();
  @override
  State<_Overview> createState() => _OverviewState();
}

class _OverviewState extends State<_Overview> {
  Map<String, dynamic>? _dash, _live;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _dash = await Api.instance.get('/admin/dashboard');
      _live = await Api.instance.get('/admin/live');
    } on ApiException catch (e) {
      _error = e.status == 403 ? 'This account is not an admin.' : e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Skeletons.list();
    if (_error != null) return CCEmpty(icon: PhosphorIconsRegular.lockKey, title: 'Access', subtitle: _error!);
    final c = (_dash?['counts'] ?? {}) as Map;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(CC.radius), gradient: const LinearGradient(colors: [CC.violet, Color(0xFF6C5CE7)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('REVENUE (30 DAYS)', style: TextStyle(color: CC.ink.withValues(alpha: 0.7), fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text('GHC ${(_dash?['revenue30d'] ?? 0).toStringAsFixed(2)}', style: AppTheme.mono(size: 30, color: CC.ink)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          _live2('Online drivers', '${(_live?['drivers'] as List?)?.length ?? 0}', PhosphorIconsFill.steeringWheel),
          const SizedBox(width: 12),
          _live2('Active trips', '${_live?['activeTrips'] ?? 0}', PhosphorIconsFill.car),
          const SizedBox(width: 12),
          _live2('Active orders', '${_live?['activeOrders'] ?? 0}', PhosphorIconsFill.package),
        ]),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.7,
          children: [
            _metric('Users', '${c['users'] ?? 0}', PhosphorIconsFill.users),
            _metric('Drivers', '${c['drivers'] ?? 0}', PhosphorIconsFill.steeringWheel),
            _metric('Vendors', '${c['vendors'] ?? 0}', PhosphorIconsFill.storefront),
            _metric('Trips done', '${c['completedTrips'] ?? 0}', PhosphorIconsFill.car),
            _metric('Deliveries', '${c['deliveredOrders'] ?? 0}', PhosphorIconsFill.package),
            _metric('Listings', '${c['activeListings'] ?? 0}', PhosphorIconsFill.tag),
          ],
        ),
      ]),
    );
  }

  Widget _live2(String label, String value, IconData icon) => Expanded(child: CCCard(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: CC.violet, size: 18),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.mono(size: 18)),
          Text(label, style: const TextStyle(color: CC.textDim, fontSize: 10.5)),
        ]),
      ));

  Widget _metric(String label, String value, IconData icon) => CCCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: CC.violet, size: 20),
          Text(value, style: AppTheme.mono(size: 22)),
          Text(label, style: const TextStyle(color: CC.textDim, fontSize: 12)),
        ]),
      );
}

// ── Users ──
class _Users extends StatefulWidget {
  const _Users();
  @override
  State<_Users> createState() => _UsersState();
}

class _UsersState extends State<_Users> {
  List _users = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Api.instance.get('/admin/users', query: {if (_search.text.trim().isNotEmpty) 'q': _search.text.trim()});
      _users = res['users'] as List? ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setStatus(String id, String status) async {
    await Api.instance.patch('/admin/users/$id', {'status': status}).catchError((_) => <String, dynamic>{});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _search,
          onSubmitted: (_) => _load(),
          style: const TextStyle(color: CC.text),
          decoration: InputDecoration(
            hintText: 'Search name, email, phone…',
            hintStyle: const TextStyle(color: CC.textFaint),
            prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, color: CC.textFaint, size: 18),
            filled: true, fillColor: CC.surfaceHi,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(CC.radiusSm), borderSide: BorderSide.none),
          ),
        ),
      ),
      Expanded(
        child: _loading
            ? Skeletons.tiles()
            : _users.isEmpty
                ? const CCEmpty(icon: PhosphorIconsRegular.users, title: 'No users', subtitle: 'Try a different search.')
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const Divider(color: CC.line, height: 1),
                    itemBuilder: (_, i) => _userTile(_users[i]),
                  ),
      ),
    ]);
  }

  Widget _userTile(Map u) {
    final status = u['status'] ?? 'ACTIVE';
    final color = status == 'ACTIVE' ? CC.success : status == 'SUSPENDED' ? CC.warning : CC.danger;
    return ListTile(
      leading: CCAvatar((u['fullName'] ?? u['email'] ?? 'U').toString().substring(0, 1).toUpperCase()),
      title: Text('${u['fullName'] ?? 'Unnamed'}', style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('${u['email'] ?? u['phone'] ?? ''} • ${u['campusRole'] ?? ''}', style: const TextStyle(color: CC.textDim, fontSize: 12.5)),
      trailing: PopupMenuButton<String>(
        color: CC.surfaceHi,
        icon: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
        onSelected: (v) => _setStatus(u['id'], v),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'ACTIVE', child: Text('Activate')),
          PopupMenuItem(value: 'SUSPENDED', child: Text('Suspend')),
          PopupMenuItem(value: 'BANNED', child: Text('Ban')),
        ],
      ),
    );
  }
}

// ── Verify ──
class _Verify extends StatefulWidget {
  const _Verify();
  @override
  State<_Verify> createState() => _VerifyState();
}

class _VerifyState extends State<_Verify> {
  List _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Api.instance.get('/admin/verifications', query: {'status': 'PENDING'});
      _items = res['verifications'] as List? ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Widget _docThumb(String label, dynamic url) {
    if (url == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => _viewImage('$url', label),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network('$url', width: 66, height: 66, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 66, height: 66, color: CC.surfaceHi, child: const Icon(PhosphorIconsRegular.image, color: CC.textFaint))),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10.5, color: CC.textDim)),
        ]),
      ),
    );
  }

  void _viewImage(String url, String label) {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: CC.ink,
      insetPadding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 8, 8), child: Row(children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(icon: const Icon(PhosphorIconsRegular.x), onPressed: () => Navigator.pop(context)),
        ])),
        Flexible(child: InteractiveViewer(
          child: Image.network(url, errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(40), child: Text('Image unavailable', style: TextStyle(color: CC.textDim)))),
        )),
      ]),
    ));
  }

  Widget _faceBadge(dynamic score) {
    if (score == null) return const SizedBox.shrink();
    final s = (score as num).toDouble();
    final pass = s >= 0.8;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: (pass ? CC.success : CC.danger).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text('Face ${(s * 100).toStringAsFixed(0)}%', style: TextStyle(color: pass ? CC.success : CC.danger, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }

  Future<void> _review(String id, String decision) async {
    await Api.instance.patch('/admin/verifications/$id', {'decision': decision}).catchError((_) => <String, dynamic>{});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Skeletons.list();
    if (_items.isEmpty) return const CCEmpty(icon: PhosphorIconsRegular.sealCheck, title: 'Queue clear', subtitle: 'No pending verifications.');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: _items.map((v) {
        final user = v['user'] ?? {};
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: CCCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.circular(8)), child: Text('${v['type']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CC.violet))),
            const Spacer(),
            Text('${v['idDocType']}'.replaceAll('_', ' '), style: const TextStyle(color: CC.textDim, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Text(user['fullName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          Text('${user['email'] ?? user['phone'] ?? ''}', style: const TextStyle(color: CC.textDim, fontSize: 12.5)),
          if (v['idNumber'] != null) Text('ID: ${v['idNumber']}', style: AppTheme.mono(size: 12, color: CC.textDim)),
          const SizedBox(height: 12),
          // Tap any document to inspect it full-screen and compare with the selfie.
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _docThumb('ID front', v['idFrontUrl']),
            _docThumb('ID back', v['idBackUrl']),
            _docThumb('Selfie', v['selfieUrl']),
            const Spacer(),
            _faceBadge(v['faceMatchScore']),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: CCButton('Reject', outlined: true, onTap: () => _review(v['id'], 'REJECTED'))),
            const SizedBox(width: 10),
            Expanded(child: CCButton('Approve', onTap: () => _review(v['id'], 'APPROVED'))),
          ]),
        ])));
      }).toList()),
    );
  }
}

// ── Orders (ops + refunds) ──
class _Orders extends StatefulWidget {
  const _Orders();
  @override
  State<_Orders> createState() => _OrdersState();
}

class _OrdersState extends State<_Orders> {
  List _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Api.instance.get('/admin/orders', query: {'limit': 50});
      _items = res['orders'] as List? ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refund(Map o) async {
    final amount = TextEditingController(text: '${o['total']}');
    final reason = TextEditingController();
    final go = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, backgroundColor: CC.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Refund order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 6),
          Text('Max GHC ${o['total']} • credited to the customer\'s wallet', style: const TextStyle(color: CC.textDim, fontSize: 12.5)),
          const SizedBox(height: 14),
          CCField('Amount (GHC)', amount, icon: PhosphorIconsRegular.currencyDollar, keyboard: TextInputType.number),
          const SizedBox(height: 12),
          CCField('Reason', reason, icon: PhosphorIconsRegular.note),
          const SizedBox(height: 18),
          CCButton('Issue refund', onTap: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    if (go != true) return;
    try {
      await Api.instance.post('/admin/orders/${o['id']}/refund', {
        'amount': double.tryParse(amount.text.trim()), 'reason': reason.text.trim(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refund issued')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Skeletons.list();
    if (_items.isEmpty) return const CCEmpty(illustration: 'empty_orders', title: 'No orders', subtitle: 'Delivery orders will appear here.');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: _items.map((o) {
        final refunded = o['refundedAt'] != null;
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: CCCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.circular(8)), child: Text('${o['type']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CC.violet))),
            const Spacer(),
            Text('${o['status']}'.replaceAll('_', ' '), style: const TextStyle(color: CC.textDim, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Text('${o['customer']?['fullName'] ?? 'Customer'}${o['vendor'] != null ? ' • ${o['vendor']['name']}' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('GHC ${o['total']} • ${o['paymentMethod']}', style: AppTheme.mono(size: 12.5, color: CC.textDim)),
          const SizedBox(height: 12),
          if (refunded)
            Row(children: [const Icon(PhosphorIconsFill.checkCircle, color: CC.success, size: 16), const SizedBox(width: 6), Text('Refunded GHC ${o['refundAmount']}', style: const TextStyle(color: CC.success, fontWeight: FontWeight.w700, fontSize: 12.5))])
          else
            Align(alignment: Alignment.centerLeft, child: CCButton('Refund', outlined: true, icon: PhosphorIconsRegular.arrowUUpLeft, onTap: () => _refund(o))),
        ])));
      }).toList()),
    );
  }
}

// ── Reports ──
class _Reports extends StatefulWidget {
  const _Reports();
  @override
  State<_Reports> createState() => _ReportsState();
}

class _ReportsState extends State<_Reports> {
  List _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Api.instance.get('/admin/reports', query: {'status': 'OPEN'});
      _items = res['reports'] as List? ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resolve(String id, String action, {bool removeListing = false}) async {
    await Api.instance.patch('/admin/reports/$id', {'action': action, 'removeListing': removeListing}).catchError((_) => <String, dynamic>{});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Skeletons.list();
    if (_items.isEmpty) return const CCEmpty(icon: PhosphorIconsRegular.flag, title: 'No open reports', subtitle: 'Flagged content will appear here.');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: _items.map((r) {
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: CCCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: CC.danger.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)), child: Text('${r['targetType']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CC.danger))),
            const Spacer(),
            Text('by ${r['reporter']?['fullName'] ?? 'user'}', style: const TextStyle(color: CC.textDim, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Text('${r['reason']}', style: const TextStyle(fontWeight: FontWeight.w700)),
          if (r['note'] != null) Text('${r['note']}', style: const TextStyle(color: CC.textDim, fontSize: 13)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: CCButton('Dismiss', outlined: true, onTap: () => _resolve(r['id'], 'DISMISSED'))),
            const SizedBox(width: 10),
            Expanded(child: CCButton('Action', onTap: () => _resolve(r['id'], 'ACTIONED', removeListing: r['targetType'] == 'LISTING'))),
          ]),
        ])));
      }).toList()),
    );
  }
}
