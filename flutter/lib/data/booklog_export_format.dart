// Spec: spec/features/booklog-mvp/booklog-mvp.md — FR-11
// Plan: plan/PLAN-000004_dev-db-export-import/plan.md

/// JSON file **format** version (not the same as SQLite `userVersion`).
const int booklogExportFormatVersion = 1;

const int booklogExportFormatMinSupported = 1;
const int booklogExportFormatMaxSupported = 1;

const String kExportKeySchemaVersion = 'export_schema_version';
const String kExportKeyAppSchemaVersion = 'app_schema_version';
const String kExportKeyExportedAt = 'exported_at';
const String kExportKeyBooks = 'books';
const String kExportKeyReadingEntries = 'reading_entries';

/// Example payload for AI / manual edits (field names match SQLite columns).
const String kBooklogExportExampleJson = '''
{
  "export_schema_version": 1,
  "app_schema_version": 2,
  "exported_at": "2026-05-15T12:00:00.000Z",
  "books": [
    {
      "id": 1,
      "title": "Sample book",
      "isbn": "9781234567890",
      "image_url": "",
      "link": null,
      "author": "Author",
      "publisher": "Publisher",
      "description": null,
      "pubdate": "20200101",
      "total_pages": 300,
      "completion_note": null,
      "created_at": 1715769600000
    }
  ],
  "reading_entries": [
    {
      "id": 1,
      "book_id": 1,
      "calendar_date": "2026-05-10",
      "pages": 12,
      "last_page_read": 12,
      "note": null,
      "created_at": 1715769600000
    }
  ]
}
''';

/// Thrown when [AppDatabase.importDatabaseFromJson] rejects the payload.
class BooklogImportException implements Exception {
  const BooklogImportException(this.message);
  final String message;
  @override
  String toString() => 'BooklogImportException: $message';
}
