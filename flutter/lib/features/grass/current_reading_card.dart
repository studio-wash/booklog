import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers.dart';

// Spec: spec/features/booklog-mvp/booklog-mvp.md — FR-10
// Plan: plan/PLAN-000002_main-current-reading/plan.md

/// Read: **primary**. Remaining: **surface** (white in our light theme) on the
/// tinted card — no border.
class _BookProgressBar extends StatelessWidget {
  const _BookProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        color: scheme.primary,
        backgroundColor: scheme.surface,
      ),
    );
  }
}

/// Below the grass strip: last logged book and last page (no inline log
/// button — use the main FAB).
class CurrentReadingCardSection extends ConsumerWidget {
  const CurrentReadingCardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(currentReadingProvider);
    return async.when(
      data: (snap) {
        if (snap == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'No reading logs yet. Add a book, then tap + to log.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        final total = snap.book.totalPages;
        final dateStr = DateFormat.yMMMd().format(snap.lastLogCalendarDate);
        final pagesLine =
            total != null && total > 0
                ? 'On page ${snap.lastPageReached} / $total · last log $dateStr'
                : 'On page ${snap.lastPageReached} · last log $dateStr';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Current book',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snap.book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pagesLine,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (total != null && total > 0) ...[
                    const SizedBox(height: 10),
                    _BookProgressBar(
                      value: (snap.lastPageReached / total).clamp(0.0, 1.0),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 8),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
