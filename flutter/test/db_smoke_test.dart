import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:booklog/data/app_database.dart';

void main() {
  test('AppDatabase entriesForMonth returns', () async {
    final dir = await Directory.systemTemp.createTemp('booklog_db_');
    final dbPath = p.join(dir.path, 'booklog.db');
    final db = await AppDatabase.open(pathOverride: dbPath);
    final rows = await db.entriesForMonth(2026, 5);
    expect(rows, isEmpty);
    await db.close();
    await dir.delete(recursive: true);
  });

  test('AppDatabase entriesBetween inclusive range', () async {
    final dir = await Directory.systemTemp.createTemp('booklog_db_');
    final dbPath = p.join(dir.path, 'booklog.db');
    final db = await AppDatabase.open(pathOverride: dbPath);
    final b = await db.insertBook(title: 'T');
    await db.insertEntry(
      bookId: b.id,
      calendarDate: DateTime(2026, 5, 10),
      pages: 3,
    );
    await db.insertEntry(
      bookId: b.id,
      calendarDate: DateTime(2026, 5, 20),
      pages: 5,
    );
    final before = await db.entriesBetween(
      DateTime(2026, 5, 1),
      DateTime(2026, 5, 9),
    );
    expect(before, isEmpty);
    final span = await db.entriesBetween(
      DateTime(2026, 5, 1),
      DateTime(2026, 5, 31),
    );
    expect(span.length, 2);
    await db.close();
    await dir.delete(recursive: true);
  });
}
