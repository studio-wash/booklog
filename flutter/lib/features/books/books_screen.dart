import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/booklog_ui.dart';
import '../../data/app_database.dart';
import '../../providers.dart';
import 'data/book_search_api.dart';
import 'data/book_search_hit.dart';

Widget _bookSearchThumbPlaceholder(ThemeData theme) {
  return ColoredBox(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Center(
      child: Icon(
        Icons.menu_book_outlined,
        color: theme.colorScheme.onSurfaceVariant,
        size: 28,
      ),
    ),
  );
}

Widget _shelfThumb(Book b, ThemeData theme) {
  if (b.imageUrl.trim().isEmpty) {
    return _bookSearchThumbPlaceholder(theme);
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: Image.network(
      b.imageUrl,
      width: 48,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _bookSearchThumbPlaceholder(theme),
    ),
  );
}

/// New book flow: search-first sheet (PLAN-000003). Controllers live in [State] so
/// async search cannot run [setState] after [dispose] (e.g. sheet closed or hot restart).
class _AddBookSheetBody extends ConsumerStatefulWidget {
  const _AddBookSheetBody();

  @override
  ConsumerState<_AddBookSheetBody> createState() => _AddBookSheetBodyState();
}

class _AddBookSheetBodyState extends ConsumerState<_AddBookSheetBody> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _pagesCtrl;
  late final TextEditingController _baselineCtrl;
  late final TextEditingController _searchCtrl;
  late final TextEditingController _isbnCtrl;
  late final TextEditingController _imageUrlCtrl;

  List<BookSearchHit> _hits = [];
  bool _searching = false;
  int _selectedIndex = -1;
  String? _inlineHint;
  bool _ranSearchAtLeastOnce = false;
  bool _suppressSelectionSync = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _pagesCtrl = TextEditingController();
    _baselineCtrl = TextEditingController();
    _searchCtrl = TextEditingController();
    _isbnCtrl = TextEditingController();
    _imageUrlCtrl = TextEditingController();
    _titleCtrl.addListener(_syncSelectionClear);
    _isbnCtrl.addListener(_syncSelectionClear);
    _imageUrlCtrl.addListener(_syncSelectionClear);
  }

  void _syncSelectionClear() {
    if (_suppressSelectionSync) return;
    if (_selectedIndex < 0 || _selectedIndex >= _hits.length) return;
    final h = _hits[_selectedIndex];
    if (_titleCtrl.text != h.title ||
        _isbnCtrl.text != h.isbn ||
        _imageUrlCtrl.text != h.imageUrl) {
      setState(() => _selectedIndex = -1);
    }
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_syncSelectionClear);
    _isbnCtrl.removeListener(_syncSelectionClear);
    _imageUrlCtrl.removeListener(_syncSelectionClear);
    _titleCtrl.dispose();
    _pagesCtrl.dispose();
    _baselineCtrl.dispose();
    _searchCtrl.dispose();
    _isbnCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _inlineHint = 'Type a title or keyword to search.';
        _hits = [];
        _ranSearchAtLeastOnce = true;
        _selectedIndex = -1;
      });
      return;
    }
    setState(() {
      _searching = true;
      _inlineHint = null;
    });
    final r = await searchBookHits(q);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _ranSearchAtLeastOnce = true;
      _hits = r.hits;
      _selectedIndex = -1;
      _suppressSelectionSync = true;
      _titleCtrl.clear();
      _isbnCtrl.clear();
      _imageUrlCtrl.clear();
      _suppressSelectionSync = false;
      _inlineHint = r.hint ?? (r.hits.isEmpty ? 'No books found.' : null);
    });
  }

  Future<void> _save() async {
    final db = ref.read(databaseProvider);
    final tp = int.tryParse(_pagesCtrl.text.trim());

    late final String title;
    late final String isbn;
    late final String imageUrl;
    String? link;
    String? author;
    String? publisher;
    String? pubdate;

    if (_selectedIndex >= 0 && _selectedIndex < _hits.length) {
      final h = _hits[_selectedIndex];
      title = h.title;
      isbn = h.isbn;
      imageUrl = h.imageUrl;
      link = h.link;
      author = h.author;
      publisher = h.publisher;
      pubdate = h.pubdate;
    } else {
      title = _titleCtrl.text.trim();
      isbn = _isbnCtrl.text.trim();
      imageUrl = _imageUrlCtrl.text.trim();
      if (title.isEmpty || isbn.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title and ISBN are required.')),
        );
        return;
      }
    }

    final dup = await db.bookByIsbn(isbn);
    if (dup != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Already in shelf: ${dup.title}')));
      return;
    }

    int? startingBaseline;
    final baselineRaw = _baselineCtrl.text.trim();
    if (baselineRaw.isNotEmpty) {
      final bl = int.tryParse(baselineRaw);
      if (bl == null || bl < 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '“Already read up to page” must be empty or a whole number ≥ 0.',
            ),
          ),
        );
        return;
      }
      if (tp != null && tp > 0 && bl >= tp) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Prior last page must be less than total pages when both are set.',
            ),
          ),
        );
        return;
      }
      startingBaseline = bl;
    }

    final book = await db.insertBook(
      title: title,
      isbn: isbn,
      imageUrl: imageUrl,
      link: link,
      author: author,
      publisher: publisher,
      pubdate: pubdate,
      totalPages: tp,
      startingLastPageRead: startingBaseline,
    );
    ref.read(readingDataTickProvider.notifier).state++;
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(book);
  }

  List<Widget> _resultSlivers(ThemeData theme) {
    if (!bookSearchEnabled) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Search is unavailable. Use manual entry below.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ];
    }
    if (_searching) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ];
    }
    if (_hits.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _ranSearchAtLeastOnce
                    ? (_inlineHint ??
                        'No results. Try another keyword or manual entry.')
                    : 'Enter a keyword and tap Search.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ];
    }
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate((context, i) {
          final h = _hits[i];
          final sel = _selectedIndex == i;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (i > 0)
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
              ListTile(
                selected: sel,
                selectedTileColor: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.35),
                leading: SizedBox(
                  width: 48,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child:
                        h.imageUrl.isNotEmpty
                            ? Image.network(
                              h.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      _bookSearchThumbPlaceholder(theme),
                            )
                            : _bookSearchThumbPlaceholder(theme),
                  ),
                ),
                title: Text(
                  h.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        if (h.author != null && h.author!.isNotEmpty) h.author!,
                        if (h.publisher != null && h.publisher!.isNotEmpty)
                          h.publisher!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (h.totalPages != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${h.totalPages} pages',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  _suppressSelectionSync = true;
                  _titleCtrl.text = h.title;
                  _isbnCtrl.text = h.isbn;
                  _imageUrlCtrl.text = h.imageUrl;
                  _pagesCtrl.text =
                      h.totalPages != null ? '${h.totalPages}' : '';
                  _suppressSelectionSync = false;
                  setState(() => _selectedIndex = i);
                },
              ),
            ],
          );
        }, childCount: _hits.length),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('New book', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (bookSearchEnabled) ...[
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Search by title or keyword',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              if (!_searching) _runSearch();
            },
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.search),
            label: const Text('Search'),
            onPressed: _searching ? null : _runSearch,
          ),
        ] else ...[
          Text(
            'Set API_BASE_URL on the server / app to enable search.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              ..._resultSlivers(theme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _pagesCtrl,
                        decoration: InputDecoration(
                          labelText: 'Total pages (optional)',
                          helperText:
                              _selectedIndex >= 0 &&
                                      _hits[_selectedIndex].totalPages != null
                                  ? 'Filled from catalog (Aladin Open API). You can change it.'
                                  : null,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _baselineCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Already read up to page (optional)',
                          helperText:
                              'If you were on e.g. page 99 before adding here, '
                              'enter 99 so the next log counts from 100.',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 4),
                      ExpansionTile(
                        initiallyExpanded: !bookSearchEnabled,
                        title: const Text('Manual entry'),
                        subtitle: Text(
                          _selectedIndex >= 0
                              ? 'A search result is selected — Save uses it.'
                              : 'Title + ISBN required. Cover URL optional.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        children: [
                          TextField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _isbnCtrl,
                            decoration: const InputDecoration(
                              labelText: 'ISBN (required)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _imageUrlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Cover image URL (optional)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton(onPressed: _save, child: const Text('Save')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Search-first new book sheet (PLAN-000003). Returns saved [Book] or null if dismissed.
Future<Book?> showAddBookSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<Book?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return AnimatedPadding(
        duration: Duration.zero,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.88,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _AddBookSheetBody(),
          ),
        ),
      );
    },
  );
}

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
            onPressed: () => showAddBookSheet(context, ref),
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
                        child: _shelfThumb(b, theme),
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
