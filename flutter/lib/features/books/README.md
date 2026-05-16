# Books feature

**마지막 업데이트**: 2026-05-15

## Spec 정보
- **Spec**: `spec/features/booklog-mvp/booklog-mvp.md` (FR-1, FR-7, FR-12)
- **Plan**: PLAN-000003, PLAN-000007, **PLAN-000008** (2-step add book)

## 코드 위치
- **Flutter**: `flutter/lib/features/books/`
- **API**: `api-server/app/api/books/`

## Spec-Code 매핑

| Spec | 코드 |
|------|------|
| FR-1 서재 CRUD | `books_screen.dart`, `app_database.dart` |
| FR-7 검색 피커 (Naver only) | `book_search_picker_screen.dart`, `searchNaverOnly()` |
| FR-7 추가 폼 + 쪽수 | `add_book_form_screen.dart`, `book_catalog_api.dart` |
| FR-12 `+` 진입 | `add_book_flow.dart`, `app_router.dart` `/books/add/*` |

## Add book flow (PLAN-000008)

1. `pushAddBookFlow` → `/books/add/search`
2. Pick hit → loading overlay → `POST /api/books/catalog/pages` → `/books/add/form` with `AddBookFormArgs`
3. Form: read-only cover/title/ISBN; edit total pages + read-up-to only (manual entry: title/ISBN + same fields)
4. Save → `insertBook`, pop with `Book`
