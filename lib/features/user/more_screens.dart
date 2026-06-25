import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/api.dart';
import '../../core/cc_image.dart';
import '../../core/haptics.dart';
import '../../core/icons.dart';
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
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == 0) {
                return CCChip('All', selected: _categoryId == null, onTap: () => _selectCategory(null));
              }
              final c = _categories[i - 1];
              return CCChip('${c['name']}',
                  icon: CCIcons.of('${c['name']}'),
                  selected: _categoryId == c['id'],
                  onTap: () => _selectCategory(c['id']));
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

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
                          itemCount: _items.length + (_hasMore ? 2 : 0),
                          itemBuilder: (_, i) {
                            // Trailing shimmer tiles stand in for the next page
                            // (no spinners — skeletons only).
                            if (i >= _items.length) return const _ListingSkeleton();
                            return _listingCard(_items[i])
                                .animate(delay: ((i % _pageSize) * 40).ms).fadeIn(duration: 300.ms).slideY(begin: 0.12, curve: Curves.easeOut);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _listingCard(Listing l) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(l.id)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Square, image-forward hero with a condition tag (Carousell/FB feel).
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(CC.radiusMd),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CCImage(l.images.isEmpty ? null : l.images.first, fallbackIcon: PhosphorIconsRegular.tag),
                  Positioned(top: 8, left: 8, child: _GlassPill(text: l.conditionLabel)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text('GHS ${l.price.toStringAsFixed(0)}',
              style: AppTheme.mono(size: 15.5, color: CC.accent, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(l.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          const SizedBox(height: 6),
          Row(children: [
            CCAvatar(l.sellerName.isNotEmpty ? l.sellerName[0].toUpperCase() : 'S',
                size: 19, imageUrl: l.sellerPhoto),
            const SizedBox(width: 6),
            Expanded(
              child: Text(l.sellerName.split(' ').first,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: CC.textDim, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            if (l.sellerVerified)
              const Icon(PhosphorIconsFill.sealCheck, size: 14, color: CC.lime),
          ]),
        ],
      ),
    );
  }
}

/// Shimmer placeholder matching a marketplace card (used for the next page).
class _ListingSkeleton extends StatelessWidget {
  const _ListingSkeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.circular(CC.radiusMd)),
          ),
        ),
        const SizedBox(height: 9),
        Container(width: 70, height: 14, decoration: BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.circular(6))),
        const SizedBox(height: 7),
        Container(width: 120, height: 12, decoration: BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.circular(6))),
      ],
    ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms);
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
  List<({String id, String name})> _cats = [];
  String? _activeCat; // null = All
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _load();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await Api.instance.get('/categories', query: {'type': 'SERVICE'});
      final cats = ((res['categories'] as List?) ?? [])
          .map((e) => (id: '${e['id']}', name: '${e['name']}'))
          .toList();
      if (mounted) setState(() => _cats = cats);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Api.instance.get('/services',
          query: {if (_activeCat != null) 'categoryId': _activeCat!});
      _items = ((res['services'] as List?) ?? []).map((e) => ServiceItem.fromJson(e)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _selectCat(String? id) {
    if (_activeCat == id) return;
    setState(() => _activeCat = id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        bottom: _cats.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(54),
                child: SizedBox(
                  height: 54,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    itemCount: _cats.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return CCChip('All', selected: _activeCat == null, onTap: () => _selectCat(null));
                      }
                      final c = _cats[i - 1];
                      return CCChip(c.name,
                          icon: CCIcons.of(c.name),
                          selected: _activeCat == c.id,
                          onTap: () => _selectCat(c.id));
                    },
                  ),
                ),
              ),
      ),
      body: _loading
          ? Skeletons.list()
          : _items.isEmpty
              ? const CCEmpty(
                  illustration: 'empty_search',
                  title: 'No services here yet',
                  subtitle: 'Hair, nails, printing, tutoring & more — booked from peers around campus.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 22),
                  itemBuilder: (_, i) => _ServiceExperienceCard(_items[i])
                      .animate(delay: (50 * i).ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, curve: Curves.easeOut),
                ),
    );
  }
}

