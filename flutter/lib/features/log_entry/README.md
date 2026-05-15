# Log entry (읽기 기록)

**마지막 업데이트**: 2026-05-15

## Spec 정보

- **Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md`
- **Plan 파일**: `plan/PLAN-000001_haruhanjang-mvp/plan.md`, `plan/PLAN-000005_resume-reading-from-page/plan.md`
- **구현 상태**: ✅ 완료

## 코드 위치

- **Flutter**: `flutter/lib/features/log_entry/log_entry_screen.dart`

## Spec-Code 매핑

| Spec 요구사항 | 코드 파일 | 상태 | 마지막 업데이트 |
|--------------|-----------|------|----------------|
| FR-2 날짜·책·페이지 저장 | `log_entry_screen.dart` — `_save`, `insertEntry`, `lastPageBoundsForNewEntry`; 기준선 힌트; 날짜는 **오늘 이전만**; `initialLogDay`·`/log?day=` | ✅ | 2026-05-15 |
| FR-3 접힘 감상 | `log_entry_screen.dart` — `_showNote`, `TextField` | ✅ | 2026-05-12 |
| FR-8 완독 축하·한줄 평 | `log_entry_screen.dart` — `maxLastPageReadForBook`(기준선 포함) vs `totalPages` 바텀시트 | ✅ | 2026-05-15 |

## 생성/수정 이력

- 2026-05-15: PLAN-000005 — 책 기준선에 따른 “마지막 쪽” 필드 helper 문구
- 2026-05-12: 과거 날짜 보정 UX(`lastDate: today`), `/log?day=`·`initialLogDay`
