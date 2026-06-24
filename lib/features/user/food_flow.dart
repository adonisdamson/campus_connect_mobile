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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loc = await LocationService.current();
      final lat = loc?.latitude ?? defaultCenter.lat;
      final lng = loc?.longitude ?? defaultCenter.lng;
      final res = await Api.instance.get('/vendors', query: {'lat': lat, 'lng': lng});
      _vendors = (res['vendors'] as List).map((e) => Vendor.fromJson(e)).toList();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food'), actions: const [_CartIcon()]),
      body: _loading
          ? Skeletons.list()
          : _vendors.isEmpty
              ? const CCEmpty(icon: PhosphorIconsRegular.forkKnife, title: 'No vendors open', subtitle: 'Campus kitchens will show up here once they open.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _vendors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _vendorCard(_vendors[i])
                        .animate(delay: (i * 60).ms).fadeIn(duration: 320.ms).slideY(begin: 0.12, curve: Curves.easeOut),
                  ),
                ),
    );
  }

  Widget _vendorCard(Vendor v) {
    return CCCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorScreen(v))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.vertical(top: Radius.circular(CC.radius))),
            child: v.coverUrl == null
                ? const Center(child: Icon(PhosphorIconsFill.storefront, color: CC.textFaint, size: 34))
                : ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(CC.radius)), child: CCImage(v.coverUrl, width: double.infinity)),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(v.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(v.category.replaceAll('_', ' ').toLowerCase(), style: const TextStyle(color: CC.textDim, fontSize: 13)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Row(children: [
                    const Icon(PhosphorIconsFill.star, size: 13, color: CC.warning),
                    const SizedBox(width: 4),
                    Text(v.rating.toStringAsFixed(1), style: AppTheme.mono(size: 12.5)),
                  ]),
                  const SizedBox(height: 4),
                  Text('${v.prepMinutes} min', style: const TextStyle(color: CC.textDim, fontSize: 12)),
                  if (v.distanceKm != null) Text('${v.distanceKm} km', style: AppTheme.mono(size: 11, color: CC.textFaint)),
                ]),
              ],
            ),
          ),
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
            Text('${p.hasOptions ? 'from ' : ''}GHC ${p.price.toStringAsFixed(2)}', style: AppTheme.mono(color: CC.accent)),
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
              Text('GHC ${cart.subtotal.toStringAsFixed(2)}', style: AppTheme.mono(color: CC.ink, weight: FontWeight.w500, size: 15)),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Coupon applied — GHC ${_discount.toStringAsFixed(2)} off')));
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
                        Text('GHC ${l.lineTotal.toStringAsFixed(2)}', style: AppTheme.mono()),
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
                CCButton('Place order  •  GHC ${total.toStringAsFixed(2)}', loading: _placing, onTap: _placeOrder),
              ],
            ),
    );
  }

  Widget _row(String label, double v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(label, style: TextStyle(color: bold ? CC.text : CC.textDim, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 16 : 14)),
          const Spacer(),
          Text('GHC ${v.toStringAsFixed(2)}', style: AppTheme.mono(weight: bold ? FontWeight.w500 : FontWeight.w400, color: bold ? CC.accent : CC.text)),
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
