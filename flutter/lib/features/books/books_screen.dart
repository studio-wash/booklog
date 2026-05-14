import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  late final TextEditingController _searchCtrl;

  List<BookSearchHit> _hits = [];
  bool _searching = false;
  int _selectedIndex = -1;
  String? _inlineHint;
  bool _ranSearchAtLeastOnce = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _pagesCtrl = TextEditingController();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _pagesCtrl.dispose();
    _searchCtrl.dispose();
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
      _titleCtrl.clear();
      _inlineHint = r.hint ?? (r.hits.isEmpty ? 'No books found.' : null);
    });
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
        delegate: SliverChildBuilderDelegate(
          (context, i) {
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
                      child: h.imageUrl != null && h.imageUrl!.isNotEmpty
                          ? Image.network(
                              h.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
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
                  subtitle: Text(
                    [
                      if (h.author != null && h.author!.isNotEmpty) h.author!,
                      if (h.publisher != null && h.publisher!.isNotEmpty)
                        h.publisher!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedIndex = i;
                      _titleCtrl.text = h.title;
                    });
                  },
                ),
              ],
            );
          },
          childCount: _hits.length,
        ),
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
                        decoration: const InputDecoration(
                          labelText: 'Total pages (optional)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 4),
                      ExpansionTile(
                        initiallyExpanded: !bookSearchEnabled,
                        title: const Text('Manual entry'),
                        children: [
                          TextField(
                            controller: _titleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () async {
                          final t = _titleCtrl.text.trim();
                          if (t.isEmpty) return;
                          final tp = int.tryParse(_pagesCtrl.text.trim());
                          await ref
                              .read(databaseProvider)
                              .insertBook(title: t, totalPages: tp);
                          ref.read(readingDataTickProvider.notifier).state++;
                          if (!mounted) return;
                          // Avoid InkWell / MediaQuery lookups on deactivated subtree
                          // when the route pops (focus highlight mode can still notify).
                          FocusManager.instance.primaryFocus?.unfocus();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            Navigator.of(context).pop();
                          });
                        },
                        child: const Text('Save'),
                      ),
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
    await showModalBottomSheet<void>(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const _AddBookSheetBody(),
            ),
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
    ).whenComplete(() {
      titleCtrl.dispose();
      pagesCtrl.dispose();
    });
  }
}
