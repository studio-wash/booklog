import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';
import 'book_search_hit.dart';

// Spec FR-7 / PLAN-000008 — catalog page count after add-book form opens.

const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kApiBaseUrlDefault,
);

Uri _catalogPagesUri() {
  final base = _apiBaseUrl.trim();
  final root = base.endsWith('/') ? base : '$base/';
  return Uri.parse(root).resolve('api/books/catalog/pages');
}

/// POST catalog/pages — upsert meta + read/Aladin enrich for total pages.
Future<int?> fetchCatalogTotalPages(BookSearchHit hit) async {
  if (_apiBaseUrl.trim().isEmpty) return null;
  try {
    final res = await http.post(
      _catalogPagesUri(),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'isbn': hit.isbn,
        'title': hit.title,
        'image': hit.imageUrl,
        'author': hit.author,
        'publisher': hit.publisher,
        'pubdate': hit.pubdate,
        'link': hit.link,
      }),
    );
    if (res.statusCode != 200) return null;
    return parseCatalogTotalPagesResponse(res.body);
  } catch (_) {
    return null;
  }
}

/// Parses [total_pages] from catalog/pages JSON (for tests).
int? parseCatalogTotalPagesResponse(String body) {
  try {
    final map = jsonDecode(body);
    if (map is! Map<String, dynamic>) return null;
    final v = map['total_pages'];
    if (v is int && v > 0) return v;
    if (v is num && v > 0) return v.round();
  } catch (_) {}
  return null;
}
