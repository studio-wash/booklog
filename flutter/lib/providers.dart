import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';

/// Injected from [main] via [ProviderScope.overrides].
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in main()');
});

/// Bump to reload month aggregates & book lists after writes.
final readingDataTickProvider = StateProvider<int>((ref) => 0);

/// Month shown in the **calendar bottom sheet** (chevron navigation).
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month);
});

final booksProvider = FutureProvider.autoDispose<List<Book>>((ref) async {
  ref.watch(readingDataTickProvider);
  final db = ref.watch(databaseProvider);
  return db.booksByRecentReading();
});

/// Map of calendar day (date-only) -> total pages that day in [selectedMonthProvider].
/// Used by the month calendar sheet (not the main 12-month strip).
final dayPageTotalsForSelectedMonthProvider =
    FutureProvider.autoDispose<Map<DateTime, int>>((ref) async {
      ref.watch(readingDataTickProvider);
      final month = ref.watch(selectedMonthProvider);
      final db = ref.watch(databaseProvider);
      final entries = await db.entriesForMonth(month.year, month.month);
      final map = <DateTime, int>{};
      for (final e in entries) {
        final d = DateTime(
          e.calendarDate.year,
          e.calendarDate.month,
          e.calendarDate.day,
        );
        map[d] = (map[d] ?? 0) + e.pages;
      }
      return map;
    });

/// First local calendar day of the month **11 months before** [today]’s month
/// (inclusive 12 calendar months through [today]).
DateTime mainGrassWindowStart(DateTime today) {
  final y = today.year;
  final m = today.month;
  var startM = m - 11;
  var startY = y;
  while (startM < 1) {
    startM += 12;
    startY -= 1;
  }
  return DateTime(startY, startM, 1);
}

/// Main grass strip: **12 calendar months** ending today — day → total `pages`.
/// Intensity max is the max day total within this window.
final dayPageTotalsRolling12MonthsProvider =
    FutureProvider.autoDispose<Map<DateTime, int>>((ref) async {
      ref.watch(readingDataTickProvider);
      final db = ref.watch(databaseProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = mainGrassWindowStart(today);
      final entries = await db.entriesBetween(start, today);
      final map = <DateTime, int>{};
      for (final e in entries) {
        final d = DateTime(
          e.calendarDate.year,
          e.calendarDate.month,
          e.calendarDate.day,
        );
        map[d] = (map[d] ?? 0) + e.pages;
      }
      return map;
    });

final booksMapProvider = FutureProvider.autoDispose<Map<int, Book>>((
  ref,
) async {
  final books = await ref.watch(booksProvider.future);
  return {for (final b in books) b.id: b};
});

/// Spec FR-10 — book tied to the latest `reading_entries.created_at`, with
/// last reached page for that book and the last log’s calendar date.
class CurrentReadingSnapshot {
  const CurrentReadingSnapshot({
    required this.book,
    required this.lastPageReached,
    required this.lastLogCalendarDate,
  });

  final Book book;
  final int lastPageReached;
  final DateTime lastLogCalendarDate;
}

/// Home streak — consecutive days with logs (PLAN-000006).
final readingStreakProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(readingDataTickProvider);
  return ref.watch(databaseProvider).readingStreakDays();
});

/// Books with ≥1 log in the current calendar year (PLAN-000006).
final booksReadThisYearProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(readingDataTickProvider);
  final year = DateTime.now().year;
  return ref.watch(databaseProvider).distinctBooksWithLogsInYear(year);
});

/// Null when there are no reading entries (or book row missing).
final currentReadingProvider =
    FutureProvider.autoDispose<CurrentReadingSnapshot?>((ref) async {
      ref.watch(readingDataTickProvider);
      final db = ref.watch(databaseProvider);
      final latest = await db.latestReadingEntry();
      if (latest == null) return null;
      final book = await db.bookById(latest.bookId);
      if (book == null) return null;
      final lastPage = await db.maxLastPageReadForBook(book.id);
      return CurrentReadingSnapshot(
        book: book,
        lastPageReached: lastPage,
        lastLogCalendarDate: latest.calendarDate,
      );
    });
