import 'package:flutter/material.dart';

import '../currencies.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';

/// Searchable currency list. During onboarding ([onboarding] = true) it's the screen right
/// after sign-up; from Account it's pushed and pops once a currency is chosen.
class CurrencyPickerScreen extends StatefulWidget {
  const CurrencyPickerScreen({super.key, this.onboarding = false});
  final bool onboarding;

  @override
  State<CurrencyPickerScreen> createState() => _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends State<CurrencyPickerScreen> {
  final _search = TextEditingController();
  String? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selected ??= SpentScope.of(context).currency ?? suggestedCurrency();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _confirm() {
    SpentScope.of(context).setCurrency(_selected!);
    if (!widget.onboarding) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final list = allCurrencies
        .where((c) => q.isEmpty || c.code.toLowerCase().contains(q) || c.name.toLowerCase().contains(q))
        .toList();
    final firstName = SpentScope.of(context).user?.name.split(' ').first ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (widget.onboarding)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Step 2 of 2'),
                    const SizedBox(height: 10),
                    Text('Hi $firstName, which currency do you spend in?', style: t(26, FontWeight.w700, height: 1.15, tracking: -0.6)),
                    const SizedBox(height: 6),
                    Text('You can change this later in Account.', style: t(14, FontWeight.w400, color: C.inkMuted)),
                  ],
                ),
              )
            else
              const ScreenHeader('Currency'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: t(15, FontWeight.w500),
                cursorColor: C.brand,
                decoration: InputDecoration(
                  hintText: 'Search currency or code (e.g. INR)',
                  hintStyle: t(15, FontWeight.w400, color: C.inkFaint),
                  prefixIcon: const Icon(Icons.search_rounded, color: C.inkFaint, size: 20),
                  filled: true,
                  fillColor: C.pill,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? EmptyNote('No currency matches "${_search.text}".')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _row(list[i]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: 'Use ${currencyInfo(_selected!).name} (${_selected!})',
                  background: C.ink,
                  color: Colors.white,
                  height: 54,
                  onTap: _confirm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(CurrencyInfo c) {
    final on = c.code == _selected;
    return Pressable(
      onTap: () => setState(() => _selected = c.code),
      semanticLabel: '${c.name}, ${c.code}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: on ? C.pill : Colors.transparent, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: on ? C.brand : Colors.white, shape: BoxShape.circle, boxShadow: on ? null : softShadow),
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(currencySymbol(c.code), style: t(16, FontWeight.w700, color: on ? Colors.white : C.ink)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.code, style: t(15, FontWeight.w700)),
                  Text(c.name, style: t(13, FontWeight.w400, color: C.inkMuted)),
                ],
              ),
            ),
            if (on) const Icon(Icons.check_circle_rounded, color: C.brand, size: 22),
          ],
        ),
      ),
    );
  }
}
