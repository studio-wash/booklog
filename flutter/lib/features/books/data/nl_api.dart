import 'package:http/http.dart' as http;

// Spec FR-7 — NL library search (stub until base URL / contract is wired).
// Enable with: flutter run --dart-define=NL_API_BASE=https://example.invalid

/// `true` when `--dart-define=NL_API_BASE=...` is a non-empty string.
bool get nlSearchEnabled {
  const base = String.fromEnvironment('NL_API_BASE', defaultValue: '');
  return base.trim().isNotEmpty;
}

/// Placeholder search. Returns empty until real API mapping exists.
Future<List<String>> nlSearchTitles(String query) async {
  if (!nlSearchEnabled) return [];
  const base = String.fromEnvironment('NL_API_BASE');
  try {
    final uri = Uri.parse(base).replace(queryParameters: {'q': query});
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    // TODO: parse NL JSON when schema is known.
    return [];
  } catch (_) {
    return [];
  }
}
