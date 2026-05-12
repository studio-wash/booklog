import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_branding.dart';
import '../../providers.dart';
import '../reading/domain/grass_github_palette.dart';
import '../reading/domain/grass_intensity.dart';
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
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            DateFormat.yMMMd().format(selected),
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Text('No entries this day.')
          else
            ...entries.map((e) {
              final t = byId[e.bookId]?.title ?? '#${e.bookId}';
              return ListTile(
                title: Text(t),
                subtitle: Text(
                  '${e.pages} p${e.note != null && e.note!.isNotEmpty ? ' · ${e.note}' : ''}',
                ),
              );
            }),
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

/// Main grass view (Spec FR-4 ~ FR-6). Rolling **365-day** strip; month UI in sheet.
class GrassScreen extends ConsumerWidget {
  const GrassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(dayPageTotalsRolling365Provider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(const Duration(days: 364));

    return Scaffold(
      appBar: AppBar(
        title: Text(appDisplayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Month calendar',
            onPressed: () => _openMonthCalendarSheet(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Books',
            onPressed: () => context.push('/books'),
          ),
        ],
      ),
      body: totals.when(
        data: (map) {
          final maxP = monthMaxPages(map);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Last 365 days · ${DateFormat.yMMMd().format(windowStart)} – ${DateFormat.yMMMd().format(today)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GithubContributionStrip(
                  key: const ValueKey('rolling365'),
                  windowStart: windowStart,
                  windowEnd: today,
                  dayTotals: map,
                  windowMaxPages: maxP,
                  onDayTap: (d) => _openGrassDaySheet(context, ref, d),
                ),
              ),
              if (map.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No reading logs in the last 365 days. Tap below to add one.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/log'),
        icon: const Icon(Icons.edit_note),
        label: const Text('Log reading'),
      ),
    );
  }
}
