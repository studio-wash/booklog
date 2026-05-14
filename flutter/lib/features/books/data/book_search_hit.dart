/// One row from Naver book search JSON (`items[]`).
///
/// Spec FR-7 / PLAN-000003 — see `knowledge/reference/api/naver-book-search.md`.
class BookSearchHit {
  const BookSearchHit({
    required this.title,
    this.imageUrl,
    this.author,
    this.publisher,
  });

  final String title;
  final String? imageUrl;
  final String? author;
  final String? publisher;

  static String _stripHtml(String s) => s.replaceAll(RegExp(r'<[^>]*>'), '');

  static String? _stringField(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Returns null if [json] has no usable title.
  static BookSearchHit? tryParse(Map<String, dynamic> json) {
    final rawTitle = json['title'];
    if (rawTitle is! String || rawTitle.trim().isEmpty) return null;
    final title = _stripHtml(rawTitle).trim();
    if (title.isEmpty) return null;
    return BookSearchHit(
      title: title,
      imageUrl: _stringField(json['image']),
      author: _stringField(json['author']),
      publisher: _stringField(json['publisher']),
    );
  }
}
