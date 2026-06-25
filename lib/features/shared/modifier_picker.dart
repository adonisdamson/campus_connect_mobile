import 'package:flutter/material.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models.dart';

/// Bottom sheet to choose a product's modifiers (e.g. Size, Extras). Returns the
/// chosen options as [{group, label, price}], or null if dismissed. Enforces
/// required single-select groups; multi groups allow any number.
Future<List<Map<String, dynamic>>?> pickModifiers(BuildContext context, Product product) {
  return showModalBottomSheet<List<Map<String, dynamic>>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CC.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _ModifierSheet(product: product),
  );
}

class _ModifierSheet extends StatefulWidget {
  final Product product;
  const _ModifierSheet({required this.product});
  @override
  State<_ModifierSheet> createState() => _ModifierSheetState();
}

class _ModifierSheetState extends State<_ModifierSheet> {
  // group name -> set of chosen labels
  final Map<String, Set<String>> _chosen = {};

  bool _isMulti(Map g) => g['multi'] == true;
  bool _isRequired(Map g) => g['required'] == true;

  void _toggle(Map group, Map choice) {
    Haptics.select();
    final name = '${group['name']}';
    final label = '${choice['label']}';
    setState(() {
      final set = _chosen.putIfAbsent(name, () => <String>{});
      if (_isMulti(group)) {
        set.contains(label) ? set.remove(label) : set.add(label);
      } else {
        set
          ..clear()
          ..add(label);
      }
    });
  }

  bool get _valid {
    for (final g in widget.product.options) {
      if (_isRequired(g) && (_chosen['${g['name']}']?.isEmpty ?? true)) return false;
    }
    return true;
  }

  double get _extra {
    var total = 0.0;
    for (final g in widget.product.options) {
      final picked = _chosen['${g['name']}'] ?? {};
      for (final c in (g['choices'] as List? ?? [])) {
        if (picked.contains('${c['label']}')) total += (c['price'] as num?)?.toDouble() ?? 0;
      }
    }
    return total;
  }

  List<Map<String, dynamic>> _result() {
    final out = <Map<String, dynamic>>[];
    for (final g in widget.product.options) {
      final picked = _chosen['${g['name']}'] ?? {};
      for (final c in (g['choices'] as List? ?? [])) {
        if (picked.contains('${c['label']}')) {
          out.add({'group': '${g['name']}', 'label': '${c['label']}', 'price': (c['price'] as num?)?.toDouble() ?? 0});
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final total = p.price + _extra;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: CC.line, borderRadius: BorderRadius.circular(4))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Align(alignment: Alignment.centerLeft, child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final g in p.options) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                    child: Row(children: [
                      Text('${g['name']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(width: 8),
                      Text(_isRequired(g) ? 'Required' : (_isMulti(g) ? 'Choose any' : 'Choose one'),
                          style: const TextStyle(color: CC.textFaint, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  for (final c in (g['choices'] as List? ?? []))
                    _choiceTile(g, c as Map),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: CCButton(
                _valid ? 'Add  •  GHS ${total.toStringAsFixed(2)}' : 'Select required options',
                onTap: _valid ? () => Navigator.pop(context, _result()) : null,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _choiceTile(Map group, Map choice) {
    final name = '${group['name']}';
    final label = '${choice['label']}';
    final price = (choice['price'] as num?)?.toDouble() ?? 0;
    final selected = _chosen[name]?.contains(label) ?? false;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _toggle(group, choice),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(children: [
          Icon(
            _isMulti(group)
                ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
                : (selected ? Icons.radio_button_checked : Icons.radio_button_off),
            color: selected ? CC.accent : CC.textFaint,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          if (price > 0) Text('+GHS ${price.toStringAsFixed(2)}', style: AppTheme.mono(size: 12.5, color: CC.textDim)),
        ]),
      ),
    );
  }
}
