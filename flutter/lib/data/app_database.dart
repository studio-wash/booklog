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
///
/// [pages] is the **delta** for that log (grass / day totals); [lastPageRead]
/// is the absolute page number the user was on after this session.
class ReadingEntry {
  ReadingEntry({
    required this.id,
    required this.bookId,
    required this.calendarDate,
    required this.pages,
    required this.lastPageRead,
    this.note,
    required this.createdAt,
  });

  final int id;
  final int bookId;
  final DateTime calendarDate;
  final int pages;
  final int lastPageRead;
  final String? note;
  final DateTime createdAt;

  static ReadingEntry fromMap(Map<String, Object?> m) => ReadingEntry(
    id: m['id']! as int,
    bookId: m['book_id']! as int,
    calendarDate: _parseLocalDate(m['calendar_date']! as String),
    pages: m['pages']! as int,
    lastPageRead: m['last_page_read']! as int,
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

  /// Pre-MVP: stays at 1; schema changes reset by **new default file name**
  /// (no migration path until first store release).
  static const int _schemaVersion = 1;

  static Future<AppDatabase> open({String? pathOverride}) async {
    final path =
        pathOverride ?? p.join(await getDatabasesPath(), 'booklog_store.db');
    final db = await openDatabase(
      path,
      version: _schemaVersion,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
      },
    );
    return AppDatabase._(db);
  }

  static Future<void> _createSchema(Database db) async {
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
  last_page_read INTEGER NOT NULL,
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

  /// Most recently saved log row (`created_at` desc). Null if no entries.
  Future<ReadingEntry?> latestReadingEntry() async {
    final rows = await _db.query(
      'reading_entries',
      orderBy: 'created_at DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ReadingEntry.fromMap(rows.single);
  }

  Future<Book?> bookById(int id) async {
    final rows = await _db.query('books', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Book.fromMap(rows.single);
  }

  /// Saves [lastPageRead] (absolute page number). [pages] is the delta from
  /// the **chronological** previous log for this book; after insert, all
  /// [pages] for the book are recomputed so day totals stay correct.
  ///
  /// Allowed range for a new row at [createdAt] (default now): every existing
  /// log **strictly before** this slot sets a floor; every log **strictly
  /// after** sets a ceiling (so back-dated logs fit between neighbors).
  Future<ReadingEntry> insertEntry({
    required int bookId,
    required DateTime calendarDate,
    required int lastPageRead,
    String? note,

    /// When set (e.g. in tests), used as row `created_at` and for timeline
    /// bounds (must match [lastPageBoundsForNewEntry] if you pre-validate).
    DateTime? createdAt,
  }) async {
    if (lastPageRead < 1) {
      throw ArgumentError.value(lastPageRead, 'lastPageRead', 'Must be >= 1');
    }
    final at = createdAt ?? DateTime.now();
    final ts = at.millisecondsSinceEpoch;
    final dk = _dateKey(calendarDate);
    final prev = await _maxLastPageReadBefore(bookId, dk, ts);
    final next = await _minLastPageReadAfter(bookId, dk, ts);
    if (lastPageRead < prev) {
      throw ArgumentError.value(
        lastPageRead,
        'lastPageRead',
        'Must be ≥ $prev (last page on or before this log’s place in time)',
      );
    }
    if (next != null && lastPageRead > next) {
      throw ArgumentError.value(
        lastPageRead,
        'lastPageRead',
        'Must be ≤ $next (a later log for this book already reached that page)',
      );
    }
    final pages = lastPageRead - prev;
    final id = await _db.insert('reading_entries', {
      'book_id': bookId,
      'calendar_date': dk,
      'pages': pages,
      'last_page_read': lastPageRead,
      'note': note,
      'created_at': ts,
    });
    await _reconcileReadingEntryPagesForBook(bookId);
    final rows = await _db.query(
      'reading_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    return ReadingEntry.fromMap(rows.single);
  }

  /// Floor / ceiling for [lastPageRead] when adding a row on [calendarDate]
  /// at [atTime] (same instant you pass to [insertEntry] as `createdAt`).
  Future<({int lowerBound, int? upperBound})> lastPageBoundsForNewEntry({
    required int bookId,
    required DateTime calendarDate,
    DateTime? atTime,
  }) async {
    final ts = (atTime ?? DateTime.now()).millisecondsSinceEpoch;
    final dk = _dateKey(calendarDate);
    final lower = await _maxLastPageReadBefore(bookId, dk, ts);
    final upper = await _minLastPageReadAfter(bookId, dk, ts);
    return (lowerBound: lower, upperBound: upper);
  }

  Future<int> _maxLastPageReadBefore(
    int bookId,
    String dateKey,
    int createdAtMs,
  ) async {
    final r = await _db.rawQuery(
      '''
SELECT COALESCE(MAX(last_page_read), 0) AS m FROM reading_entries
WHERE book_id = ? AND (
  calendar_date < ? OR (calendar_date = ? AND created_at < ?)
)
''',
      [bookId, dateKey, dateKey, createdAtMs],
    );
    return (r.first['m'] as int?) ?? 0;
  }

  Future<int?> _minLastPageReadAfter(
    int bookId,
    String dateKey,
    int createdAtMs,
  ) async {
    final r = await _db.rawQuery(
      '''
SELECT MIN(last_page_read) AS m FROM reading_entries
WHERE book_id = ? AND (
  calendar_date > ? OR (calendar_date = ? AND created_at > ?)
)
''',
      [bookId, dateKey, dateKey, createdAtMs],
    );
    final v = r.first['m'];
    if (v == null) return null;
    return v as int;
  }

  /// Recompute each row’s [pages] from ordered [last_page_read] chain.
  Future<void> _reconcileReadingEntryPagesForBook(int bookId) async {
    final rows = await _db.query(
      'reading_entries',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'calendar_date ASC, created_at ASC, id ASC',
    );
    var prevL = 0;
    for (final row in rows) {
      final id = row['id']! as int;
      final l = row['last_page_read']! as int;
      final newPages = l - prevL;
      prevL = l;
      if ((row['pages'] as int) != newPages) {
        await _db.update(
          'reading_entries',
          {'pages': newPages},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
  }

  /// Highest [lastPageRead] stored for [bookId] (0 if none).
  Future<int> maxLastPageReadForBook(int bookId) async {
    final r = await _db.rawQuery(
      'SELECT COALESCE(MAX(last_page_read), 0) AS m FROM reading_entries WHERE book_id = ?',
      [bookId],
    );
    return (r.first['m'] as int?) ?? 0;
  }

  /// Sum of per-log [pages] (deltas) for [bookId].
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
