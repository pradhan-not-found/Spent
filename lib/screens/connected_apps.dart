import 'package:flutter/material.dart';

import '../brands.dart';
import '../device_apps.dart';
import '../store.dart';
import '../sfx.dart';
import '../theme.dart';
import '../widgets.dart';

/// Pick which payment apps Spent should follow. On Android it shows which are installed
/// (with their real icons) and manages the Notification access permission.
class ConnectedAppsScreen extends StatefulWidget {
  const ConnectedAppsScreen({super.key});

  @override
  State<ConnectedAppsScreen> createState() => _ConnectedAppsScreenState();
}

class _ConnectedAppsScreenState extends State<ConnectedAppsScreen> with WidgetsBindingObserver {
  Set<String>? _installed;
  bool _access = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back from Android settings: re-check whether access was granted.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final installed = await DeviceApps.refreshInstalled();
    final access = await DeviceApps.listenerEnabled();
    if (mounted) {
      setState(() {
        _installed = DeviceApps.supported ? installed : null;
        _access = access;
      });
    }
  }

  Future<void> _toggle(SpentStore s, PaymentApp app, bool on) async {
    Sfx.select();
    s.setConnected(app.id, on);
    await DeviceApps.setWatched(s.connectedApps);
  }

  @override
  Widget build(BuildContext context) {
    final s = SpentScope.of(context);
    final installed = _installed;
    final onPhone = installed == null ? paymentApps : paymentApps.where((a) => installed.contains(a.package)).toList();
    final missing = installed == null ? <PaymentApp>[] : paymentApps.where((a) => !installed.contains(a.package)).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader('Payment apps'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(
                    'Choose the apps you pay with. Spent will spot their payment notifications and '
                    'put them in a review list. No bank login, no SMS access, nothing leaves your phone.',
                    style: t(14, FontWeight.w400, color: C.inkMuted, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  if (DeviceApps.supported) _accessCard() else _webNote(),
                  const SizedBox(height: 24),
                  SectionTitle(installed == null ? 'Payment apps' : 'On this phone'),
                  const SizedBox(height: 10),
                  if (installed != null && onPhone.isEmpty)
                    const EmptyNote('No supported payment apps found on this phone.')
                  else
                    _group([for (final a in onPhone) _appRow(s, a, available: true)]),
                  if (missing.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const SectionTitle('Not installed'),
                    const SizedBox(height: 10),
                    _group([for (final a in missing) _appRow(s, a, available: false)]),
                  ],
                  const SizedBox(height: 24),
                  _safety(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accessCard() => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _access ? const Color(0xFFE3F6EC) : const Color(0xFFFFEFE6),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Icon(_access ? Icons.verified_user_rounded : Icons.notifications_active_outlined,
                color: _access ? C.income : C.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_access ? 'Auto-tracking is on' : 'Allow notification access',
                      style: t(15, FontWeight.w700, color: _access ? C.income : C.brand)),
                  const SizedBox(height: 2),
                  Text(
                    _access
                        ? 'Spent reads payment alerts only from the apps switched on below.'
                        : 'Android asks you to allow this once. You can turn it off any time.',
                    style: t(13, FontWeight.w400, color: C.inkMuted, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PillButton(
              label: _access ? 'Manage' : 'Allow',
              height: 38,
              background: Colors.white,
              color: _access ? C.ink : C.brand,
              onTap: DeviceApps.openListenerSettings,
            ),
          ],
        ),
      );

  Widget _webNote() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: C.pill, borderRadius: BorderRadius.circular(22)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.phone_android_rounded, color: C.inkMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Finding installed apps and tracking their payments automatically works in the Spent '
                'Android app. Here you can still pick your apps and use Paste & add or Pay via UPI.',
                style: t(13, FontWeight.w400, color: C.inkMuted, height: 1.4),
              ),
            ),
          ],
        ),
      );

  Widget _appRow(SpentStore s, PaymentApp a, {required bool available}) {
    final on = s.connectedApps.contains(a.id);
    return Opacity(
      opacity: available ? 1 : 0.5,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              AppLogo(a, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name, style: t(15, FontWeight.w600)),
                    Text(
                      !available
                          ? 'Not on this phone'
                          : on
                              ? (DeviceApps.supported && !_access ? 'Waiting for notification access' : 'Tracking payments')
                              : 'Off',
                      style: t(12, FontWeight.w500, color: on ? C.income : C.inkFaint),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: on && available,
                activeTrackColor: C.income,
                onChanged: available ? (v) => _toggle(s, a, v) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _group(List<Widget> rows) => Container(
        decoration: BoxDecoration(color: C.pill, borderRadius: BorderRadius.circular(22)),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFE2E2E2)),
              rows[i],
            ],
          ],
        ),
      );

  Widget _safety() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('How Spent keeps this safe'),
          const SizedBox(height: 12),
          for (final (icon, text) in const [
            (Icons.filter_alt_outlined, 'Only notifications from the apps you switch on are read. Everything else is ignored.'),
            (Icons.fact_check_outlined, 'Detected payments wait in a review list. Nothing is added until you confirm it.'),
            (Icons.phonelink_lock_outlined, 'Everything is processed and stored on this phone. Nothing is uploaded.'),
            (Icons.block_rounded, 'Spent never asks for your UPI PIN or bank login, and never makes a payment on its own.'),
            (Icons.toggle_off_outlined, 'Switch an app off, or remove notification access in Android settings, to stop at any time.'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: C.inkMuted),
                  const SizedBox(width: 12),
                  Expanded(child: Text(text, style: t(13, FontWeight.w400, color: C.inkMuted, height: 1.4))),
                ],
              ),
            ),
        ],
      );
}
