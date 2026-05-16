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
| `GET /api/books/search` | Naver search; `?catalog=0` = Naver only (picker); default = background enrich |
| `POST /api/books/catalog/pages` | Form: upsert meta + read/Aladin 1× for `total_pages` |
| `GET /api/health` | Health + Aladin daily call summary |
| `GET /api/dev/aladin-stats` | Aladin daily counter (dev) |

## Env

Copy `.env.example` → `.env` (gitignored).

| Variable | Required | Notes |
|----------|----------|--------|
| `NAVER_CLIENT_ID`, `NAVER_CLIENT_SECRET` | search | Naver book API |
| `DATABASE_URL` or `POSTGRES_URL` | Vercel / shared catalog | [Neon](https://neon.tech) pooled connection string (Vercel integration often sets `POSTGRES_URL` only) |
| `ALADIN_TTB_KEY` | optional | Aladin `total_pages` enrich |

Without a Postgres URL, catalog uses local SQLite (`data/catalog.sqlite`). On Vercel, set Neon’s pooled URL so catalog and Aladin daily counters persist across invocations. Search enriches at most **3** Aladin ItemLookUp calls per request (see `lib/catalog/enrich.ts`).

## Code layout

| Path | Role |
|------|------|
| `lib/isbn.ts` | ISBN-13 normalization |
| `lib/catalog/` | Neon Postgres (or SQLite locally) `book_catalog`, Naver upsert, enrich |
| `lib/aladin/` | ItemLookUp client, daily limit, metrics |
| `app/api/books/search/route.ts` | Search handler |

## Tests

```bash
npm test
```
