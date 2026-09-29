// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:fairsplit/app.dart';
import 'package:fairsplit/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fairsplit/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  const members = [
    FairMember(id: 'a', name: 'Amulya'),
    FairMember(id: 'b', name: 'Rahul'),
    FairMember(id: 'c', name: 'Priya'),
    FairMember(id: 'd', name: 'Anu'),
  ];
  const group = FairGroup(
    id: 'trip',
    name: 'Trip',
    category: 'Travel',
    members: members,
  );

  test('an equal expense credits the payer and debits every participant', () {
    final expense = FairExpense(
      id: 'dinner',
      groupId: group.id,
      title: 'Dinner',
      amountCents: 120000,
      paidBy: 'a',
      shares: const {'a': 30000, 'b': 30000, 'c': 30000, 'd': 30000},
      splitMethod: SplitMethod.equal,
      category: 'Food',
      date: DateTime(2026),
    );
    expect(calculateBalances(group, [expense], []), {
      'a': 90000,
      'b': -30000,
      'c': -30000,
      'd': -30000,
    });
  });

  test('a settlement reduces payer debt and payee credit', () {
    final expense = FairExpense(
      id: 'dinner',
      groupId: 'trip',
      title: 'Dinner',
      amountCents: 120000,
      paidBy: 'a',
      shares: {'a': 30000, 'b': 30000, 'c': 30000, 'd': 30000},
      splitMethod: SplitMethod.equal,
      category: 'Food',
      date: DateTime(2026),
    );
    final settlement = FairSettlement(
      id: 'payment',
      groupId: 'trip',
      paidBy: 'b',
      paidTo: 'a',
      amountCents: 10000,
      date: DateTime(2026),
    );
    final balances = calculateBalances(group, [expense], [settlement]);
    expect(balances['a'], 80000);
    expect(balances['b'], -20000);
    expect(balances.values.reduce((sum, value) => sum + value), 0);
  });

  test('simplified payments preserve the total group debt', () {
    final suggested = simplifyDebts(group, {
      'a': 45000,
      'b': -30000,
      'c': -10000,
      'd': -5000,
    });
    expect(suggested, hasLength(3));
    expect(
      suggested.fold<int>(0, (sum, payment) => sum + payment.amountCents),
      45000,
    );
  });

  test('expense records round-trip through JSON', () {
    final expense = FairExpense(
      id: 'custom',
      groupId: 'trip',
      title: 'Cab',
      amountCents: 9999,
      paidBy: 'a',
      shares: {'a': 3333, 'b': 3333, 'c': 3333},
      splitMethod: SplitMethod.custom,
      category: 'Travel',
      date: DateTime(2026),
    );
    final restored = FairExpense.fromJson(expense.toJson());
    expect(restored.amountCents, expense.amountCents);
    expect(restored.shares, expense.shares);
    expect(restored.splitMethod, SplitMethod.custom);
  });

  testWidgets(
    'theme switch updates the app and persists across state reloads',
    (tester) async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final state = await FairSplitState.create(
        databasePathOverride: inMemoryDatabasePath,
      );
      await state.completeOnboarding();
      await tester.pumpWidget(FairSplitApp(state: state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(state.darkMode, isFalse);
      expect(
        Theme.of(tester.element(find.byType(Switch).first)).brightness,
        Brightness.light,
      );
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(state.darkMode, isTrue);
      expect(
        Theme.of(tester.element(find.byType(Switch).first)).brightness,
        Brightness.dark,
      );

      final restored = await FairSplitState.create(
        databasePathOverride: inMemoryDatabasePath,
      );
      expect(restored.darkMode, isTrue);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(state.darkMode, isFalse);
      expect(
        Theme.of(tester.element(find.byType(Switch).first)).brightness,
        Brightness.light,
      );
      final lightMode = await FairSplitState.create(
        databasePathOverride: inMemoryDatabasePath,
      );
      expect(lightMode.darkMode, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await state.close();
    },
  );
}
