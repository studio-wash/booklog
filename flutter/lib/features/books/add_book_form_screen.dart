import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import 'book_search_thumb.dart';
import 'data/book_search_hit.dart';

/// Add book form after search pick or manual entry (PLAN-000008).
class AddBookFormScreen extends ConsumerStatefulWidget {
  const AddBookFormScreen({super.key, this.hit, this.initialTotalPages});

  /// From search pick (read-only meta on screen).
  final BookSearchHit? hit;

  /// Page count resolved on picker before navigation.
  final int? initialTotalPages;

  @override
  ConsumerState<AddBookFormScreen> createState() => _AddBookFormScreenState();
}

class _AddBookFormScreenState extends ConsumerState<AddBookFormScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _isbnCtrl;
  late final TextEditingController _pagesCtrl;
  late final TextEditingController _baselineCtrl;

  @override
  void initState() {
    super.initState();
    final h = widget.hit;
    _titleCtrl = TextEditingController(text: h?.title ?? '');
    _isbnCtrl = TextEditingController(text: h?.isbn ?? '');
    _pagesCtrl = TextEditingController(
      text: widget.initialTotalPages != null
          ? '${widget.initialTotalPages}'
          : '',
    );
    _baselineCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _isbnCtrl.dispose();
    _pagesCtrl.dispose();
    _baselineCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final h = widget.hit;
    final title = (h?.title ?? _titleCtrl.text).trim();
    final isbn = (h?.isbn ?? _isbnCtrl.text).trim();
    final imageUrl = h?.imageUrl ?? '';

    if (title.isEmpty || isbn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and ISBN are required.')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final dup = await db.bookByIsbn(isbn);
    if (dup != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Already in shelf: ${dup.title}')),
      );
      return;
    }

    final tp = int.tryParse(_pagesCtrl.text.trim());
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
      link: h?.link,
      author: h?.author,
      publisher: h?.publisher,
      pubdate: h?.pubdate,
      totalPages: tp,
      startingLastPageRead: startingBaseline,
    );
    ref.read(readingDataTickProvider.notifier).state++;
    if (!mounted) return;
    context.pop(book);
  }

  Widget _pickedBookHeader(ThemeData theme, BookSearchHit h) {
    final meta = [
      if (h.author != null && h.author!.isNotEmpty) h.author!,
      if (h.publisher != null && h.publisher!.isNotEmpty) h.publisher!,
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              height: 72,
              child: bookSearchThumb(h.imageUrl, theme),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    h.isbn,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hit;
    final fromSearch = h != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(fromSearch ? 'Add book' : 'Add book manually'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (fromSearch) ...[
              _pickedBookHeader(theme, h),
              const SizedBox(height: 16),
            ] else ...[
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _isbnCtrl,
                decoration: const InputDecoration(
                  labelText: 'ISBN',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _pagesCtrl,
              decoration: InputDecoration(
                labelText: 'Total pages (optional)',
                helperText: fromSearch && widget.initialTotalPages != null
                    ? 'Filled from catalog. You can change it.'
                    : fromSearch
                    ? 'Could not load from catalog — enter if you know it.'
                    : null,
                border: const OutlineInputBorder(),
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
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
