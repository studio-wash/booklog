import 'data/book_search_hit.dart';

/// Arguments for [AddBookFormScreen] after search pick (PLAN-000008).
class AddBookFormArgs {
  const AddBookFormArgs({required this.hit, this.totalPages});

  final BookSearchHit hit;
  final int? totalPages;
}
