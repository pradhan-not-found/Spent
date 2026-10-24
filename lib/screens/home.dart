import 'package:flutter/material.dart';

import '../brands.dart';
import '../categories.dart';
import '../payment_parser.dart';
import '../store.dart';
import '../sfx.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'categories_screen.dart';
import 'connected_apps.dart';
import 'details.dart';
import 'expenses.dart';
import 'notifications.dart';
import 'payments.dart';

/// Space the floating dock covers, so the last card always scrolls clear of it.
const dockClearance = 120.0;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenRecurring});
  final VoidCallback onOpenRecurring;

  @override
  Widget build(BuildContext context) {
    final s = SpentScope.of(context);
    final entries = s.entriesFor(s.month);
    final expenses = entries.where((e) => e.txn.isExpense);
    final recurring = expenses.where((e) => e.txn.recurring).toList();
    final oneOffTotal = sumOf(expenses.where((e) => !e.txn.recurring));
    final recurringTotal = sumOf(recurring);
    final spent = oneOffTotal + recurringTotal;
    final incomeTotal = sumOf(entries.where((e) => !e.txn.isExpense));
    final balance = incomeTotal - spent;
    final parts = s.month.split('-').map(int.parse).toList();
    final (year, month) = (parts[0], parts[1]);
    final name = s.user?.name.split(' ').first ?? '';
    // Recent means already happened; upcoming recurring charges live on the Recurring tab.
    final recent = entries.where((e) => e.date.compareTo(today()) <= 0).take(4).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, dockClearance + MediaQuery.of(context).padding.bottom),
      children: [
        SizedBox(
          height: 60,
          child: Row(
            children: [
              const Wordmark(),
              const Spacer(),
              RoundButton(
                icon: Icons.notifications_rounded,
                label: 'Notifications',
                background: Colors.white,
                shadow: true,
                badge: s.hasUnread,
                onTap: () => push(context, const NotificationsScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SectionTitle('Overview'),
        const SizedBox(height: 8),
        Text('Hello $name!', style: t(32, FontWeight.w700, height: 1.15, tracking: -0.8)),
        const SizedBox(height: 4),
        Text(
          '${recurring.length} recurring payment${recurring.length == 1 ? '' : 's'} this month',
          style: t(15, FontWeight.w600),
        ),
        if (s.inbox.isNotEmpty) ...[
          const SizedBox(height: 20),
          _InboxCard(store: s),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: monthNames[month - 1],
                onTap: () => _pick(context, 'Month', monthNames, month - 1,
                    (i) => s.setMonth('$year-${(i + 1).toString().padLeft(2, '0')}')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PillButton(
                label: '$year',
                onTap: () {
                  final now = DateTime.now().year;
                  final years = [for (var y = now - 4; y <= now + 1; y++) '$y'];
                  _pick(context, 'Year', years, years.indexOf('$year'),
                      (i) => s.setMonth('${years[i]}-${month.toString().padLeft(2, '0')}'));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Income',
                value: money(context, incomeTotal),
                colors: const [C.mint, C.mintSoft],
                compact: true,
                onTap: () => push(context, const TransactionsScreen(filter: TxnFilter.income)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Expenses',
                value: money(context, oneOffTotal),
                colors: const [C.brand, C.brandSoft],
                compact: true,
                onTap: () => push(context, const TransactionsScreen(filter: TxnFilter.oneOff)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          label: 'Recurring Payments',
          value: money(context, recurringTotal),
          colors: const [C.sky, C.skySoft],
          onTap: onOpenRecurring,
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          label: 'Balance',
          value: '${balance < 0 ? '−' : ''}${money(context, balance.abs())}',
          caption: 'Total spent ${money(context, spent)}',
          colors: const [C.gray, C.graySoft],
          onTap: () => push(context, const TransactionsScreen(filter: TxnFilter.all)),
        ),
        const SizedBox(height: 20),
        _TodayCard(store: s),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader('Recent activity', onSeeAll: () => push(context, const TransactionsScreen(filter: TxnFilter.all))),
              const SizedBox(height: 6),
              if (recent.isEmpty)
                const EmptyNote('Nothing yet this month.\nTap + to add an expense or income.')
              else
                for (final e in recent) TxnRow(e, onTap: () => openEditor(context, Draft.of(e.txn))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader('By category', onSeeAll: () => push(context, const CategoriesScreen())),
              const SizedBox(height: 16),
              CategoryBars(entries, limit: 3),
            ],
          ),
        ),
      ],
    );
  }

  void _pick(BuildContext context, String title, List<String> options, int selected, ValueChanged<int> onPick) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              SectionTitle(title),
              const SizedBox(height: 8),
              for (var i = 0; i < options.length; i++)
                Pressable(
                  onTap: () {
                    onPick(i);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: i == selected ? C.pill : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(options[i], style: t(15, FontWeight.w600))),
                        if (i == selected) const Icon(Icons.check_rounded, size: 18, color: C.brand),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void push(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

/// Payments picked up from connected apps, waiting for a yes/no.
class _InboxCard extends StatelessWidget {
  const _InboxCard({required this.store});
  final SpentStore store;

  @override
  Widget build(BuildContext context) {
    final items = store.inbox.take(4).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionTitle('Detected payments · ${store.inbox.length}', color: C.brand),
              const Spacer(),
              Pressable(
                onTap: () {
                  Sfx.success();
                  for (final d in [...store.inbox]) {
                    store.acceptDetected(d);
                  }
                  toast(context, 'Added to your transactions.');
                },
                child: Text('Add all', style: t(15, FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final d in items) _row(context, d),
          if (store.inbox.length > items.length)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('+${store.inbox.length - items.length} more', style: t(13, FontWeight.w500, color: C.inkMuted)),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, Detected d) {
    final p = parsePayment(d.text);
    final app = paymentApp(d.app);
    if (p == null || app == null) return const SizedBox.shrink();
    final expense = p.type == TxType.expense;
    final posted = DateTime.fromMillisecondsSinceEpoch(d.postedAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          AppLogo(app, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title, style: t(15, FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  '${expense ? '' : '+'}${moneyExact(context, p.amount)} · ${app.name} · ${dayHeading(isoDate(posted))}',
                  style: t(13, FontWeight.w400, color: expense ? C.inkMuted : C.income),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          RoundButton(icon: Icons.close_rounded, label: 'Skip', onTap: () {
            Sfx.remove();
            store.dismissDetected(d);
          }),
          const SizedBox(width: 8),
          RoundButton(
            icon: Icons.check_rounded,
            label: 'Add',
            background: C.ink,
            color: Colors.white,
            onTap: () {
              Sfx.success();
              store.acceptDetected(d);
            },
          ),
        ],
      ),
    );
  }
}

/// End-of-day check: what went out today, plus one-tap ways to bring in UPI payments.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.store});
  final SpentStore store;

  @override
  Widget build(BuildContext context) {
    final todays = store.entriesOn(today());
    final out = sumOf(todays.where((e) => e.txn.isExpense));
    final count = todays.where((e) => e.txn.isExpense).length;
    final inc = sumOf(todays.where((e) => !e.txn.isExpense));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionTitle('Today'),
              const Spacer(),
              if (inc > 0) Text('+${moneyExact(context, inc)} in', style: t(13, FontWeight.w600, color: C.income)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(moneyExact(context, out), style: t(28, FontWeight.w700, height: 1, tracking: -0.6)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  count == 0 ? 'spent so far' : 'across $count payment${count == 1 ? '' : 's'}',
                  style: t(13, FontWeight.w500, color: C.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Paid with GPay, PhonePe or Paytm today? Add it before the day ends.',
            style: t(13, FontWeight.w400, color: C.inkMuted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'Paste & add',
                  icon: Icons.content_paste_rounded,
                  height: 44,
                  onTap: () => push(context, const PaymentsScreen()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PillButton(
                  label: 'Pay via UPI',
                  icon: Icons.qr_code_rounded,
                  height: 44,
                  onTap: () => push(context, const PaymentsScreen(startOnUpi: true)),
                ),
              ),
            ],
          ),
          if (store.connectedApps.isEmpty) ...[
            const SizedBox(height: 12),
            Pressable(
              onTap: () => push(context, const ConnectedAppsScreen()),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: C.pill, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    for (final a in paymentApps.take(3))
                      Padding(padding: const EdgeInsets.only(right: 6), child: AppLogo(a, size: 28)),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Auto-track your payment apps', style: t(13, FontWeight.w600))),
                    const Icon(Icons.chevron_right_rounded, color: C.inkFaint),
                  ],
                ),
              ),
            ),
          ],
          if (todays.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => push(context, const TransactionsScreen(filter: TxnFilter.today)),
                child: Text('Review today', style: t(13, FontWeight.w600, color: C.brand)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.colors,
    required this.onTap,
    this.caption,
    this.compact = false,
  });
  final String label;
  final String value;
  final String? caption;
  final List<Color> colors;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        semanticLabel: '$label $value',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(label, color: Colors.white),
              SizedBox(height: compact ? 12 : 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: t(compact ? 24 : 30, FontWeight.w700, color: Colors.white, height: 1, tracking: -0.6)),
              ),
              if (caption != null) ...[
                const SizedBox(height: 6),
                Text(caption!, style: t(13, FontWeight.w500, color: Colors.white.withValues(alpha: 0.92))),
              ],
            ],
          ),
        ),
      );
}

class _CardHeader extends StatelessWidget {
  const _CardHeader(this.title, {required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SectionTitle(title),
          const Spacer(),
          Pressable(onTap: onSeeAll, child: Text('See all', style: t(15, FontWeight.w600))),
        ],
      );
}
