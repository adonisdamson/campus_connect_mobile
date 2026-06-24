import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/haptics.dart';
import '../../core/places.dart';
import '../../core/theme.dart';

/// Opens a search sheet and returns the chosen [Place] (or null).
Future<Place?> pickPlace(BuildContext context, {String title = 'Where to?'}) {
  return showModalBottomSheet<Place>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CC.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _PlacePicker(title: title),
  );
}

class _PlacePicker extends StatefulWidget {
  final String title;
  const _PlacePicker({required this.title});
  @override
  State<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<_PlacePicker> {
  final _q = TextEditingController();
  List<Place> _results = [];
  bool _loading = false;
  Timer? _debounce;
  int _seq = 0; // guards against out-of-order async responses

  @override
  void initState() {
    super.initState();
    _run('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  // Debounce keystrokes so we don't hammer the geocoder (and the 2.5k/day cap).
  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () => _run(q));
  }

  Future<void> _run(String q) async {
    final mySeq = ++_seq;
    setState(() => _loading = true);
    final r = await PlacesService.search(q);
    if (!mounted || mySeq != _seq) return; // a newer query superseded this one
    setState(() { _results = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.66,
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: CC.line, borderRadius: BorderRadius.circular(4))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _q,
              autofocus: true,
              onChanged: _onChanged,
              style: const TextStyle(color: CC.text),
              decoration: InputDecoration(
                hintText: widget.title,
                hintStyle: const TextStyle(color: CC.textFaint),
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, color: CC.textFaint, size: 19),
                filled: true,
                fillColor: CC.surfaceHi,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(CC.radiusSm), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(CC.radiusSm), borderSide: BorderSide(color: CC.accent, width: 1.4)),
              ),
            ),
          ),
          if (_q.text.trim().isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(alignment: Alignment.centerLeft, child: Text('Campus locations', style: TextStyle(color: CC.textFaint, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6))),
            ),
          Expanded(
            child: _loading && _results.isEmpty
                ? const Center(child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4)))
                : _results.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No places found — try a different search', style: TextStyle(color: CC.textDim))))
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(color: CC.line, height: 1),
                        itemBuilder: (_, i) {
                          final p = _results[i];
                          return ListTile(
                            leading: Icon(PhosphorIconsRegular.mapPin, color: CC.accent),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () { Haptics.tap(); Navigator.pop(context, p); },
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}
