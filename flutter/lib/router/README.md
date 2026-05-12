# App router

**마지막 업데이트**: 2026-05-12

## Spec 정보

- **Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md`
- **Plan 파일**: `plan/PLAN-000001_haruhanjang-mvp/plan.md`
- **구현 상태**: ✅ 완료

## 코드 위치

- `flutter/lib/router/app_router.dart` — `go_router` (`/`, `/books`, `/log`)

## Spec-Code 매핑

| 경로 | 화면 | 상태 |
|------|------|------|
| `/` | `GrassScreen` | ✅ |
| `/books` | `BooksScreen` | ✅ |
| `/log` | `LogEntryScreen` — 쿼리 `bookId`, **`day=YYYY-MM-DD`**(해당 일 기록 프리필) | ✅ |
