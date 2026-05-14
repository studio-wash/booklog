# Implementation Tasks — 개발용 DB JSON export/import

**생성일**: 2026-05-15  
**Plan 파일**: `plan/PLAN-000004_dev-db-export-import/plan.md`  
**Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md`

## 실행 가능한 Tasks (Quick Reference)

| Task ID | 한 줄 요약 | 상태 | 우선순위 | 의존성 | 예상 시간 |
|---------|-----------|------|----------|--------|-----------|
| `export-spec` | export JSON 포맷 상수·필드 정의·예시 블록 문서화 | ✅ 완료 | High | - | 30분 |
| `db-read-snapshot` | 전체 `reading_entries` 조회 등 export/import용 DB API | ✅ 완료 | High | - | 20분 |
| `impl-export` | 스냅샷 → JSON 문자열(indent)·메타(`export_schema_version` 등) | ✅ 완료 | High | export-spec, db-read-snapshot | 45분 |
| `impl-import` | JSON 파싱·검증·빈 DB만 허용·트랜잭션·`book_id` 재매핑 삽입 | ✅ 완료 | High | export-spec, db-read-snapshot | 90분 |
| `deps-io-ui` | `share_plus`·`file_picker` 추가, Export/Import 진입 UI·공유/선택 | ✅ 완료 | Medium | impl-export, impl-import | 60분 |
| `test-roundtrip` | 동일 스키마에서 export JSON → 빈 DB → import 후 건수·필드 일치 | ✅ 완료 | High | impl-import | 45분 |
| `spec-fr11` | Spec FR-11 및 코드 매핑 행 추가(export/import) | ✅ 완료 | Medium | impl-export, impl-import | 15분 |

**전체 진행률**: 100% (7/7 tasks 완료)  
**마지막 업데이트**: 2026-05-15

> **사용법**: `/code PLAN-000004 <task-id>` (예: `/code PLAN-000004 export-spec`)

---

## Tasks 상세 목록

### Phase 1: 포맷·DB 읽기

#### Task export-spec

- [x] **상태**: 완료
- **Task ID**: `export-spec`
- **한 줄 요약**: export JSON 포맷 상수·필드 정의·예시 블록 문서화
- **설명**: `export_schema_version`(포맷 버전, 초기값 `1`), `app_schema_version`, `exported_at`, `books`·`reading_entries` 배열 키 규칙(snake_case, DB 컬럼과 동일)을 Dart 상수 또는 단일 모듈(`flutter/lib/data/booklog_export_format.dart` 등)에 둔다. `flutter/lib/data/README.md` 또는 `knowledge/reference/`에 **예시 JSON 한 블록**(더미 1권·기록 1건)을 넣어 AI 변환 시 붙여넣기 쉽게 한다.
- **의존성**: 없음
- **우선순위**: High
- **예상 시간**: 30분
- **구현 위치**: `flutter/lib/data/`, `flutter/lib/data/README.md` 또는 `knowledge/reference/data/`

#### Task db-read-snapshot

- [x] **상태**: 완료
- **Task ID**: `db-read-snapshot`
- **한 줄 요약**: 전체 `reading_entries` 조회 등 export/import용 DB API
- **설명**: `AppDatabase`에 `reading_entries` 전체를 `calendar_date`, `id` 순으로 읽는 메서드 추가. `allBooks()`와 함께 export 스냅샷에 쓴다. import 전 **빈 DB 여부**(`books`·`reading_entries` 건수 0) 판별용 메서드도 같은 계층에 두면 `impl-import`가 재사용하기 좋다.
- **의존성**: 없음
- **우선순위**: High
- **예상 시간**: 20분
- **구현 위치**: `flutter/lib/data/app_database.dart`

### Phase 2: 직렬화·수입

#### Task impl-export

- [x] **상태**: 완료
- **Task ID**: `impl-export`
- **한 줄 요약**: 스냅샷 → JSON 문자열(indent)·메타 필드
- **설명**: 스냅샷에서 `Map` 리스트를 구성해 `JsonEncoder.withIndent('  ')` 등으로 UTF-8 문자열 생성. `created_at` 등 int ms, null 필드는 JSON `null`로 일관 처리. `app_schema_version`은 `AppDatabase`의 현재 `userVersion` 상수와 동기.
- **의존성**: `export-spec`, `db-read-snapshot`
- **우선순위**: High
- **예상 시간**: 45분
- **구현 위치**: `flutter/lib/data/` (export 전용 함수 또는 `AppDatabase` 확장)

#### Task impl-import

- [x] **상태**: 완료
- **Task ID**: `impl-import`
- **한 줄 요약**: JSON 파싱·검증·빈 DB만 허용·트랜잭션·`book_id` 재매핑 삽입
- **설명**: `export_schema_version` 지원 범위 검사. 빈 DB가 아니면 명확한 에러/스낵바 메시지로 거절. 트랜잭션 안에서 `books`를 **옛 `id` 오름차순**으로 삽입해 `old_book_id → new_row.id` 맵을 만든 뒤, `reading_entries`의 `book_id`를 치환해 삽입. 삽입 후 책별 `_reconcileReadingEntryPagesForBook` 호출 여부는보낸 `pages`·`last_page_read` 일관성에 맞춰 결정(필요 시 전 책에 한 번씩 호출). 실패 시 롤백.
- **의존성**: `export-spec`, `db-read-snapshot`
- **우선순위**: High
- **예상 시간**: 90분
- **구현 위치**: `flutter/lib/data/app_database.dart` 또는 `flutter/lib/data/booklog_import.dart`

### Phase 3: 의존성·UI

#### Task deps-io-ui

- [x] **상태**: 완료
- **Task ID**: `deps-io-ui`
- **한 줄 요약**: `share_plus`·`file_picker` 추가, Export/Import 진입 UI
- **설명**: `pubspec.yaml`에 의존성 추가. Export: JSON 문자열을 임시 파일에 쓰거나 `Share.shareXFiles` / `Share.share`로 공유. Import: `file_picker`로 `.json` 선택 후 UTF-8 디코드 → `impl-import` 호출. 진입은 **개발자용**으로 Books 화면 `AppBar` 액션, 또는 `/dev/data` 라우트 등 한 곳에 모은다(중복 진입 최소화).
- **의존성**: `impl-export`, `impl-import`
- **우선순위**: Medium
- **예상 시간**: 60분
- **구현 위치**: `flutter/pubspec.yaml`, `flutter/lib/router/app_router.dart`, `flutter/lib/features/...`

### Phase 4: 테스트·Spec

#### Task test-roundtrip

- [x] **상태**: 완료
- **Task ID**: `test-roundtrip`
- **한 줄 요약**: export → 빈 DB → import 후 데이터 일치 검증
- **설명**: `sqflite` + 임시 DB 경로로 시드 데이터 삽입 → export → DB 드롭/재생성 또는 별도 빈 파일 → import → `books`/`reading_entries` 건수·대표 필드(ISBN, `last_page_read`, `calendar_date`) 비교. UI·파일 피커 없이 문자열만으로 검증 가능하게 한다.
- **의존성**: `impl-import` (및 `impl-export`가 완료되어 있어야 함)
- **우선순위**: High
- **예상 시간**: 45분
- **구현 위치**: `flutter/test/` (예: `export_import_roundtrip_test.dart`)

#### Task spec-fr11

- [x] **상태**: 완료
- **Task ID**: `spec-fr11`
- **한 줄 요약**: Spec FR-11 및 코드 매핑 행 추가
- **설명**: `booklog-mvp.md`에 **FR-11**(로컬 JSON export/import, 빈 서재 시 import, 개발·백업 목적) 요구 한 줄과 구현 파일 매핑을 추가한다.
- **의존성**: `impl-export`, `impl-import` (동작 확정 후 문구 고정)
- **우선순위**: Medium
- **예상 시간**: 15분
- **구현 위치**: `spec/features/booklog-mvp/booklog-mvp.md`

---

## 의존성 그래프

```
export-spec ──┬──► impl-export ──┐
              │                  ├──► deps-io-ui
db-read-snapshot ─┬─► impl-export ┘
                  └──► impl-import ──┬──► deps-io-ui
                                       └──► test-roundtrip

impl-export + impl-import ──► spec-fr11
(deps-io-ui 이후에 spec 반영해도 됨; FR 문구는 impl 확정 뒤 권장)
```

---

## 변경 이력

- 2026-05-15: `tasks.md` 초기 생성 (PLAN-000004)
- 2026-05-15: 전 task 완료 — 포맷·DB API·import/export·UI·라운드트립 테스트·FR-11 spec
