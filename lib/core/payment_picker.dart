import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'api.dart';
import 'haptics.dart';
import 'theme.dart';
import 'widgets.dart';

/// A selectable payment option. `code` matches the backend PaymentMethod enum.
class PayMethod {
  final String code, label, sub;
  final IconData icon;
  const PayMethod(this.code, this.label, this.sub, this.icon);
}

const _methods = <PayMethod>[
  PayMethod('WALLET', 'Campus Wallet', 'Pay instantly from balance', PhosphorIconsFill.wallet),
  PayMethod('CASH', 'Cash', 'Pay the partner directly', PhosphorIconsFill.money),
  PayMethod('MTN_MOMO', 'MTN MoMo', 'Mobile money', PhosphorIconsFill.deviceMobile),
  PayMethod('TELECEL_CASH', 'Telecel Cash', 'Mobile money', PhosphorIconsFill.deviceMobile),
  PayMethod('AIRTELTIGO', 'AirtelTigo Money', 'Mobile money', PhosphorIconsFill.deviceMobile),
  PayMethod('CARD', 'Card', 'Visa / Mastercard', PhosphorIconsFill.creditCard),
];

PayMethod payMethodFor(String code) =>
    _methods.firstWhere((m) => m.code == code, orElse: () => _methods[1]);

/// Bottom sheet to choose how to pay. Returns the chosen method code, or null
/// if dismissed. Fetches the wallet balance so the wallet option shows it.
Future<String?> pickPayment(BuildContext context, {String selected = 'CASH'}) async {
  double? balance;
  try {
    final r = await Api.instance.get('/wallet');
    balance = (r['balance'] as num?)?.toDouble();
  } catch (_) {}
  if (!context.mounted) return null;
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: CC.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text('Payment method', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          ..._methods.map((m) {
            final isSel = m.code == selected;
            final sub = m.code == 'WALLET' && balance != null
                ? 'Balance GHS ${balance.toStringAsFixed(2)}'
                : m.sub;
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Haptics.tap();
                Navigator.pop(ctx, m.code);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.circular(12)),
                    child: Icon(m.icon, color: CC.lime, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(sub, style: const TextStyle(color: CC.textDim, fontSize: 12.5)),
                    ]),
                  ),
                  if (isSel) const Icon(PhosphorIconsFill.checkCircle, color: CC.lime),
                ]),
              ),
            );
          }),
        ]),
      ),
    ),
  );
}

/// Bottom sheet to choose a top-up amount (presets + custom). Returns GHS amount.
Future<double?> pickTopupAmount(BuildContext context) async {
  const presets = [20.0, 50.0, 100.0, 200.0];
  final custom = TextEditingController();
  return showModalBottomSheet<double>(
    context: context,
    backgroundColor: CC.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Top up wallet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final p in presets)
            GestureDetector(
              onTap: () {
                Haptics.tap();
                Navigator.pop(ctx, p);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(color: CC.surfaceHi, borderRadius: BorderRadius.circular(14)),
                child: Text('GHS ${p.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: CC.lime)),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        CCField('Custom amount (GHS)', custom, icon: PhosphorIconsRegular.currencyDollar, keyboard: TextInputType.number),
        const SizedBox(height: 16),
        CCButton('Continue', onTap: () {
          final v = double.tryParse(custom.text.trim());
          if (v != null && v > 0) Navigator.pop(ctx, v);
        }),
      ]),
    ),
  );
}
