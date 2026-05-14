import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:booklog/data/app_database.dart';
import 'package:booklog/data/booklog_export_format.dart';

String _testIsbn(String tag) => 'TEST-$tag-${DateTime.now().microsecondsSinceEpoch}';

void main() {
  test('export → empty DB → import roundtrip preserves books and entries', () async {
    final dirA = await Directory.systemTemp.createTemp('booklog_export_');
    final pathA = p.join(dirA.path, 'a.db');
    final dbA = await AppDatabase.open(pathOverride: pathA);

    final b = await dbA.insertBook(
      title: 'Roundtrip Book',
      isbn: _testIsbn('rt'),
      imageUrl: 'https://example.com/cover.jpg',
      author: 'A. Writer',
      totalPages: 200,
    );
    await dbA.insertEntry(
      bookId: b.id,
      calendarDate: DateTime(2026, 5, 10),
      lastPageRead: 42,
      createdAt: DateTime(2026, 5, 10, 9),
    );
    await dbA.insertEntry(
      bookId: b.id,
      calendarDate: DateTime(2026, 5, 11),
      lastPageRead: 55,
      createdAt: DateTime(2026, 5, 11, 10),
    );

    final json = await dbA.exportDatabaseAsIndentedJson();
    await dbA.close();

    final dirB = await Directory.systemTemp.createTemp('booklog_import_');
    final pathB = p.join(dirB.path, 'b.db');
    final dbB = await AppDatabase.open(pathOverride: pathB);
    expect(await dbB.isImportSafeEmptyState(), isTrue);

    await dbB.importDatabaseFromJson(json);

    final books = await dbB.allBooks();
    expect(books.length, 1);
    expect(books.single.title, 'Roundtrip Book');
    expect(books.single.isbn, b.isbn);
    expect(books.single.imageUrl, 'https://example.com/cover.jpg');
    expect(books.single.author, 'A. Writer');
    expect(books.single.totalPages, 200);

    final span = await dbB.entriesBetween(
      DateTime(2026, 5, 1),
      DateTime(2026, 5, 31),
    );
    expect(span.length, 2);
    expect(span[0].calendarDate, DateTime(2026, 5, 10));
    expect(span[0].lastPageRead, 42);
    expect(span[0].pages, 42);
    expect(span[1].lastPageRead, 55);
    expect(span[1].pages, 13);

    await dbB.close();
    await dirA.delete(recursive: true);
    await dirB.delete(recursive: true);
  });

  test('import rejects non-empty database', () async {
    final dir = await Directory.systemTemp.createTemp('booklog_nonempty_');
    final path = p.join(dir.path, 'c.db');
    final db = await AppDatabase.open(pathOverride: path);
    await db.insertBook(title: 'X', isbn: _testIsbn('ne'), imageUrl: '');

    await expectLater(
      db.importDatabaseFromJson('{"export_schema_version":1,"app_schema_version":2,"exported_at":"x","books":[],"reading_entries":[]}'),
      throwsA(isA<BooklogImportException>()),
    );

    await db.close();
    await dir.delete(recursive: true);
  });
}
