import 'package:flutter_test/flutter_test.dart';

import 'package:booklog/features/books/data/book_search_hit.dart';

void main() {
  test('parses total_pages from search JSON', () {
    final hit = BookSearchHit.tryParse({
      'title': 'Test',
      'isbn': '9788936434267',
      'image': '',
      'total_pages': 280,
    });
    expect(hit, isNotNull);
    expect(hit!.totalPages, 280);
  });

  test('total_pages omitted stays null', () {
    final hit = BookSearchHit.tryParse({
      'title': 'Test',
      'isbn': '9788936434267',
      'image': '',
    });
    expect(hit?.totalPages, isNull);
  });

  test('ignores description in API JSON', () {
    final hit = BookSearchHit.tryParse({
      'title': 'Test',
      'isbn': '9788936434267',
      'image': '',
      'description': 'Long blurb from Naver',
    });
    expect(hit, isNotNull);
  });
}
