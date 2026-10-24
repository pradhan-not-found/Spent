import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spent/brands.dart';
import 'package:spent/payment_parser.dart';
import 'package:spent/sfx.dart';
import 'package:spent/store.dart';

void main() {
  test('payment app is read from the message, by whole word', () {
    expect(paymentAppIn('You paid ₹249 to Swiggy using Google Pay'), 'gpay');
    expect(paymentAppIn('Sent ₹1,200 to Rahul on PhonePe'), 'phonepe');
    expect(paymentAppIn('Rs 500 credited to your account'), isNull, reason: '"credited" is not CRED');
    expect(paymentAppIn('Paid via CRED'), 'cred');
  });

  test('known merchants get their logo and proper name', () {
    expect(brandFor('Swiggy')?.id, 'swiggy');
    expect(brandFor('Dinner · Zomato')?.id, 'zomato');
    expect(brandFor('Tuber bakery'), isNull, reason: '"tuber" is not Uber');
    expect(parsePayment('Paid ₹320 to mcdonalds@ybl')!.title, 'McDonald\'s');
  });

  group('detected payments inbox', () {
    late SpentStore s;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      s = SpentStore();
      await s.load();
      s.signUp(name: 'A', email: 'a@example.com', password: 'secret123');
      Sfx.enabled = false;
    });

    Detected d(String id, String app, String text) =>
        Detected(id: id, app: app, text: text, postedAt: DateTime(2026, 10, 20, 9).millisecondsSinceEpoch);

    test('keeps only payments from connected apps, once', () {
      s.setConnected('gpay', true);
      final added = s.receiveDetected([
        d('1', 'gpay', 'You paid ₹249.00 to Swiggy using Google Pay'),
        d('1', 'gpay', 'You paid ₹249.00 to Swiggy using Google Pay'),
        d('2', 'gpay', 'Your cashback offer is live!'),
        d('3', 'phonepe', 'Sent ₹100 to Asha'),
      ]);
      expect(added, 1);
      expect(s.inbox.single.id, '1');
      expect(s.receiveDetected([d('1', 'gpay', 'You paid ₹249.00 to Swiggy using Google Pay')]), 0);
    });

    test('accepting turns it into a transaction dated when it was posted', () {
      s.setConnected('gpay', true);
      s.receiveDetected([d('1', 'gpay', 'You paid ₹249.00 to Swiggy using Google Pay')]);
      s.acceptDetected(s.inbox.single);
      final t = s.txns.single;
      expect((t.title, t.amount, t.app, t.source, t.date), ('Swiggy', 249.0, 'gpay', TxSource.detected, '2026-10-20'));
      expect(s.inbox, isEmpty);
    });

    test('inbox and connections survive logging out and back in', () async {
      s.setConnected('paytm', true);
      s.receiveDetected([d('9', 'paytm', 'Paid Rs. 80 to Chai Point via Paytm')]);
      s.logOut();
      s.logIn(email: 'a@example.com', password: 'secret123');
      expect(s.connectedApps, {'paytm'});
      expect(s.inbox.single.id, '9');
    });
  });
}
