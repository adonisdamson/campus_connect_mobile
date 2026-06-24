import 'package:flutter/foundation.dart';
import '../../models.dart';

class CartLine {
  final Product product;
  // Chosen modifiers: [{ group, label, price }]
  final List<Map<String, dynamic>> options;
  int qty;
  CartLine(this.product, this.qty, {this.options = const []});

  double get optionsTotal => options.fold(0.0, (s, o) => s + ((o['price'] as num?)?.toDouble() ?? 0));
  double get unitPrice => product.price + optionsTotal;
  double get lineTotal => unitPrice * qty;

  /// Distinct cart key — same product with different modifiers = separate line.
  String get key {
    final sig = options.map((o) => '${o['group']}:${o['label']}').toList()..sort();
    return '${product.id}|${sig.join(',')}';
  }

  String get optionsLabel => options.map((o) => o['label']).join(', ');
}

/// One open food cart at a time (single vendor), mirroring Uber Eats.
class CartProvider extends ChangeNotifier {
  String? vendorId;
  String? vendorName;
  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();
  int get count => _lines.values.fold(0, (s, l) => s + l.qty);
  double get subtotal => _lines.values.fold(0, (s, l) => s + l.lineTotal);
  bool get isEmpty => _lines.isEmpty;

  /// Add a product (optionally with chosen modifiers). Switching vendor clears
  /// the previous cart. Same product + same modifiers stacks; different
  /// modifiers create a separate line.
  void add(Product p, String vId, String vName, {List<Map<String, dynamic>> options = const []}) {
    if (vendorId != null && vendorId != vId) _lines.clear();
    vendorId = vId;
    vendorName = vName;
    final line = CartLine(p, 1, options: options);
    final existing = _lines[line.key];
    if (existing != null) {
      existing.qty++;
    } else {
      _lines[line.key] = line;
    }
    notifyListeners();
  }

  void incrementKey(String key) {
    final line = _lines[key];
    if (line == null) return;
    line.qty++;
    notifyListeners();
  }

  void decrementKey(String key) {
    final line = _lines[key];
    if (line == null) return;
    line.qty--;
    if (line.qty <= 0) _lines.remove(key);
    if (_lines.isEmpty) vendorId = null;
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    vendorId = null;
    vendorName = null;
    notifyListeners();
  }

  /// Payload for POST /orders — includes chosen modifiers per line.
  List<Map<String, dynamic>> get orderItems => _lines.values
      .map((l) => {
            'productId': l.product.id,
            'quantity': l.qty,
            if (l.options.isNotEmpty) 'options': l.options,
          })
      .toList();
}
