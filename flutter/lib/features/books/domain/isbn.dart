// PLAN-000007 — same rules as api-server/lib/isbn.ts (catalog PK isbn13).

final _isbn10Last = RegExp(r'^[0-9]{9}[0-9X]$', caseSensitive: false);

String _digitsOnly(String s) =>
    s.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();

/// Naver `isbn` field → optional 10- and 13-digit parts.
({String? isbn10, String? isbn13}) parseIsbnCandidates(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return (isbn10: null, isbn13: null);

  String? isbn10;
  String? isbn13;
  for (final token in trimmed.split(RegExp(r'\s+'))) {
    final d = _digitsOnly(token);
    if (d.length == 13) {
      isbn13 = d;
    } else if (d.length == 10 && _isbn10Last.hasMatch(d)) {
      isbn10 = d;
    }
  }

  if (isbn10 == null && isbn13 == null) {
    final all = _digitsOnly(trimmed);
    if (all.length == 13) {
      isbn13 = all;
    } else if (all.length == 10 && _isbn10Last.hasMatch(all)) {
      isbn10 = all;
    }
  }

  return (isbn10: isbn10, isbn13: isbn13);
}

/// ISBN-10 (no hyphens) → ISBN-13 with 978 prefix.
String? isbn10ToIsbn13(String isbn10) {
  final body = _digitsOnly(isbn10);
  if (!_isbn10Last.hasMatch(body)) return null;
  final core = body.substring(0, 9);
  final withoutCheck = '978$core';
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final n = int.parse(withoutCheck[i]);
    sum += n * (i.isEven ? 1 : 3);
  }
  final check = (10 - (sum % 10)) % 10;
  return '$withoutCheck$check';
}

/// Catalog-style primary key; null when unusable.
String? normalizeIsbn13(String raw) {
  final c = parseIsbnCandidates(raw);
  if (c.isbn13 != null && c.isbn13!.length == 13) return c.isbn13;
  if (c.isbn10 != null) return isbn10ToIsbn13(c.isbn10!);
  final all = _digitsOnly(raw);
  if (all.length == 13) return all;
  if (all.length == 10) return isbn10ToIsbn13(all);
  return null;
}
