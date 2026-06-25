import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/api.dart';
import '../../core/haptics.dart';
import '../../core/cc_image.dart';
import '../../core/live_map.dart';
import '../../core/location.dart';
import '../../core/payment_picker.dart';
import '../../core/skeletons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models.dart';
import '../shared/modifier_picker.dart';
import '../shared/place_picker.dart';
import 'cart.dart';
import 'order_tracking_screen.dart';

// ── Vendor list ──
class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});
  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  List<Vendor> _vendors = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final loc = await LocationService.current();
      final lat = loc?.latitude ?? defaultCenter.lat;
      final lng = loc?.longitude ?? defaultCenter.lng;
      final res = await Api.instance.get('/vendors', query: {'lat': lat, 'lng': lng});
      _vendors = ((res['vendors'] as List?) ?? []).map((e) => Vendor.fromJson(e)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Vendor> get _filtered => _query.isEmpty
      ? _vendors
      : _vendors.where((v) => v.name.toLowerCase().contains(_query) || v.category.toLowerCase().contains(_query)).toList();

  void _open(Vendor v) => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorScreen(v)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food'), actions: const [_CartIcon()]),
      body: _loading
          ? Skeletons.list()
          : _vendors.isEmpty
              ? const CCEmpty(
                  illustration: 'empty_search',
                  title: 'No kitchens open',
                  subtitle: 'Campus kitchens will appear here as soon as they start taking orders.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _searchBar()),
                      if (_query.isNotEmpty)
                        ..._searchResults()
                      else
                        ..._curatedRails(),
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    ],
                  ),
                ),
    );
  }

  Widget _searchBar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: CCField('Search kitchens & cuisines', _searchCtrl,
            icon: PhosphorIconsRegular.magnifyingGlass),
      );

  // ── Curated rails (derived from one dataset; no fabricated data) ──────────
  List<Widget> _curatedRails() {
    final popular = (_vendors.where((v) => v.rating > 0).toList()
          ..sort((a, b) => b.rating.compareTo(a.rating)))
        .take(8)
        .toList();
    final fast = (_vendors.toList()..sort((a, b) => a.prepMinutes.compareTo(b.prepMinutes)))
        .where((v) => v.prepMinutes <= 30)
        .take(8)
        .toList();

    return [
      if (popular.isNotEmpty) ...[
        const SliverToBoxAdapter(child: CCSectionHeader('Popular on campus')),
        _railSliver(popular),
      ],
      if (fast.isNotEmpty) ...[
        const SliverToBoxAdapter(child: CCSectionHeader('Fast delivery')),
        _railSliver(fast),
      ],
      const SliverToBoxAdapter(child: CCSectionHeader('All restaurants')),
      _listSliver(_vendors),
    ];
  }

  List<Widget> _searchResults() {
    final r = _filtered;
    if (r.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 64),
            child: CCEmpty(
                illustration: 'empty_search',
                title: 'Nothing matched',
                subtitle: 'Try another kitchen name or cuisine.'),
          ),
        ),
      ];
    }
    return [
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
      _listSliver(r),
    ];
  }

  Widget _railSliver(List<Vendor> vendors) => SliverToBoxAdapter(
        child: SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            itemCount: vendors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _RailCard(vendors[i], onTap: () => _open(vendors[i])),
          ),
        ),
      );

  Widget _listSliver(List<Vendor> vendors) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        sliver: SliverList.separated(
          itemCount: vendors.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (_, i) => _ListCard(vendors[i], onTap: () => _open(vendors[i]))
              .animate(delay: (i * 50).ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, curve: Curves.easeOut),
        ),
      );
}

/// Vendor meta line: rating · category · prep · distance.
class _VendorMeta extends StatelessWidget {
  final Vendor v;
  const _VendorMeta(this.v);
  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      v.category.replaceAll('_', ' ').toLowerCase(),
      '${v.prepMinutes} min',
      if (v.distanceKm != null) '${v.distanceKm!.toStringAsFixed(1)} km',
    ];
    return Row(children: [
      const Icon(PhosphorIconsFill.star, size: 13, color: CC.lime),
      const SizedBox(width: 4),
      Text(v.rating > 0 ? v.rating.toStringAsFixed(1) : 'New',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
      Expanded(
        child: Text('  ·  ${parts.join('  ·  ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: CC.textDim, fontSize: 12.5, fontWeight: FontWeight.w500)),
      ),
    ]);
  }
}

