import 'package:flutter_test/flutter_test.dart';

import 'package:booklog/features/books/data/book_search_hit.dart';

void main() {
  test('parses core fields from search JSON', () {
    final hit = BookSearchHit.tryParse({
      'title': 'Test',
      'isbn': '9788936434267',
      'image': 'https://example/cover.jpg',
      'author': 'Author',
    });
    expect(hit, isNotNull);
    expect(hit!.title, 'Test');
    expect(hit.author, 'Author');
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
