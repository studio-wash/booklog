import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:booklog/data/app_database.dart';

String _isbn(String tag) => 'TEST-$tag-${DateTime.now().microsecondsSinceEpoch}';

void main() {
  test('starting baseline 99 then first log 100 gives pages delta 1', () async {
    final dir = await Directory.systemTemp.createTemp('booklog_bl_');
    final path = p.join(dir.path, 'db.db');
    final db = await AppDatabase.open(pathOverride: path);
    final b = await db.insertBook(
      title: 'B',
      isbn: _isbn('bl'),
      imageUrl: '',
      startingLastPageRead: 99,
    );
    final e = await db.insertEntry(
      bookId: b.id,
      calendarDate: DateTime(2026, 5, 15),
      lastPageRead: 100,
      createdAt: DateTime(2026, 5, 15, 12),
    );
    expect(e.pages, 1);
    expect(e.lastPageRead, 100);
    expect(await db.maxLastPageReadForBook(b.id), 100);
    await db.close();
    await dir.delete(recursive: true);
  });

  test('no baseline first log 100 still gives pages 100', () async {
    final dir = await Directory.systemTemp.createTemp('booklog_nobl_');
    final path = p.join(dir.path, 'db.db');
    final db = await AppDatabase.open(pathOverride: path);
    final b = await db.insertBook(title: 'B', isbn: _isbn('nb'), imageUrl: '');
    final e = await db.insertEntry(
      bookId: b.id,
      calendarDate: DateTime(2026, 5, 15),
      lastPageRead: 100,
      createdAt: DateTime(2026, 5, 15, 12),
    );
    expect(e.pages, 100);
    await db.close();
    await dir.delete(recursive: true);
  });

  test('baseline 50 rejects first log at 50 or below', () async {
    final dir = await Directory.systemTemp.createTemp('booklog_rej_');
    final path = p.join(dir.path, 'db.db');
    final db = await AppDatabase.open(pathOverride: path);
    final b = await db.insertBook(
      title: 'B',
      isbn: _isbn('rj'),
      imageUrl: '',
      startingLastPageRead: 50,
    );
    await expectLater(
      db.insertEntry(
        bookId: b.id,
        calendarDate: DateTime(2026, 5, 15),
        lastPageRead: 50,
        createdAt: DateTime(2026, 5, 15, 12),
      ),
      throwsA(isA<ArgumentError>()),
    );
    await db.close();
    await dir.delete(recursive: true);
  });

  test('export/import preserves starting_last_page_read', () async {
    final dirA = await Directory.systemTemp.createTemp('booklog_ex_');
    final pathA = p.join(dirA.path, 'a.db');
    final dbA = await AppDatabase.open(pathOverride: pathA);
    await dbA.insertBook(
      title: 'With baseline',
      isbn: _isbn('ex'),
      imageUrl: '',
      totalPages: 400,
      startingLastPageRead: 120,
    );
    final json = await dbA.exportDatabaseAsIndentedJson();
    await dbA.close();

    final dirB = await Directory.systemTemp.createTemp('booklog_im_');
    final pathB = p.join(dirB.path, 'b.db');
    final dbB = await AppDatabase.open(pathOverride: pathB);
    await dbB.importDatabaseFromJson(json);
    final books = await dbB.allBooks();
    expect(books.single.startingLastPageRead, 120);
    expect(books.single.totalPages, 400);
    await dbB.close();
    await dirA.delete(recursive: true);
    await dirB.delete(recursive: true);
  });
}
