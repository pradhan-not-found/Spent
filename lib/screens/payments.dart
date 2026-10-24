import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../brands.dart';
import '../categories.dart';
import '../device_apps.dart';
import '../payment_parser.dart';
import '../store.dart';
import '../sfx.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'details.dart';

/// Bring payments in from GPay, PhonePe, Paytm or bank SMS without linking any account:
/// paste the notification text, or start a UPI payment from Spent so it's logged as you pay.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key, this.startOnUpi = false});
  final bool startOnUpi;

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late bool _upi = widget.startOnUpi;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const ScreenHeader('From payment apps'),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: _Segmented(
                  options: const ['Paste message', 'Pay via UPI'],
                  index: _upi ? 1 : 0,
                  onChanged: (i) => setState(() => _upi = i == 1),
                ),
              ),
              Expanded(child: _upi ? const _UpiPay() : const _PasteMessage()),
            ],
          ),
        ),
      );
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.options, required this.index, required this.onChanged});
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: C.pill, borderRadius: BorderRadius.circular(99)),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++)
              Expanded(
                child: Pressable(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: i == index ? softShadow : null,
                    ),
                    child: Text(options[i], style: t(14, FontWeight.w600, color: i == index ? C.ink : C.inkMuted)),
                  ),
                ),
              ),
          ],
        ),
      );
}

const _example =
    'You paid ₹249.00 to Swiggy using Google Pay. UPI Ref No 432178650912. 24 Oct 2026';

class _PasteMessage extends StatefulWidget {
  const _PasteMessage();

  @override
  State<_PasteMessage> createState() => _PasteMessageState();
}

