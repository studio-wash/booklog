import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:booklog/app.dart';
import 'package:booklog/data/app_database.dart';
import 'package:booklog/providers.dart';

void main() {
  testWidgets('BooklogApp loads', (WidgetTester tester) async {
    final db = await AppDatabase.open(pathOverride: inMemoryDatabasePath);
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const BooklogApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
