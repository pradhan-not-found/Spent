import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spent/categories.dart';
import 'package:spent/main.dart';
import 'package:spent/store.dart';

/// Renders each screen at iPhone size; any overflow or build error fails the test.
void main() {
  late SpentStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = SpentStore();
    await store.load();
  });

  Future<void> boot(WidgetTester tester, {bool signedIn = true}) async {
    if (signedIn) {
      store.signUp(name: 'Asha Rao', email: 'asha@example.com', password: 'secret123');
      store.setCurrency('INR');
    }
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(SpentScope(store: store, child: const SpentApp()));
    await tester.pumpAndSettle();
  }

  /// Scroll Home until [finder] is on screen and clear of the bottom dock.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
    await tester.pumpAndSettle();
  }

  testWidgets('sign up, pick a currency, land on an empty home', (tester) async {
    await boot(tester, signedIn: false);
    expect(find.text('Create account'), findsOneWidget);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Asha Rao');
    await tester.enterText(fields.at(1), 'asha@example.com');
    await tester.enterText(fields.at(2), 'secret123');
    await tester.tap(find.text('Create account').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('which currency'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'rupee');
    await tester.pumpAndSettle();
    await tester.tap(find.text('INR'));
    await tester.pump();
    await tester.tap(find.textContaining('Use Indian Rupee'));
    await tester.pumpAndSettle();

    expect(find.text('Hello Asha!'), findsOneWidget);
    expect(find.text('₹0'), findsWidgets);
    expect(store.txns, isEmpty);
  });

  testWidgets('wrong password is rejected; right one logs back in', (tester) async {
    await boot(tester);
    store.logOut();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'asha@example.com');
    await tester.enterText(fields.at(1), 'nope-nope');
    await tester.tap(find.text('Log in').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('don\'t match'), findsOneWidget);

    await tester.enterText(fields.at(1), 'secret123');
    await tester.tap(find.text('Log in').last);
    await tester.pumpAndSettle();
    expect(find.text('Hello Asha!'), findsOneWidget);
  });

  testWidgets('add expense with numpad maths', (tester) async {
    await boot(tester);
    await tester.tap(find.bySemanticsLabel('Add transaction'));
    await tester.pumpAndSettle();
    for (final k in ['3', '5']) {
      await tester.tap(find.text(k));
    }
    await tester.tap(find.text('Plus'));
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(find.text('= ₹40'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('New expense'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Books');
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    expect(store.txns.single.amount, 40);
    expect(store.txns.single.type, TxType.expense);
    await reveal(tester, find.text('Books'));
    expect(find.text('Books'), findsOneWidget);
  });

  testWidgets('add income shows up in green on the income card', (tester) async {
    await boot(tester);
    await tester.tap(find.bySemanticsLabel('Add transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Income'));
    await tester.pump();
    for (final k in ['5', '0', '0', '0']) {
      await tester.tap(find.text(k));
    }
    // Continue starts disabled at 0; let it rebuild as enabled like a real frame would.
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('New income'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    await tester.tap(find.text('Add income'));
    await tester.pumpAndSettle();
    expect(store.txns.single.type, TxType.income);
    expect(find.text('₹5,000'), findsWidgets);
  });

  testWidgets('paste a GPay message and save it', (tester) async {
    await boot(tester);
    await reveal(tester, find.text('Paste & add'));
    await tester.tap(find.text('Paste & add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Rs.450.00 debited from A/c XX1234 to VPA zomato@icici on 20-10-26');
    await tester.tap(find.text('Read message'));
    await tester.pumpAndSettle();
    expect(find.text('Zomato'), findsOneWidget);
    expect(find.text('Food and Drink · Oct 20'), findsOneWidget);
    await tester.tap(find.text('Review & save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    final t = store.txns.single;
    expect((t.amount, t.title, t.categoryId, t.date, t.source), (450.0, 'Zomato', 'food', '2026-10-20', TxSource.message));
  });

  testWidgets('every other screen renders', (tester) async {
    await boot(tester);
    store.save(Draft(amount: 750, title: 'Rent', categoryId: 'housing', date: '2026-09-27', recurring: true));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Notifications'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Payment will be taken'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    await reveal(tester, find.text('By category'));
    await tester.tap(find.text('See all').last);
    await tester.pumpAndSettle();
    expect(find.text('By category'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recurring'));
    await tester.pumpAndSettle();
    expect(find.text('Goes out every month'), findsOneWidget);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('asha@example.com'), findsOneWidget);
    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD'));
    await tester.pump();
    await tester.tap(find.textContaining('Use US Dollar'));
    await tester.pumpAndSettle();
    expect(store.currency, 'USD');
  });
}
