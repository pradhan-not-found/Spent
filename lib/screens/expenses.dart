import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'details.dart';

enum TxnFilter { all, oneOff, income, today }

/// Every transaction in the selected month (or today), grouped by day, with search.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.filter});
  final TxnFilter filter;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late var _filter = widget.filter;
  var _query = '';

  static const _labels = {
    TxnFilter.all: 'All',
    TxnFilter.oneOff: 'Spending',
    TxnFilter.income: 'Income',
    TxnFilter.today: 'Today',
  };

  bool _keep(Entry e) => switch (_filter) {
        TxnFilter.all => true,
        TxnFilter.oneOff => e.txn.isExpense && !e.txn.recurring,
        TxnFilter.income => !e.txn.isExpense,
        TxnFilter.today => true,
      };

  @override
  Widget build(BuildContext context) {
    final s = SpentScope.of(context);
    final q = _query.trim().toLowerCase();
    final source = _filter == TxnFilter.today ? s.entriesOn(today()) : s.entriesFor(s.month);
    final entries = source.where(_keep).where((e) => q.isEmpty || e.txn.title.toLowerCase().contains(q)).toList();
    final out = sumOf(entries.where((e) => e.txn.isExpense));
    final inc = sumOf(entries.where((e) => !e.txn.isExpense));
    final groups = <String, List<Entry>>{};
    for (final e in entries) {
      groups.putIfAbsent(e.date, () => []).add(e);
    }
    final parts = s.month.split('-').map(int.parse).toList();
    final period = _filter == TxnFilter.today ? 'Today' : '${monthNames[parts[1] - 1]} ${parts[0]}';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader('Transactions'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: SectionTitle(period)),
                      if (inc > 0) ...[
                        Text('+${moneyExact(context, inc)}', style: t(14, FontWeight.w700, color: C.income)),
                        const SizedBox(width: 10),
                      ],
                      Text('−${moneyExact(context, out)}', style: t(14, FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    style: t(15, FontWeight.w500),
                    cursorColor: C.brand,
                    decoration: InputDecoration(
                      hintText: 'Search transactions',
                      hintStyle: t(15, FontWeight.w400, color: C.inkFaint),
                      prefixIcon: const Icon(Icons.search_rounded, color: C.inkFaint, size: 20),
                      filled: true,
                      fillColor: C.pill,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in TxnFilter.values) ...[_chip(f), const SizedBox(width: 8)],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? EmptyNote(q.isEmpty ? 'Nothing here yet.' : 'Nothing matches "$_query".')
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        for (final MapEntry(key: day, value: items) in groups.entries) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 14, bottom: 4),
                            child: SectionTitle(dayHeading(day)),
                          ),
                          for (final e in items) TxnRow(e, onTap: () => openEditor(context, Draft.of(e.txn))),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(TxnFilter f) {
    final on = _filter == f;
    return Pressable(
      onTap: () => setState(() => _filter = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: on ? C.ink : C.pill, borderRadius: BorderRadius.circular(99)),
        child: Text(_labels[f]!, style: t(13, FontWeight.w600, color: on ? Colors.white : C.ink)),
      ),
    );
  }
}