/// Airbnb-Experiences style card: a photo hero with category + rating overlays,
/// then title, provider, and price below. Cover photo is API-driven; a distinct
/// per-category icon stands in when a provider hasn't uploaded one.
class _ServiceExperienceCard extends StatelessWidget {
  final ServiceItem s;
  const _ServiceExperienceCard(this.s);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(s.id)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(CC.radius),
                child: CCImage(s.coverUrl,
                    width: double.infinity, height: 188, fallbackIcon: CCIcons.of(s.categoryName ?? s.title)),
              ),
              if (s.categoryName != null)
                Positioned(top: 12, left: 12, child: _GlassPill(text: s.categoryName!)),
              if (s.rating > 0)
                Positioned(
                  top: 12, right: 12,
                  child: _GlassPill(text: s.rating.toStringAsFixed(1), icon: PhosphorIconsFill.star),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5, letterSpacing: -0.2)),
          const SizedBox(height: 8),
          Row(children: [
            CCAvatar(s.providerName.isNotEmpty ? s.providerName[0].toUpperCase() : 'P',
                size: 26, imageUrl: s.providerPhoto),
            const SizedBox(width: 8),
            Expanded(
              child: Text(s.providerName,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: CC.textDim, fontSize: 13.5, fontWeight: FontWeight.w500)),
            ),
            Text(s.priceLabel,
                style: AppTheme.mono(size: 14.5, color: CC.accent, weight: FontWeight.w700)),
          ]),
        ],
      ),
    );
  }
}

/// Frosted dark pill used to overlay labels on photography.
class _GlassPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _GlassPill({required this.text, this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon != null ? 9 : 11, vertical: 6),
      decoration: BoxDecoration(
        color: CC.ink.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(CC.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12.5, color: CC.lime), const SizedBox(width: 4)],
        Text(text,
            style: const TextStyle(color: CC.text, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ]),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wallet topped up by GHS ${amount.toStringAsFixed(2)}')));
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
          CCField('Amount (GHS)', amount, icon: PhosphorIconsRegular.currencyDollar, keyboard: TextInputType.number),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: _loading
          ? Skeletons.tiles()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  // Cash App-style: the balance is the hero — no bank-card chrome.
                  const Text('Campus balance',
                      style: TextStyle(color: CC.textDim, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('GHS ', style: AppTheme.mono(size: 20, color: CC.textDim, weight: FontWeight.w600)),
                        Text(_balance.toStringAsFixed(2),
                            style: AppTheme.mono(size: 46, weight: FontWeight.w700, color: CC.text)),
                      ],
                    ),
                  ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.15, curve: Curves.easeOut),
                  const SizedBox(height: 22),
                  Row(children: [
                    Expanded(child: CCButton('Add money', icon: PhosphorIconsBold.plus, onTap: _topup)),
                    const SizedBox(width: 12),
                    Expanded(child: CCButton('Withdraw',
                        variant: CCVariant.secondary, icon: PhosphorIconsBold.arrowUp, onTap: _payout)),
                  ]),
                  const SizedBox(height: 30),
                  const Text('Activity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19, letterSpacing: -0.2)),
                  const SizedBox(height: 6),
                  if (_txns.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: CCEmpty(
                          illustration: 'empty_wallet',
                          title: 'No activity yet',
                          subtitle: 'Top up, ride, eat and shop — it all shows up here.'),
                    )
                  else
                    ..._txns.map((t) => _TxnRow(Map<String, dynamic>.from(t as Map))),
                ],
              ),
            ),
    );
  }
}

/// A single wallet ledger row — Cash App timeline feel.
class _TxnRow extends StatelessWidget {
  final Map<String, dynamic> t;
  const _TxnRow(this.t);

  static const _credit = {'TOPUP', 'REFUND', 'REWARD', 'TIP'};

