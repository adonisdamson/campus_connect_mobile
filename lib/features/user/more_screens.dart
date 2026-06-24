import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/api.dart';
import '../../core/cc_image.dart';
import '../../core/haptics.dart';
import '../../core/payment_picker.dart';
import '../../core/skeletons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models.dart';
import '../auth/auth_provider.dart';
import '../shared/chat_screens.dart';
import '../shared/verification_screen.dart';
import 'activity_screen.dart';
import 'marketplace_screens.dart';
import 'notifications_screen.dart';
import 'profile_extras.dart';
import 'service_screens.dart';
import 'vendor_store_screen.dart';

// ── Marketplace ──
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<Listing> _items = [];
  List _categories = [];
  String? _categoryId;
  final _search = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) _loadMore();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await Api.instance.get('/categories', query: {'type': 'MARKETPLACE'});
      if (mounted) setState(() => _categories = res['categories'] as List? ?? []);
    } catch (_) {}
  }

  Map<String, dynamic> get _query => {
        if (_search.text.trim().isNotEmpty) 'q': _search.text.trim(),
        if (_categoryId != null) 'categoryId': _categoryId,
        'limit': _pageSize,
      };

  Future<void> _load() async {
    setState(() { _loading = true; _page = 1; });
    try {
      final res = await Api.instance.get('/listings', query: {..._query, 'page': 1});
      _items = (res['listings'] as List).map((e) => Listing.fromJson(e)).toList();
      _hasMore = res['hasMore'] == true;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final res = await Api.instance.get('/listings', query: {..._query, 'page': _page + 1});
      final more = (res['listings'] as List).map((e) => Listing.fromJson(e)).toList();
      _page += 1;
      _items = [..._items, ...more];
      _hasMore = res['hasMore'] == true;
    } catch (_) {}
    if (mounted) setState(() => _loadingMore = false);
  }

  void _selectCategory(String? id) {
    Haptics.select();
    setState(() => _categoryId = id);
    _load();
  }

  Widget _filterBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _search,
            onSubmitted: (_) => _load(),
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: CC.text),
            decoration: InputDecoration(
              hintText: 'Search the marketplace…',
              hintStyle: const TextStyle(color: CC.textFaint),
              prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, color: CC.textFaint, size: 19),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(PhosphorIconsRegular.x, size: 18, color: CC.textFaint),
                      onPressed: () { _search.clear(); _load(); },
                    ),
              filled: true,
              fillColor: CC.surfaceHi,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(CC.radiusSm), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(CC.radiusSm), borderSide: BorderSide(color: CC.accent, width: 1.4)),
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chip('All', _categoryId == null, () => _selectCategory(null)),
              for (final c in _categories) _chip('${c['name']}', _categoryId == c['id'], () => _selectCategory(c['id'])),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: sel ? CC.accent : CC.surfaceHi,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? CC.accent : CC.line),
            ),
            child: Text(label, style: TextStyle(color: sel ? CC.ink : CC.textDim, fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CC.accent, foregroundColor: CC.ink,
        icon: const Icon(PhosphorIconsBold.plus),
        label: const Text('Sell', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () async {
          final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListingScreen()));
          if (created == true) _load();
        },
      ),
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: _loading
                ? Skeletons.grid()
                : _items.isEmpty
                    ? CCEmpty(
                        illustration: 'empty_search',
                        title: (_search.text.isNotEmpty || _categoryId != null) ? 'No matches' : 'Nothing listed yet',
                        subtitle: (_search.text.isNotEmpty || _categoryId != null) ? 'Try a different search or category.' : 'Be the first to sell something on campus.',
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: GridView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 230, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.72),
                          itemCount: _items.length + (_hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= _items.length) {
                              return const Center(child: Padding(
                                padding: EdgeInsets.all(16),
                                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2)),
                              ));
                            }
                            return _listingCard(_items[i])
                                .animate(delay: (i * 40).ms).fadeIn(duration: 300.ms).slideY(begin: 0.12, curve: Curves.easeOut);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _listingCard(Listing l) {
    return CCCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(l.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.vertical(top: Radius.circular(CC.radius))),
              child: l.images.isEmpty
                  ? const Icon(PhosphorIconsRegular.image, color: CC.textFaint, size: 32)
                  : ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(CC.radius)),
                      child: CCImage(l.images.first, width: double.infinity),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('GHC ${l.price.toStringAsFixed(0)}', style: AppTheme.mono(color: CC.accent, weight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Services ──
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<ServiceItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Api.instance.get('/services');
      _items = (res['services'] as List).map((e) => ServiceItem.fromJson(e)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: _loading
          ? Skeletons.list()
          : _items.isEmpty
              ? const CCEmpty(icon: PhosphorIconsRegular.sparkle, title: 'No services yet', subtitle: 'Hair, nails, printing, tutoring & more — coming from your peers.')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final s = _items[i];
                    return CCCard(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(s.id))),
                      child: Row(children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(color: CC.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(PhosphorIconsFill.sparkle, color: CC.lime),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(s.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CC.textDim, fontSize: 13)),
                          ]),
                        ),
                        Text('GHC ${s.basePrice.toStringAsFixed(0)}', style: AppTheme.mono(color: CC.accent)),
                      ]),
                    );
                  },
                ),
    );
  }
}

