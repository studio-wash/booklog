/// One row from Naver book search JSON (`items[]`).
///
/// Spec FR-7 / PLAN-000003 — see `knowledge/reference/api/naver-book-search.md`.
/// Price-related fields (`discount`, etc.) are intentionally not parsed.
class BookSearchHit {
  const BookSearchHit({
    required this.title,
    required this.isbn,
    required this.imageUrl,
    this.link,
    this.author,
    this.publisher,
    this.description,
    this.pubdate,
    this.totalPages,
  });

  final String title;

  /// Raw value from API (often `10digit 13digit` in one string).
  final String isbn;
  final String imageUrl;
  final String? link;
  final String? author;
  final String? publisher;
  final String? description;
  final String? pubdate;

  /// From api-server catalog / Aladin enrich (`total_pages` in search JSON).
  final int? totalPages;

  static String _stripHtml(String s) => s.replaceAll(RegExp(r'<[^>]*>'), '');

  static int? _totalPagesField(dynamic v) {
    if (v == null) return null;
    if (v is int && v > 0) return v;
    if (v is num && v > 0) return v.round();
    if (v is String) {
      final n = int.tryParse(v.trim());
      if (n != null && n > 0) return n;
    }
    return null;
  }

  static String? _stringField(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _isbnField(dynamic v) {
    if (v == null) return '';
    if (v is String) return v.trim();
    return v.toString().trim();
  }

  /// Returns null if [json] has no usable title or **empty ISBN** (required for shelf rows).
  static BookSearchHit? tryParse(Map<String, dynamic> json) {
    final rawTitle = json['title'];
    if (rawTitle is! String || rawTitle.trim().isEmpty) return null;
    final title = _stripHtml(rawTitle).trim();
    if (title.isEmpty) return null;

    final isbn = _isbnField(json['isbn']);
    if (isbn.isEmpty) return null;

    final rawDesc = json['description'];
    final description =
        rawDesc is String && rawDesc.trim().isNotEmpty
            ? _stripHtml(rawDesc).trim()
            : _stringField(rawDesc);

    final imageUrl = _stringField(json['image']) ?? '';

    return BookSearchHit(
      title: title,
      isbn: isbn,
      imageUrl: imageUrl,
      link: _stringField(json['link']),
      author: _stringField(json['author']),
      publisher: _stringField(json['publisher']),
      description: description,
      pubdate: _stringField(json['pubdate']),
      totalPages: _totalPagesField(json['total_pages']),
    );
  }
}
