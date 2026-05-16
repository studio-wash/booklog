import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../providers.dart';
import '../books/books_screen.dart' show showAddBookSheet;

/// Log reading session (Spec FR-2, FR-3, FR-8).
class LogEntryScreen extends ConsumerStatefulWidget {
  const LogEntryScreen({super.key, this.initialBookId, this.initialLogDay});

  final int? initialBookId;

  /// Local calendar day to pre-fill (e.g. from `/log?day=2026-05-11` or heatmap sheet).
  final DateTime? initialLogDay;

  @override
  ConsumerState<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends ConsumerState<LogEntryScreen> {
  int? _bookId;
  final _lastPageCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _showNote = false;
  bool _markFinished = false;
  DateTime _day = DateTime.now();

  @override
  void initState() {
    super.initState();
    _bookId = widget.initialBookId;
    final today = _dateOnly(DateTime.now());
    var d =
        widget.initialLogDay != null ? _dateOnly(widget.initialLogDay!) : today;
    if (d.isAfter(today)) d = today;
    _day = d;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _openAddBookSheet() async {
    final book = await showAddBookSheet(context, ref);
    if (!mounted || book == null) return;
    setState(() {
      _bookId = book.id;
      _markFinished = false;
    });
  }

  @override
  void dispose() {
    _lastPageCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    final bid = _bookId;
    if (bid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose a book')));
      return;
    }
    final lastPage = int.tryParse(_lastPageCtrl.text.trim());
    if (lastPage == null || lastPage < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the last page you read (whole number ≥ 1)'),
        ),
      );
      return;
    }
    final db = ref.read(databaseProvider);
    final at = DateTime.now();
    final bounds = await db.lastPageBoundsForNewEntry(
      bookId: bid,
      calendarDate: _day,
      atTime: at,
    );
    if (lastPage < bounds.lowerBound) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'For this date, last page must be at least ${bounds.lowerBound} '
            '(logs before this point on the timeline).',
          ),
        ),
      );
      return;
    }
    final ub = bounds.upperBound;
    if (ub != null && lastPage > ub) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'For this date, last page must be at most $ub '
            '(a later log for this book already reached that page).',
          ),
        ),
      );
      return;
    }
    final books = await db.allBooks();
    final book = books.firstWhere((b) => b.id == bid);
    final cap = book.totalPages;
    if (cap != null && cap > 0 && lastPage > cap) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('That exceeds this book’s length ($cap pages).'),
        ),
      );
      return;
    }
    final before = await db.maxLastPageReadForBook(bid);
    try {
      await db.insertEntry(
        bookId: bid,
        calendarDate: _day,
        lastPageRead: lastPage,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        createdAt: at,
      );
    } on ArgumentError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? '$e')));
      return;
    }
    final after = await db.maxLastPageReadForBook(bid);
    ref.read(readingDataTickProvider.notifier).state++;

    var bookNow = book;
    if (_markFinished && !book.isMarkedFinished) {
      bookNow = book.copyWith(finishedAt: at);
      await db.updateBook(bookNow);
      ref.read(readingDataTickProvider.notifier).state++;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved')));

    final showFinishSheet =
        (_markFinished && !book.isMarkedFinished) ||
        (!_markFinished &&
            book.totalPages != null &&
            book.totalPages! > 0 &&
            !book.isMarkedFinished &&
            before < book.totalPages! &&
            after >= book.totalPages!);

    if (showFinishSheet) {
      await _showFinishSheet(context, ref, bookNow, lastPage);
    }
    if (context.mounted) context.go('/');
  }

  Future<void> _showFinishSheet(
    BuildContext context,
    WidgetRef ref,
    Book book,
    int pageReached,
  ) async {
    final reviewCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 56,
                color: Theme.of(ctx).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Congratulations!',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You finished “${book.title}” (logged through page $pageReached).',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewCtrl,
                decoration: const InputDecoration(
                  labelText: 'One-line review (optional)',
                  hintText: 'What did you think?',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final note = reviewCtrl.text.trim();
                  if (note.isNotEmpty) {
                    await ref.read(databaseProvider).updateBook(
                          book.copyWith(completionNote: note),
                        );
                    ref.read(readingDataTickProvider.notifier).state++;
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save review'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done without note'),
              ),
            ],
          ),
        );
      },
    );
    reviewCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Log reading')),
      body: books.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add a book before logging.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _openAddBookSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('Add new book'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/books'),
                      child: const Text('Open Books shelf'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Reading date',
                  helperText:
                      'Pick a past day if you forgot to log (e.g. after midnight).',
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(_day),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final today = _dateOnly(DateTime.now());
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _day.isAfter(today) ? today : _day,
                          firstDate: DateTime(2020),
                          lastDate: today,
                        );
                        if (picked != null) {
                          setState(() => _day = _dateOnly(picked));
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value:
                    _bookId != null && list.any((b) => b.id == _bookId)
                        ? _bookId
                        : null,
                decoration: const InputDecoration(labelText: 'Book'),
                items:
                    list
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(b.title),
                          ),
                        )
                        .toList(),
                onChanged:
                    (v) => setState(() {
                      _bookId = v;
                      _markFinished = false;
                    }),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _openAddBookSheet,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add new book'),
                ),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  Book? sel;
                  for (final x in list) {
                    if (x.id == _bookId) {
                      sel = x;
                      break;
                    }
                  }
                  final bl = sel?.startingLastPageRead;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _lastPageCtrl,
                        decoration: InputDecoration(
                          labelText: 'Last page you read',
                          hintText: 'e.g. 280',
                          helperText:
                              bl != null
                                  ? 'You set prior progress through page $bl — '
                                        'enter at least ${bl + 1} unless a timeline '
                                        'log requires more. Must fit earlier/later '
                                        'logs for this book.'
                                  : 'Page you stopped on. For a past day, it must '
                                        'fit between earlier and later logs for this '
                                        'book on the timeline.',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      if (sel != null) ...[
                        const SizedBox(height: 12),
                        if (sel.totalPages != null && sel.totalPages! > 0)
                          Text(
                            'Listed length: ${sel.totalPages} pages',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        if (sel.isMarkedFinished)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('Already marked finished'),
                          )
                        else
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _markFinished,
                            onChanged:
                                (v) => setState(() => _markFinished = v ?? false),
                            title: const Text('I’ve finished reading this book'),
                          ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              ExpansionTile(
                title: const Text('Optional note'),
                initiallyExpanded: _showNote,
                onExpansionChanged: (v) => setState(() => _showNote = v),
                children: [
                  TextField(
                    controller: _noteCtrl,
                    minLines: 2,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'How it felt…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _save(context),
                child: const Text('Save'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