class _PasteMessageState extends State<_PasteMessage> {
  final _text = TextEditingController();
  ParsedPayment? _parsed;
  bool _tried = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _read() => setState(() {
        _tried = true;
        _parsed = parsePayment(_text.text);
      });

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      toast(context, 'Your clipboard is empty. Copy the payment message first.');
      return;
    }
    _text.text = text;
    _read();
  }

  void _review() {
    final p = _parsed!;
    final draft = Draft(
      type: p.type,
      amount: p.amount,
      title: p.title,
      categoryId: p.categoryId,
      date: p.date,
      source: TxSource.message,
      app: p.app,
    );
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => DetailsScreen(draft: draft)));
  }

  @override
  Widget build(BuildContext context) {
    final p = _parsed;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(
          'Copy a payment notification or bank SMS, paste it here, and Spent fills in the details. '
          'Nothing is connected or uploaded.',
          style: t(14, FontWeight.w400, color: C.inkMuted, height: 1.45),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final a in paymentApps.take(4))
              Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E2E2)), borderRadius: BorderRadius.circular(99)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLogo(a, size: 22),
                    const SizedBox(width: 6),
                    Text(a.name, style: t(12, FontWeight.w500, color: C.inkMuted)),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E2E2)), borderRadius: BorderRadius.circular(99)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sms_outlined, size: 15, color: C.inkMuted),
                  const SizedBox(width: 6),
                  Text('Bank SMS', style: t(12, FontWeight.w500, color: C.inkMuted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PillField(controller: _text, hint: 'e.g. "Rs.450 debited from A/c XX12 to VPA zomato@icici on 24-10-26"', maxLines: 5),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: PillButton(label: 'Paste', icon: Icons.content_paste_rounded, onTap: _paste)),
            const SizedBox(width: 8),
            Expanded(child: PillButton(label: 'Read message', background: C.ink, color: Colors.white, onTap: _read)),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {
              _text.text = _example;
              _read();
            },
            child: Text('Try an example', style: t(13, FontWeight.w600, color: C.brand)),
          ),
        ),
        if (_tried && p == null)
          const EmptyNote('Couldn\'t find an amount in that message.\nMake sure it includes something like ₹250 or Rs. 250.'),
        if (p != null) ...[
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(p.type == TxType.expense ? 'Payment found' : 'Money received', color: p.type == TxType.expense ? C.ink : C.income),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TxnAvatar(Txn(
                      id: 'preview',
                      type: p.type,
                      title: p.title,
                      amount: p.amount,
                      categoryId: p.categoryId,
                      date: p.date,
                      recurring: false,
                      createdAt: 0,
                      app: p.app,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title, style: t(15, FontWeight.w600)),
                          Text(
                            [categoryOf(p.categoryId).name, dayHeading(p.date), ?paymentApp(p.app)?.name].join(' · '),
                            style: t(13, FontWeight.w400, color: C.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${p.type == TxType.expense ? '' : '+'}${moneyExact(context, p.amount)}',
                      style: t(17, FontWeight.w700, color: p.type == TxType.expense ? C.ink : C.income),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: PillButton(label: 'Review & save', background: C.brand, color: Colors.white, onTap: _review),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _UpiPay extends StatefulWidget {
  const _UpiPay();

  @override
  State<_UpiPay> createState() => _UpiPayState();
}

class _UpiPayState extends State<_UpiPay> {
  final _vpa = TextEditingController();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;

  /// The app to open; null lets Android show its own UPI app chooser.
  PaymentApp? _app = paymentApps.first;

  static final _vpaRe = RegExp(r'^[\w.\-]{2,256}@[a-zA-Z][a-zA-Z0-9]{1,64}$');

  @override
  void dispose() {
    for (final c in [_vpa, _name, _amount, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pay() async {
    final vpa = _vpa.text.trim();
    final amount = double.tryParse(_amount.text.replaceAll(',', '').trim());
    if (!_vpaRe.hasMatch(vpa)) return toast(context, 'Enter a UPI ID like name@okaxis.');
    if (amount == null || amount <= 0) return toast(context, 'Enter the amount to pay.');

    final payee = _name.text.trim().isEmpty ? vpa.split('@').first : _name.text.trim();
    final params = {
      'pa': vpa,
      'pn': payee,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      if (_note.text.trim().isNotEmpty) 'tn': _note.text.trim(),
    };

    setState(() => _busy = true);
    Future<bool> open(Uri uri) async {
      try {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }

    // Try the chosen app's own link first, then the generic UPI chooser.
    var opened = await open(DeviceApps.payUri(_app, params));
    if (!opened && _app != null) opened = await open(DeviceApps.payUri(null, params));
    if (!mounted) return;
    setState(() => _busy = false);

    if (!opened) {
      toast(context, 'No UPI app found here. UPI apps open on Android phones, so install Spent on your phone to pay from it.');
      return;
    }
    final brand = brandFor('$payee ${vpa.split('@').first}');
    final name = brand?.name ?? payee;
    final title = _note.text.trim().isEmpty ? name : '${_note.text.trim()} · $name';
    SpentScope.of(context).save(Draft(
      type: TxType.expense,
      amount: amount,
      title: title,
      categoryId: guessCategory('$payee $vpa ${_note.text}', TxType.expense),
      source: TxSource.upi,
      app: _app?.id,
    ));
    Navigator.pop(context);
    Sfx.success();
    toast(context, 'Logged ${moneyExact(context, amount)} to $payee. Finish paying in your UPI app.');
  }

  @override
  Widget build(BuildContext context) {
    final inr = SpentScope.of(context).money == 'INR';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(
          'Start the payment here and Spent opens Google Pay, PhonePe or any UPI app with the details filled in, '
          'then logs it for you. You confirm the payment in your UPI app as usual.',
          style: t(14, FontWeight.w400, color: C.inkMuted, height: 1.45),
        ),
        if (!inr) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFEFE6), borderRadius: BorderRadius.circular(16)),
            child: Text('UPI payments are always in Indian Rupees (INR). Your Spent currency is ${SpentScope.of(context).money}.',
                style: t(13, FontWeight.w500, color: C.brand)),
          ),
        ],
        const SizedBox(height: 18),
        const SectionTitle('Pay with'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final a in paymentApps.take(3)) ...[Expanded(child: _appOption(a)), const SizedBox(width: 8)],
            Expanded(child: _appOption(null)),
          ],
        ),
        const SizedBox(height: 18),
        PillField(controller: _vpa, hint: 'UPI ID (e.g. shop@okaxis)', icon: Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 10),
        PillField(controller: _name, hint: 'Payee name (optional)', icon: Icons.storefront_outlined, capitalization: TextCapitalization.words),
        const SizedBox(height: 10),
        PillField(controller: _amount, hint: 'Amount (₹)', icon: Icons.currency_rupee_rounded, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        const SizedBox(height: 10),
        PillField(controller: _note, hint: 'What\'s it for? (optional)', icon: Icons.notes_rounded, capitalization: TextCapitalization.sentences),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: _busy
              ? const SizedBox(height: 54, child: Center(child: CircularProgressIndicator(color: C.brand, strokeWidth: 2.5)))
              : PillButton(label: 'Pay with ${_app?.name ?? 'UPI app'}', icon: Icons.open_in_new_rounded, background: C.brand, color: Colors.white, height: 54, onTap: _pay),
        ),
      ],
    );
  }

  /// A logo tile for picking the UPI app; null is "let Android ask".
  Widget _appOption(PaymentApp? a) {
    final on = _app?.id == a?.id;
    return Pressable(
      onTap: () {
        Sfx.select();
        setState(() => _app = a);
      },
      semanticLabel: a?.name ?? 'Any UPI app',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 76,
        decoration: BoxDecoration(
          color: on ? Colors.white : C.pill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? (a?.color ?? C.ink) : Colors.transparent, width: 1.5),
          boxShadow: on ? softShadow : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (a == null)
              const SizedBox(width: 30, height: 30, child: Icon(Icons.apps_rounded, color: C.inkMuted))
            else
              AppLogo(a, size: 30),
            const SizedBox(height: 6),
            Text(a?.name ?? 'Any app', maxLines: 1, overflow: TextOverflow.ellipsis, style: t(11, FontWeight.w600, color: on ? C.ink : C.inkMuted)),
          ],
        ),
      ),
    );
  }
}
