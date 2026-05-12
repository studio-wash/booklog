# Implementation Tasks — 메인 현재 읽기 카드 (PLAN-000002)

**생성일**: 2026-05-12  
**Plan 파일**: `plan/PLAN-000002_main-current-reading/plan.md`  
**Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md` · `spec/project.md`

## 실행 가능한 Tasks (Quick Reference)

| Task ID | 한 줄 요약 | 상태 | 우선순위 | 의존성 | 예상 시간 |
|---------|-------------|------|----------|--------|-----------|
| `db-latest-reading-entry` | `AppDatabase.latestReadingEntry()` — `created_at` 최신 1건 | ⬜ 미완료 | High | - | 20분 |
| `provider-current-reading` | 마지막 기록 책·누적 페이지 스냅샷 `FutureProvider` | ⬜ 미완료 | High | `db-latest-reading-entry` | 25분 |
| `ui-grass-current-reading-card` | `GrassScreen` 잔디 아래 카드·탭 → `/log?bookId=` | ⬜ 미완료 | High | `provider-current-reading` | 45분 |
| `test-current-reading-latest-book` | 최신 `created_at` 기준 책 선택 DB/통합 테스트 | ⬜ 미완료 | Medium | `db-latest-reading-entry` | 30분 |
| `spec-fr10-current-reading` | `booklog-mvp.md` FR-10 및 코드 매핑 행 추가 | ⬜ 미완료 | Medium | - | 15분 |

**전체 진행률**: 0% (0/5 tasks 완료)  
**마지막 업데이트**: 2026-05-12

> `/code PLAN-000002 <task-id>` — 터미널에서는 **`cd flutter`** 후 `flutter analyze` / `flutter test` 실행.

---

## Tasks 상세 목록

### Phase 1: 데이터

#### Task db-latest-reading-entry
- [ ] **상태**: 미완료
- **Task ID**: `db-latest-reading-entry`
- **한 줄 요약**: 가장 최근 읽기 기록 한 건 조회 API
- **설명**: `reading_entries`에 대해 `ORDER BY created_at DESC LIMIT 1`. 반환 타입 `ReadingEntry?`. 스키마 변경 없음. 대량 데이터 시 `created_at` 인덱스는 별도 이슈로 검토.
- **의존성**: 없음 (`persist-layer`는 PLAN-000001 완료 전제)
- **우선순위**: High
- **예상 시간**: 20분
- **구현 위치**: `flutter/lib/data/app_database.dart`

### Phase 2: 상태·프로바이더

#### Task provider-current-reading
- [ ] **상태**: 미완료
- **Task ID**: `provider-current-reading`
- **한 줄 요약**: 카드용 스냅샷(책, 누적 페이지, 총 페이지, 마지막 기록일)
- **설명**: `ref.watch(readingDataTickProvider)`와 연동해 기록 저장 후 갱신. `latestReadingEntry` → `bookId`로 `Book` 로드(단건 쿼리 또는 `allBooks` 맵) + `totalPagesReadForBook`. 불변 DTO(예: `CurrentReadingSnapshot?`)로 묶어 UI가 파싱만 하게 한다.
- **의존성**: `db-latest-reading-entry`
- **우선순위**: High
- **예상 시간**: 25분
- **구현 위치**: `flutter/lib/providers.dart` 및 필요 시 `flutter/lib/features/grass/` 또는 `lib/features/reading/` 하위 모델 파일

### Phase 3: UI

#### Task ui-grass-current-reading-card
- [ ] **상태**: 미완료
- **Task ID**: `ui-grass-current-reading-card`
- **한 줄 요약**: 메인 잔디 아래 “지금 읽는 책” 카드
- **설명**: `GrassScreen` 본문 `Column`에서 `Expanded(잔디)` **아래**에 카드 배치. 제목 말줄임, 부제에 누적/총·짧은 날짜(플랜: `calendar_date` 우선 표시 권장). `total_pages` 있으면 선형 `LinearProgressIndicator`. 탭 시 `context.push('/log?bookId=$id')`. 엔트리 없을 때 안내 문구만. 하단 FAB와 겹치지 않도록 `padding` 유지.
- **의존성**: `provider-current-reading`
- **우선순위**: High
- **예상 시간**: 45분
- **구현 위치**: `flutter/lib/features/grass/grass_screen.dart`, 필요 시 `flutter/lib/features/grass/current_reading_card.dart`로 위젯 분리

### Phase 4: 테스트

#### Task test-current-reading-latest-book
- [ ] **상태**: 미완료
- **Task ID**: `test-current-reading-latest-book`
- **한 줄 요약**: “최신 created_at 책”이 카드 데이터와 일치하는지 검증
- **설명**: 인메모리/임시 DB에 책 2권 + 엔트리 여러 건 삽입 후 `latestReadingEntry`(또는 프로바이더 로직)가 **가장 늦게 저장된** `book_id`를 가리키는지 단위 테스트 1건 이상.
- **의존성**: `db-latest-reading-entry`
- **우선순위**: Medium
- **예상 시간**: 30분
- **구현 위치**: `flutter/test/` (예: `db_smoke_test.dart` 확장 또는 전용 파일)

### Phase 5: 스펙

#### Task spec-fr10-current-reading
- [ ] **상태**: 미완료
- **Task ID**: `spec-fr10-current-reading`
- **한 줄 요약**: FR-10 요구사항·구현 매핑 반영
- **설명**: `spec/features/booklog-mvp/booklog-mvp.md`에 FR-10 행 추가: 메인에 마지막 기록 책·누적 페이지(및 총 페이지 시 진행) 표시, 탭 시 해당 책으로 기록 화면. 표 “구현 코드 매핑”에 `grass_screen`·`providers`·`app_database` 등 실제 경로 반영.
- **의존성**: 없음 (코드 완료 후 매핑 문구를 최종 맞추려면 `ui-grass-current-reading-card` 이후 실행 권장)
- **우선순위**: Medium
- **예상 시간**: 15분
- **구현 위치**: `spec/features/booklog-mvp/booklog-mvp.md`, `flutter/lib/features/grass/README.md` 매핑 한 줄 갱신

## 의존성 그래프

```
db-latest-reading-entry ──┬──> provider-current-reading ──> ui-grass-current-reading-card
                            │
                            └──> test-current-reading-latest-book

spec-fr10-current-reading  (코드 완료 후 매핑 정리 권장; 병렬 착수 가능)
```

## 변경 이력

- 2026-05-12: `tasks.md` 초기 생성 (`/tasks PLAN-000002`).
