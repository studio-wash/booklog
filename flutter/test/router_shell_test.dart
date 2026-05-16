import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:booklog/app.dart';
import 'package:booklog/data/app_database.dart';
import 'package:booklog/features/shell/booklog_shell_scaffold.dart';
import 'package:booklog/providers.dart';
import 'package:booklog/router/app_router.dart';

void main() {
  testWidgets('shell loads on home with bottom nav', (tester) async {
    final db = await AppDatabase.open(pathOverride: inMemoryDatabasePath);
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const BooklogApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BooklogShellScaffold), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Books'), findsOneWidget);
  });

  testWidgets('createAppRouter navigates to books tab', (tester) async {
    final db = await AppDatabase.open(pathOverride: inMemoryDatabasePath);
    addTearDown(db.close);

    final router = createAppRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/books');
    await tester.pumpAndSettle();

    expect(find.text('Books'), findsWidgets);
  });
}
