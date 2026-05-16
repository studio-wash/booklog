import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:booklog/data/app_database.dart';

String _isbn(String tag) =>
    'TEST-finish-$tag-${DateTime.now().microsecondsSinceEpoch}';

void main() {
  test('finished_at is independent of reaching total_pages', () async {
    final db = await AppDatabase.open(pathOverride: inMemoryDatabasePath);
    addTearDown(db.close);

    final b = await db.insertBook(
      title: 'Long book',
      isbn: _isbn('a'),
      imageUrl: '',
      totalPages: 300,
    );
    await db.insertEntry(
      bookId: b.id,
      calendarDate: DateTime(2026, 5, 10),
      lastPageRead: 280,
      createdAt: DateTime(2026, 5, 10, 12),
    );

    expect(b.isMarkedFinished, isFalse);
    expect(await db.maxLastPageReadForBook(b.id), 280);

    final finishedAt = DateTime(2026, 5, 10, 18);
    await db.updateBook(b.copyWith(finishedAt: finishedAt));

    final got = await db.bookById(b.id);
    expect(got!.isMarkedFinished, isTrue);
    expect(got.finishedAt!.millisecondsSinceEpoch, finishedAt.millisecondsSinceEpoch);
    expect(await db.maxLastPageReadForBook(b.id), 280);
  });
}
