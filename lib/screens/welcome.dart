import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

/// First screen for a signed-out user.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final returning = SpentScope.of(context).hasAccounts;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              const AppIcon(size: 84),
              const SizedBox(height: 28),
              Text('Know where\nyour money goes.', style: t(34, FontWeight.w700, height: 1.12, tracking: -1)),
              const SizedBox(height: 12),
              Text(
                'Track spending, income and recurring payments in one calm place. '
                'Log UPI payments from GPay, PhonePe or Paytm in seconds.',
                style: t(15, FontWeight.w400, color: C.inkMuted, height: 1.45),
              ),
              const SizedBox(height: 24),
              const _Point(color: C.brand, text: 'Expenses and income, month by month'),
              const _Point(color: C.sky, text: 'Reminders before recurring payments'),
              const _Point(color: C.mint, text: 'No bank linking. Your data stays on this device'),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: 'Create account',
                  background: C.ink,
                  color: Colors.white,
                  height: 54,
                  onTap: () => _go(context, const SignUpScreen()),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: returning ? 'Log in' : 'I already have an account',
                  height: 54,
                  onTap: () => _go(context, const LogInScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}

class _Point extends StatelessWidget {
  const _Point({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: t(14, FontWeight.w500))),
          ],
        ),
      );
}

/// Shared shell for the two auth forms.
class _AuthForm extends StatefulWidget {
  const _AuthForm({required this.title, required this.subtitle, required this.signUp});
  final String title;
  final String subtitle;
  final bool signUp;

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    // Let the spinner paint before the (deliberately slow) password hashing runs.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (!mounted) return;
    final store = SpentScope.of(context);
    try {
      if (widget.signUp) {
        store.signUp(name: _name.text, email: _email.text, password: _password.text);
      } else {
        store.logIn(email: _email.text, password: _password.text);
      }
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const ScreenHeader(''),
              Expanded(
                child: AutofillGroup(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      Text(widget.title, style: t(30, FontWeight.w700, tracking: -0.8)),
                      const SizedBox(height: 6),
                      Text(widget.subtitle, style: t(15, FontWeight.w400, color: C.inkMuted, height: 1.4)),
                      const SizedBox(height: 28),
                      if (widget.signUp) ...[
                        PillField(
                          controller: _name,
                          hint: 'Your name',
                          icon: Icons.person_outline_rounded,
                          autofocus: true,
                          capitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                      ],
                      PillField(
                        controller: _email,
                        hint: 'Email',
                        icon: Icons.mail_outline_rounded,
                        autofocus: !widget.signUp,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      PillField(
                        controller: _password,
                        hint: widget.signUp ? 'Password (6+ characters)' : 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _hidden,
                        autofillHints: [widget.signUp ? AutofillHints.newPassword : AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        suffix: IconButton(
                          tooltip: _hidden ? 'Show password' : 'Hide password',
                          icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: C.inkFaint),
                          onPressed: () => setState(() => _hidden = !_hidden),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        child: _error == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                child: Text(_error!, style: t(13, FontWeight.w500, color: C.brand)),
                              ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: _busy
                            ? const SizedBox(height: 54, child: Center(child: CircularProgressIndicator(color: C.brand, strokeWidth: 2.5)))
                            : PillButton(
                                label: widget.signUp ? 'Create account' : 'Log in',
                                background: C.ink,
                                color: Colors.white,
                                height: 54,
                                onTap: _submit,
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.signUp
                            ? 'Your account lives on this device. Spent never connects to your bank or UPI apps.'
                            : 'Accounts are stored on this device only, so there\'s no password reset. Keep it somewhere safe.',
                        textAlign: TextAlign.center,
                        style: t(12, FontWeight.w400, color: C.inkFaint, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AuthForm(
        title: 'Create your account',
        subtitle: 'It takes a few seconds. Next you\'ll pick your currency.',
        signUp: true,
      );
}

class LogInScreen extends StatelessWidget {
  const LogInScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AuthForm(
        title: 'Welcome back',
        subtitle: 'Log in to see your spending.',
        signUp: false,
      );
}
