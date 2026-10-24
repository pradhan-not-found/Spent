import 'package:flutter/material.dart';

import '../categories.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Clear the bell's dot once the list has been seen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SpentScope.of(context).markNotificationsSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = SpentScope.of(context).notices();
    final groups = <String, List<Notice>>{};
    for (final n in list) {
      groups.putIfAbsent(n.shownOn, () => []).add(n);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader('Notifications'),
            Expanded(
              child: list.isEmpty
                  ? const EmptyNote('No reminders yet.\nRecurring payments show up here\n3 days before they\'re taken.')
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        for (final MapEntry(key: day, value: items) in groups.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(2, 12, 0, 10),
                            child: SectionTitle(dayHeading(day), size: 14),
                          ),
                          for (final n in items) _NoticeCard(n),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard(this.n);
  final Notice n;

  @override
  Widget build(BuildContext context) {
    final upcoming = n.chargeOn.compareTo(today()) >= 0;
    final c = categoryOf(n.txn.categoryId);
    // Upcoming charges use the recurring blue; ones already taken fade to the brand tint.
    final (fg, bg) = upcoming ? (C.sky, const Color(0xFFD7F1FC)) : (C.brand, const Color(0xFFFFDCCB));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: softShadow),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(Icons.history_rounded, size: 18, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${n.txn.title} · ${c.name}', style: t(14, FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  upcoming ? 'Payment will be taken ${noticeDate(n.chargeOn)}.' : 'Payment was taken ${noticeDate(n.chargeOn)}.',
                  style: t(14, FontWeight.w400),
                ),
              ],
            ),
          ),
          Text(money(context, n.txn.amount, cents: n.txn.amount != n.txn.amount.roundToDouble()),
              style: t(14, FontWeight.w600, color: C.inkMuted)),
        ],
      ),
    );
  }
}
