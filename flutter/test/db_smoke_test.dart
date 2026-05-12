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
      lastPageRead: 3,
    );
    await db.insertEntry(
      bookId: b.id,
      calendarDate: DateTime(2026, 5, 20),
      lastPageRead: 8,
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

  test('AppDatabase latestReadingEntry picks latest created_at', () async {
    final dir = await Directory.systemTemp.createTemp('booklog_db_');
    final dbPath = p.join(dir.path, 'booklog.db');
    final db = await AppDatabase.open(pathOverride: dbPath);
    final b1 = await db.insertBook(title: 'Older', totalPages: 100);
    final b2 = await db.insertBook(title: 'Newer', totalPages: 100);
    await db.insertEntry(
      bookId: b1.id,
      calendarDate: DateTime(2026, 1, 1),
      lastPageRead: 10,
      createdAt: DateTime(2026, 1, 1, 12),
    );
    await db.insertEntry(
      bookId: b2.id,
      calendarDate: DateTime(2026, 6, 1),
      lastPageRead: 5,
      createdAt: DateTime(2026, 6, 15, 12),
    );
    final latest = await db.latestReadingEntry();
    expect(latest, isNotNull);
    expect(latest!.bookId, b2.id);
    await db.close();
    await dir.delete(recursive: true);
  });

  test('backdated last page fits between neighbors; deltas reconciled', () async {
    final dir = await Directory.systemTemp.createTemp('booklog_db_');
    final dbPath = p.join(dir.path, 'booklog.db');
    final db = await AppDatabase.open(pathOverride: dbPath);
    final b = await db.insertBook(title: 'Timeline');
    await db.insertEntry(
      bookId: b.id,
      calendarDate: DateTime(2026, 5, 20),
      lastPageRead: 100,
      createdAt: DateTime(2026, 5, 20, 12),
    );
    await db.insertEntry(
      bookId: b.id,
      calendarDate: DateTime(2026, 5, 10),
      lastPageRead: 50,
      createdAt: DateTime(2026, 5, 21, 12),
    );
    final span = await db.entriesBetween(
      DateTime(2026, 5, 1),
      DateTime(2026, 5, 31),
    );
    expect(span.length, 2);
    expect(span[0].calendarDate, DateTime(2026, 5, 10));
    expect(span[0].lastPageRead, 50);
    expect(span[0].pages, 50);
    expect(span[1].lastPageRead, 100);
    expect(span[1].pages, 50);
    await db.close();
    await dir.delete(recursive: true);
  });

  test('insertEntry rejects last page above next log on timeline', () async {
    final dir = await Directory.systemTemp.createTemp('booklog_db_');
    final dbPath = p.join(dir.path, 'booklog.db');
    final db = await AppDatabase.open(pathOverride: dbPath);
    final b = await db.insertBook(title: 'T');
    await db.insertEntry(
      bookId: b.id,
      calendarDate: DateTime(2026, 5, 10),
      lastPageRead: 3,
      createdAt: DateTime(2026, 5, 1, 10),
    );
    await db.insertEntry(
      bookId: b.id,
      calendarDate: DateTime(2026, 5, 20),
      lastPageRead: 8,
      createdAt: DateTime(2026, 5, 2, 10),
    );
    await expectLater(
      db.insertEntry(
        bookId: b.id,
        calendarDate: DateTime(2026, 5, 15),
        lastPageRead: 9,
        createdAt: DateTime(2026, 5, 3, 10),
      ),
      throwsA(isA<ArgumentError>()),
    );
    await db.close();
    await dir.delete(recursive: true);
  });
}
