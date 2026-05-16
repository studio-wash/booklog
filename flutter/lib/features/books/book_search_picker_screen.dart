import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_database.dart';
import 'add_book_form_args.dart';
import 'book_search_thumb.dart';
import 'data/book_catalog_api.dart';
import 'data/book_search_api.dart';
import 'data/book_search_hit.dart';

/// Naver search + pick only (PLAN-000008). Page count loads before opening form.
class BookSearchPickerScreen extends StatefulWidget {
  const BookSearchPickerScreen({super.key});

  @override
  State<BookSearchPickerScreen> createState() => _BookSearchPickerScreenState();
}

class _BookSearchPickerScreenState extends State<BookSearchPickerScreen> {
  final _searchCtrl = TextEditingController();
  List<BookSearchHit> _hits = [];
  bool _searching = false;
  bool _loadingPick = false;
  String? _hint;
  bool _ranOnce = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _hint = 'Type a title or keyword.';
        _hits = [];
        _ranOnce = true;
      });
      return;
    }
    setState(() {
      _searching = true;
      _hint = null;
    });
    final r = await searchNaverOnly(q);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _ranOnce = true;
      _hits = r.hits;
      _hint = r.hint ?? (r.hits.isEmpty ? 'No books found.' : null);
    });
  }

  Future<void> _openForm({BookSearchHit? hit}) async {
    if (hit == null) {
      final book = await context.push<Book>('/books/add/form');
      if (!mounted) return;
      context.pop(book);
      return;
    }

    setState(() => _loadingPick = true);
    final pages = await fetchCatalogTotalPages(hit);
    if (!mounted) return;
    setState(() => _loadingPick = false);

    final book = await context.push<Book>(
      '/books/add/form',
      extra: AddBookFormArgs(hit: hit, totalPages: pages),
    );
    if (!mounted) return;
    context.pop(book);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find book'),
        actions: [
          TextButton(
            onPressed: _loadingPick ? null : () => _openForm(),
            child: const Text('Enter manually'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  enabled: !_loadingPick,
                  decoration: const InputDecoration(
                    labelText: 'Search by title or keyword',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    if (!_searching && !_loadingPick) _runSearch();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton.tonalIcon(
                  onPressed: (_searching || _loadingPick) ? null : _runSearch,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ),
              if (!bookSearchEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Set API_BASE_URL to enable search.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Expanded(child: _buildResults(theme)),
            ],
          ),
          if (_loadingPick)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Looking up page count…'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _ranOnce
                ? (_hint ??
                      'No results. Try another keyword or enter manually.')
                : 'Search Naver book catalog.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      itemCount: _hits.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final h = _hits[i];
        return ListTile(
          enabled: !_loadingPick,
          leading: SizedBox(
            width: 48,
            height: 56,
            child: bookSearchThumb(h.imageUrl, theme),
          ),
          title: Text(
            h.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              if (h.author != null && h.author!.isNotEmpty) h.author!,
              if (h.publisher != null && h.publisher!.isNotEmpty) h.publisher!,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _openForm(hit: h),
        );
      },
    );
  }
}
