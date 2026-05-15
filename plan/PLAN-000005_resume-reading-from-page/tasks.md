# Implementation Tasks — 책 등록 시 “이미 읽은 마지막 쪽” 기준선

**생성일**: 2026-05-15  
**Plan 파일**: `plan/PLAN-000005_resume-reading-from-page/plan.md`  
**Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md`

## 실행 가능한 Tasks (Quick Reference)

| Task ID | 한 줄 요약 | 상태 | 우선순위 | 의존성 | 예상 시간 |
|---------|-----------|------|----------|--------|-----------|
| `db-schema-baseline` | `books.starting_last_page_read` 컬럼·스키마 v3·`Book`·insert/update | ✅ 완료 | High | - | 40분 |
| `db-entry-bounds-baseline` | 타임라인 하한에 기준선 반영 (`insertEntry`, `lastPageBoundsForNewEntry`) | ✅ 완료 | High | db-schema-baseline | 50분 |
| `db-progress-baseline` | `maxLastPageReadForBook` 등 진행·완독·프로바이더가 표시 쪽에 기준선 반영 | ✅ 완료 | High | db-schema-baseline, db-entry-bounds-baseline | 35분 |
| `export-import-baseline` | JSON export/import·예시·검증에 컬럼 포함(키 없으면 NULL) | ✅ 완료 | Medium | db-schema-baseline | 25분 |
| `ui-books-baseline` | 책 추가 시트·편집(로그 없을 때만) 기준선 필드·검증 | ✅ 완료 | Medium | db-schema-baseline | 45분 |
| `ui-log-hint-baseline` | 기록 화면 하한/힌트에 기준선 반영(선택 UX) | ✅ 완료 | Low | db-entry-bounds-baseline | 20분 |
| `test-baseline-pages` | 기준선 99→첫 로그 100 델타 1·회귀·거절·export 라운드트립 보강 | ✅ 완료 | High | db-progress-baseline, export-import-baseline | 40분 |

**전체 진행률**: 100% (7/7 tasks 완료)  
**마지막 업데이트**: 2026-05-15

> **사용법**: `/code PLAN-000005 <task-id>` (예: `/code PLAN-000005 db-schema-baseline`)

---

## Tasks 상세 목록

### Phase 1: 스키마·모델

#### Task db-schema-baseline

- [x] **상태**: 완료
- **Task ID**: `db-schema-baseline`
- **한 줄 요약**: `books.starting_last_page_read` 컬럼·스키마 v3·`Book`·insert/update
- **설명**: SQLite `userVersion` 3로 올리고 `onUpgrade`에서 `ALTER TABLE books ADD COLUMN starting_last_page_read INTEGER` (또는 동등). `Book`에 nullable `int? startingLastPageRead`(Dart 네이밍은 프로젝트 관례에 맞춤). `insertBook`·`updateBook`·`fromMap`·쿼리 `SELECT` 경로 반영. 값 규칙: `NULL` 또는 `>= 0`; `total_pages`가 있으면 `< total_pages`는 UI/API에서 검증 권장. 기존 DB는 컬럼 `NULL`로 동작 동일.
- **의존성**: 없음
- **우선순위**: High
- **예상 시간**: 40분
- **구현 위치**: `flutter/lib/data/app_database.dart`

### Phase 2: 읽기 로직

#### Task db-entry-bounds-baseline

- [x] **상태**: 완료
- **Task ID**: `db-entry-bounds-baseline`
- **한 줄 요약**: 타임라인 하한에 기준선 반영 (`insertEntry`, `lastPageBoundsForNewEntry`)
- **설명**: 책의 `starting_last_page_read`를 읽는 헬퍼 추가. `_maxLastPageReadBefore` 결과와 `max(..., baseline)`으로 **유효 이전 쪽** 계산. `insertEntry`의 `prev`·검증 메시지·`pages` 계산이 이 값을 쓰도록 수정. `lastPageBoundsForNewEntry`의 `lowerBound`에 기준선 반영(이웃 로그만 보던 경우와 “이 책에 로그가 하나도 없음” 분기 모두). 기준선이 99일 때 첫 `last_page_read`는 `> 99`(즉 ≥100); 기준선 0이면 기존 `≥ 1` 규칙 유지.
- **의존성**: `db-schema-baseline`
- **우선순위**: High
- **예상 시간**: 50분
- **구현 위치**: `flutter/lib/data/app_database.dart`

#### Task db-progress-baseline

- [x] **상태**: 완료
- **Task ID**: `db-progress-baseline`
- **한 줄 요약**: 표시·완독에 쓰는 “현재 쪽”에 기준선 반영
- **설명**: `maxLastPageReadForBook`를 **엔트리 MAX와 `starting_last_page_read`의 max**로 정의하거나, 별도 헬퍼로 통일 후 `totalPagesReadForBook`·완독 판정·`providers.dart`의 `currentReadingProvider`·`log_entry_screen.dart`의 완독 전후 조회가 모두 같은 정의를 쓰게 한다. 잔디 일별 합산은 여전히 `reading_entries.pages`만 사용(기준선은 델타 과대 방지·진행 표시용).
- **의존성**: `db-schema-baseline`, `db-entry-bounds-baseline`
- **우선순위**: High
- **예상 시간**: 35분
- **구현 위치**: `flutter/lib/data/app_database.dart`, `flutter/lib/providers.dart`, `flutter/lib/features/log_entry/log_entry_screen.dart`

### Phase 3: 백업·UI

#### Task export-import-baseline

- [x] **상태**: 완료
- **Task ID**: `export-import-baseline`
- **한 줄 요약**: JSON export/import·예시에 `starting_last_page_read` 포함
- **설명**: `exportDatabaseAsIndentedJson`의 `books` 행에 컬럼 포함. import 시 키 없으면 `NULL`. `_validateBookExportRow`는 선택 필드로 허용·범위만 검사. `booklog_export_format.dart`의 `kBooklogExportExampleJson`에 한 줄 추가. 필요 시 `export_import_roundtrip_test.dart`에 기준선 시드/검증 한 케이스.
- **의존성**: `db-schema-baseline`
- **우선순위**: Medium
- **예상 시간**: 25분
- **구현 위치**: `flutter/lib/data/app_database.dart`, `flutter/lib/data/booklog_export_format.dart`, `flutter/test/export_import_roundtrip_test.dart`

#### Task ui-books-baseline

- [x] **상태**: 완료
- **Task ID**: `ui-books-baseline`
- **한 줄 요약**: 책 추가·편집 UI에 “지금까지 읽은 마지막 쪽 (선택)”
- **설명**: `books_screen.dart` 추가 시트(검색·직접 입력 공통): 숫자 필드 optional, 비우면 `NULL`. `insertBook`에 전달. 편집 시트: 해당 책의 `reading_entries` **건수 0일 때만** 기준선 필드 편집 가능, 있으면 읽기 전용 또는 숨김. 총 페이지 입력 시 기준선 `< total_pages` 검증.
- **의존성**: `db-schema-baseline`
- **우선순위**: Medium
- **예상 시간**: 45분
- **구현 위치**: `flutter/lib/features/books/books_screen.dart`

#### Task ui-log-hint-baseline

- [x] **상태**: 완료
- **Task ID**: `ui-log-hint-baseline`
- **한 줄 요약**: 기록 화면 하한/힌트에 기준선 반영(선택 UX)
- **설명**: `lastPageBoundsForNewEntry`가 이미 기준선을 반영하면 검증은 자동. 추가로 `bookById`로 기준선을 읽어 “이전에 N쪽까지 읽음” 등 보조 문구를 넣으면 UX 개선(필수 아님).
- **의존성**: `db-entry-bounds-baseline`
- **우선순위**: Low
- **예상 시간**: 20분
- **구현 위치**: `flutter/lib/features/log_entry/log_entry_screen.dart`

### Phase 4: 테스트

#### Task test-baseline-pages

- [x] **상태**: 완료
- **Task ID**: `test-baseline-pages`
- **한 줄 요약**: 기준선별 `pages`·거절·회귀·export/import 검증
- **설명**: `flutter/test/`에 전용 파일 또는 `db_smoke_test.dart` 확장: (1) 기준선 99 후 첫 로그 100 → `pages==1`. (2) 기준선 없이 첫 로그 100 → `pages==100`. (3) 기준선 50, 첫 로그 50 이하 → `ArgumentError` 등 기대. (4) 선택: 기준선 포함 export → 빈 DB import 후 필드 일치.
- **의존성**: `db-progress-baseline`, `export-import-baseline`
- **우선순위**: High
- **예상 시간**: 40분
- **구현 위치**: `flutter/test/` (예: `starting_last_page_baseline_test.dart`)

---

## 의존성 그래프

```
db-schema-baseline ──┬──► db-entry-bounds-baseline ──► ui-log-hint-baseline
                     │              │
                     │              └──► db-progress-baseline ──► test-baseline-pages
                     │
                     ├──► export-import-baseline ───────────────► test-baseline-pages
                     │
                     └──► ui-books-baseline
```

---

## Spec 참고 (코드 단계에서 반영)

- **FR-1**: 책 필드에 “앱 이전 진행(마지막 쪽)” 선택 항목 추가 문구.
- **FR-2**: 타임라인·`pages` 정의에 기준선을 **가상의 이전 쪽**으로 명시.

---

## 변경 이력

- 2026-05-15: `tasks.md` 초기 생성 (PLAN-000005)
- 2026-05-15: 전 task 완료 — `/code PLAN-000005 *` 구현 반영
