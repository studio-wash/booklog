import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import '../../providers.dart';

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
  final _pagesCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _showNote = false;
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

  @override
  void dispose() {
    _pagesCtrl.dispose();
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
    final pages = int.tryParse(_pagesCtrl.text.trim());
    if (pages == null || pages <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter pages read (positive number)')),
      );
      return;
    }
    final db = ref.read(databaseProvider);
    final before = await db.totalPagesReadForBook(bid);
    final books = await db.allBooks();
    final book = books.firstWhere((b) => b.id == bid);
    await db.insertEntry(
      bookId: bid,
      calendarDate: _day,
      pages: pages,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    final after = await db.totalPagesReadForBook(bid);
    ref.read(readingDataTickProvider.notifier).state++;
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved')));
    if (book.totalPages != null &&
        before < book.totalPages! &&
        after >= book.totalPages!) {
      await _showFinishSheet(context, ref, book, after);
    }
    if (context.mounted) context.go('/');
  }

  Future<void> _showFinishSheet(
    BuildContext context,
    WidgetRef ref,
    Book book,
    int totalRead,
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
              Text(
                'Finished “${book.title}” 🎉',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Total logged: $totalRead pages'),
              const SizedBox(height: 12),
              TextField(
                controller: reviewCtrl,
                decoration: const InputDecoration(
                  labelText: 'One-line review (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final note = reviewCtrl.text.trim();
                        await ref
                            .read(databaseProvider)
                            .updateBook(
                              Book(
                                id: book.id,
                                title: book.title,
                                totalPages: book.totalPages,
                                completionNote:
                                    note.isEmpty ? book.completionNote : note,
                                createdAt: book.createdAt,
                              ),
                            );
                        ref.read(readingDataTickProvider.notifier).state++;
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save note'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add a book first.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.push('/books'),
                    child: const Text('Open books'),
                  ),
                ],
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
                onChanged: (v) => setState(() => _bookId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pagesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pages read',
                  hintText: 'Required',
                ),
                keyboardType: TextInputType.number,
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
