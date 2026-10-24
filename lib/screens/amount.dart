import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../categories.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../sfx.dart';
import '../widgets.dart';
import 'details.dart';
import 'payments.dart';

enum _Op { plus, minus }

/// Calculator-style amount entry: type a number, optionally Plus/Minus another, then Continue.
///
/// For a new expense, Continue moves on to the details screen. When [returnResult] is set
/// (changing the amount of an existing draft) it pops with the new amount instead.
class AmountScreen extends StatefulWidget {
  const AmountScreen({super.key, required this.draft, this.returnResult = false});
  final Draft draft;
  final bool returnResult;

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  late String _input = widget.draft.amount > 0 ? _fmt(widget.draft.amount) : '';
  (double, _Op)? _pending;
  final _focus = FocusNode();

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '<'];

  double get _total {
    final n = double.tryParse(_input) ?? 0;
    final p = _pending;
    if (p == null) return _round(n);
    return _round(p.$2 == _Op.plus ? p.$1 + n : p.$1 - n);
  }

  void _press(String k) {
    Sfx.tap();
    _applyKey(k);
  }

  void _applyKey(String k) => setState(() {
        if (k == '<') {
          if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
        } else if (k == '.') {
          if (!_input.contains('.')) _input = '${_input.isEmpty ? '0' : _input}.';
        } else if (_input.contains('.') && _input.split('.')[1].length >= 2) {
          return;
        } else if (_input.replaceAll('.', '').length >= 8) {
          return;
        } else {
          _input = _input == '0' ? k : _input + k;
        }
      });

  void _operate(_Op op) {
    Sfx.tap();
    _applyOp(op);
  }

  void _applyOp(_Op op) => setState(() {
        _pending = (_total, op);
        _input = '';
      });

  void _continue() {
    final total = _total;
    if (total <= 0) return;
    if (widget.returnResult) {
      Navigator.pop(context, total);
      return;
    }
    widget.draft.amount = total;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => DetailsScreen(draft: widget.draft)));
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final ch = e.character;
    if (ch != null && RegExp(r'^[0-9.]$').hasMatch(ch)) {
      _press(ch);
    } else if (ch == '+') {
      _operate(_Op.plus);
    } else if (ch == '-') {
      _operate(_Op.minus);
    } else if (e.logicalKey == LogicalKeyboardKey.backspace) {
      _press('<');
    } else if (e.logicalKey == LogicalKeyboardKey.enter) {
      _continue();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = currencySymbol(SpentScope.of(context).money);
    final p = _pending;
    final faint = t(15, FontWeight.w600, color: Colors.white.withValues(alpha: 0.75));
    final income = widget.draft.type == TxType.income;

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: income ? const [C.mint, C.mintSoft] : const [C.brand, Color(0xFFF08A5D)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        RoundButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          label: 'Back',
                          background: Colors.white.withValues(alpha: 0.4),
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        if (!widget.returnResult) _typeToggle(income),
                        const Spacer(),
                        // Where the mockup has its QR button: bring a payment in from GPay / UPI.
                        if (!widget.returnResult)
                          RoundButton(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'From payment apps',
                            background: Colors.white.withValues(alpha: 0.4),
                            onTap: () => Navigator.of(context)
                                .pushReplacement(MaterialPageRoute<void>(builder: (_) => const PaymentsScreen())),
                          )
                        else
                          const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: p == null ? 0 : 1,
                          child: Text(p == null ? ' ' : '$symbol${_group(_fmt(p.$1))} ${p.$2 == _Op.plus ? '+' : '−'}', style: faint),
                        ),
                        FittedBox(
                          child: Text(
                            '$symbol${_group(_input.isEmpty ? '0' : _input)}',
                            style: t(66, FontWeight.w700, color: Colors.white, height: 1.1, tracking: -2),
                          ),
                        ),
                        Opacity(
                          opacity: p == null ? 0 : 1,
                          child: Text('= $symbol${_group(_fmt(_total))}', style: faint.copyWith(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.75,
                    children: [
                      for (final k in _keys)
                        Pressable(
                          onTap: () => _press(k),
                          semanticLabel: k == '<' ? 'Delete' : k,
                          child: Center(
                            child: k == '<'
                                ? const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)
                                : Text(k, style: t(26, FontWeight.w400, color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _white('Minus', () => _operate(_Op.minus))),
                      const SizedBox(width: 8),
                      Expanded(child: _white('Plus', () => _operate(_Op.plus))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _white('Continue', _total > 0 ? _continue : null),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color get _accent => widget.draft.type == TxType.income ? C.income : C.brand;

  Widget _white(String label, VoidCallback? onTap) =>
      PillButton(label: label, onTap: onTap, background: Colors.white, color: _accent, height: 50);

  void _setType(TxType type) {
    Sfx.select();
    _applyType(type);
  }

  void _applyType(TxType type) => setState(() {
        widget.draft.type = type;
        widget.draft.categoryId = defaultCategory(type);
      });

  /// Expense / Income switch, styled as a frosted pill on the gradient.
  Widget _typeToggle(bool income) => Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in TxType.values)
              Pressable(
                onTap: () => _setType(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.draft.type == type ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    type == TxType.expense ? 'Expense' : 'Income',
                    style: t(13, FontWeight.w600, color: widget.draft.type == type ? _accent : Colors.white),
                  ),
                ),
              ),
          ],
        ),
      );
}

double _round(double n) => (n * 100).roundToDouble() / 100;

/// Thousands separators on the whole part of what's being typed ("12000." → "12,000.").
String _group(String s) {
  final neg = s.startsWith('-');
  final body = neg ? s.substring(1) : s;
  final dot = body.indexOf('.');
  final whole = dot == -1 ? body : body.substring(0, dot);
  final grouped = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${neg ? '−' : ''}$grouped${dot == -1 ? '' : body.substring(dot)}';
}

String _fmt(double n) => n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