class _RailCard extends StatelessWidget {
  final Vendor v;
  final VoidCallback onTap;
  const _RailCard(this.v, {required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { Haptics.tap(); onTap(); },
      child: SizedBox(
        width: 248,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(CC.radiusMd),
              child: CCImage(v.coverUrl, width: 248, height: 132, fallbackIcon: PhosphorIconsRegular.forkKnife),
            ),
            const SizedBox(height: 9),
            Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            _VendorMeta(v),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final Vendor v;
  final VoidCallback onTap;
  const _ListCard(this.v, {required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { Haptics.tap(); onTap(); },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(CC.radius),
              child: CCImage(v.coverUrl, width: double.infinity, height: 168, fallbackIcon: PhosphorIconsRegular.forkKnife),
            ),
            if (v.prepMinutes <= 20)
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: CC.ink.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(CC.pill),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(PhosphorIconsFill.lightning, size: 12.5, color: CC.lime),
                    SizedBox(width: 4),
                    Text('Fast', style: TextStyle(color: CC.text, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 11),
          Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: -0.3)),
          const SizedBox(height: 6),
          _VendorMeta(v),
        ],
      ),
    );
  }
}

// ── Vendor menu + cart ──
class VendorScreen extends StatefulWidget {
  final Vendor vendor;
  const VendorScreen(this.vendor, {super.key});
  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen> {
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Api.instance.get('/vendors/${widget.vendor.id}');
      _products = ((res['vendor']['products'] as List?) ?? []).map((e) => Product.fromJson(e)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.vendor.name), actions: const [_CartIcon()]),
      body: _loading
          ? Skeletons.list()
          : _products.isEmpty
              ? const CCEmpty(icon: PhosphorIconsRegular.bowlFood, title: 'Menu empty', subtitle: 'This vendor has not added dishes yet.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _products.length,
                  separatorBuilder: (_, __) => const Divider(color: CC.line, height: 24),
                  itemBuilder: (_, i) => _productRow(_products[i]),
                ),
      bottomNavigationBar: const _CartBar(),
    );
  }

  Widget _productRow(Product p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            if (p.description != null) ...[const SizedBox(height: 3), Text(p.description!, style: const TextStyle(color: CC.textDim, fontSize: 13))],
            const SizedBox(height: 6),
            Text('${p.hasOptions ? 'from ' : ''}GHS ${p.price.toStringAsFixed(2)}', style: AppTheme.mono(color: CC.accent)),
          ]),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _addProduct(p),
          style: ElevatedButton.styleFrom(backgroundColor: CC.accent, foregroundColor: CC.ink, shape: const CircleBorder(), padding: const EdgeInsets.all(12)),
          child: const Icon(PhosphorIconsBold.plus, size: 18),
        ),
      ],
    );
  }

  Future<void> _addProduct(Product p) async {
    Haptics.tap();
    final cart = context.read<CartProvider>();
    if (!p.hasOptions) {
      cart.add(p, widget.vendor.id, widget.vendor.name);
      return;
    }
    final chosen = await pickModifiers(context, p);
    if (chosen == null || !mounted) return;
    cart.add(p, widget.vendor.id, widget.vendor.name, options: chosen);
  }
}