  @override
  Widget build(BuildContext context) {
    final type = '${t['type']}';
    final isCredit = _credit.contains(type);
    final amount = (t['amount'] is num) ? (t['amount'] as num).toDouble() : double.tryParse('${t['amount']}') ?? 0;
    final when = DateTime.tryParse('${t['createdAt']}');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCredit ? CC.tint(0.14) : CC.surfaceHi,
            shape: BoxShape.circle,
          ),
          child: Icon(_icon(type), size: 19, color: isCredit ? CC.accent : CC.text),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_label(type), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
            if (when != null) ...[
              const SizedBox(height: 2),
              Text(_date(when), style: const TextStyle(color: CC.textFaint, fontSize: 12.5, fontWeight: FontWeight.w500)),
            ],
          ]),
        ),
        Text('${isCredit ? '+' : '−'}GHS ${amount.toStringAsFixed(2)}',
            style: AppTheme.mono(size: 14.5, weight: FontWeight.w700, color: isCredit ? CC.accent : CC.text)),
      ]),
    );
  }

  IconData _icon(String type) => switch (type) {
        'TOPUP' => PhosphorIconsFill.arrowDown,
        'REFUND' => PhosphorIconsFill.arrowUUpLeft,
        'REWARD' => PhosphorIconsFill.gift,
        'TIP' => PhosphorIconsFill.coins,
        'RIDE_PAYMENT' => PhosphorIconsFill.carProfile,
        'ORDER_PAYMENT' => PhosphorIconsFill.bag,
        'SERVICE_PAYMENT' => PhosphorIconsFill.calendarCheck,
        'PAYOUT' => PhosphorIconsFill.arrowUp,
        'FEE' => PhosphorIconsFill.receipt,
        _ => PhosphorIconsFill.arrowsDownUp,
      };

  String _label(String type) => switch (type) {
        'TOPUP' => 'Top up',
        'REFUND' => 'Refund',
        'REWARD' => 'Reward',
        'TIP' => 'Tip',
        'RIDE_PAYMENT' => 'Ride',
        'ORDER_PAYMENT' => 'Order',
        'SERVICE_PAYMENT' => 'Service',
        'PAYOUT' => 'Withdrawal',
        'FEE' => 'Fee',
        _ => type.replaceAll('_', ' '),
      };

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  String _date(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.day} ${_months[d.month - 1]}${d.year == now.year ? '' : ' ${d.year}'}';
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ── Identity header card (Revolut/Notion) ──
          CCCard(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CCAvatar(user?.initials ?? 'U', size: 58, imageUrl: user?.profilePhoto),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.fullName ?? 'Student',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.2)),
                  const SizedBox(height: 3),
                  Text(user?.email ?? user?.phone ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: CC.textDim, fontSize: 13.5, fontWeight: FontWeight.w500)),
                  if (user?.isVerified == true) ...[
                    const SizedBox(height: 8),
                    const CCBadge('Verified', icon: PhosphorIconsFill.sealCheck, tone: CCBadgeTone.success),
                  ],
                ]),
              ),
              const Icon(PhosphorIconsRegular.caretRight, size: 18, color: CC.textFaint),
            ]),
          ),
          _section('Activity'),
          _GroupCard(rows: [
            _AccountRow(PhosphorIconsRegular.clockCounterClockwise, 'Your activity',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()))),
            _AccountRow(PhosphorIconsRegular.bell, 'Notifications',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
            _AccountRow(PhosphorIconsRegular.chatCircle, 'Messages',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()))),
          ]),
          _section('Earn with us'),
          _GroupCard(rows: [
            _AccountRow(PhosphorIconsRegular.steeringWheel, 'Become a driver / courier',
                () => _become(context, '/profile/become-driver', 'DRIVER')),
            _AccountRow(PhosphorIconsRegular.storefront, 'My store',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorStoreScreen()))),
            _AccountRow(PhosphorIconsRegular.scissors, 'Offer a service',
                () => _become(context, '/profile/become-provider', 'SERVICE_PROVIDER')),
            _AccountRow(PhosphorIconsRegular.sealCheck, 'Verify my identity',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen(type: 'DRIVER')))),
          ]),
          _section('More'),
          _GroupCard(rows: [
            _AccountRow(PhosphorIconsRegular.gift, 'Refer & earn',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()))),
            _AccountRow(PhosphorIconsRegular.question, 'Help & support',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
            _AccountRow(PhosphorIconsRegular.shieldCheck, 'Privacy policy',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(title: 'Privacy policy', body: kPrivacyText)))),
            _AccountRow(PhosphorIconsRegular.scroll, 'Terms of service',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen(title: 'Terms of service', body: kTermsText)))),
          ]),
          const SizedBox(height: 14),
          _GroupCard(rows: [
            _AccountRow(PhosphorIconsRegular.signOut, 'Sign out', () => auth.signOut(), danger: true),
          ]),
        ],
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
        child: Text(label.toUpperCase(),
            style: const TextStyle(color: CC.textFaint, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.9)),
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
}

/// A grouped settings card — rows share one rounded surface with hairline
/// separators (Revolut/Notion), instead of loose repeated list tiles.
class _GroupCard extends StatelessWidget {
  final List<_AccountRow> rows;
  const _GroupCard({required this.rows});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CC.surface,
        borderRadius: BorderRadius.circular(CC.radius),
        border: Border.all(color: CC.line, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 62),
                child: Divider(height: 1, thickness: 1, color: CC.hair),
              ),
          ],
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _AccountRow(this.icon, this.label, this.onTap, {this.danger = false});
  @override
  Widget build(BuildContext context) {
    final c = danger ? CC.danger : CC.text;
    return InkWell(
      onTap: () { Haptics.tap(); onTap(); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: danger ? CC.danger.withValues(alpha: 0.12) : CC.surfaceHi,
              borderRadius: BorderRadius.circular(CC.radiusXs),
            ),
            child: Icon(icon, size: 18, color: c),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: c))),
          if (!danger) const Icon(PhosphorIconsRegular.caretRight, size: 16, color: CC.textFaint),
        ]),
      ),
    );
  }
}
