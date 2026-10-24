import 'package:flutter/material.dart';

import '../brands.dart';
import '../categories.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../sfx.dart';
import '../widgets.dart';
import 'amount.dart';

/// Start a new transaction: amount first, then details.
void openNew(BuildContext context, {TxType type = TxType.expense}) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AmountScreen(draft: Draft(type: type)), fullscreenDialog: true),
    );

/// Edit an existing transaction: straight to details (the amount can be changed from there).
void openEditor(BuildContext context, Draft draft) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DetailsScreen(draft: draft)));

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.draft});
  final Draft draft;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Draft get d => widget.draft;
  bool get _income => d.type == TxType.income;
  late final _title = TextEditingController(text: d.title);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _changeAmount() async {
    final v = await Navigator.of(context).push<double>(
      MaterialPageRoute(builder: (_) => AmountScreen(draft: d, returnResult: true), fullscreenDialog: true),
    );
    if (v != null) setState(() => d.amount = v);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseIso(d.date),
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => d.date = isoDate(picked));
  }

  void _save() {
    Sfx.success();
    d.title = _title.text;
    SpentScope.of(context).save(d);
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(_income ? 'Delete income?' : 'Delete expense?', style: t(18, FontWeight.w700)),
        content: Text(
          d.recurring ? 'This removes it from every month.' : 'This can\'t be undone.',
          style: t(14, FontWeight.w400, color: C.inkMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: t(15, FontWeight.w600))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: t(15, FontWeight.w600, color: C.brand)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Sfx.remove();
      SpentScope.of(context).remove(d.id!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = d.id != null;
    final noun = _income ? 'income' : 'expense';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              editing ? 'Edit $noun' : 'New $noun',
              trailing: editing
                  ? RoundButton(icon: Icons.delete_outline_rounded, label: 'Delete', onTap: _delete)
                  : null,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Pressable(
                    onTap: _changeAmount,
                    semanticLabel: 'Change amount',
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: _income ? const [C.mint, C.mintSoft] : const [C.brand, C.brandSoft],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SectionTitle(_income ? 'Money in' : 'Amount', color: Colors.white),
                              const Spacer(),
                              Text('Change', style: t(13, FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            moneyExact(context, d.amount),
                            style: t(34, FontWeight.w700, color: Colors.white, height: 1, tracking: -0.8),
                          ),
                          if (d.source != TxSource.manual) ...[
                            const SizedBox(height: 8),
                            Text(
                              switch (d.source) {
                                TxSource.upi => 'Paid via UPI',
                                TxSource.detected => 'Detected from ${paymentApp(d.app)?.name ?? 'a payment app'}',
                                _ => 'Read from a payment message',
                              },
                              style: t(12, FontWeight.w500, color: Colors.white.withValues(alpha: 0.9)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionTitle(_income ? 'Where is it from?' : 'What was it?'),
                  const SizedBox(height: 10),
                  PillField(
                    controller: _title,
                    hint: _income ? 'e.g. October salary, Client invoice' : 'e.g. Rent, Coffee, Netflix',
                    autofocus: !editing && d.title.isEmpty,
                    capitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle('Category'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                    children: [for (final c in categoriesFor(d.type)) _categoryChip(c)],
                  ),
                  const SizedBox(height: 20),
                  SectionTitle(_income ? 'Received in' : 'Paid with'),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        _appChip(null),
                        for (final a in paymentApps) _appChip(a),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle('Details'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: C.pill, borderRadius: BorderRadius.circular(22)),
                    child: Column(
                      children: [
                        _row(
                          icon: Icons.calendar_today_rounded,
                          label: d.recurring ? 'First date' : 'Date',
                          onTap: _pickDate,
                          trailing: Text(dayHeading(d.date), style: t(15, FontWeight.w600)),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE2E2E2)),
                        _row(
                          icon: Icons.history_rounded,
                          label: 'Repeats monthly',
                          onTap: () => setState(() => d.recurring = !d.recurring),
                          trailing: Switch.adaptive(
                            value: d.recurring,
                            activeTrackColor: _income ? C.mint : C.sky,
                            onChanged: (v) => setState(() => d.recurring = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: editing ? 'Save changes' : 'Add $noun',
                  background: C.ink,
                  color: Colors.white,
                  height: 52,
                  onTap: d.amount > 0 ? _save : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One "Paid with" option; null means cash, card, or not recorded.
  Widget _appChip(PaymentApp? a) {
    final on = d.app == a?.id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: () {
          Sfx.select();
          setState(() => d.app = a?.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 42,
          padding: EdgeInsets.only(left: a == null ? 14 : 5, right: 14),
          decoration: BoxDecoration(
            color: on ? Colors.white : C.pill,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: on ? (a?.color ?? C.ink) : Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              if (a == null)
                const Icon(Icons.payments_outlined, size: 18, color: C.inkMuted)
              else
                AppLogo(a, size: 30),
              const SizedBox(width: 8),
              Text(a?.name ?? 'Cash / other', style: t(13, FontWeight.w600, color: on ? C.ink : C.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(Category c) {
    final selected = d.categoryId == c.id;
    return Pressable(
      onTap: () {
        Sfx.select();
        setState(() => d.categoryId = c.id);
      },
      semanticLabel: c.name,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? c.color : Colors.transparent, width: 2),
            ),
            child: CategoryAvatar(c.id, size: 42),
          ),
          const SizedBox(height: 4),
          Text(
            c.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t(11, selected ? FontWeight.w600 : FontWeight.w400, color: selected ? C.ink : C.inkMuted),
          ),
        ],
      ),
    );
  }

  Widget _row({required IconData icon, required String label, required VoidCallback onTap, required Widget trailing}) =>
      Pressable(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 18, color: C.inkMuted),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: t(15, FontWeight.w500))),
                trailing,
              ],
            ),
          ),
        ),
      );
}
