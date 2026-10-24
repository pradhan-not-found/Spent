// ignore_for_file: invalid_use_of_visible_for_testing_member
// Renders the README screenshots into docs/screenshots/ with the real fonts.
//
//   flutter test test_screenshots --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spent/categories.dart';
import 'package:spent/main.dart';
import 'package:spent/sfx.dart';
import 'package:spent/store.dart';
import 'package:spent/utils.dart';

Future<void> _font(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _font('Switzer', ['assets/fonts/Switzer-Variable.ttf']);
    await _font('SpentFallback', ['regular', 'medium', 'bold'].map((w) => 'assets/fonts/Roboto-$w.ttf').toList());
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? 'D:/flutter';
    await _font('MaterialIcons', ['$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf']);
  });

  Future<SpentStore> seeded({bool signedIn = true}) async {
    SharedPreferences.setMockInitialValues({});
    final s = SpentStore();
    await s.load();
    if (!signedIn) return s;
    s.signUp(name: 'Souradeep Pradhan', email: 'me@example.com', password: 'secret123');
    s.setCurrency('INR');
    Sfx.enabled = false;
    final t = today();
    void add(int back, String title, double amt, String cat,
            {bool rec = false, bool inc = false, TxSource src = TxSource.manual, String? app}) =>
        s.save(Draft(
          type: inc ? TxType.income : TxType.expense,
          amount: amt,
          title: title,
          categoryId: cat,
          date: addDays(t, -back),
          recurring: rec,
          source: src,
          app: app,
        ));
    add(23, 'Salary', 85000, 'salary', rec: true, inc: true);
    add(20, 'Rent', 18000, 'housing', rec: true);
    add(26, 'Netflix', 649, 'subscription', rec: true);
    add(27, 'Gym', 1500, 'entertainment', rec: true);
    add(6, 'Groceries', 2340.5, 'food');
    add(3, 'Uber', 289, 'transport', src: TxSource.upi, app: 'phonepe');
    add(1, 'Zomato', 412, 'food', src: TxSource.detected, app: 'paytm');
    add(0, 'Swiggy', 249, 'food', src: TxSource.detected, app: 'gpay');
    add(0, 'Chai', 30, 'food', src: TxSource.upi, app: 'gpay');
    s.setConnected('gpay', true);
    s.setConnected('phonepe', true);
    s.receiveDetected([
      Detected(id: 'a', app: 'gpay', text: 'You paid ₹180.00 to Starbucks using Google Pay', postedAt: DateTime.now().millisecondsSinceEpoch),
      Detected(id: 'b', app: 'phonepe', text: 'Sent ₹650 to Airtel recharge on PhonePe', postedAt: DateTime.now().millisecondsSinceEpoch),
    ]);
    return s;
  }

  Future<void> shoot(WidgetTester tester, SpentStore s, String name, [Future<void> Function()? go]) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(SpentScope(store: s, child: const SpentApp()));
    await tester.pumpAndSettle();
    if (go != null) await go();
    await tester.pumpAndSettle();
    await expectLater(find.byType(SpentApp), matchesGoldenFile('../docs/screenshots/$name.png'));
  }

  Future<void> scroll(WidgetTester tester, double dy) async {
    await tester.drag(find.byType(Scrollable).first, Offset(0, -dy));
    await tester.pumpAndSettle();
  }

  testWidgets('welcome', (tester) async => shoot(tester, await seeded(signedIn: false), 'welcome'));
  testWidgets('currency', (tester) async {
    final s = await seeded(signedIn: false);
    s.signUp(name: 'Souradeep', email: 'me@example.com', password: 'secret123');
    await shoot(tester, s, 'currency', () async {
      await tester.tap(find.text('INR'));
    });
  });
  testWidgets('home', (tester) async => shoot(tester, await seeded(), 'home'));
  testWidgets('home cards', (tester) async => shoot(tester, await seeded(), 'home_cards', () => scroll(tester, 420)));
  testWidgets('home activity', (tester) async => shoot(tester, await seeded(), 'home_activity', () => scroll(tester, 1150)));
  testWidgets('numpad', (tester) async => shoot(tester, await seeded(), 'numpad', () async {
        await tester.tap(find.bySemanticsLabel('Add transaction'));
        await tester.pumpAndSettle();
        for (final k in ['3', '5']) {
          await tester.tap(find.text(k));
        }
      }));
  testWidgets('income', (tester) async => shoot(tester, await seeded(), 'income', () async {
        await tester.tap(find.bySemanticsLabel('Add transaction'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Income'));
        await tester.pump();
        for (final k in ['1', '2', '0', '0', '0']) {
          await tester.tap(find.text(k));
        }
      }));
  testWidgets('details', (tester) async => shoot(tester, await seeded(), 'details', () async {
        await tester.tap(find.bySemanticsLabel('Add transaction'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('4'));
        await tester.tap(find.text('5'));
        await tester.tap(find.text('0'));
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Dinner at Zomato');
        await tester.tap(find.text('Google Pay'));
      }));
  testWidgets('payment apps', (tester) async => shoot(tester, await seeded(), 'payment_apps', () async {
        await tester.tap(find.text('Account'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Payment apps'));
      }));
  testWidgets('paste', (tester) async => shoot(tester, await seeded(), 'paste', () async {
        await tester.tap(find.text('Account'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Paste or pay via UPI'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Try an example'));
      }));
  testWidgets('upi', (tester) async => shoot(tester, await seeded(), 'upi', () async {
        await tester.tap(find.text('Account'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Paste or pay via UPI'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pay via UPI'));
      }));
  testWidgets('notifications', (tester) async => shoot(tester, await seeded(), 'notifications', () async {
        await tester.tap(find.bySemanticsLabel('Notifications'));
      }));
  testWidgets('recurring', (tester) async => shoot(tester, await seeded(), 'recurring', () async {
        await tester.tap(find.text('Recurring'));
      }));
  testWidgets('account', (tester) async => shoot(tester, await seeded(), 'account', () async {
        await tester.tap(find.text('Account'));
      }));
}