class _CartIcon extends StatelessWidget {
  const _CartIcon();
  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().count;
    return Stack(alignment: Alignment.center, children: [
      IconButton(icon: const Icon(PhosphorIconsRegular.shoppingCartSimple), onPressed: () {
        if (count > 0) Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
      }),
      if (count > 0)
        Positioned(right: 6, top: 8, child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: CC.lime, shape: BoxShape.circle), child: Text('$count', style: const TextStyle(color: CC.ink, fontSize: 10, fontWeight: FontWeight.w800)))),
    ]);
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar();
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(color: CC.accent, borderRadius: BorderRadius.circular(CC.radiusSm)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: CC.ink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text('${cart.count}', style: const TextStyle(color: CC.ink, fontWeight: FontWeight.w800))),
              const SizedBox(width: 12),
              const Text('View cart', style: TextStyle(color: CC.ink, fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              Text('GHS ${cart.subtotal.toStringAsFixed(2)}', style: AppTheme.mono(color: CC.ink, weight: FontWeight.w500, size: 15)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Checkout ──
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _placing = false;
  // Delivery address auto-fills from device GPS; editable via the picker.
  ({double lat, double lng, String address}) _dropoff =
      (address: 'Locating…', lat: defaultCenter.lat, lng: defaultCenter.lng);
  final _coupon = TextEditingController();
  double _discount = 0;
  String? _couponCode;
  String _payment = 'CASH';

  @override
  void initState() {
    super.initState();
    _resolveDropoff();
  }

  Future<void> _resolveDropoff() async {
    final pos = await LocationService.current();
    if (!mounted) return;
    setState(() => _dropoff = pos != null
        ? (lat: pos.latitude, lng: pos.longitude, address: 'Current location')
        : (lat: defaultCenter.lat, lng: defaultCenter.lng, address: 'Set delivery address'));
  }

  Future<void> _editDropoff() async {
    final p = await pickPlace(context, title: 'Delivery address');
    if (p == null || !mounted) return;
    setState(() => _dropoff = (lat: p.lat, lng: p.lng, address: p.name));
  }

  Future<void> _applyCoupon(double amount) async {
    final code = _coupon.text.trim().toUpperCase();
    if (code.isEmpty) return;
    try {
      final res = await Api.instance.post('/coupons/validate', {'code': code, 'amount': amount, 'context': 'ORDER'});
      setState(() {
        _discount = (res['discount'] as num).toDouble();
        _couponCode = code;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Coupon applied — GHS ${_discount.toStringAsFixed(2)} off')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final method = await pickPayment(context, selected: _payment);
    if (method == null) return;
    _payment = method;
    setState(() => _placing = true);
    try {
      final res = await Api.instance.post('/orders', {
        'type': 'FOOD',
        'vendorId': cart.vendorId,
        'items': cart.orderItems,
        'dropoff': {'address': _dropoff.address, 'lat': _dropoff.lat, 'lng': _dropoff.lng},
        'paymentMethod': _payment,
      });
      final orderId = res['order']['id'];
      if (_couponCode != null && _discount > 0) {
        await Api.instance.post('/coupons/redeem', {
          'code': _couponCode, 'amount': _discount, 'contextType': 'ORDER', 'contextId': orderId,
        }).catchError((_) => <String, dynamic>{});
      }
      cart.clear();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId)));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _placing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    const serviceFee = 2.0;
    const deliveryFee = 6.0 + 1.5; // est.; backend recomputes authoritatively
    final total = (cart.subtotal + serviceFee + deliveryFee - _discount).clamp(0, double.infinity).toDouble();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.isEmpty
          ? const CCEmpty(illustration: 'empty_box', title: 'Cart is empty', subtitle: 'Add dishes to get started.')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(cart.vendorName ?? 'Order', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...cart.lines.map((l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        _QtyStepper(l),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (l.options.isNotEmpty) Text(l.optionsLabel, style: const TextStyle(color: CC.textDim, fontSize: 12)),
                        ])),
                        Text('GHS ${l.lineTotal.toStringAsFixed(2)}', style: AppTheme.mono()),
                      ]),
                    )),
                const Divider(color: CC.line, height: 28),
                _row('Subtotal', cart.subtotal),
                _row('Delivery fee', deliveryFee),
                _row('Service fee', serviceFee),
                if (_discount > 0) _row('Discount ($_couponCode)', -_discount),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: CCField('Coupon code', _coupon, icon: PhosphorIconsRegular.tag)),
                  const SizedBox(width: 10),
                  SizedBox(height: 54, child: CCButton('Apply', outlined: true, onTap: () => _applyCoupon(cart.subtotal + serviceFee + deliveryFee))),
                ]),
                const Divider(color: CC.line, height: 24),
                _row('Total', total, bold: true),
                const SizedBox(height: 18),
                CCCard(onTap: _editDropoff, child: Row(children: [
                  const Icon(PhosphorIconsFill.mapPin, color: CC.lime),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Deliver to', style: TextStyle(color: CC.textDim, fontSize: 12)),
                    Text(_dropoff.address, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ])),
                  const Icon(PhosphorIconsRegular.pencilSimple, size: 14, color: CC.textFaint),
                ])),
                const SizedBox(height: 12),
                const CCCard(child: Row(children: [
                  Icon(PhosphorIconsFill.money, color: CC.lime),
                  SizedBox(width: 12),
                  Text('Cash on delivery', style: TextStyle(fontWeight: FontWeight.w600)),
                ])),
                const SizedBox(height: 24),
                CCButton('Place order  •  GHS ${total.toStringAsFixed(2)}', loading: _placing, onTap: _placeOrder),
              ],
            ),
    );
  }

  Widget _row(String label, double v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(label, style: TextStyle(color: bold ? CC.text : CC.textDim, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 16 : 14)),
          const Spacer(),
          Text('GHS ${v.toStringAsFixed(2)}', style: AppTheme.mono(weight: bold ? FontWeight.w500 : FontWeight.w400, color: bold ? CC.accent : CC.text)),
        ]),
      );
}

class _QtyStepper extends StatelessWidget {
  final CartLine line;
  const _QtyStepper(this.line);
  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Container(
      decoration: BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(visualDensity: VisualDensity.compact, icon: const Icon(PhosphorIconsBold.minus, size: 14), onPressed: () => cart.decrementKey(line.key)),
        Text('${line.qty}', style: AppTheme.mono()),
        IconButton(visualDensity: VisualDensity.compact, icon: const Icon(PhosphorIconsBold.plus, size: 14), onPressed: () => cart.incrementKey(line.key)),
      ]),
    );
  }
}
