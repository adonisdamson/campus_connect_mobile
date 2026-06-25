import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/api.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../auth/auth_provider.dart';

// ── Edit profile ──
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _name = TextEditingController(text: context.read<AuthProvider>().user?.fullName ?? '');
  late final _phone = TextEditingController(text: context.read<AuthProvider>().user?.phone ?? '');
  final _address = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      await Api.instance.put('/profile', {
        'fullName': _name.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
      });
      await auth.refreshMe();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } on ApiException catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: CC.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        CCField('Full name', _name, icon: PhosphorIconsRegular.user),
        const SizedBox(height: 14),
        CCField('Phone', _phone, icon: PhosphorIconsRegular.phone, keyboard: TextInputType.phone),
        const SizedBox(height: 14),
        CCField('Default address', _address, icon: PhosphorIconsRegular.mapPin),
        const SizedBox(height: 28),
        CCButton('Save changes', loading: _saving, onTap: _save),
      ]),
    );
  }
}

// ── Referral ──
class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final code = context.watch<AuthProvider>().user?.referralCode ?? '—';
    return Scaffold(
      appBar: AppBar(title: const Text('Refer & earn')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(CC.radius), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1DE26F), CC.lime])),
            child: Column(children: [
              Text('YOUR CODE', style: TextStyle(color: CC.ink.withValues(alpha: 0.7), fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Text(code, style: AppTheme.mono(size: 30, weight: FontWeight.w500, color: CC.ink)),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Share your code with friends. When they take their first ride or order, you both earn campus credit.', textAlign: TextAlign.center, style: TextStyle(color: CC.textDim, height: 1.5)),
          const SizedBox(height: 24),
          CCButton('Copy code', icon: PhosphorIconsRegular.copy, onTap: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
          }),
        ]),
      ),
    );
  }
}

// ── Static legal/help screens ──
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  static const _faqs = [
    ('How do I request a ride?', 'Tap Ride on the home screen, confirm your route, choose a class and request. The nearest driver is matched automatically.'),
    ('How are drivers and couriers paid?', 'Fares and delivery fees are credited to the partner wallet on completion. Partners request payouts to mobile money.'),
    ('Is my payment secure?', 'Payments run through Paystack (cards + mobile money). Campus Connect never stores your full card details.'),
    ('How do I become a seller or vendor?', 'Open Account → choose a role, submit your ID + a selfie for verification, and start once approved.'),
    ('How do I report a problem?', 'Every listing and chat has a report option, or reach support below.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        ..._faqs.map((f) => Card(
              color: CC.surface,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CC.radiusSm)),
              child: ExpansionTile(
                iconColor: CC.lime,
                collapsedIconColor: CC.textDim,
                title: Text(f.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [Text(f.$2, style: const TextStyle(color: CC.textDim, height: 1.5))],
              ),
            )),
        const SizedBox(height: 12),
        const CCCard(child: Row(children: [
          Icon(PhosphorIconsFill.headset, color: CC.lime),
          SizedBox(width: 12),
          Expanded(child: Text('Contact support: support@campusconnect.app', style: TextStyle(fontWeight: FontWeight.w600))),
        ])),
      ]),
    );
  }
}

class LegalScreen extends StatelessWidget {
  final String title, body;
  const LegalScreen({super.key, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(body, style: const TextStyle(color: CC.textDim, height: 1.6)),
      ),
    );
  }
}

const kPrivacyText =
    'Campus Connect respects your privacy. We collect only the data needed to run rides, '
    'deliveries, the marketplace and services — your name, contact details, location while '
    'a trip is active, and transaction history. Location is used solely to match you with '
    'nearby partners and is not shared with third parties for advertising. Verification '
    'documents are stored securely and used only to confirm partner identity. You can '
    'request deletion of your account and associated data at any time via support.';

const kTermsText =
    'By using Campus Connect you agree to use the platform lawfully and respectfully. '
    'Riders and customers agree to pay confirmed fares and fees. Partners agree to provide '
    'safe, timely service and to keep their vehicle and documents valid. Sellers are '
    'responsible for the accuracy and legality of their listings. Campus Connect is a '
    'marketplace connecting members of the campus community and is not party to individual '
    'transactions. Abuse, fraud or unsafe behaviour may result in suspension or a ban.';
