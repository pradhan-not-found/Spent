import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth.dart';
import 'categories.dart';
import 'payment_parser.dart';
import 'sfx.dart';
import 'utils.dart';

/// How a transaction got into Spent.
enum TxSource { manual, upi, message, detected }

/// One-off transactions happen once on [date]. Recurring ones are monthly: [date] is the
/// first one, and they repeat on that day of every following month.
class Txn {
  Txn({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.recurring,
    required this.createdAt,
    this.source = TxSource.manual,
    this.app,
  });

  final String id;
  final TxType type;
  final String title;
  final double amount;
  final String categoryId;
  final String date; // YYYY-MM-DD
  final bool recurring;
  final int createdAt;
  final TxSource source;

  /// Payment app it went through ([paymentApps] id), when known.
  final String? app;

  bool get isExpense => type == TxType.expense;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'amount': amount,
        'categoryId': categoryId,
        'date': date,
        'recurring': recurring,
        'createdAt': createdAt,
        'source': source.name,
        'app': app,
      };

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        id: j['id'] as String,
        type: TxType.values.byName(j['type'] as String? ?? 'expense'),
        title: j['title'] as String,
        amount: (j['amount'] as num).toDouble(),
        categoryId: j['categoryId'] as String,
        date: j['date'] as String,
        recurring: j['recurring'] as bool,
        createdAt: j['createdAt'] as int,
        source: TxSource.values.byName(j['source'] as String? ?? 'manual'),
        app: j['app'] as String?,
      );
}

/// What the add/edit flow carries between the numpad and the details screen.
class Draft {
  Draft({
    this.id,
    this.type = TxType.expense,
    this.amount = 0,
    this.title = '',
    String? categoryId,
    String? date,
    this.recurring = false,
    this.source = TxSource.manual,
    this.app,
  })  : categoryId = categoryId ?? defaultCategory(type),
        date = date ?? today();

  factory Draft.of(Txn e) => Draft(
        id: e.id,
        type: e.type,
        amount: e.amount,
        title: e.title,
        categoryId: e.categoryId,
        date: e.date,
        recurring: e.recurring,
        source: e.source,
        app: e.app,
      );

  final String? id;
  TxType type;
  double amount;
  String title;
  String categoryId;
  String date;
  bool recurring;
  TxSource source;
  String? app;
}

/// A payment notification picked up from a connected app, waiting for the user to confirm.
class Detected {
  const Detected({required this.id, required this.app, required this.text, required this.postedAt});
  final String id;
  final String app;
  final String text;
  final int postedAt;

  Map<String, dynamic> toJson() => {'id': id, 'app': app, 'text': text, 'postedAt': postedAt};

  factory Detected.fromJson(Map<String, dynamic> j) => Detected(
        id: j['id'] as String,
        app: j['app'] as String,
        text: j['text'] as String,
        postedAt: j['postedAt'] as int,
      );
}

/// A transaction as it lands in a particular month (recurring ones land every month).
class Entry {
  const Entry(this.txn, this.date);
  final Txn txn;
  final String date;
}

class Notice {
  const Notice(this.txn, this.shownOn, this.chargeOn);
  final Txn txn;

  /// When the reminder appeared ([remindDays] before the charge).
  final String shownOn;
  final String chargeOn;
}

