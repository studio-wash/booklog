import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../providers.dart';
import 'data/book_search_api.dart';

/// Shelf: list / add / edit / delete books (Spec FR-1).
class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Books')),
      body: books.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Add a book with + to start logging.'),
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final b = list[i];
              return ListTile(
                title: Text(b.title),
                subtitle: Text(
                  b.totalPages != null ? '${b.totalPages} pages' : 'Pages: —',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref.read(databaseProvider).deleteBook(b.id);
                    ref.read(readingDataTickProvider.notifier).state++;
                  },
                ),
                onTap: () => _editBook(context, ref, b),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addBook(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addBook(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final pagesCtrl = TextEditingController();
    final searchCtrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        String? searchFeedback;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx2, setModalState) {
              final theme = Theme.of(ctx2);
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Text('New book', style: theme.textTheme.titleMedium),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                    autofocus: true,
                  ),
                  TextField(
                    controller: pagesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Total pages (optional)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (bookSearchEnabled) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Book search (Naver via API)',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final q = searchCtrl.text.trim();
                        if (q.isEmpty) {
                          setModalState(() {
                            searchFeedback =
                                'Type a title or keyword to search.';
                          });
                          return;
                        }
                        final r = await searchBookTitles(q);
                        if (!ctx2.mounted) return;
                        final msg = r.titles.isNotEmpty
                            ? 'Found ${r.titles.length}: ${r.titles.take(3).join(' · ')}'
                            : (r.hint ?? 'No books found for that query.');
                        setModalState(() {
                          searchFeedback = msg;
                        });
                      },
                      child: const Text('Search books'),
                    ),
                    if (searchFeedback != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        searchFeedback!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      final t = titleCtrl.text.trim();
                      if (t.isEmpty) return;
                      final tp = int.tryParse(pagesCtrl.text.trim());
                      await ref
                          .read(databaseProvider)
                          .insertBook(title: t, totalPages: tp);
                      ref.read(readingDataTickProvider.notifier).state++;
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _editBook(BuildContext context, WidgetRef ref, Book b) async {
    final titleCtrl = TextEditingController(text: b.title);
    final pagesCtrl = TextEditingController(
      text: b.totalPages?.toString() ?? '',
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit book', style: Theme.of(ctx).textTheme.titleMedium),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: pagesCtrl,
                decoration: const InputDecoration(labelText: 'Total pages'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final t = titleCtrl.text.trim();
                  if (t.isEmpty) return;
                  final tp = int.tryParse(pagesCtrl.text.trim());
                  await ref
                      .read(databaseProvider)
                      .updateBook(
                        Book(
                          id: b.id,
                          title: t,
                          totalPages: tp,
                          completionNote: b.completionNote,
                          createdAt: b.createdAt,
                        ),
                      );
                  ref.read(readingDataTickProvider.notifier).state++;
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}
