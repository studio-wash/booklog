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
/// Used by the month calendar sheet (not the main 365-day strip).
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

/// Last **365** local calendar days ending today (inclusive): day -> total pages.
/// Main grass strip; intensity max is the max within this window.
final dayPageTotalsRolling365Provider =
    FutureProvider.autoDispose<Map<DateTime, int>>((ref) async {
      ref.watch(readingDataTickProvider);
      final db = ref.watch(databaseProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = today.subtract(const Duration(days: 364));
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
