import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/brand.dart';
import '../../core/campus.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models.dart';
import '../shared/campus_picker.dart';
import 'auth_provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CC.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Signature pulse — the brand anchor doubles as the loading state
            // (no spinner). Real app icon sits centred over expanding rings.
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const _PulseRings(),
                  Brand.appIcon(size: 96, radius: 26)
                      .animate()
                      .scale(begin: const Offset(0.72, 0.72), end: const Offset(1, 1), duration: 560.ms, curve: Curves.easeOutBack)
                      .fadeIn(duration: 360.ms),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _Wordmark()
                .animate()
                .fadeIn(delay: 220.ms, duration: 500.ms)
                .slideY(begin: 0.3, curve: Curves.easeOut),
            const SizedBox(height: 10),
            Text('Your Campus. Connected.',
                    style: TextStyle(color: CC.textFaint, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2))
                .animate()
                .fadeIn(delay: 460.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

/// Expanding radar rings in the brand accent — the app's signature pulse.
class _PulseRings extends StatelessWidget {
  const _PulseRings();

  Widget _ring(int delayMs) => Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: CC.accent, width: 1.6),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .scaleXY(begin: 0.42, end: 1.0, duration: 2600.ms, delay: delayMs.ms, curve: Curves.easeOut)
          .fadeOut(duration: 2600.ms, delay: delayMs.ms, curve: Curves.easeIn);

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.center, children: [_ring(0), _ring(870), _ring(1740)]);
  }
}

/// "Campus" (soft white) / "Connect" (brand green) — matches the logo lockup.
class _Wordmark extends StatelessWidget {
  const _Wordmark();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Campus',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 26, height: 1.05, color: CC.text, letterSpacing: -0.6)),
        Text('Connect',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 26, height: 1.05, color: CC.accent, letterSpacing: -0.6)),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) {
    // The real app icon — not the legacy geometric mark.
    return Brand.appIcon(size: 56, radius: 56 * 0.28)
        .animate()
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 460.ms, curve: Curves.easeOutBack);
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    final ok = await context.read<AuthProvider>().login(_email.text.trim(), _password.text);
    if (mounted) setState(() => _loading = false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<AuthProvider>().error ?? 'Login failed'), backgroundColor: CC.danger),
      );
    }
  }

  Future<void> _google() async {
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (mounted) setState(() => _googleLoading = false);
    if (!ok && mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: CC.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: ResponsiveCenter(maxWidth: 460, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Logo(),
              const SizedBox(height: 28),
              Text('Welcome\nback.', style: Theme.of(context).textTheme.displayLarge)
                  .animate().fadeIn().slideX(begin: -0.1),
              const SizedBox(height: 8),
              const Text('Your campus, one tap away.', style: TextStyle(color: CC.textDim, fontSize: 15)),
              const SizedBox(height: 36),
              CCField('Email', _email, icon: PhosphorIconsRegular.envelopeSimple, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 14),
              CCField('Password', _password, icon: PhosphorIconsRegular.lock, obscure: true),
              const SizedBox(height: 24),
              CCButton('Sign in', loading: _loading, onTap: _submit),
              const SizedBox(height: 18),
              const _OrDivider(),
              const SizedBox(height: 18),
              CCButton('Continue with Google', outlined: true, icon: PhosphorIconsRegular.googleLogo, loading: _googleLoading, onTap: _google),
              const SizedBox(height: 14),
              CCButton('Continue as guest', outlined: true, onTap: () => context.read<AuthProvider>().guest()),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text.rich(TextSpan(text: "New here?  ", style: TextStyle(color: CC.textDim), children: [
                    TextSpan(text: 'Create account', style: TextStyle(color: CC.text, fontWeight: FontWeight.w700)),
                  ])),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }
}

/// Thin "or" rule used to separate primary auth from social / guest options.
class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: CC.line, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: CC.textFaint, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Divider(color: CC.line, thickness: 1)),
      ],
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  University? _campus;
  bool _loading = false;
  bool _googleLoading = false;

  Future<void> _google() async {
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle(universityId: _campus?.id);
    if (mounted) setState(() => _googleLoading = false);
    if (ok && mounted) Navigator.pop(context);
    if (!ok && mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: CC.danger),
      );
    }
  }

  Future<void> _pickCampus() async {
    final u = await pickCampus(context);
    if (u != null) {
      CampusService.apply(u);
      setState(() => _campus = u);
    }
  }

  Future<void> _submit() async {
    if (_campus == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select your campus')));
      return;
    }
    setState(() => _loading = true);
    final ok = await context.read<AuthProvider>().register(_email.text.trim(), _password.text, _name.text.trim(), universityId: _campus!.id);
    if (mounted) setState(() => _loading = false);
    if (ok && mounted) Navigator.pop(context);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<AuthProvider>().error ?? 'Sign up failed'), backgroundColor: CC.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: ResponsiveCenter(maxWidth: 460, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join the\ncampus.', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 32),
              CCField('Full name', _name, icon: PhosphorIconsRegular.user),
              const SizedBox(height: 14),
              CCField('Email', _email, icon: PhosphorIconsRegular.envelopeSimple, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 14),
              CCField('Password (min 6)', _password, icon: PhosphorIconsRegular.lock, obscure: true),
              const SizedBox(height: 14),
              Material(
                color: CC.surfaceHi,
                borderRadius: BorderRadius.circular(CC.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(CC.radiusSm),
                  onTap: _pickCampus,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                    child: Row(children: [
                      const Icon(PhosphorIconsRegular.graduationCap, color: CC.textFaint, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_campus?.shortName ?? 'Select your campus',
                          style: TextStyle(color: _campus == null ? CC.textFaint : CC.text, fontSize: 15.5, fontWeight: _campus == null ? FontWeight.w400 : FontWeight.w600))),
                      const Icon(PhosphorIconsRegular.caretDown, size: 16, color: CC.textFaint),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CCButton('Create account', loading: _loading, onTap: _submit),
              const SizedBox(height: 18),
              const _OrDivider(),
              const SizedBox(height: 18),
              CCButton('Continue with Google', outlined: true, icon: PhosphorIconsRegular.googleLogo, loading: _googleLoading, onTap: _google),
            ],
          )),
        ),
      ),
    );
  }
}
