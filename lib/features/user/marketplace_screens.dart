import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/api.dart';
import '../../core/cc_image.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/uploads.dart';
import '../../core/widgets.dart';
import '../shared/chat_screens.dart';

// ── Listing detail ──
class ListingDetailScreen extends StatefulWidget {
  final String listingId;
  const ListingDetailScreen(this.listingId, {super.key});
  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  Map? _l;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Api.instance.get('/listings/${widget.listingId}');
      _l = res['listing'];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _chatSeller() async {
    final seller = _l!['seller'];
    if (seller?['id'] == null) return;
    try {
      final res = await Api.instance.post('/chat/start', {
        'otherUserId': seller['id'], 'type': 'MARKETPLACE', 'contextId': _l!['id'],
      });
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatThreadScreen(res['conversation']['id'], seller['fullName'] ?? 'Seller')));
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  Future<void> _favorite() async {
    await Api.instance.post('/listings/${widget.listingId}/favorite').catchError((_) => <String, dynamic>{});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to favorites')));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_l == null) return const Scaffold(body: CCEmpty(icon: PhosphorIconsRegular.warning, title: 'Not found', subtitle: 'This listing is no longer available.'));
    final images = ((_l!['images'] as List?) ?? []).map((e) => '${e['url']}').toList();
    final seller = _l!['seller'] ?? {};
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 300, pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: images.isEmpty
                ? Container(color: CC.surfaceHi, child: const Center(child: Icon(PhosphorIconsRegular.image, size: 48, color: CC.textFaint)))
                : CCImage(images.first, fit: BoxFit.cover),
          ),
          actions: [IconButton(onPressed: _favorite, icon: const Icon(PhosphorIconsFill.heart, color: CC.lime))],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_l!['title']}', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Row(children: [
                Text('GHC ${_l!['price']}', style: AppTheme.mono(size: 24, color: CC.accent)),
                if (_l!['negotiable'] == true) ...[const SizedBox(width: 10), const Chip(label: Text('Negotiable', style: TextStyle(fontSize: 11)), backgroundColor: CC.surfaceHi)],
              ]),
              const SizedBox(height: 16),
              Text('${_l!['description']}', style: const TextStyle(color: CC.textDim, height: 1.5)),
              const Divider(color: CC.line, height: 36),
              Row(children: [
                CCAvatar((seller['fullName'] ?? 'S').toString().substring(0, 1)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(seller['fullName'] ?? 'Seller', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Text('Campus seller', style: TextStyle(color: CC.textDim, fontSize: 12)),
                ])),
              ]),
              const SizedBox(height: 24),
              CCButton('Chat seller', icon: PhosphorIconsFill.chatCircle, onTap: _chatSeller),
              const SizedBox(height: 10),
              CCButton('Report listing', outlined: true, onTap: () => _report()),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _report() async {
    await Api.instance.post('/listings/${widget.listingId}/report', {'reason': 'Inappropriate'}).catchError((_) => <String, dynamic>{});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reported — thank you')));
  }
}

// ── Create listing ──
class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});
  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  List _categories = [];
  String? _categoryId;
  String _condition = 'USED';
  bool _saving = false;

  Future<void> _pickImage() async {
    if (_images.length >= 6) return;
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 82);
    if (x != null) setState(() => _images.add(x));
  }

  @override
  void initState() {
    super.initState();
    _loadCats();
  }

  Future<void> _loadCats() async {
    try {
      final res = await Api.instance.get('/categories', query: {'type': 'MARKETPLACE'});
      _categories = res['categories'] as List;
      if (_categories.isNotEmpty) _categoryId = _categories.first['id'];
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _price.text.trim().isEmpty || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a title, price and category')));
      return;
    }
    setState(() => _saving = true);
    try {
      // Upload each chosen photo, then attach the returned URLs to the listing.
      final urls = <String>[];
      for (final img in _images) {
        urls.add(await Uploads.uploadImage(img.path, img.name));
      }
      await Api.instance.post('/listings', {
        'title': _title.text.trim(), 'description': _desc.text.trim(),
        'price': double.tryParse(_price.text.trim()) ?? 0,
        'categoryId': _categoryId, 'condition': _condition,
        'images': urls,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listed! 🎉')));
    } on ApiException catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sell an item')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Photos', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < _images.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(File(_images[i].path), width: 92, height: 92, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(Icons.close, size: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    ]),
                  ),
                if (_images.length < 6)
                  GestureDetector(
                    onTap: () { Haptics.tap(); _pickImage(); },
                    child: Container(
                      width: 92, height: 92,
                      decoration: BoxDecoration(
                        color: CC.surfaceHi,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CC.line),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(PhosphorIconsRegular.camera, color: CC.accent),
                        const SizedBox(height: 4),
                        const Text('Add', style: TextStyle(fontSize: 11, color: CC.textDim)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          CCField('Title', _title, icon: PhosphorIconsRegular.tag),
          const SizedBox(height: 14),
          CCField('Price (GHC)', _price, icon: PhosphorIconsRegular.currencyDollar, keyboard: TextInputType.number),
          const SizedBox(height: 14),
          CCField('Description', _desc, icon: PhosphorIconsRegular.note),
          const SizedBox(height: 18),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_categories.isEmpty) const LinearProgressIndicator()
          else Wrap(spacing: 8, runSpacing: 8, children: _categories.map((c) {
            final sel = c['id'] == _categoryId;
            return ChoiceChip(
              label: Text('${c['name']}'), selected: sel,
              onSelected: (_) { Haptics.select(); setState(() => _categoryId = c['id']); },
              backgroundColor: CC.surfaceHi, selectedColor: CC.accent,
              labelStyle: TextStyle(color: sel ? CC.ink : CC.text, fontWeight: FontWeight.w600, fontSize: 12.5),
            );
          }).toList()),
          const SizedBox(height: 18),
          const Text('Condition', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: ['NEW', 'LIKE_NEW', 'USED', 'FOR_PARTS'].map((c) {
            final sel = c == _condition;
            return ChoiceChip(
              label: Text(c.replaceAll('_', ' ')), selected: sel,
              onSelected: (_) { Haptics.select(); setState(() => _condition = c); },
              backgroundColor: CC.surfaceHi, selectedColor: CC.accent,
              labelStyle: TextStyle(color: sel ? CC.ink : CC.text, fontWeight: FontWeight.w600, fontSize: 12.5),
            );
          }).toList()),
          const SizedBox(height: 28),
          CCButton('Post listing', loading: _saving, onTap: _save),
        ],
      ),
    );
  }
}
