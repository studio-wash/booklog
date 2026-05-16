import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/booklog_ui.dart';
import '../../data/app_database.dart';
import '../../providers.dart';
import 'add_book_flow.dart';
import 'book_search_thumb.dart';

/// Shelf: list / add / edit / delete books (Spec FR-1).
class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);
    final shellBottom =
        MediaQuery.paddingOf(context).bottom + 56 + 32;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        actions: [
          IconButton(
            onPressed: () => pushAddBookFlow(context),
            icon: const Icon(Icons.add),
            tooltip: 'Add book',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: shellBottom),
        child: books.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: BooklogCard(
                  child: Text(
                    'Tap + above to add a book, then log from Home.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final b = list[i];
              final theme = Theme.of(context);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BooklogCard(
                  onTap: () => _editBook(context, ref, b),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 64,
                        child: b.imageUrl.trim().isEmpty
                            ? bookSearchThumbPlaceholder(theme)
                            : bookSearchThumb(b.imageUrl, theme),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (b.author != null && b.author!.isNotEmpty)
                                  b.author!,
                                if (b.totalPages != null)
                                  '${b.totalPages} pages',
                              ].where((s) => s.isNotEmpty).join(' · '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref.read(databaseProvider).deleteBook(b.id);
                          ref.read(readingDataTickProvider.notifier).state++;
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        ),
      ),
    );
  }

  Future<void> _editBook(BuildContext context, WidgetRef ref, Book b) async {
    final db = ref.read(databaseProvider);
    final entryCount = await db.readingEntryCountForBook(b.id);
    final canEditBaseline = entryCount == 0;

    final titleCtrl = TextEditingController(text: b.title);
    final isbnCtrl = TextEditingController(text: b.isbn);
    final imageUrlCtrl = TextEditingController(text: b.imageUrl);
    final linkCtrl = TextEditingController(text: b.link ?? '');
    final authorCtrl = TextEditingController(text: b.author ?? '');
    final publisherCtrl = TextEditingController(text: b.publisher ?? '');
    final pubdateCtrl = TextEditingController(text: b.pubdate ?? '');
    final pagesCtrl = TextEditingController(
      text: b.totalPages?.toString() ?? '',
    );
    final baselineCtrl = TextEditingController(
      text: b.startingLastPageRead?.toString() ?? '',
    );
    if (!context.mounted) return;
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
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit book', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: isbnCtrl,
                          decoration: const InputDecoration(
                            labelText: 'ISBN',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: imageUrlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cover image URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: linkCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Naver book link (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: authorCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Author',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: publisherCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Publisher',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: pubdateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Pub. date (API string)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: pagesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Total pages',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: baselineCtrl,
                          readOnly: !canEditBaseline,
                          decoration: InputDecoration(
                            labelText: 'Already read up to page (optional)',
                            helperText: canEditBaseline
                                ? 'Set before your first log. Locked after logs exist.'
                                : 'Locked: change is disabled once reading logs exist.',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    final t = titleCtrl.text.trim();
                    final isbn = isbnCtrl.text.trim();
                    if (t.isEmpty || isbn.isEmpty) return;
                    final img = imageUrlCtrl.text.trim();
                    final tp = int.tryParse(pagesCtrl.text.trim());

                    String? emptyToNull(String s) {
                      final v = s.trim();
                      return v.isEmpty ? null : v;
                    }

                    final dbSave = ref.read(databaseProvider);
                    final other = await dbSave.bookByIsbn(isbn);
                    if (other != null && other.id != b.id) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              'ISBN already used by: ${other.title}',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    int? startingBaseline = b.startingLastPageRead;
                    if (canEditBaseline) {
                      final br = baselineCtrl.text.trim();
                      if (br.isEmpty) {
                        startingBaseline = null;
                      } else {
                        final bl = int.tryParse(br);
                        if (bl == null || bl < 0) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Prior last page must be empty or a whole number ≥ 0.',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        if (tp != null && tp > 0 && bl >= tp) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Prior last page must be less than total pages.',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        startingBaseline = bl;
                      }
                    }

                    await ref.read(databaseProvider).updateBook(
                          Book(
                            id: b.id,
                            title: t,
                            isbn: isbn,
                            imageUrl: img,
                            link: emptyToNull(linkCtrl.text),
                            author: emptyToNull(authorCtrl.text),
                            publisher: emptyToNull(publisherCtrl.text),
                            description: null,
                            pubdate: emptyToNull(pubdateCtrl.text),
                            totalPages: tp,
                            completionNote: b.completionNote,
                            startingLastPageRead: startingBaseline,
                            finishedAt: b.finishedAt,
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
          ),
        );
      },
    ).whenComplete(() {
      titleCtrl.dispose();
      isbnCtrl.dispose();
      imageUrlCtrl.dispose();
      linkCtrl.dispose();
      authorCtrl.dispose();
      publisherCtrl.dispose();
      pubdateCtrl.dispose();
      pagesCtrl.dispose();
      baselineCtrl.dispose();
    });
  }
}
