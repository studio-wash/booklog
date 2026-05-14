import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_config.dart';
import 'book_search_hit.dart';

// Spec FR-7 — book search: GET {API_BASE_URL}/api/books/search?q=... (Naver via api-server).

const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kApiBaseUrlDefault,
);

/// On when [API_BASE_URL] resolves to a non-empty string (after trim).
bool get bookSearchEnabled => _apiBaseUrl.trim().isNotEmpty;

/// Parses book search API or Naver error JSON bodies.
String? _parseSearchErrorHint(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;
    final naverMsg = decoded['errorMessage'] as String?;
    final naverCode = decoded['errorCode'] as String?;
    if (naverMsg != null && naverMsg.trim().isNotEmpty) {
      if (naverCode != null && naverCode.isNotEmpty) {
        return '${naverMsg.trim()} (${naverCode.trim()})';
      }
      return naverMsg.trim();
    }
    final ours = decoded['error'] as String?;
    if (ours != null && ours.trim().isNotEmpty) return ours.trim();
  } catch (_) {}
  return null;
}

/// Returns parsed [hits] or an error [hint] when the request fails or shape is wrong.
Future<({List<BookSearchHit> hits, String? hint})> searchBookHits(String query) async {
  if (!bookSearchEnabled) {
    return (
      hits: <BookSearchHit>[],
      hint: 'Book search is off (empty API_BASE_URL).',
    );
  }
  final q = query.trim();
  if (q.isEmpty) {
    return (hits: <BookSearchHit>[], hint: null);
  }
  try {
    final baseUri = Uri.parse(_apiBaseUrl.trim());
    final uri = baseUri.resolve('api/books/search').replace(
      queryParameters: {'q': q, 'display': '10'},
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      final err = _parseSearchErrorHint(res.body);
      return (
        hits: <BookSearchHit>[],
        hint: err ?? 'Search failed (HTTP ${res.statusCode}).',
      );
    }
    final map = jsonDecode(res.body);
    if (map is! Map<String, dynamic>) {
      return (hits: <BookSearchHit>[], hint: 'Unexpected response shape.');
    }
    final items = map['items'];
    if (items is! List<dynamic>) {
      return (hits: <BookSearchHit>[], hint: 'No items in response.');
    }
    final out = <BookSearchHit>[];
    for (final it in items) {
      if (it is! Map<String, dynamic>) continue;
      final hit = BookSearchHit.tryParse(it);
      if (hit != null) out.add(hit);
    }
    return (hits: out, hint: null);
  } catch (_) {
    return (
      hits: <BookSearchHit>[],
      hint: 'Network error — check connection and API_BASE_URL.',
    );
  }
}
