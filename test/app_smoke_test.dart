import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:librario/app.dart';
import 'package:librario/data/database.dart';
import 'package:librario/data/providers.dart';
import 'package:librario/data/seed.dart';

/// Drift streams resolve on real async I/O, so let the event loop turn between frames.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('seeded app shows Home, then the Library tab and a book', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final db = AppDatabase(NativeDatabase.memory());
    await tester.runAsync(() => seedSampleData(db));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const LibrarioApp(),
      ),
    );
    await settle(tester);
    expect(find.text('Currently reading'), findsOneWidget);
    expect(find.text('Due soon'), findsOneWidget);

    await tester.tap(find.text('LIBRARY'));
    await settle(tester);
    expect(find.text('Zero to One'), findsWidgets);

    await tester.tap(find.text('Zero to One').last);
    await settle(tester);
    expect(find.text('Copies'.toUpperCase()), findsOneWidget);
    expect(find.text('WITH PRIYA'), findsOneWidget);

    // Unmount first so drift's stream subscriptions are cancelled before the database closes.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
