# Implementation Tasks — Add book search picker (2-step)

**생성일**: 2026-05-15  
**Plan 파일**: `plan/PLAN-000008_add-book-search-picker/plan.md`  
**Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md` (FR-1, FR-7, FR-12)

## 실행 가능한 Tasks (Quick Reference)

| Task ID | 한 줄 요약 | 상태 | 우선순위 | 의존성 | 예상 시간 |
|---------|-----------|------|----------|--------|-----------|
| `search-catalog-flag` | `GET /api/books/search?catalog=0` — Naver만, 백그라운드 enrich 생략 | ✅ 완료 | High | - | 20분 |
| `catalog-pages-api` | `POST /api/books/catalog/pages` — upsert(메타) + 쪽수 조회·Aladin 1회 | ✅ 완료 | High | search-catalog-flag | 50분 |
| `test-catalog-pages` | catalog/pages·catalog=0 라우트 단위 테스트 | ✅ 완료 | Medium | catalog-pages-api | 35분 |
| `api-search-naver-only` | Flutter `searchNaverOnly` (`catalog=0`) | ✅ 완료 | High | search-catalog-flag | 15분 |
| `api-fetch-pages` | Flutter `fetchCatalogTotalPages(BookSearchHit)` | ✅ 완료 | High | catalog-pages-api | 20분 |
| `picker-screen` | `BookSearchPickerScreen` — 검색·리스트·탭 시 pop(hit) | ✅ 완료 | High | api-search-naver-only | 45분 |
| `form-screen` | `AddBookFormScreen` — 메타·기준선·저장·쪽수 async pre-fill | ✅ 완료 | High | api-fetch-pages | 50분 |
| `router-add-book` | `/books/add/search`, `/books/add/form` + `extra` 타입 | ✅ 완료 | High | picker-screen, form-screen | 30분 |
| `wire-books-entry` | Books AppBar `+` → 검색 피커 플로우 | ✅ 완료 | High | router-add-book | 15분 |
| `wire-log-entry` | `/log` 책 추가 → 동일 피커→폼 플로우 | ✅ 완료 | High | router-add-book | 20분 |
| `manual-add-entry` | “검색 없이 추가” → 빈 폼 진입점 | ✅ 완료 | Medium | form-screen | 15분 |
| `remove-monolithic-sheet` | `_AddBookSheetBody` 통합 시트 제거·정리 | ✅ 완료 | Medium | wire-books-entry, wire-log-entry | 25분 |
| `test-flutter-pages` | `fetchCatalogTotalPages`·파서 테스트 | ✅ 완료 | Medium | api-fetch-pages | 25분 |
| `sync-spec-plan008` | spec FR-7·FR-1·FR-12·코드 매핑 (2단계 추가) | ✅ 완료 | Low | remove-monolithic-sheet | 20분 |

**전체 진행률**: 100% (14/14 tasks 완료)  
**마지막 업데이트**: 2026-05-15

> **사용법**: `/code PLAN-000008 <task-id>` · 일괄: `/code PLAN-000008 *`

---

## 변경 이력

- 2026-05-15: PLAN-000008 초기 `tasks.md` 생성
- 2026-05-15: `/code PLAN-000008 *` — 2-step add book (picker + form), catalog/pages API, spec sync
