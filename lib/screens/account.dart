import 'package:flutter/material.dart';

import '../currencies.dart';
import '../sfx.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'connected_apps.dart';
import 'currency_picker.dart';
import 'home.dart' show dockClearance, push;
import 'payments.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  TextEditingController? _name;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _name ??= TextEditingController(text: SpentScope.of(context).user?.name ?? '');
  }

  @override
  void dispose() {
    _name?.dispose();
    super.dispose();
  }

  Future<void> _confirm(String title, String body, String action, VoidCallback run) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: t(18, FontWeight.w700)),
        content: Text(body, style: t(14, FontWeight.w400, color: C.inkMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: t(15, FontWeight.w600))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action, style: t(15, FontWeight.w600, color: C.brand))),
        ],
      ),
    );
    if (ok == true) run();
  }

  @override
  Widget build(BuildContext context) {
    final s = SpentScope.of(context);
    final user = s.user;
    final cur = currencyInfo(s.money);
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, dockClearance + MediaQuery.of(context).padding.bottom),
      children: [
        SizedBox(height: 60, child: Align(alignment: Alignment.centerLeft, child: Text('Account', style: t(28, FontWeight.w700, tracking: -0.6)))),
        const SizedBox(height: 8),
        AppCard(
          child: Row(
            children: [
              const AppIcon(size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? '', style: t(18, FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(user?.email ?? '', style: t(13, FontWeight.w400, color: C.inkMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${s.txns.length} transactions', style: t(12, FontWeight.w500, color: C.inkFaint)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Your name'),
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          onChanged: (v) {
            if (v.trim().isNotEmpty) s.setName(v.trim());
          },
          textCapitalization: TextCapitalization.words,
          style: t(15, FontWeight.w600),
          cursorColor: C.brand,
          decoration: InputDecoration(
            hintText: 'Shown on the home screen',
            hintStyle: t(15, FontWeight.w400, color: C.inkFaint),
            filled: true,
            fillColor: C.pill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Settings'),
        const SizedBox(height: 10),
        _group([
          _action(
            Icons.payments_outlined,
            'Currency',
            () => push(context, const CurrencyPickerScreen()),
            value: '${currencySymbol(cur.code)} ${cur.code}',
          ),
          _action(Icons.apps_rounded, 'Payment apps', () => push(context, const ConnectedAppsScreen()),
              value: s.connectedApps.isEmpty ? 'Off' : '${s.connectedApps.length} on'),
          _action(Icons.qr_code_rounded, 'Paste or pay via UPI', () => push(context, const PaymentsScreen())),
          _soundRow(s),
        ]),
        const SizedBox(height: 24),
        const SectionTitle('Data'),
        const SizedBox(height: 10),
        _group([
          _action(Icons.delete_sweep_outlined, 'Delete all transactions', () => _confirm(
                'Delete all transactions?',
                'Every expense, income and recurring payment in this account will be removed. This can\'t be undone.',
                'Delete all',
                () {
                  Sfx.remove();
                  s.clearAll();
                },
              ), danger: true),
        ]),
        const SizedBox(height: 24),
        const SectionTitle('Session'),
        const SizedBox(height: 10),
        _group([
          _action(Icons.logout_rounded, 'Log out', () => _confirm(
                'Log out?',
                'Your data stays saved on this device. Log in again with ${user?.email} to see it.',
                'Log out',
                s.logOut,
              )),
          _action(Icons.person_remove_outlined, 'Delete account', () => _confirm(
                'Delete your account?',
                'This removes ${user?.email} and all of its data from this device. This can\'t be undone.',
                'Delete account',
                () {
                  Sfx.remove();
                  s.deleteAccount();
                },
              ), danger: true),
        ]),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Spent stores everything on this device.\nIt never connects to your bank or UPI apps.',
            textAlign: TextAlign.center,
            style: t(12, FontWeight.w400, color: C.inkFaint, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _soundRow(SpentStore s) => SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            children: [
              const Icon(Icons.graphic_eq_rounded, size: 18, color: C.inkMuted),
              const SizedBox(width: 12),
              Expanded(child: Text('Sounds & haptics', style: t(15, FontWeight.w500))),
              Switch.adaptive(
                value: s.soundOn,
                activeTrackColor: C.brand,
                onChanged: (v) {
                  s.setSound(v);
                  if (v) Sfx.success();
                },
              ),
            ],
          ),
        ),
      );

  Widget _group(List<Widget> rows) => Container(
        decoration: BoxDecoration(color: C.pill, borderRadius: BorderRadius.circular(22)),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE2E2E2)),
              rows[i],
            ],
          ],
        ),
      );

  Widget _action(IconData icon, String label, VoidCallback onTap, {bool danger = false, String? value}) => Pressable(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 18, color: danger ? C.brand : C.inkMuted),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: t(15, FontWeight.w500, color: danger ? C.brand : C.ink))),
                if (value != null) Text(value, style: t(14, FontWeight.w600, color: C.inkMuted)),
                const Icon(Icons.chevron_right_rounded, color: C.inkFaint),
              ],
            ),
          ),
        ),
      );
}
