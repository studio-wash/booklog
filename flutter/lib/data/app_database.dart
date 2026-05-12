import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Book row (Spec FR-1).
class Book {
  Book({
    required this.id,
    required this.title,
    this.totalPages,
    this.completionNote,
    required this.createdAt,
  });

  final int id;
  final String title;
  final int? totalPages;
  final String? completionNote;
  final DateTime createdAt;

  static Book fromMap(Map<String, Object?> m) => Book(
    id: m['id']! as int,
    title: m['title']! as String,
    totalPages: m['total_pages'] as int?,
    completionNote: m['completion_note'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
  );
}

/// Reading log row (Spec FR-2, FR-3).
class ReadingEntry {
  ReadingEntry({
    required this.id,
    required this.bookId,
    required this.calendarDate,
    required this.pages,
    this.note,
    required this.createdAt,
  });

  final int id;
  final int bookId;
  final DateTime calendarDate;
  final int pages;
  final String? note;
  final DateTime createdAt;

  static ReadingEntry fromMap(Map<String, Object?> m) => ReadingEntry(
    id: m['id']! as int,
    bookId: m['book_id']! as int,
    calendarDate: _parseLocalDate(m['calendar_date']! as String),
    pages: m['pages']! as int,
    note: m['note'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
  );

  static DateTime _parseLocalDate(String s) {
    final p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }
}

/// Local SQLite (sqflite). Plan: `persist-layer`.
class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  static Future<AppDatabase> open({String? pathOverride}) async {
    final path = pathOverride ?? p.join(await getDatabasesPath(), 'booklog.db');
    final db = await openDatabase(
      path,
      version: 1,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE books (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  total_pages INTEGER,
  completion_note TEXT,
  created_at INTEGER NOT NULL
);
''');
        await db.execute('''
CREATE TABLE reading_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL,
  calendar_date TEXT NOT NULL,
  pages INTEGER NOT NULL,
  note TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
);
''');
        await db.execute(
          'CREATE INDEX idx_reading_date ON reading_entries(calendar_date);',
        );
        await db.execute(
          'CREATE INDEX idx_reading_book ON reading_entries(book_id);',
        );
      },
    );
    return AppDatabase._(db);
  }

  Future<void> close() => _db.close();

  Future<List<Book>> allBooks() async {
    final rows = await _db.query('books', orderBy: 'created_at DESC');
    return rows.map(Book.fromMap).toList();
  }

  /// Books ordered by most recent reading entry (for picker).
  Future<List<Book>> booksByRecentReading() async {
    final rows = await _db.rawQuery('''
SELECT b.* FROM books b
LEFT JOIN (
  SELECT book_id, MAX(created_at) AS last_read
  FROM reading_entries
  GROUP BY book_id
) e ON e.book_id = b.id
ORDER BY COALESCE(e.last_read, b.created_at) DESC;
''');
    return rows.map(Book.fromMap).toList();
  }

  Future<Book> insertBook({required String title, int? totalPages}) async {
    final id = await _db.insert('books', {
      'title': title,
      'total_pages': totalPages,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    final rows = await _db.query('books', where: 'id = ?', whereArgs: [id]);
    return Book.fromMap(rows.single);
  }

  Future<void> updateBook(Book book) async {
    await _db.update(
      'books',
      {
        'title': book.title,
        'total_pages': book.totalPages,
        'completion_note': book.completionNote,
      },
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<void> deleteBook(int id) async {
    await _db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ReadingEntry>> entriesForMonth(int year, int month) async {
    final prefix =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final rows = await _db.query(
      'reading_entries',
      where: "calendar_date LIKE ?",
      whereArgs: ['$prefix%'],
      orderBy: 'calendar_date ASC, id ASC',
    );
    return rows.map(ReadingEntry.fromMap).toList();
  }

  /// Entries with [calendar_date] in the inclusive local-date range (ISO keys).
  Future<List<ReadingEntry>> entriesBetween(
    DateTime inclusiveStart,
    DateTime inclusiveEnd,
  ) async {
    final a = _dateKey(inclusiveStart);
    final b = _dateKey(inclusiveEnd);
    final rows = await _db.query(
      'reading_entries',
      where: 'calendar_date >= ? AND calendar_date <= ?',
      whereArgs: [a, b],
      orderBy: 'calendar_date ASC, id ASC',
    );
    return rows.map(ReadingEntry.fromMap).toList();
  }

  Future<List<ReadingEntry>> entriesForDay(DateTime day) async {
    final d = _dateKey(day);
    final rows = await _db.query(
      'reading_entries',
      where: 'calendar_date = ?',
      whereArgs: [d],
      orderBy: 'id ASC',
    );
    return rows.map(ReadingEntry.fromMap).toList();
  }

  Future<ReadingEntry> insertEntry({
    required int bookId,
    required DateTime calendarDate,
    required int pages,
    String? note,
  }) async {
    final id = await _db.insert('reading_entries', {
      'book_id': bookId,
      'calendar_date': _dateKey(calendarDate),
      'pages': pages,
      'note': note,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    final rows = await _db.query(
      'reading_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    return ReadingEntry.fromMap(rows.single);
  }

  /// Sum of pages for [bookId] across all entries.
  Future<int> totalPagesReadForBook(int bookId) async {
    final r = await _db.rawQuery(
      'SELECT COALESCE(SUM(pages), 0) AS s FROM reading_entries WHERE book_id = ?',
      [bookId],
    );
    return (r.first['s'] as int?) ?? 0;
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
