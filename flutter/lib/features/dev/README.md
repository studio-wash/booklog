# Dev tools (backup & restore)

**마지막 업데이트**: 2026-05-15

## Spec 정보

- **Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md` (FR-11)
- **Plan 파일**: `plan/PLAN-000004_dev-db-export-import/plan.md`
- **구현 상태**: ✅ 완료

## 코드 위치

- **화면**: `flutter/lib/features/dev/data_backup_screen.dart`
- **라우트**: `flutter/lib/router/app_router.dart` — `GoRoute(path: '/dev/data', …)`
- **진입**: `flutter/lib/features/books/books_screen.dart` — AppBar zip 아이콘 → `context.push('/dev/data')`

## Spec-Code 매핑

| Spec 요구사항 | 코드 파일 | 상태 | 마지막 업데이트 |
|--------------|-----------|------|----------------|
| FR-11 Export / 공유 | `data_backup_screen.dart` (`Share.shareXFiles`, 임시 JSON) | ✅ | 2026-05-15 |
| FR-11 Import / 빈 DB만 | `data_backup_screen.dart` (`FilePicker`, `importDatabaseFromJson`) | ✅ | 2026-05-15 |

## 생성/수정 이력

- 2026-05-15: PLAN-000004 — `DataBackupScreen`, `/dev/data`, Books AppBar 진입
