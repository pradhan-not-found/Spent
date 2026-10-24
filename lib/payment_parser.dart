import 'brands.dart';
import 'categories.dart';
import 'utils.dart';

/// What we could read out of a pasted payment notification or bank SMS.
class ParsedPayment {
  const ParsedPayment({required this.amount, required this.type, required this.title, required this.categoryId, required this.date, this.app});
  final double amount;
  final TxType type;
  final String title;
  final String categoryId;
  final String date;

  /// The payment app named in the message, if any.
  final String? app;
}

final _amountRes = [
  RegExp(r'(?:₹|rs\.?|inr|\$|€|£|usd|eur|gbp)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)', caseSensitive: false),
  RegExp(r'([0-9][0-9,]*(?:\.[0-9]{1,2})?)\s*(?:rs\.?|inr|rupees)\b', caseSensitive: false),
];

const _incomeWords = ['credited', 'received', 'deposited', 'refund', 'cashback', 'added to your', 'reversed'];
const _expenseWords = ['debited', 'paid', 'sent', 'spent', 'withdrawn', 'purchase', 'payment of', 'transferred to', 'debit'];

final _payeeRes = [
  // "paid to Swiggy", "sent ₹200 to Rahul", "transferred to ABC"
  RegExp(r'\b(?:paid|sent|transferred|payment)\b[^\n]*?\bto\s+([A-Za-z][A-Za-z0-9 &.\x27-]{1,40}?)(?=\s+(?:on|via|using|from|ref|upi|with|at|for|thru|through)\b|[.,\n(]|$)', caseSensitive: false),
  // "received ₹500 from Amit"
  RegExp(r'\bfrom\s+([A-Za-z][A-Za-z0-9 &.\x27-]{1,40}?)(?=\s+(?:on|via|using|to|ref|upi|with|in|into)\b|[.,\n(]|$)', caseSensitive: false),
  // "at AMAZON PAY" (card spends)
  RegExp(r'\bat\s+([A-Za-z][A-Za-z0-9 &.\x27-]{1,40}?)(?=\s+(?:on|via|ref|using)\b|[.,\n(]|$)', caseSensitive: false),
  // "to VPA swiggy@icici"
  RegExp(r'\b(?:vpa|upi id)\s*:?\s*([\w.\-]+)@[\w]+', caseSensitive: false),
  RegExp(r'\b([\w.\-]+)@(?:ok\w+|ybl|ibl|axl|paytm|upi|icici|hdfcbank|sbi|apl|yapl)\b', caseSensitive: false),
];

final _numericDate = RegExp(r'\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})\b');
final _textDate = RegExp(r'\b(\d{1,2})[\s-]?(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[\s,-]*(\d{2,4})?\b', caseSensitive: false);
const _months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];

/// Reads a GPay / PhonePe / Paytm notification or a bank debit/credit SMS.
/// Returns null when no amount can be found.
ParsedPayment? parsePayment(String text) {
  final amount = _amount(text);
  if (amount == null || amount <= 0) return null;
  final type = _direction(text);
  // A known merchant gets its proper name ("Mcdonalds" → "McDonald's").
  final payee = _payee(text, type);
  final title = brandFor(payee)?.name ?? payee;
  return ParsedPayment(
    amount: amount,
    type: type,
    title: title,
    categoryId: guessCategory('$title $text', type),
    date: _date(text) ?? today(),
    app: paymentAppIn(text),
  );
}

double? _amount(String text) {
  for (final re in _amountRes) {
    final m = re.firstMatch(text);
    if (m != null) return double.tryParse(m.group(1)!.replaceAll(',', ''));
  }
  return null;
}

TxType _direction(String text) {
  final lower = text.toLowerCase();
  int first(List<String> words) =>
      words.map(lower.indexOf).where((i) => i >= 0).fold(1 << 30, (a, b) => a < b ? a : b);
  // Whichever kind of word appears first wins ("Rs 500 debited ... refund policy" is a debit).
  return first(_incomeWords) < first(_expenseWords) ? TxType.income : TxType.expense;
}

String _payee(String text, TxType type) {
  for (final re in _payeeRes) {
    // Income messages name the sender after "from"; skip the "paid to" pattern for them.
    if (type == TxType.income && re == _payeeRes.first) continue;
    final m = re.firstMatch(text);
    if (m == null) continue;
    final raw = m.group(1)!.trim();
    if (raw.isEmpty || RegExp(r'^(a/?c|ac|account|your|xx)', caseSensitive: false).hasMatch(raw)) continue;
    return _titleCase(raw.replaceAll(RegExp(r'[._-]+'), ' '));
  }
  return type == TxType.expense ? 'UPI payment' : 'Money received';
}

String? _date(String text) {
  final n = _numericDate.firstMatch(text);
  if (n != null) {
    final d = int.parse(n.group(1)!), m = int.parse(n.group(2)!);
    var y = int.parse(n.group(3)!);
    if (y < 100) y += 2000;
    if (m >= 1 && m <= 12 && d >= 1 && d <= 31) return _notFuture(DateTime(y, m, d));
  }
  final t = _textDate.firstMatch(text);
  if (t != null) {
    final d = int.parse(t.group(1)!);
    final m = _months.indexOf(t.group(2)!.toLowerCase()) + 1;
    var y = t.group(3) == null ? DateTime.now().year : int.parse(t.group(3)!);
    if (y < 100) y += 2000;
    if (d >= 1 && d <= 31) return _notFuture(DateTime(y, m, d));
  }
  return null;
}

/// A payment message can't be from the future; a bad parse falls back to today.
String _notFuture(DateTime d) => d.isAfter(DateTime.now()) ? today() : isoDate(d);

String _titleCase(String s) => s
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .map((w) => w.length <= 3 && w == w.toUpperCase() ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
    .join(' ');
