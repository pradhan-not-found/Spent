import 'package:flutter/material.dart';

import '../categories.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'details.dart';
import 'home.dart' show dockClearance;

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SpentScope.of(context);
    final items = s.txns.where((e) => e.recurring).toList()
      ..sort((a, b) => s.nextCharge(a).compareTo(s.nextCharge(b)));
    final payments = items.where((e) => e.isExpense).toList();
    final monthly = payments.fold(0.0, (a, e) => a + e.amount);
    final monthlyIn = items.where((e) => !e.isExpense).fold(0.0, (a, e) => a + e.amount);

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, dockClearance + MediaQuery.of(context).padding.bottom),
      children: [
        SizedBox(height: 60, child: Align(alignment: Alignment.centerLeft, child: Text('Recurring', style: t(28, FontWeight.w700, tracking: -0.6)))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.sky, C.skySoft]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Goes out every month', color: Colors.white),
              const SizedBox(height: 14),
              Text(money(context, monthly), style: t(30, FontWeight.w700, color: Colors.white, height: 1, tracking: -0.6)),
              const SizedBox(height: 6),
              Text(
                '${payments.length} payment${payments.length == 1 ? '' : 's'} · ${money(context, monthly * 12)} a year'
                '${monthlyIn > 0 ? ' · ${money(context, monthlyIn)} comes in' : ''}',
                style: t(13, FontWeight.w500, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Upcoming'),
              const SizedBox(height: 6),
              if (items.isEmpty)
                const EmptyNote('No recurring payments yet.\nTurn on "Repeats monthly" when adding\nrent, subscriptions or salary.')
              else
                for (final e in items) _row(context, e, s.nextCharge(e)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, Txn e, String next) {
    final days = parseIso(next).difference(parseIso(today())).inDays;
    final when = switch (days) { 0 => 'Today', 1 => 'Tomorrow', _ => 'In $days days' };
    return Pressable(
      onTap: () => openEditor(context, Draft.of(e)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CategoryAvatar(e.categoryId),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title, style: t(15, FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${categoryOf(e.categoryId).name} · ${shortDate(next)}', style: t(13, FontWeight.w400, color: C.inkMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${e.isExpense ? '' : '+'}${moneyExact(context, e.amount)}',
                    style: t(15, FontWeight.w700, color: e.isExpense ? C.ink : C.income)),
                Text(when, style: t(12, FontWeight.w600, color: e.isExpense && days <= remindDays ? C.brand : C.inkFaint)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
