# Data layer — SQLite

**마지막 업데이트**: 2026-05-12

## Spec 정보

- **Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md`
- **Plan 파일**: `plan/PLAN-000001_haruhanjang-mvp/plan.md`, `plan/PLAN-000002_main-current-reading/plan.md`
- **구현 상태**: ✅ 완료

## 코드 위치

- **Flutter**: `flutter/lib/data/app_database.dart`
- **로컬 파일**: 기본 경로 파일명 `booklog_store.db`. `userVersion` **2**: `books`에 ISBN(유일)·표지 URL·링크·저자·출판사·설명·출간일 등 저장. v1 DB 파일을 열면 **onUpgrade에서 테이블 드롭 후 재생성**(데이터 소실, 마이그레이션 없음).

## Spec-Code 매핑

| Spec 요구사항 | 코드 | 상태 | 마지막 업데이트 |
|--------------|------|------|----------------|
| FR-1 책 엔티티 | `Book` 클래스, `books` 테이블 | ✅ | 2026-05-12 |
| FR-2 읽기 기록 | `ReadingEntry`, `reading_entries` 테이블 | ✅ | 2026-05-12 |
| FR-3 감상(노트) | `ReadingEntry.note` | ✅ | 2026-05-12 |
| FR-4 잔디 집계 | `entriesForMonth`, `entriesBetween` | ✅ | 2026-05-12 |
| FR-8 완독 누적 | `totalPagesReadForBook`, `completion_note` | ✅ | 2026-05-12 |
| FR-10 현재 읽기 카드 | `latestReadingEntry`, `bookById`, `insertEntry`(…`createdAt`) | ✅ | 2026-05-12 |

## 생성/수정 이력

- 2026-05-15: `books` 스키마 v2 — ISBN(유일)·표지·저자·출판사·설명·출간일·링크 저장; v1→v2 업그레이드 시 테이블 재생성.
- 2026-05-12: PLAN-000002 — `latestReadingEntry`, `bookById`, 테스트용 `insertEntry`의 `createdAt` 선택 인자.
- 2026-05-12: 메인 잔디 집계용 `entriesBetween` 추가. (이후 메인 창은 **12개 달** 롤링 + `dayPageTotalsRolling12MonthsProvider`.)
- 2026-05-12: PLAN-000001 완료 — `AppDatabase`·스키마·쿼리 확정
