import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/api.dart';
import '../../core/cc_image.dart';
import '../../core/haptics.dart';
import '../../core/icons.dart';
import '../../core/live_map.dart';
import '../../core/location.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models.dart';
import '../auth/auth_provider.dart';
import 'delivery_screen.dart';
import 'food_flow.dart';
import 'marketplace_screens.dart';
import 'notifications_screen.dart';
import 'ride_screen.dart';
import 'service_screens.dart';

/// Home — the front door. Bolt/Uber-style live hero + "Where to?", a quiet
/// monochrome quick-action row, then real, breathing API-fed sections. No
/// dashboard grid, no random colours, no sparkle iconography.
class HomeScreen extends StatelessWidget {
  /// Lets quick actions jump to a sibling tab (Market / Services) instead of
  /// pushing a duplicate screen. Index matches [UserShell]'s tab order.
  final ValueChanged<int>? onNavigateTab;
  const HomeScreen({super.key, this.onNavigateTab});

  void _push(BuildContext c, Widget w) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            titleSpacing: 20,
            toolbarHeight: 68,
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_greeting(),
                          style: const TextStyle(
                              color: CC.textDim, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(user?.fullName?.split(' ').first ?? 'Student',
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
                _BellButton(onTap: () => _push(context, const NotificationsScreen())),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () { Haptics.tap(); onNavigateTab?.call(4); },
                  child: CCAvatar(user?.initials ?? 'U', size: 42, imageUrl: user?.profilePhoto),
                ),
              ],
            ),
          ),

          // ── Hero: live map + "Where to?" ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _Hero(onTap: () => _push(context, const RideScreen()))
                  .animate()
                  .fadeIn(duration: 380.ms)
                  .slideY(begin: 0.06, curve: Curves.easeOutCubic),
            ),
          ),

          // ── Quick actions ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: _QuickActions(
                onRide: () => _push(context, const RideScreen()),
                onFood: () => _push(context, const FoodScreen()),
                onDelivery: () => _push(context, const DeliveryScreen()),
                onMarket: () => onNavigateTab?.call(1),
                onServices: () => onNavigateTab?.call(2),
              ),
            ),
          ),

          // ── Real, API-fed sections (each hides itself when empty) ────────
          SliverToBoxAdapter(
            child: _TrendingSection(onSeeAll: () => onNavigateTab?.call(1)),
          ),
          SliverToBoxAdapter(
            child: _FoodSection(onSeeAll: () => _push(context, const FoodScreen())),
          ),
          SliverToBoxAdapter(
            child: _ServicesSection(onSeeAll: () => onNavigateTab?.call(2)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ─────────────────────────────────────────────────────────────────────────
// HERO
// ─────────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final VoidCallback onTap;
  const _Hero({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(CC.radius),
      child: SizedBox(
        height: 196,
        child: StaticMapPreview(
          overlay: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: CC.surface,
                borderRadius: BorderRadius.circular(CC.radiusMd),
                child: InkWell(
                  borderRadius: BorderRadius.circular(CC.radiusMd),
                  onTap: () { Haptics.tap(); onTap(); },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
                    child: Row(children: [
                      Container(
                        width: 34, height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: CC.tint(0.16),
                          borderRadius: BorderRadius.circular(CC.radiusXs),
                        ),
                        child: const Icon(PhosphorIconsFill.magnifyingGlass,
                            size: 17, color: CC.lime),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Where to?',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                            SizedBox(height: 1),
                            Text('Book a ride across campus',
                                style: TextStyle(color: CC.textDim, fontSize: 12.5, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const Icon(PhosphorIconsRegular.arrowRight, size: 18, color: CC.textDim),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// QUICK ACTIONS — evenly-spaced monochrome tiles (no colour blocks)
// ─────────────────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final VoidCallback onRide, onFood, onDelivery, onMarket, onServices;
  const _QuickActions({
    required this.onRide,
    required this.onFood,
    required this.onDelivery,
    required this.onMarket,
    required this.onServices,
  });

  @override
  Widget build(BuildContext context) {
    final actions = <_QAItem>[
      _QAItem('Ride', PhosphorIconsRegular.carProfile, onRide),
      _QAItem('Food', PhosphorIconsRegular.forkKnife, onFood),
      _QAItem('Send', PhosphorIconsRegular.package, onDelivery),
      _QAItem('Market', PhosphorIconsRegular.storefront, onMarket),
      _QAItem('Services', PhosphorIconsRegular.squaresFour, onServices),
    ];
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++)
          Expanded(
            child: _QuickTile(actions[i])
                .animate(delay: (50 * i).ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.25, curve: Curves.easeOut),
          ),
      ],
    );
  }
}

class _QAItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QAItem(this.label, this.icon, this.onTap);
}

class _QuickTile extends StatefulWidget {
  final _QAItem item;
  const _QuickTile(this.item);
  @override
  State<_QuickTile> createState() => _QuickTileState();
}

class _QuickTileState extends State<_QuickTile> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () { Haptics.tap(); widget.item.onTap(); },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedScale(
            scale: _down ? 0.93 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Container(
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: CC.surface,
                borderRadius: BorderRadius.circular(CC.radiusMd),
                border: Border.all(color: CC.line, width: 1),
              ),
              child: Icon(widget.item.icon, size: 24, color: CC.text),
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CC.textDim)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// SECTION SCAFFOLDING
// ─────────────────────────────────────────────────────────────────────────

/// A horizontal skeleton row shown while a section loads.
class _SkeletonRow extends StatelessWidget {
  final double width, height;
  const _SkeletonRow({required this.width, required this.height});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: width,
          decoration: BoxDecoration(
            color: CC.surfaceHi,
            borderRadius: BorderRadius.circular(CC.radius),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// TRENDING (marketplace listings)
// ─────────────────────────────────────────────────────────────────────────

class _TrendingSection extends StatefulWidget {
  final VoidCallback onSeeAll;
  const _TrendingSection({required this.onSeeAll});
  @override
  State<_TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<_TrendingSection> {
  List<Listing> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Api.instance.get('/listings', query: {'limit': 10});
      final items =
          ((res['listings'] as List?) ?? []).map((e) => Listing.fromJson(e)).toList();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(children: [
        const CCSectionHeader('Trending on campus'),
        const _SkeletonRow(width: 168, height: 214),
      ]);
    }
    if (_items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CCSectionHeader('Trending on campus', actionLabel: 'See all', onAction: widget.onSeeAll),
        SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _ListingCard(_items[i])
                .animate(delay: (40 * i).ms)
                .fadeIn(duration: 280.ms)
                .slideX(begin: 0.12, curve: Curves.easeOut),
          ),
        ),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Listing listing;
  const _ListingCard(this.listing);
  @override
  Widget build(BuildContext context) {
    final img = listing.images.isNotEmpty ? listing.images.first : null;
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ListingDetailScreen(listing.id)));
      },
      child: SizedBox(
        width: 168,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(CC.radiusMd),
              child: CCImage(img,
                  width: 168, height: 140, fallbackIcon: PhosphorIconsRegular.tag),
            ),
            const SizedBox(height: 9),
            Text(listing.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 3),
            Text('GHS ${listing.price.toStringAsFixed(0)}',
                style: AppTheme.mono(size: 14.5, color: CC.accent, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// FOOD (vendors near you)
// ─────────────────────────────────────────────────────────────────────────

class _FoodSection extends StatefulWidget {
  final VoidCallback onSeeAll;
  const _FoodSection({required this.onSeeAll});
  @override
  State<_FoodSection> createState() => _FoodSectionState();
}

class _FoodSectionState extends State<_FoodSection> {
  List<Vendor> _items = [];
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
      final items = ((res['vendors'] as List?) ?? []).map((e) => Vendor.fromJson(e)).toList();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(children: [
        const CCSectionHeader('Food near you'),
        const _SkeletonRow(width: 244, height: 200),
      ]);
    }
    if (_items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CCSectionHeader('Food near you', actionLabel: 'See all', onAction: widget.onSeeAll),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _VendorCard(_items[i])
                .animate(delay: (40 * i).ms)
                .fadeIn(duration: 280.ms)
                .slideX(begin: 0.12, curve: Curves.easeOut),
          ),
        ),
      ],
    );
  }
}

class _VendorCard extends StatelessWidget {
  final Vendor vendor;
  const _VendorCard(this.vendor);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        Navigator.push(context, MaterialPageRoute(builder: (_) => VendorScreen(vendor)));
      },
      child: SizedBox(
        width: 244,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(CC.radiusMd),
                  child: CCImage(vendor.coverUrl,
                      width: 244, height: 132, fallbackIcon: PhosphorIconsRegular.forkKnife),
                ),
                Positioned(
                  top: 10, left: 10,
                  child: CCBadge('${vendor.prepMinutes} min',
                      icon: PhosphorIconsFill.clock, tone: CCBadgeTone.neutral),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(vendor.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(PhosphorIconsFill.star, size: 13, color: CC.lime),
              const SizedBox(width: 4),
              Text(vendor.rating > 0 ? vendor.rating.toStringAsFixed(1) : 'New',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
              Text('  ·  ${vendor.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: CC.textDim, fontSize: 12.5, fontWeight: FontWeight.w500)),
              if (vendor.distanceKm != null) ...[
                const Text('  ·  ', style: TextStyle(color: CC.textDim, fontSize: 12.5)),
                Text('${vendor.distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(color: CC.textDim, fontSize: 12.5, fontWeight: FontWeight.w500)),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// SERVICES (on campus)
// ─────────────────────────────────────────────────────────────────────────

class _ServicesSection extends StatefulWidget {
  final VoidCallback onSeeAll;
  const _ServicesSection({required this.onSeeAll});
  @override
  State<_ServicesSection> createState() => _ServicesSectionState();
}

class _ServicesSectionState extends State<_ServicesSection> {
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
      final items = ((res['services'] as List?) ?? []).map((e) => ServiceItem.fromJson(e)).toList();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(children: [
        const CCSectionHeader('Services on campus'),
        const _SkeletonRow(width: 210, height: 148),
      ]);
    }
    if (_items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CCSectionHeader('Services on campus', actionLabel: 'See all', onAction: widget.onSeeAll),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _ServiceCard(_items[i])
                .animate(delay: (40 * i).ms)
                .fadeIn(duration: 280.ms)
                .slideX(begin: 0.12, curve: Curves.easeOut),
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceItem service;
  const _ServiceCard(this.service);
  @override
  Widget build(BuildContext context) {
    final providerName = (service.provider?['user']?['fullName'] ??
            service.provider?['businessName'] ??
            'Campus pro')
        .toString();
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => ServiceDetailScreen(service.id)));
      },
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: CC.surface,
          borderRadius: BorderRadius.circular(CC.radius),
          border: Border.all(color: CC.line, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CC.tint(0.14),
                    borderRadius: BorderRadius.circular(CC.radiusXs),
                  ),
                  child: Icon(CCIcons.of(service.title), size: 21, color: CC.accent),
                ),
                const Spacer(),
                if (service.rating > 0) ...[
                  const Icon(PhosphorIconsFill.star, size: 12, color: CC.lime),
                  const SizedBox(width: 3),
                  Text(service.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ],
              ],
            ),
            const Spacer(),
            Text(service.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            const SizedBox(height: 2),
            Text(providerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: CC.textDim, fontSize: 12.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('from GHS ${service.basePrice.toStringAsFixed(0)}',
                style: AppTheme.mono(size: 13.5, color: CC.accent, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// BELL
// ─────────────────────────────────────────────────────────────────────────

class _BellButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BellButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(PhosphorIconsRegular.bell, size: 22, color: CC.text),
      onPressed: () { Haptics.tap(); onTap(); },
      tooltip: 'Notifications',
      splashRadius: 22,
    );
  }
}
