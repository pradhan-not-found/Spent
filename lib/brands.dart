import 'package:flutter/painting.dart';

/// A merchant whose official logo we ship (from Simple Icons, CC0), matched by name.
class Brand {
  const Brand(this.id, this.name, this.color, this.keywords);
  final String id;
  final String name;
  final Color color;
  final List<String> keywords;

  String get asset => 'assets/brands/$id.svg';
}

const merchants = [
  Brand('swiggy', 'Swiggy', Color(0xFFFC8019), ['swiggy', 'instamart']),
  Brand('zomato', 'Zomato', Color(0xFFE23744), ['zomato']),
  Brand('uber', 'Uber', Color(0xFF000000), ['uber']),
  Brand('netflix', 'Netflix', Color(0xFFE50914), ['netflix']),
  Brand('spotify', 'Spotify', Color(0xFF1ED760), ['spotify']),
  Brand('youtube', 'YouTube', Color(0xFFFF0000), ['youtube']),
  Brand('airtel', 'Airtel', Color(0xFFE40000), ['airtel']),
  Brand('jio', 'Jio', Color(0xFF0A2885), ['jio']),
  Brand('bookmyshow', 'BookMyShow', Color(0xFFC4242B), ['bookmyshow', 'book my show']),
  Brand('airbnb', 'Airbnb', Color(0xFFFF5A5F), ['airbnb']),
  Brand('starbucks', 'Starbucks', Color(0xFF006241), ['starbucks']),
  Brand('mcdonalds', 'McDonald\'s', Color(0xFFDA291C), ['mcdonald', 'mcdonalds', "mcdonald's"]),
  Brand('kfc', 'KFC', Color(0xFFF40027), ['kfc']),
  Brand('apple', 'Apple', Color(0xFF000000), ['apple.com', 'apple services', 'itunes', 'icloud']),
  Brand('bigbasket', 'bigbasket', Color(0xFF84C225), ['bigbasket']),
  Brand('ikea', 'IKEA', Color(0xFF0058A3), ['ikea']),
  Brand('indigo', 'IndiGo', Color(0xFF09009B), ['indigo']),
  Brand('airindia', 'Air India', Color(0xFFDA0E29), ['air india', 'airindia']),
  Brand('zerodha', 'Zerodha', Color(0xFF387ED1), ['zerodha']),
];

/// The merchant behind a transaction title or payment message, if we know its logo.
Brand? brandFor(String text) {
  final lower = text.toLowerCase();
  for (final b in merchants) {
    if (b.keywords.any((k) => _hasWord(lower, k))) return b;
  }
  return null;
}

/// A UPI app Spent can recognise, open, and (on Android, with permission) listen to.
class PaymentApp {
  const PaymentApp(this.id, this.name, this.color, this.package, this.payScheme, {this.logo, this.keywords = const []});
  final String id;
  final String name;
  final Color color;

  /// Android package name, used to check it's installed and to filter its notifications.
  final String package;

  /// Deep link that opens this app's UPI pay screen directly.
  final String payScheme;

  /// Bundled logo (Simple Icons). Apps without one fall back to the phone's own icon on
  /// Android, or a tinted wallet glyph elsewhere.
  final String? logo;
  final List<String> keywords;
}

const paymentApps = [
  PaymentApp('gpay', 'Google Pay', Color(0xFF4285F4), 'com.google.android.apps.nbu.paisa.user', 'tez://upi/pay',
      logo: 'assets/brands/googlepay.svg', keywords: ['google pay', 'gpay', 'tez']),
  PaymentApp('phonepe', 'PhonePe', Color(0xFF5F259F), 'com.phonepe.app', 'phonepe://pay',
      logo: 'assets/brands/phonepe.svg', keywords: ['phonepe']),
  PaymentApp('paytm', 'Paytm', Color(0xFF00BAF2), 'net.one97.paytm', 'paytmmp://pay',
      logo: 'assets/brands/paytm.svg', keywords: ['paytm']),
  PaymentApp('bhim', 'BHIM', Color(0xFFF37021), 'in.org.npci.upiapp', 'upi://pay', keywords: ['bhim']),
  PaymentApp('amazonpay', 'Amazon Pay', Color(0xFFFF9900), 'in.amazon.mShop.android.shopping', 'upi://pay',
      keywords: ['amazon pay']),
  PaymentApp('cred', 'CRED', Color(0xFF1A1A1A), 'com.dreamplug.androidapp', 'upi://pay', keywords: ['cred']),
];

final _appsById = {for (final a in paymentApps) a.id: a};
final _appsByPackage = {for (final a in paymentApps) a.package: a};

PaymentApp? paymentApp(String? id) => id == null ? null : _appsById[id];
PaymentApp? paymentAppForPackage(String package) => _appsByPackage[package];

/// Which app a pasted message came from ("…using Google Pay" → gpay).
String? paymentAppIn(String text) {
  final lower = text.toLowerCase();
  for (final a in paymentApps) {
    if (a.keywords.any((k) => _hasWord(lower, k))) return a.id;
  }
  return null;
}

/// Whole-word match, so "credited" isn't CRED and "tuber" isn't Uber.
bool _hasWord(String lower, String word) =>
    RegExp('(^|[^a-z0-9])${RegExp.escape(word)}(\$|[^a-z0-9])').hasMatch(lower);
