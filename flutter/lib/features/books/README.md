# Books (서재)

**마지막 업데이트**: 2026-05-13

## Spec 정보

- **Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md`
- **Plan 파일**: `plan/PLAN-000001_haruhanjang-mvp/plan.md`, `plan/PLAN-000003_add-book-search-first/plan.md`
- **구현 상태**: ✅ 완료

## 코드 위치

- **Flutter UI**: `flutter/lib/features/books/books_screen.dart`
- **책 검색 (FR-7)**: `data/book_search_api.dart` (`searchBookHits`), `data/book_search_hit.dart`, 기본 origin `flutter/lib/core/api_config.dart`

## Spec-Code 매핑

| Spec 요구사항 | 코드 파일 | 상태 | 마지막 업데이트 |
|--------------|-----------|------|----------------|
| FR-1 책 CRUD | `books_screen.dart`, `AppDatabase` (`lib/data/`) | ✅ | 2026-05-12 |
| FR-7 외부 도서 검색·선택 | `book_search_hit.dart`, `book_search_api.dart`, `books_screen.dart` — 검색 우선 시트·썸네일 목록·수동 입력 접기 | ✅ | 2026-05-13 |

## 생성/수정 이력

- 2026-05-12: PLAN-000001 서재 화면·검색 연동
- 2026-05-13: PLAN-000003 검색 우선 새 책 추가·`BookSearchHit`·`searchBookHits`
