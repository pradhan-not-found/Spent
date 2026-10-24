import 'package:intl/intl.dart';

import 'currencies.dart';

/// Whole amounts drop the cents (₹450), others keep them (₹25.00), like the mockups.
String formatMoney(double amount, String currency, {bool forceCents = false}) {
  final whole = amount == amount.roundToDouble() && !forceCents;
  final digits = zeroDecimal.contains(currency) || whole ? 0 : 2;
  return NumberFormat.simpleCurrency(name: currency, decimalDigits: digits).format(amount);
}

String currencySymbol(String currency) => NumberFormat.simpleCurrency(name: currency).currencySymbol;

/// Local YYYY-MM-DD (not UTC, so late-evening entries stay on the right day).
String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

DateTime parseIso(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String today() => isoDate(DateTime.now());

String addDays(String iso, int n) {
  final d = parseIso(iso);
  return isoDate(DateTime(d.year, d.month, d.day + n));
}

/// Month key like "2026-10".
String monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);

String shiftMonth(String key, int delta) {
  final p = key.split('-').map(int.parse).toList();
  return monthKey(DateTime(p[0], p[1] + delta));
}

/// The date a monthly charge falls on in [month], clamped (a 31st becomes the 30th in April).
String dateInMonth(String startIso, String month) {
  final p = month.split('-').map(int.parse).toList();
  final last = DateTime(p[0], p[1] + 1, 0).day;
  final day = int.parse(startIso.substring(8, 10)).clamp(1, last);
  return '$month-${day.toString().padLeft(2, '0')}';
}

const monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "29 Feb" — the compact date used in list rows.
String shortDate(String iso) => DateFormat('d MMM').format(parseIso(iso));

/// "Feb 29" — the date style used in notification copy.
String noticeDate(String iso) => DateFormat('MMM d').format(parseIso(iso));

/// Section headings: Today / Yesterday / Jan 25 / Dec 15, 2025.
String dayHeading(String iso) {
  final t = today();
  if (iso == t) return 'Today';
  if (iso == addDays(t, -1)) return 'Yesterday';
  final d = parseIso(iso);
  return d.year == DateTime.now().year ? DateFormat('MMM d').format(d) : DateFormat('MMM d, y').format(d);
}