// ── Wallet ──
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0;
  List _txns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Api.instance.get('/wallet');
      _balance = (res['balance'] as num).toDouble();
      _txns = res['transactions'] as List;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _topup() async {
    final amount = await pickTopupAmount(context);
    if (amount == null) return;
    try {
      final res = await Api.instance.post('/wallet/topup', {'amount': amount});
      if (!mounted) return;
      // When a payment provider is configured the backend returns an
      // authorization URL to complete payment; otherwise it credits instantly.
      if (res['authorizationUrl'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Continue payment in the opened page')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wallet topped up by GHC ${amount.toStringAsFixed(2)}')));
      }
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  Future<void> _payout() async {
    final number = TextEditingController();
    final amount = TextEditingController();
    final go = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, backgroundColor: CC.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Withdraw to MoMo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout requested')));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  Widget _pill(String label, IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: () { Haptics.tap(); onTap(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: CC.ink, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: CC.lime),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: CC.lime, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: _loading
          ? Skeletons.tiles()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(CC.radius),
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [CC.lime, Color(0xFF8FE000)]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CAMPUS BALANCE', style: TextStyle(color: CC.ink.withValues(alpha: 0.7), fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text('GHC ${_balance.toStringAsFixed(2)}', style: AppTheme.mono(size: 32, weight: FontWeight.w500, color: CC.ink)),
                      const SizedBox(height: 18),
                      Row(children: [
                        _pill('Top up', PhosphorIconsBold.plus, _topup),
                        const SizedBox(width: 10),
                        _pill('Withdraw', PhosphorIconsBold.arrowUp, _payout),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Recent activity', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                if (_txns.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No transactions yet', style: TextStyle(color: CC.textDim)))),
                ..._txns.map((t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: CC.surfaceHi, child: Icon(PhosphorIconsRegular.arrowsDownUp, size: 18, color: CC.accent)),
                      title: Text('${t['type']}'.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: Text('GHC ${t['amount']}', style: AppTheme.mono()),
                    )),
              ],
            ),
    );
  }
}

// ── Account ──
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            CCAvatar(user?.initials ?? 'U', size: 64),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.fullName ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                Text(user?.email ?? user?.phone ?? '', style: const TextStyle(color: CC.textDim)),
              ]),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: CC.line), shape: const StadiumBorder()),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              child: const Text('Edit', style: TextStyle(color: CC.text)),
            ),
          ]),
          const SizedBox(height: 26),
          _section('Activity'),
          _tile(PhosphorIconsRegular.clockCounterClockwise, 'Your activity', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()))),
          _tile(PhosphorIconsRegular.bell, 'Notifications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
          _tile(PhosphorIconsRegular.chatCircle, 'Messages', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()))),
          _section('Earn with us'),
          _tile(PhosphorIconsRegular.steeringWheel, 'Become a driver / courier', () => _become(context, '/profile/become-driver', 'DRIVER')),
          _tile(PhosphorIconsRegular.storefront, 'My store', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorStoreScreen()))),
          _tile(PhosphorIconsRegular.sparkle, 'Offer a service', () => _become(context, '/profile/become-provider', 'SERVICE_PROVIDER')),
          _tile(PhosphorIconsRegular.sealCheck, 'Verify my identity', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen(type: 'DRIVER')))),
          _section('More'),
          _tile(PhosphorIconsRegular.gift, 'Refer & earn', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()))),
          _tile(PhosphorIconsRegular.question, 'Help & support', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
          _tile(PhosphorIconsRegular.shieldCheck, 'Privacy policy', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(title: 'Privacy policy', body: kPrivacyText)))),
          _tile(PhosphorIconsRegular.scroll, 'Terms of service', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(title: 'Terms of service', body: kTermsText)))),
          const SizedBox(height: 8),
          _tile(PhosphorIconsRegular.signOut, 'Sign out', () => auth.signOut(), danger: true),
        ],
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Text(label.toUpperCase(), style: const TextStyle(color: CC.textFaint, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
      );

  Future<void> _become(BuildContext c, String path, String verifyType) async {
    try {
      final auth = c.read<AuthProvider>();
      await Api.instance.post(path);
      await auth.refreshMe();
      if (c.mounted) {
        Navigator.push(c, MaterialPageRoute(builder: (_) => VerificationScreen(type: verifyType)));
      }
    } on ApiException catch (e) {
      if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: danger ? CC.danger : CC.text, size: 22),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: danger ? CC.danger : CC.text)),
      trailing: const Icon(PhosphorIconsRegular.caretRight, size: 16, color: CC.textFaint),
      onTap: () { Haptics.tap(); onTap(); },
    );
  }
}
