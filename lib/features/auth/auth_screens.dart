import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/brand.dart';
import '../../core/campus.dart';
import '../../core/config.dart';
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Logo(size: 72),
            const SizedBox(height: 20),
            Text(AppConfig.appName, style: Theme.of(context).textTheme.titleLarge)
                .animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
            const SizedBox(height: 28),
            const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4)),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final double size;
  const _Logo({this.size = 56});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CC.surfaceHi,
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(color: CC.line),
        boxShadow: [BoxShadow(color: CC.accent.withValues(alpha: 0.28), blurRadius: 26, spreadRadius: -4)],
      ),
      child: Brand.mark(size: size * 0.56),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
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
            ],
          )),
        ),
      ),
    );
  }
}
