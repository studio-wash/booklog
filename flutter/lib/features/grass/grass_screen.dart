import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/booklog_ui.dart';
import '../../providers.dart';
import '../reading/domain/grass_github_palette.dart';
import '../reading/domain/grass_intensity.dart';
import 'current_reading_card.dart';
import 'month_grass_grid.dart';

Future<void> _openGrassDaySheet(
  BuildContext context,
  WidgetRef ref,
  DateTime selected,
) async {
  final entries = await ref.read(databaseProvider).entriesForDay(selected);
  if (!context.mounted) return;
  final books = await ref.read(databaseProvider).allBooks();
  final byId = {for (final b in books) b.id: b};
  if (!context.mounted) return;
  final dayKey = DateFormat('yyyy-MM-dd').format(selected);
  final totalPages = entries.fold<int>(0, (s, e) => s + e.pages);
  final bookIds = entries.map((e) => e.bookId).toSet();

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          shrinkWrap: true,
          children: [
            Text(
              DateFormat.yMMMd().format(selected),
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              Text(
                'No entries this day.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: BooklogStatChip(
                      label: 'Pages',
                      value: '$totalPages',
                      icon: Icons.menu_book_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BooklogStatChip(
                      label: 'Sessions',
                      value: '${entries.length}',
                      icon: Icons.timelapse_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BooklogStatChip(
                      label: 'Books',
                      value: '${bookIds.length}',
                      icon: Icons.library_books_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...entries.map((e) {
                final book = byId[e.bookId];
                final t = book?.title ?? '#${e.bookId}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BooklogCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t,
                          style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'p. ${e.lastPageRead} (+${e.pages} p)'
                          '${e.note != null && e.note!.isNotEmpty ? ' · ${e.note}' : ''}',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(ctx);
                if (context.mounted) {
                  context.push('/log?day=$dayKey');
                }
              },
              child: const Text('Log reading for this day'),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _openMonthCalendarSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final now = DateTime.now();
  ref.read(selectedMonthProvider.notifier).state = DateTime(
    now.year,
    now.month,
  );

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Consumer(
            builder: (context, ref, _) {
              final month = ref.watch(selectedMonthProvider);
              final totals = ref.watch(dayPageTotalsForSelectedMonthProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          ref
                              .read(selectedMonthProvider.notifier)
                              .state = DateTime(month.year, month.month - 1);
                        },
                      ),
                      Expanded(
                        child: Text(
                          DateFormat.yMMMM().format(month),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          ref
                              .read(selectedMonthProvider.notifier)
                              .state = DateTime(month.year, month.month + 1);
                        },
                      ),
                    ],
                  ),
                  totals.when(
                    data:
                        (map) => MonthGithubContributionStrip(
                          month: month,
                          dayTotals: map,
                          monthMaxPages: monthMaxPages(map),
                          onDayTap: (d) {
                            Navigator.pop(sheetCtx);
                            _openGrassDaySheet(context, ref, d);
                          },
                        ),
                    loading:
                        () => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    error:
                        (e, _) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('$e'),
                        ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

/// Main grass view (Spec FR-4 ~ FR-6, PLAN-000006 home skin).
class GrassScreen extends ConsumerWidget {
  const GrassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(dayPageTotalsRolling12MonthsProvider);
    final streak = ref.watch(readingStreakProvider);
    final booksYear = ref.watch(booksReadThisYearProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = mainGrassWindowStart(today);
    final shellBottom =
        MediaQuery.paddingOf(context).bottom + 56 + 32;

    return Scaffold(
      appBar: AppBar(
        title: Text(homeGreetingForHour(now.hour)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Month calendar',
            onPressed: () => _openMonthCalendarSheet(context, ref),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: shellBottom),
        child: totals.when(
          data: (map) {
            final maxP = monthMaxPages(map);
            final hasAnyReading = map.values.any((p) => p > 0);
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        streak.when(
                          data:
                              (n) => BooklogStatChip(
                                label: 'Streak',
                                value: n == 0 ? '—' : '$n days',
                                icon: Icons.local_fire_department_outlined,
                              ),
                          loading:
                              () => const Expanded(
                                child: SizedBox(height: 64),
                              ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 8),
                        booksYear.when(
                          data:
                              (n) => BooklogStatChip(
                                label: 'Books this year',
                                value: '$n',
                                icon: Icons.auto_stories_outlined,
                              ),
                          loading:
                              () => const Expanded(
                                child: SizedBox(height: 64),
                              ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const BooklogSectionHeader('Reading activity'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Text(
                      '${DateFormat.yMMMd().format(windowStart)} – ${DateFormat.yMMMd().format(today)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Row(
                      children: [
                        Text(
                          'Less',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: 8),
                        for (var lv = 0; lv <= 4; lv++) ...[
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: githubGrassCellFill(lv),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: githubGrassCellBorder,
                                width: 0.5,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          'More',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  GithubContributionStrip(
                    key: const ValueKey('rolling12m'),
                    windowStart: windowStart,
                    windowEnd: today,
                    dayTotals: map,
                    windowMaxPages: maxP,
                    onDayTap: (d) => _openGrassDaySheet(context, ref, d),
                  ),
                  if (!hasAnyReading) ...[
                    const SizedBox(height: 16),
                    const _HeatmapEmptyHint(),
                  ],
                  const SizedBox(height: 20),
                  const CurrentReadingCardSection(),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
      ),
    );
  }
}

class _HeatmapEmptyHint extends StatelessWidget {
  const _HeatmapEmptyHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Your heatmap will fill in as you log reading.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
