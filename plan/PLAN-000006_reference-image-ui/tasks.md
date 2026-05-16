# Implementation Tasks — reference.png UI 정렬

**생성일**: 2026-05-15  
**Plan 파일**: `plan/PLAN-000006_reference-image-ui/plan.md`  
**Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md`  
**레퍼런스**: `plan/PLAN-000006_reference-image-ui/reference/reference.png`

## 실행 가능한 Tasks (Quick Reference)

| Task ID | 한 줄 요약 | 상태 | 우선순위 | 의존성 | 예상 시간 |
|---------|-----------|------|----------|--------|-----------|
| `theme-tokens` | 목업 토큰 반영 — `app_theme.dart` 색·타이포·입력·FAB | ✅ 완료 | High | - | 30분 |
| `ui-shared-widgets` | `BooklogCard`, `StatChip`, `SectionHeader` 공통 위젯 | ✅ 완료 | High | theme-tokens | 35분 |
| `providers-home-stats` | Streak·올해 읽은 권 수 provider (DB 집계만) | ✅ 완료 | Medium | - | 25분 |
| `nav-bottom-shell` | `ShellRoute` + 하단 5탭(중앙 + → `/log`) | ✅ 완료 | High | theme-tokens | 50분 |
| `skin-grass-home` | 홈: 인사·칩·잔디·현재 읽기·AppBar 정리 (목업 #1) | ✅ 완료 | High | ui-shared-widgets, providers-home-stats, nav-bottom-shell | 55분 |
| `skin-empty-home` | 기록 없을 때 empty state (목업 #10) | ✅ 완료 | Medium | skin-grass-home | 20분 |
| `skin-day-detail-sheet` | 날 탭 시트 — 합계·세션 카드 (목업 #11) | ✅ 완료 | Medium | ui-shared-widgets | 35분 |
| `skin-current-reading-card` | Currently Reading 카드 스타일 | ✅ 완료 | Medium | ui-shared-widgets | 25분 |
| `skin-log-entry` | 기록 화면 레이아웃·큰 쪽 수·± (목업 #2) | ✅ 완료 | High | ui-shared-widgets, nav-bottom-shell | 45분 |
| `skin-books-list-search` | 서재 목록·검색 시트 (목업 #3·#4 1차) | ✅ 완료 | Medium | ui-shared-widgets, nav-bottom-shell | 40분 |
| `skin-completion-sheet` | 완독·한줄 평 시트 톤 (목업 #6·#7, 별점 제외) | ✅ 완료 | Medium | ui-shared-widgets | 25분 |
| `test-nav-shell` | 라우터·셸 스모크 테스트 | ✅ 완료 | Medium | nav-bottom-shell | 20분 |
| `sync-spec-nav-ui` | spec에 하단 네비·홈 집계 표시 FR/매핑 반영 | ✅ 완료 | Low | nav-bottom-shell, skin-grass-home | 15분 |

**전체 진행률**: 100% (13/13 tasks 완료)  
**마지막 업데이트**: 2026-05-15

> **사용법**: `/code PLAN-000006 <task-id>` (예: `/code PLAN-000006 theme-tokens`) · 일괄: `/code PLAN-000006 *`

### Phase C — 후속 (본 tasks 범위 밖, 별 plan/태스크 권장)

| 항목 | 설명 |
|------|------|
| 책 상세 `/books/:id` | 목업 #4 전용 화면 — 신규 FR |
| 전역 Reading History | 목업 #5 — `/history` |
| Profile / Settings | 목업 #8·#9 — 통계·목표·다크모드 등 신규 FR |
| 별점 리뷰 | 목업 #7 — FR-8 한줄 평만 유지 |

---

## Tasks 상세 목록

### Phase A: 테마·셸·공통

#### Task theme-tokens

- [x] **상태**: 완료
- **Task ID**: `theme-tokens`
- **한 줄 요약**: 목업 토큰 반영 — `app_theme.dart` 색·타이포·입력·FAB
- **설명**: `reference.png` 대조해 배경·카드 surface·뮤트 그린 primary/secondary·`borderRadius` 12–16·AppBar 흰 배경·FAB 둥근 형태 조정. 잔디 `grass_github_palette`는 히트맵 가독성 유지하며 톤만 맞춤(로직 변경 없음).
- **의존성**: 없음
- **우선순위**: High
- **예상 시간**: 30분
- **구현 위치**: `flutter/lib/core/app_theme.dart`, 필요 시 `grass_github_palette.dart`

#### Task ui-shared-widgets

- [x] **상태**: 완료
- **Task ID**: `ui-shared-widgets`
- **한 줄 요약**: `BooklogCard`, `StatChip`, `SectionHeader` 공통 위젯
- **설명**: 카드(elevation 0~1, padding 16), 상단 섹션 제목, 홈용 통계 칩(Streak / Books this year 라벨+값) 위젯을 `core/` 또는 `features/shared/`에 추가. 이후 skin 태스크에서 재사용.
- **의존성**: `theme-tokens`
- **우선순위**: High
- **예상 시간**: 35분
- **구현 위치**: `flutter/lib/core/` (예: `booklog_card.dart`, `booklog_stat_chip.dart`)

#### Task providers-home-stats

- [x] **상태**: 완료
- **Task ID**: `providers-home-stats`
- **한 줄 요약**: Streak·올해 읽은 권 수 provider (DB 집계만)
- **설명**: **Streak**: `reading_entries`의 distinct `log_day`로 오늘부터 연속 읽은 일수 계산. **Books this year**: 올해 달력 연도에 최소 1건 `reading_entries`가 있는 distinct `book_id` 수(또는 plan과 동일한 정의로 문서화). 스키마 변경 없음.
- **의존성**: 없음
- **우선순위**: Medium
- **예상 시간**: 25분
- **구현 위치**: `flutter/lib/providers.dart`, `flutter/lib/data/app_database.dart` (집계 쿼리 헬퍼)

#### Task nav-bottom-shell

- [x] **상태**: 완료
- **Task ID**: `nav-bottom-shell`
- **한 줄 요약**: `ShellRoute` + 하단 5탭(중앙 + → `/log`)
- **설명**: 목업 #12: Home=`/`, History=임시 placeholder(간단 “Coming soon” 또는 Books로 redirect — **비활성 토글 금지**), 중앙 **+**=`/log`(최근 책 `bookId` 프리필은 기존 로직 유지), Books=`/books`, Profile=임시 About/백업 링크만 있는 최소 화면 또는 Books와 동일 탭 금지 시 간단 Profile 스텁. `GrassScreen` AppBar의 Books 아이콘·중복 FAB 제거(셸 FAB/탭으로 통일). `/dev/data`는 Profile 스텁 또는 Books AppBar에서만 진입.
- **의존성**: `theme-tokens`
- **우선순위**: High
- **예상 시간**: 50분
- **구현 위치**: `flutter/lib/router/app_router.dart`, `flutter/lib/features/shell/` (신규), `flutter/lib/app.dart`

---

### Phase B: 화면 스킨 (FR 동작 유지)

#### Task skin-grass-home

- [x] **상태**: 완료
- **Task ID**: `skin-grass-home`
- **한 줄 요약**: 홈: 인사·칩·잔디·현재 읽기·AppBar 정리 (목업 #1)
- **설명**: 본문 상단 시간대 인사(Good morning/afternoon), `StatChip`으로 streak·올해 권수, 12개월 잔디·범례 유지(FR-4~6), `CurrentReadingCardSection` 아래 배치. AppBar는 앱명 또는 최소 타이틀만. FAB는 셸 중앙 +에 위임.
- **의존성**: `ui-shared-widgets`, `providers-home-stats`, `nav-bottom-shell`
- **우선순위**: High
- **예상 시간**: 55분
- **구현 위치**: `flutter/lib/features/grass/grass_screen.dart`

#### Task skin-empty-home

- [x] **상태**: 완료
- **Task ID**: `skin-empty-home`
- **한 줄 요약**: 기록 없을 때 empty state (목업 #10)
- **설명**: 잔디 데이터 없음 또는 `currentReading` 없을 때 중앙 일러스트(아이콘)·“No reading recorded yet”류 카피·CTA(+로 기록). FR-10 안내 문구와 통합.
- **의존성**: `skin-grass-home`
- **우선순위**: Medium
- **예상 시간**: 20분
- **구현 위치**: `flutter/lib/features/grass/grass_screen.dart`, `current_reading_card.dart`

#### Task skin-day-detail-sheet

- [x] **상태**: 완료
- **Task ID**: `skin-day-detail-sheet`
- **한 줄 요약**: 날 탭 시트 — 합계·세션 카드 (목업 #11)
- **설명**: `_openGrassDaySheet`: 당일 **총 페이지·세션 수·책 수** 헤더 + 세션별 `BooklogCard`(제목, +pages, 쪽, 메모 요약). “Log reading for this day” 버튼 유지(FR-6).
- **의존성**: `ui-shared-widgets`
- **우선순위**: Medium
- **예상 시간**: 35분
- **구현 위치**: `flutter/lib/features/grass/grass_screen.dart`

#### Task skin-current-reading-card

- [x] **상태**: 완료
- **Task ID**: `skin-current-reading-card`
- **한 줄 요약**: Currently Reading 카드 스타일
- **설명**: 표지·제목·진행바·마지막 기록일을 목업 #1 카드와 동일 톤(라운드 카드, 진행 %). 탭 시 `/log?bookId=`(기존 동작).
- **의존성**: `ui-shared-widgets`
- **우선순위**: Medium
- **예상 시간**: 25분
- **구현 위치**: `flutter/lib/features/grass/current_reading_card.dart`

#### Task skin-log-entry

- [x] **상태**: 완료
- **Task ID**: `skin-log-entry`
- **한 줄 요약**: 기록 화면 레이아웃·큰 쪽 수·± (목업 #2)
- **설명**: 책 선택·날짜·**큰 숫자 last page**·increment/decrement·접힌 메모 UI를 공통 토큰으로 정렬. FR-2·FR-3·기준선 검증 로직 변경 없음.
- **의존성**: `ui-shared-widgets`, `nav-bottom-shell`
- **우선순위**: High
- **예상 시간**: 45분
- **구현 위치**: `flutter/lib/features/log_entry/log_entry_screen.dart`

#### Task skin-books-list-search

- [x] **상태**: 완료
- **Task ID**: `skin-books-list-search`
- **한 줄 요약**: 서재 목록·검색 시트 (목업 #3·#4 1차)
- **설명**: 목록 행=표지+제목+메타 카드형. 검색 시트=상단 검색바·결과 리스트·추가 버튼 스타일(FR-7). 전용 상세 라우트는 하지 않음(Phase C).
- **의존성**: `ui-shared-widgets`, `nav-bottom-shell`
- **우선순위**: Medium
- **예상 시간**: 40분
- **구현 위치**: `flutter/lib/features/books/books_screen.dart`

#### Task skin-completion-sheet

- [x] **상태**: 완료
- **Task ID**: `skin-completion-sheet`
- **한 줄 요약**: 완독·한줄 평 시트 톤 (목업 #6·#7, 별점 제외)
- **설명**: 완독 축하 바텀시트·한줄 평 입력을 목업 Review/Completion 톤으로. **별점 UI 추가하지 않음**(FR-8 유지).
- **의존성**: `ui-shared-widgets`
- **우선순위**: Medium
- **예상 시간**: 25분
- **구현 위치**: `flutter/lib/features/log_entry/log_entry_screen.dart`

---

### Phase D: 검증·스펙

#### Task test-nav-shell

- [x] **상태**: 완료
- **Task ID**: `test-nav-shell`
- **한 줄 요약**: 라우터·셸 스모크 테스트
- **설명**: `createAppRouter()`로 `/`, `/books`, `/log` 진입 시 `MaterialApp`·하단 네비(또는 Shell) 위젯 1건 이상 pump. 기존 `widget_test`·DB 테스트 깨지지 않게.
- **의존성**: `nav-bottom-shell`
- **우선순위**: Medium
- **예상 시간**: 20분
- **구현 위치**: `flutter/test/router_shell_test.dart` (신규)

#### Task sync-spec-nav-ui

- [x] **상태**: 완료
- **Task ID**: `sync-spec-nav-ui`
- **한 줄 요약**: spec에 하단 네비·홈 집계 표시 FR/매핑 반영
- **설명**: `booklog-mvp.md`에 FR 또는 UI 절: 하단 탭 구조, 홈 Streak/연간 권수 표시, FAB 위치. 구현 코드 매핑 테이블 갱신. `spec/project.md` plan 연동에 PLAN-000006 한 줄.
- **의존성**: `nav-bottom-shell`, `skin-grass-home`
- **우선순위**: Low
- **예상 시간**: 15분
- **구현 위치**: `spec/features/booklog-mvp/booklog-mvp.md`, `spec/project.md`

---

## 의존성 그래프

```
theme-tokens ─┬─► ui-shared-widgets ─┬─► skin-grass-home ─► skin-empty-home
              │                      ├─► skin-day-detail-sheet
              │                      ├─► skin-current-reading-card
              │                      ├─► skin-log-entry
              │                      ├─► skin-books-list-search
              │                      └─► skin-completion-sheet
              │
              └─► nav-bottom-shell ─┬─► skin-grass-home
                                    ├─► skin-log-entry
                                    ├─► skin-books-list-search
                                    └─► test-nav-shell

providers-home-stats ─► skin-grass-home

nav-bottom-shell + skin-grass-home ─► sync-spec-nav-ui
```

## 권장 실행 순서

1. `theme-tokens` → `ui-shared-widgets` + `providers-home-stats` (병렬 가능)
2. `nav-bottom-shell`
3. `skin-grass-home` → `skin-empty-home` / `skin-current-reading-card` / `skin-day-detail-sheet`
4. `skin-log-entry` · `skin-books-list-search` · `skin-completion-sheet`
5. `test-nav-shell` → `sync-spec-nav-ui`

## 변경 이력

- 2026-05-15: PLAN-000006 `reference.png` 기준 초기 tasks.md 생성 (Phase A·B 13 tasks, Phase C 후속 표만 기록)
- 2026-05-15: `/code PLAN-000006 *` — 13/13 tasks 구현 완료
- 2026-05-15: `/revise` — 테마를 레퍼런스대로 **UI=흰/검정·회색**, **초록=잔디만** (`app_theme.dart` 수정, plan·FR-12 정정)
