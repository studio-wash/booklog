# booklog API server

**마지막 업데이트**: 2026-05-15

Next.js proxy for Naver book search + shared ISBN catalog (PLAN-000007).

## Spec / Plan

- **Spec**: `spec/features/booklog-mvp/booklog-mvp.md` (FR-7)
- **Plan**: `plan/PLAN-000007_aladin-page-catalog/plan.md`
- **Knowledge**: `knowledge/reference/api/naver-book-search.md`, `knowledge/reference/api/aladin-openapi.md`

## Endpoints

| Route | 설명 |
|-------|------|
| `GET /api/books/search` | Naver search + catalog upsert + lazy Aladin `total_pages` |
| `GET /api/health` | Health + Aladin daily call summary |
| `GET /api/dev/aladin-stats` | Aladin daily counter (dev) |

## Env

Copy `.env.example` → `.env` (gitignored). Required for search: `NAVER_*`. Optional enrich: `ALADIN_TTB_KEY`.

## Code layout

| Path | Role |
|------|------|
| `lib/isbn.ts` | ISBN-13 normalization |
| `lib/catalog/` | SQLite `book_catalog`, Naver upsert, enrich |
| `lib/aladin/` | ItemLookUp client, daily limit, metrics |
| `app/api/books/search/route.ts` | Search handler |

## Tests

```bash
npm test
```
