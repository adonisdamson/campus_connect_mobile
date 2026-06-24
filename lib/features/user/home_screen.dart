import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/api.dart';
import '../../core/cc_image.dart';
import '../../core/haptics.dart';
import '../../core/live_map.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models.dart';
import '../auth/auth_provider.dart';
import 'delivery_screen.dart';
import 'food_flow.dart';
import 'marketplace_screens.dart';
import 'notifications_screen.dart';
import 'ride_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 64,
            titleSpacing: 20,
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Hey there 👋', style: TextStyle(color: CC.textDim, fontSize: 12.5)),
                      Text(user?.fullName?.split(' ').first ?? 'Student',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.bell, size: 22),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
                CCAvatar(user?.initials ?? 'U', size: 40),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero map + "where to?"
                  ClipRRect(
                    borderRadius: BorderRadius.circular(CC.radius),
                    child: SizedBox(
                      height: 188,
                      child: StaticMapPreview(
                        overlay: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Material(
                              color: CC.surface,
                              borderRadius: BorderRadius.circular(CC.radiusSm),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(CC.radiusSm),
                                onTap: () { Haptics.tap(); _go(context, const RideScreen()); },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                  child: Row(children: [
                                    Icon(PhosphorIconsBold.magnifyingGlass, size: 19, color: CC.lime),
                                    SizedBox(width: 10),
                                    Text('Where to?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    Spacer(),
                                    Icon(PhosphorIconsRegular.arrowRight, size: 18, color: CC.textDim),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),
                  const SizedBox(height: 22),
                  const Text('What do you need?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 14),
                  _ServiceGrid(),
                  const SizedBox(height: 24),
                  Row(children: [
                    const Text('Trending on campus', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const Spacer(),
                    Text('See all', style: TextStyle(color: CC.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _TrendingRow()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  static void _go(BuildContext c, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));
}

class _ServiceGrid extends StatelessWidget {
  final _items = const [
    (_S('Ride', PhosphorIconsFill.car, Color(0xFFCBFF3C))),
    (_S('Food', PhosphorIconsFill.forkKnife, Color(0xFFFF8A5B))),
    (_S('Delivery', PhosphorIconsFill.package, Color(0xFF5BC8FF))),
    (_S('Market', PhosphorIconsFill.storefront, Color(0xFFFF6BD6))),
    (_S('Services', PhosphorIconsFill.sparkle, Color(0xFFB388FF))),
    (_S('Gas', PhosphorIconsFill.flame, Color(0xFFFFC24B))),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 6 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.02,
      children: [
        for (var i = 0; i < _items.length; i++)
          CCCard(
            padding: const EdgeInsets.all(14),
            onTap: () {
              final dest = switch (_items[i].label) {
                'Ride' => const RideScreen(),
                'Food' => const FoodScreen(),
                'Delivery' => const DeliveryScreen(),
                'Gas' => const DeliveryScreen(initialType: 'GAS'),
                _ => null,
              };
              if (dest != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => dest));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_items[i].label} — coming online soon')));
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: _items[i].color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
                  child: Icon(_items[i].icon, color: _items[i].color, size: 22),
                ),
                Text(_items[i].label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              ],
            ),
          ).animate(delay: (60 * i).ms).fadeIn().slideY(begin: 0.2),
      ],
    );
  }
}

class _TrendingRow extends StatefulWidget {
  @override
  State<_TrendingRow> createState() => _TrendingRowState();
}

class _TrendingRowState extends State<_TrendingRow> {
  List<Listing> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Api.instance.get('/listings', query: {'limit': 8});
      final items = ((res['listings'] as List?) ?? []).map((e) => Listing.fromJson(e)).toList();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Container(
            width: 190,
            decoration: BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.circular(CC.radius)),
          ),
        ),
      );
    }
    // No listings yet — don't show a fake row.
    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CC.radius),
            border: Border.all(color: CC.line),
          ),
          child: const Text('No listings yet — be the first to sell', style: TextStyle(color: CC.textDim)),
        ),
      );
    }
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final l = _items[i];
          final img = l.images.isNotEmpty ? l.images.first : null;
          return GestureDetector(
            onTap: () {
              Haptics.tap();
              Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(l.id)));
            },
            child: Container(
              width: 190,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CC.radius),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [CC.surfaceHi, CC.surface],
                ),
                border: Border.all(color: CC.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CCImage(img, width: double.infinity, fallbackIcon: PhosphorIconsFill.tag),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('GHC ${l.price.toStringAsFixed(0)}', style: AppTheme.mono(color: CC.accent, weight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


class _S {
  final String label;
  final IconData icon;
  final Color color;
  const _S(this.label, this.icon, this.color);
}
