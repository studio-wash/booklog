# Books (서재)

**마지막 업데이트**: 2026-05-12

## Spec 정보

- **Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md`
- **Plan 파일**: `plan/PLAN-000001_haruhanjang-mvp/plan.md`
- **구현 상태**: ✅ 완료

## 코드 위치

- **Flutter UI**: `flutter/lib/features/books/books_screen.dart`
- **책 검색 API (FR-7)**: `flutter/lib/features/books/data/book_search_api.dart`, 기본 origin `flutter/lib/core/api_config.dart`

## Spec-Code 매핑

| Spec 요구사항 | 코드 파일 | 상태 | 마지막 업데이트 |
|--------------|-----------|------|----------------|
| FR-1 책 CRUD | `books_screen.dart`, `AppDatabase` (`lib/data/`) | ✅ | 2026-05-12 |
| FR-7 외부 책 검색 | `data/book_search_api.dart` — 기본 `API_BASE_URL` 내장, 빈 `dart-define`으로 비활성 가능 | ✅ | 2026-05-12 |

## 생성/수정 이력

- 2026-05-12: PLAN-000001 서재 화면·NL 스tub 연동
