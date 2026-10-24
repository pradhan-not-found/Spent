import 'package:flutter_test/flutter_test.dart';
import 'package:spent/categories.dart';
import 'package:spent/payment_parser.dart';

void main() {
  ParsedPayment p(String s) => parsePayment(s)!;

  test('Google Pay "you paid"', () {
    final r = p('You paid ₹249.00 to Swiggy using Google Pay. UPI Ref No 432178650912. 24 Oct 2026');
    expect((r.amount, r.type, r.title, r.categoryId, r.date), (249.0, TxType.expense, 'Swiggy', 'food', '2026-10-24'));
  });

  test('bank debit SMS with VPA', () {
    final r = p('Rs.450.00 debited from A/c XX1234 to VPA zomato@icici on 20-10-26. Not you? Call 1800');
    expect((r.amount, r.type, r.title, r.categoryId, r.date), (450.0, TxType.expense, 'Zomato', 'food', '2026-10-20'));
  });

  test('PhonePe "sent to" with commas in the amount', () {
    final r = p('Sent ₹1,200 to Rahul Sharma on PhonePe');
    expect((r.amount, r.type, r.title), (1200.0, TxType.expense, 'Rahul Sharma'));
  });

  test('money received is income', () {
    final r = p('Received Rs 5,000.00 from Amit Kumar via UPI');
    expect((r.amount, r.type, r.title, r.categoryId), (5000.0, TxType.income, 'Amit Kumar', 'other-income'));
  });

  test('credited salary', () {
    final r = p('INR 85,000.00 credited to your A/c XX9876 on 01/10/2026 - SALARY OCT');
    expect((r.amount, r.type, r.categoryId, r.date), (85000.0, TxType.income, 'salary', '2026-10-01'));
  });

  test('card spend "at" merchant guesses the category', () {
    final r = p('Rs. 1,499 spent on your card XX45 at AMAZON on 18-Oct-26');
    expect((r.amount, r.type, r.categoryId), (1499.0, TxType.expense, 'shopping'));
  });

  test('no amount → null', () {
    expect(parsePayment('Your OTP is 123456'), isNull);
  });
}
