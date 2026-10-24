import 'package:flutter/painting.dart';

enum TxType { expense, income }

class Category {
  const Category(this.id, this.name, this.color, this.tint, {this.type = TxType.expense, this.keywords = const []});

  final String id;
  final String name;

  /// Strong hue for bars, dots and avatar letters.
  final Color color;

  /// Pastel fill behind the avatar letter.
  final Color tint;
  final TxType type;

  /// Merchant / payee words that suggest this category when importing a payment message.
  final List<String> keywords;
}

const categories = [
  Category('housing', 'Housing', Color(0xFF3AA0E0), Color(0xFFD4EBF8),
      keywords: ['rent', 'landlord', 'maintenance', 'society', 'nobroker']),
  Category('food', 'Food and Drink', Color(0xFFF0607A), Color(0xFFFCD9DF),
      keywords: ['swiggy', 'zomato', 'restaurant', 'cafe', 'coffee', 'starbucks', 'dominos', 'pizza', 'blinkit', 'zepto', 'bigbasket', 'instamart', 'grocer', 'kitchen', 'food', 'bakery', 'mcdonald', 'kfc']),
  Category('entertainment', 'Entertainment', Color(0xFFB3C41A), Color(0xFFF3F6C4),
      keywords: ['bookmyshow', 'pvr', 'inox', 'cinema', 'movie', 'gym', 'cult', 'game', 'steam']),
  Category('subscription', 'Subscription', Color(0xFF8A6AE0), Color(0xFFE6DEFA),
      keywords: ['netflix', 'spotify', 'prime', 'hotstar', 'youtube', 'apple', 'google one', 'icloud', 'subscription']),
  Category('transport', 'Transport', Color(0xFFF29A2E), Color(0xFFFDE6C9),
      keywords: ['uber', 'ola', 'rapido', 'metro', 'irctc', 'petrol', 'fuel', 'hpcl', 'bpcl', 'indianoil', 'fastag', 'parking', 'redbus']),
  Category('shopping', 'Shopping', Color(0xFFE05AB4), Color(0xFFF9D8EE),
      keywords: ['amazon', 'flipkart', 'myntra', 'ajio', 'meesho', 'nykaa', 'decathlon', 'ikea', 'mall', 'store']),
  Category('bills', 'Bills', Color(0xFF2FB59A), Color(0xFFD0F0E8),
      keywords: ['electricity', 'recharge', 'jio', 'airtel', 'vodafone', 'bsnl', 'broadband', 'bill', 'gas', 'water', 'insurance', 'emi', 'loan']),
  Category('health', 'Health', Color(0xFFE0503A), Color(0xFFFAD6D0),
      keywords: ['pharmacy', 'medical', 'apollo', 'hospital', 'clinic', 'pharmeasy', '1mg', 'netmeds', 'doctor']),
  Category('travel', 'Travel', Color(0xFF3A6AE0), Color(0xFFD6E0FA),
      keywords: ['makemytrip', 'goibibo', 'indigo', 'airindia', 'vistara', 'hotel', 'oyo', 'airbnb', 'booking.com', 'cleartrip']),
  Category('other', 'Other', Color(0xFF8A8A8A), Color(0xFFE8E8E8)),
  // Money coming in.
  Category('salary', 'Salary', Color(0xFF1FA968), Color(0xFFD2F2E2),
      type: TxType.income, keywords: ['salary', 'payroll', 'sal ']),
  Category('freelance', 'Freelance', Color(0xFF0E9AA7), Color(0xFFCFEFF1),
      type: TxType.income, keywords: ['invoice', 'client', 'freelance', 'upwork', 'fiverr']),
  Category('refund', 'Refund', Color(0xFF6A7FE0), Color(0xFFDEE3FA),
      type: TxType.income, keywords: ['refund', 'cashback', 'reversal', 'reversed']),
  Category('gift', 'Gift', Color(0xFFE05A8A), Color(0xFFF9D8E5), type: TxType.income),
  Category('other-income', 'Other income', Color(0xFF5C8A6E), Color(0xFFDDEBE2), type: TxType.income),
];

final _byId = {for (final c in categories) c.id: c};

Category categoryOf(String id) => _byId[id] ?? _byId['other']!;

List<Category> categoriesFor(TxType type) => categories.where((c) => c.type == type).toList();

String defaultCategory(TxType type) => type == TxType.expense ? 'food' : 'salary';

/// Best guess from free text (payee, message); falls back to the type's catch-all.
String guessCategory(String text, TxType type) {
  final lower = text.toLowerCase();
  for (final c in categoriesFor(type)) {
    if (c.keywords.any(lower.contains)) return c.id;
  }
  return type == TxType.expense ? 'other' : 'other-income';
}

/// Lucide (ISC) glyph for each category, tinted with the category colour when drawn.
const _icons = {
  'housing': 'house',
  'food': 'utensils',
  'entertainment': 'ticket',
  'subscription': 'tv',
  'transport': 'car',
  'shopping': 'shopping-bag',
  'bills': 'receipt',
  'health': 'heart-pulse',
  'travel': 'plane',
  'other': 'ellipsis',
  'salary': 'briefcase',
  'freelance': 'laptop',
  'refund': 'undo-2',
  'gift': 'gift',
  'other-income': 'wallet',
};

extension CategoryIcon on Category {
  String get icon => 'assets/icons/${_icons[id] ?? 'ellipsis'}.svg';
}