const remindDays = 3;
const _historyMonths = 3;
const _accountsKey = 'spent:accounts';
const _sessionKey = 'spent:session';
String _dataKey(String email) => 'spent:data:$email';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class SpentStore extends ChangeNotifier {
  Map<String, Account> _accounts = {};
  Account? user;

  List<Txn> txns = [];

  /// Null until the user picks one during onboarding.
  String? currency;
  int notificationsSeenAt = 0;

  /// "Sounds & haptics" in Account.
  bool soundOn = true;

  /// Payment apps the user chose to connect (ids from [paymentApps]).
  Set<String> connectedApps = {};

  /// Payments read from connected apps' notifications, waiting for review.
  List<Detected> inbox = [];

  /// The month the Home screen is looking at; not persisted.
  String month = monthKey(DateTime.now());

  SharedPreferences? _prefs;

  bool get hasAccounts => _accounts.isNotEmpty;
  String get money => currency ?? 'USD';

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_accountsKey);
    if (raw != null) {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _accounts = j.map((k, v) => MapEntry(k, Account.fromJson(v as Map<String, dynamic>)));
    }
    final session = _prefs!.getString(_sessionKey);
    if (session != null && _accounts[session] != null) _openSession(_accounts[session]!);
  }

  // ---- Accounts -----------------------------------------------------------------

  void signUp({required String name, required String email, required String password}) {
    final key = normaliseEmail(email);
    if (name.trim().isEmpty) throw const AuthException('Enter your name.');
    if (!isValidEmail(key)) throw const AuthException('Enter a valid email address.');
    if (password.length < 6) throw const AuthException('Use at least 6 characters for your password.');
    if (_accounts.containsKey(key)) throw const AuthException('An account with this email already exists. Log in instead.');
    final salt = newSalt();
    final account = Account(name: name.trim(), email: key, salt: salt, hash: hashPassword(password, salt));
    _accounts = {..._accounts, key: account};
    _saveAccounts();
    _openSession(account);
    notifyListeners();
  }

  void logIn({required String email, required String password}) {
    final account = _accounts[normaliseEmail(email)];
    if (account == null || !verifyPassword(account, password)) {
      throw const AuthException('That email and password don\'t match.');
    }
    _openSession(account);
    notifyListeners();
  }

  void logOut() {
    user = null;
    txns = [];
    currency = null;
    _prefs?.remove(_sessionKey);
    notifyListeners();
  }

  /// Removes the account and all of its data from this device.
  void deleteAccount() {
    final u = user;
    if (u == null) return;
    _accounts = {..._accounts}..remove(u.email);
    _saveAccounts();
    _prefs?.remove(_dataKey(u.email));
    logOut();
  }

  void setName(String v) {
    final u = user;
    if (u == null) return;
    user = u.copyWith(name: v);
    _accounts = {..._accounts, u.email: user!};
    _saveAccounts();
    notifyListeners();
  }

  void _openSession(Account a) {
    user = a;
    _prefs?.setString(_sessionKey, a.email);
    txns = [];
    currency = null;
    notificationsSeenAt = 0;
    connectedApps = {};
    soundOn = true;
    Sfx.enabled = true;
    inbox = [];
    month = monthKey(DateTime.now());
    final raw = _prefs?.getString(_dataKey(a.email));
    if (raw == null) return;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    txns = (j['txns'] as List).map((e) => Txn.fromJson(e as Map<String, dynamic>)).toList();
    currency = j['currency'] as String?;
    notificationsSeenAt = j['notificationsSeenAt'] as int? ?? 0;
    connectedApps = {...(j['connectedApps'] as List? ?? const []).cast<String>()};
    inbox = (j['inbox'] as List? ?? const []).map((e) => Detected.fromJson(e as Map<String, dynamic>)).toList();
    soundOn = j['soundOn'] as bool? ?? true;
    Sfx.enabled = soundOn;
  }

  void _saveAccounts() =>
      _prefs?.setString(_accountsKey, jsonEncode(_accounts.map((k, v) => MapEntry(k, v.toJson()))));

  void _saveData() {
    final u = user;
    if (u == null) return;
    _prefs?.setString(
      _dataKey(u.email),
      jsonEncode({
        'txns': txns.map((e) => e.toJson()).toList(),
        'currency': currency,
        'notificationsSeenAt': notificationsSeenAt,
        'connectedApps': connectedApps.toList(),
        'inbox': inbox.map((e) => e.toJson()).toList(),
        'soundOn': soundOn,
      }),
    );
  }

  void _commit() {
    _saveData();
    notifyListeners();
  }

  // ---- Transactions -------------------------------------------------------------

  void save(Draft d) {
    final fallback = d.type == TxType.expense ? 'Expense' : 'Income';
    final e = Txn(
      id: d.id ?? _uid(),
      type: d.type,
      title: d.title.trim().isEmpty ? fallback : d.title.trim(),
      amount: d.amount,
      categoryId: d.categoryId,
      date: d.date,
      recurring: d.recurring,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      source: d.source,
      app: d.app,
    );
    final i = txns.indexWhere((x) => x.id == e.id);
    txns = i == -1 ? [e, ...txns] : ([...txns]..[i] = e);
    _commit();
  }

  void remove(String id) {
    txns = txns.where((e) => e.id != id).toList();
    _commit();
  }

  void setSound(bool on) {
    soundOn = on;
    Sfx.enabled = on;
    _commit();
  }

  void setCurrency(String v) {
    currency = v;
    _commit();
  }

  void setMonth(String v) {
    month = v;
    notifyListeners();
  }

  void markNotificationsSeen() {
    notificationsSeenAt = DateTime.now().millisecondsSinceEpoch;
    _commit();
  }

  void clearAll() {
    txns = [];
    _commit();
  }

  // ---- Connected payment apps ---------------------------------------------------

  void setConnected(String appId, bool on) {
    connectedApps = on ? {...connectedApps, appId} : ({...connectedApps}..remove(appId));
    _commit();
  }

  /// Adds notifications picked up on the device. Anything that doesn't read as a payment,
  /// or comes from an app the user hasn't connected, is dropped rather than stored.
  int receiveDetected(List<Detected> items) {
    final known = {for (final d in inbox) d.id};
    final fresh = items
        // Set.add returns false for an id already seen, in the inbox or earlier in this batch.
        .where((d) => connectedApps.contains(d.app) && parsePayment(d.text) != null && known.add(d.id))
        .toList();
    if (fresh.isEmpty) return 0;
    inbox = [...fresh, ...inbox];
    _commit();
    return fresh.length;
  }

  /// Turns a detected notification into a transaction.
  void acceptDetected(Detected d) {
    final p = parsePayment(d.text);
    inbox = inbox.where((x) => x.id != d.id).toList();
    if (p != null) {
      final posted = DateTime.fromMillisecondsSinceEpoch(d.postedAt);
      save(Draft(
        type: p.type,
        amount: p.amount,
        title: p.title,
        categoryId: p.categoryId,
        date: isoDate(posted),
        source: TxSource.detected,
        app: d.app,
      ));
    } else {
      _commit();
    }
  }

  void dismissDetected(Detected d) {
    inbox = inbox.where((x) => x.id != d.id).toList();
    _commit();
  }

  // ---- Queries ------------------------------------------------------------------

  List<Entry> entriesFor(String month) {
    final out = <Entry>[];
    for (final e in txns) {
      if (e.recurring) {
        if (e.date.substring(0, 7).compareTo(month) <= 0) out.add(Entry(e, dateInMonth(e.date, month)));
      } else if (e.date.startsWith(month)) {
        out.add(Entry(e, e.date));
      }
    }
    out.sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : b.txn.createdAt - a.txn.createdAt;
    });
    return out;
  }

  /// Everything that has happened on [day] (recurring charges included).
  List<Entry> entriesOn(String day) =>
      entriesFor(day.substring(0, 7)).where((e) => e.date == day).toList();

  /// The next date a recurring transaction will happen, on or after today.
  String nextCharge(Txn e) {
    final t = today();
    if (e.date.compareTo(t) >= 0) return e.date;
    var month = monthKey(DateTime.now());
    var d = dateInMonth(e.date, month);
    while (d.compareTo(t) < 0) {
      month = shiftMonth(month, 1);
      d = dateInMonth(e.date, month);
    }
    return d;
  }

  /// Reminders for every recurring payment over the last few months, up to the next one.
  List<Notice> notices() {
    final t = today();
    final thisMonth = monthKey(DateTime.now());
    final out = <Notice>[];
    for (final e in txns.where((e) => e.recurring && e.isExpense)) {
      for (var back = _historyMonths; back >= -1; back--) {
        final month = shiftMonth(thisMonth, -back);
        if (month.compareTo(e.date.substring(0, 7)) < 0) continue;
        final chargeOn = dateInMonth(e.date, month);
        final shownOn = addDays(chargeOn, -remindDays);
        if (shownOn.compareTo(t) > 0) continue;
        out.add(Notice(e, shownOn, chargeOn));
      }
    }
    out.sort((a, b) => b.shownOn.compareTo(a.shownOn));
    return out;
  }

  /// A reminder counts as unread until the screen is opened on or after the day it appeared.
  bool get hasUnread =>
      notices().any((n) => parseIso(n.shownOn).millisecondsSinceEpoch > notificationsSeenAt);
}

double sumOf(Iterable<Entry> es) => es.fold(0.0, (a, e) => a + e.txn.amount);

final _rand = Random();
String _uid() => '${DateTime.now().microsecondsSinceEpoch}-${_rand.nextInt(0x7fffffff)}';

/// Makes the store reachable from any widget and rebuilds dependents when it changes.
class SpentScope extends InheritedNotifier<SpentStore> {
  const SpentScope({super.key, required SpentStore store, required super.child}) : super(notifier: store);

  static SpentStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SpentScope>()!.notifier!;
}
