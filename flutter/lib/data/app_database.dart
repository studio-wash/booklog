import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'booklog_export_format.dart';

// Plan: plan/PLAN-000005_resume-reading-from-page/plan.md — starting baseline

/// Book row (Spec FR-1).
///
/// [isbn] is required (non-empty); unique in DB. [imageUrl] may be empty when
/// no cover URL is known; UI should show a placeholder.
class Book {
  Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.imageUrl,
    this.link,
    this.author,
    this.publisher,
    this.description,
    this.pubdate,
    this.totalPages,
    this.completionNote,
    this.startingLastPageRead,
    this.finishedAt,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String isbn;
  final String imageUrl;
  final String? link;
  final String? author;
  final String? publisher;
  /// Legacy column; new books do not persist Naver blurb (search UI only).
  final String? description;
  final String? pubdate;
  final int? totalPages;
  final String? completionNote;
  /// Pages already read before the first in-app log (PLAN-000005). Inclusive
  /// “last page reached” outside the app; first log must be `> this` (or null).
  final int? startingLastPageRead;
  /// User marked the book finished (FR-8); independent of [totalPages] / last log.
  final DateTime? finishedAt;
  final DateTime createdAt;

  bool get isMarkedFinished => finishedAt != null;

  static Book fromMap(Map<String, Object?> m) => Book(
    id: m['id']! as int,
    title: m['title']! as String,
    isbn: m['isbn']! as String,
    imageUrl: (m['image_url'] as String?) ?? '',
    link: m['link'] as String?,
    author: m['author'] as String?,
    publisher: m['publisher'] as String?,
    description: m['description'] as String?,
    pubdate: m['pubdate'] as String?,
    totalPages: m['total_pages'] as int?,
    completionNote: m['completion_note'] as String?,
    startingLastPageRead: m['starting_last_page_read'] as int?,
    finishedAt:
        m['finished_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['finished_at']! as int),
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
  );

  Book copyWith({
    int? id,
    String? title,
    String? isbn,
    String? imageUrl,
    String? link,
    String? author,
    String? publisher,
    String? description,
    String? pubdate,
    int? totalPages,
    String? completionNote,
    int? startingLastPageRead,
    DateTime? finishedAt,
    DateTime? createdAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      imageUrl: imageUrl ?? this.imageUrl,
      link: link ?? this.link,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      description: description ?? this.description,
      pubdate: pubdate ?? this.pubdate,
      totalPages: totalPages ?? this.totalPages,
      completionNote: completionNote ?? this.completionNote,
      startingLastPageRead:
          startingLastPageRead ?? this.startingLastPageRead,
      finishedAt: finishedAt ?? this.finishedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
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

/// Local SQLite (sqflite). Plan: `persist-layer`; PLAN-000005 baseline page.
class AppDatabase {
  AppDatabase._(this._db);

  final Database _db;

  /// v2: full Naver catalog fields. v3: `starting_last_page_read`. v4:
  /// `finished_at` (FR-8 manual finish). v1 → v2 **drops** books and entries.
  static const int _schemaVersion = 4;

  /// Same as SQLite `userVersion` — used in JSON export (`app_schema_version`).
  static int get booklogDbSchemaVersion => _schemaVersion;

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
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS reading_entries');
          await db.execute('DROP TABLE IF EXISTS books');
          await _createSchema(db);
        } else if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE books ADD COLUMN starting_last_page_read INTEGER',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE books ADD COLUMN finished_at INTEGER',
          );
        }
      },
    );
    return AppDatabase._(db);
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
CREATE TABLE books (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  isbn TEXT NOT NULL,
  image_url TEXT NOT NULL,
  link TEXT,
  author TEXT,
  publisher TEXT,
  description TEXT,
  pubdate TEXT,
  total_pages INTEGER,
  completion_note TEXT,
  starting_last_page_read INTEGER,
  finished_at INTEGER,
  created_at INTEGER NOT NULL,
  UNIQUE (isbn)
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

  Future<Book?> bookByIsbn(String isbn) async {
    final rows = await _db.query(
      'books',
      where: 'isbn = ?',
      whereArgs: [isbn],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Book.fromMap(rows.single);
  }

  Future<Book> insertBook({
    required String title,
    required String isbn,
    required String imageUrl,
    String? link,
    String? author,
    String? publisher,
    String? description,
    String? pubdate,
    int? totalPages,
    int? startingLastPageRead,
  }) async {
    if (startingLastPageRead != null) {
      if (startingLastPageRead < 0) {
        throw ArgumentError.value(
          startingLastPageRead,
          'startingLastPageRead',
          'Must be null or >= 0',
        );
      }
      if (totalPages != null &&
          totalPages > 0 &&
          startingLastPageRead >= totalPages) {
        throw ArgumentError(
          'starting_last_page_read must be less than total_pages when set.',
        );
      }
    }
    final id = await _db.insert('books', {
      'title': title,
      'isbn': isbn,
      'image_url': imageUrl,
      'link': link,
      'author': author,
      'publisher': publisher,
      'description': description,
      'pubdate': pubdate,
      'total_pages': totalPages,
      'starting_last_page_read': startingLastPageRead,
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
        'isbn': book.isbn,
        'image_url': book.imageUrl,
        'link': book.link,
        'author': book.author,
        'publisher': book.publisher,
        'description': book.description,
        'pubdate': book.pubdate,
        'total_pages': book.totalPages,
        'completion_note': book.completionNote,
        'starting_last_page_read': book.startingLastPageRead,
        'finished_at': book.finishedAt?.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<void> deleteBook(int id) async {
    await _db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  /// Count of reading logs for [bookId] (for PLAN-000005 baseline edit guard).
  Future<int> readingEntryCountForBook(int bookId) async {
    final n = Sqflite.firstIntValue(
      await _db.rawQuery(
        'SELECT COUNT(*) FROM reading_entries WHERE book_id = ?',
        [bookId],
      ),
    );
    return n ?? 0;
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

  /// Consecutive calendar days with ≥1 log, ending today or yesterday if today
  /// has no log yet (PLAN-000006 home streak).
  Future<int> readingStreakDays() async {
    final rows = await _db.rawQuery(
      'SELECT DISTINCT calendar_date FROM reading_entries',
    );
    if (rows.isEmpty) return 0;
    final logged = {for (final r in rows) r['calendar_date']! as String};
    var d = DateTime.now();
    d = DateTime(d.year, d.month, d.day);
    if (!logged.contains(_dateKey(d))) {
      d = d.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (logged.contains(_dateKey(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Distinct books with at least one log in [year] (calendar `calendar_date`).
  Future<int> distinctBooksWithLogsInYear(int year) async {
    final rows = await _db.rawQuery(
      '''
SELECT COUNT(DISTINCT book_id) AS c
FROM reading_entries
WHERE calendar_date LIKE ?
''',
      ['$year-%'],
    );
    final c = rows.single['c'];
    if (c is int) return c;
    return (c as num?)?.toInt() ?? 0;
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
    final prev = await _effectivePrevFloor(bookId, dk, ts);
    final next = await _minLastPageReadAfter(bookId, dk, ts);
    if (lastPageRead <= prev) {
      throw ArgumentError.value(
        lastPageRead,
        'lastPageRead',
        'Must be > $prev (must advance past the timeline floor / prior progress)',
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
    final prev = await _effectivePrevFloor(bookId, dk, ts);
    final upper = await _minLastPageReadAfter(bookId, dk, ts);
    final lb = prev + 1;
    return (lowerBound: lb < 1 ? 1 : lb, upperBound: upper);
  }

  /// Max `last_page_read` from rows **strictly before** this slot (entries only).
  Future<int> _entryMaxLastPageReadBefore(
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

  Future<int> _startingLastPageBaseline(int bookId) async {
    final rows = await _db.query(
      'books',
      columns: ['starting_last_page_read'],
      where: 'id = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return (rows.single['starting_last_page_read'] as int?) ?? 0;
  }

  /// Timeline floor: max(reading progress before this slot, off-app baseline).
  Future<int> _effectivePrevFloor(
    int bookId,
    String dateKey,
    int createdAtMs,
  ) async {
    final fromEntries = await _entryMaxLastPageReadBefore(
      bookId,
      dateKey,
      createdAtMs,
    );
    final baseline = await _startingLastPageBaseline(bookId);
    return fromEntries > baseline ? fromEntries : baseline;
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
    final bRows = await _db.query(
      'books',
      columns: ['starting_last_page_read'],
      where: 'id = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    var prevL = 0;
    if (bRows.isNotEmpty) {
      prevL = (bRows.single['starting_last_page_read'] as int?) ?? 0;
    }
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

  /// Highest absolute page for [bookId]: max(latest entry, off-app baseline).
  Future<int> maxLastPageReadForBook(int bookId) async {
    final r = await _db.rawQuery(
      'SELECT COALESCE(MAX(last_page_read), 0) AS m FROM reading_entries WHERE book_id = ?',
      [bookId],
    );
    final entryMax = (r.first['m'] as int?) ?? 0;
    final baseline = await _startingLastPageBaseline(bookId);
    return entryMax > baseline ? entryMax : baseline;
  }

  /// Sum of per-log [pages] (deltas) for [bookId].
  Future<int> totalPagesReadForBook(int bookId) async {
    final r = await _db.rawQuery(
      'SELECT COALESCE(SUM(pages), 0) AS s FROM reading_entries WHERE book_id = ?',
      [bookId],
    );
    return (r.first['s'] as int?) ?? 0;
  }

  /// True when there are no books and no reading entries (safe for PLAN-000004 import).
  Future<bool> isImportSafeEmptyState() async {
    final b =
        Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM books')) ??
        0;
    final e =
        Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) FROM reading_entries'),
        ) ??
        0;
    return b == 0 && e == 0;
  }

  /// Raw `books` rows for export (`id ASC`).
  Future<List<Map<String, Object?>>> allBookRowsOrderedById() async {
    return _db.query('books', orderBy: 'id ASC');
  }

  /// Raw `reading_entries` rows for export.
  Future<List<Map<String, Object?>>> allReadingEntryRowsOrdered() async {
    return _db.query(
      'reading_entries',
      orderBy: 'calendar_date ASC, id ASC',
    );
  }

  /// Full DB snapshot as indented JSON (PLAN-000004 / FR-11).
  Future<String> exportDatabaseAsIndentedJson() async {
    final books = await allBookRowsOrderedById();
    final entries = await allReadingEntryRowsOrdered();
    final payload = <String, Object?>{
      kExportKeySchemaVersion: booklogExportFormatVersion,
      kExportKeyAppSchemaVersion: booklogDbSchemaVersion,
      kExportKeyExportedAt: DateTime.now().toUtc().toIso8601String(),
      kExportKeyBooks: books,
      kExportKeyReadingEntries: entries,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Restores data from [exportDatabaseAsIndentedJson] output. **Only when DB is empty.**
  Future<void> importDatabaseFromJson(String json) async {
    if (!await isImportSafeEmptyState()) {
      throw const BooklogImportException(
        'Import only when there are no books and no reading entries.',
      );
    }
    final dynamic decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const BooklogImportException('Root JSON must be an object.');
    }
    final root = Map<String, dynamic>.from(decoded);
    final ev = root[kExportKeySchemaVersion];
    if (ev is! num) {
      throw const BooklogImportException(
        'Missing or invalid export_schema_version.',
      );
    }
    final exportVer = ev.toInt();
    if (exportVer < booklogExportFormatMinSupported ||
        exportVer > booklogExportFormatMaxSupported) {
      throw BooklogImportException(
        'Unsupported export_schema_version: $exportVer '
        '(supported $booklogExportFormatMinSupported–$booklogExportFormatMaxSupported).',
      );
    }
    final booksRaw = root[kExportKeyBooks];
    final entriesRaw = root[kExportKeyReadingEntries];
    if (booksRaw is! List<dynamic> || entriesRaw is! List<dynamic>) {
      throw const BooklogImportException(
        'books and reading_entries must be JSON arrays.',
      );
    }
    final bookRows =
        booksRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, Object?>.from(e))
            .toList();
    final entryRows =
        entriesRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, Object?>.from(e))
            .toList();
    bookRows.sort((a, b) => _numInt(a['id']).compareTo(_numInt(b['id'])));
    entryRows.sort((a, b) {
      final ca = '${a['calendar_date']}';
      final cb = '${b['calendar_date']}';
      final c = ca.compareTo(cb);
      if (c != 0) return c;
      return _numInt(a['id']).compareTo(_numInt(b['id']));
    });
    for (final row in bookRows) {
      _validateBookExportRow(row);
    }
    for (final row in entryRows) {
      _validateEntryExportRow(row);
    }
    final idMap = <int, int>{};
    await _db.transaction((txn) async {
      for (final row in bookRows) {
        final oldId = _numInt(row['id']);
        final insert = _bookInsertFromExportRow(row);
        final newId = await txn.insert('books', insert);
        idMap[oldId] = newId;
      }
      for (final row in entryRows) {
        final oldBookId = _numInt(row['book_id']);
        final newBookId = idMap[oldBookId];
        if (newBookId == null) {
          throw BooklogImportException(
            'reading_entries references missing book_id: $oldBookId',
          );
        }
        final insert = _entryInsertFromExportRow(row, newBookId);
        await txn.insert('reading_entries', insert);
      }
    });
    for (final newBookId in idMap.values) {
      await _reconcileReadingEntryPagesForBook(newBookId);
    }
  }

  static int _numInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    throw BooklogImportException('Expected int-compatible value, got $v');
  }

  static void _validateBookExportRow(Map<String, Object?> row) {
    final title = row['title'];
    if (title is! String || title.trim().isEmpty) {
      throw const BooklogImportException('Each book needs a non-empty title.');
    }
    final isbn = row['isbn'];
    if (isbn is! String || isbn.trim().isEmpty) {
      throw const BooklogImportException('Each book needs a non-empty isbn.');
    }
    if (row['created_at'] == null) {
      throw const BooklogImportException('Each book needs created_at.');
    }
    _numInt(row['created_at']);
    _numInt(row['id']);
    final sl = row['starting_last_page_read'];
    if (sl != null) {
      final v = _numInt(sl);
      if (v < 0) {
        throw const BooklogImportException(
          'starting_last_page_read must be >= 0 when set.',
        );
      }
      final tpRaw = row['total_pages'];
      if (tpRaw != null) {
        final tp = _numInt(tpRaw);
        if (tp > 0 && v >= tp) {
          throw const BooklogImportException(
            'starting_last_page_read must be less than total_pages when both set.',
          );
        }
      }
    }
  }

  static void _validateEntryExportRow(Map<String, Object?> row) {
    final dk = row['calendar_date'];
    if (dk is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dk)) {
      throw const BooklogImportException(
        'Each reading entry needs calendar_date YYYY-MM-DD.',
      );
    }
    _numInt(row['id']);
    _numInt(row['book_id']);
    _numInt(row['pages']);
    _numInt(row['last_page_read']);
    _numInt(row['created_at']);
  }

  static Map<String, Object?> _bookInsertFromExportRow(
    Map<String, Object?> row,
  ) {
    return {
      'title': row['title']! as String,
      'isbn': row['isbn']! as String,
      'image_url': (row['image_url'] as String?) ?? '',
      'link': row['link'],
      'author': row['author'],
      'publisher': row['publisher'],
      'description': row['description'],
      'pubdate': row['pubdate'],
      'total_pages': row['total_pages'],
      'completion_note': row['completion_note'],
      'starting_last_page_read':
          row['starting_last_page_read'] == null
              ? null
              : _numInt(row['starting_last_page_read']),
      'finished_at':
          row['finished_at'] == null ? null : _numInt(row['finished_at']),
      'created_at': _numInt(row['created_at']),
    };
  }

  static Map<String, Object?> _entryInsertFromExportRow(
    Map<String, Object?> row,
    int newBookId,
  ) {
    return {
      'book_id': newBookId,
      'calendar_date': row['calendar_date']! as String,
      'pages': _numInt(row['pages']),
      'last_page_read': _numInt(row['last_page_read']),
      'note': row['note'],
      'created_at': _numInt(row['created_at']),
    };
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
