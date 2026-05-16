import 'package:flutter_test/flutter_test.dart';

import 'package:booklog/features/books/data/book_catalog_api.dart';

void main() {
  test('parseCatalogTotalPagesResponse', () {
    expect(parseCatalogTotalPagesResponse('{"total_pages":320}'), 320);
    expect(parseCatalogTotalPagesResponse('{"total_pages":null}'), isNull);
  });
}
