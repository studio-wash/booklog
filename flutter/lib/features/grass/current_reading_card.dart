import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/booklog_ui.dart';
import '../../providers.dart';

class _BookProgressBar extends StatelessWidget {
  const _BookProgressBar({required this.value, this.label});

  final double value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            color: scheme.primary,
            backgroundColor: scheme.surface,
          ),
        ),
      ],
    );
  }
}

/// Currently reading card (PLAN-000006 reference #1). Tap opens log for this book.
class CurrentReadingCardSection extends ConsumerWidget {
  const CurrentReadingCardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(currentReadingProvider);
    return async.when(
      data: (snap) {
        if (snap == null) {
          return const _HomeEmptyReadingPrompt();
        }
        final total = snap.book.totalPages;
        final dateStr = DateFormat.yMMMd().format(snap.lastLogCalendarDate);
        final progress =
            total != null && total > 0
                ? (snap.lastPageReached / total).clamp(0.0, 1.0)
                : null;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: BooklogCard(
            onTap: () => context.push('/log?bookId=${snap.book.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Currently reading',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (snap.book.imageUrl.trim().isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          snap.book.imageUrl,
                          width: 56,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  const SizedBox(width: 56, height: 80),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            snap.book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            total != null && total > 0
                                ? 'Page ${snap.lastPageReached} of $total · $dateStr'
                                : 'Page ${snap.lastPageReached} · $dateStr',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: 12),
                  _BookProgressBar(
                    value: progress,
                    label:
                        '${snap.lastPageReached} / $total pages',
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 8),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Empty prompt when no logs yet (PLAN-000006 #10).
class _HomeEmptyReadingPrompt extends ConsumerWidget {
  const _HomeEmptyReadingPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: BooklogCard(
        child: Column(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No reading recorded yet',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a book from the Books tab, then tap + to log your first session.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
