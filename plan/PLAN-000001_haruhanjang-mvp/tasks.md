# Implementation Tasks — booklog MVP (PLAN-000001)

**생성일**: 2026-05-12  
**Plan 파일**: `plan/PLAN-000001_haruhanjang-mvp/plan.md`  
**Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md` · `spec/project.md`

## 실행 가능한 Tasks (Quick Reference)

| Task ID | 한 줄 요약 | 상태 | 우선순위 | 의존성 | 예상 시간 |
|---------|-------------|------|----------|--------|-----------|
| `flutter-init` | `flutter/`에 Flutter 프로젝트·`lib/` 구조·번들 `com.studiowash.booklog` | ✅ 완료 | High | - | 45분 |
| `wire-branding` | `app_branding`·Android `@string/app_name`·iOS 표시명 분리 | ✅ 완료 | High | flutter-init | 30분 |
| `persist-layer` | 로컬 DB(sqflite)·Book / ReadingEntry 스키마 | ✅ 완료 | High | flutter-init | 90분 |
| `router-shell` | `go_router`·`MaterialApp.router`·경로 뼈대 | ✅ 완료 | High | flutter-init | 45분 |
| `domain-grass` | 월 단위 합산·상대 진하기·하한 규칙 (순수 Dart) | ✅ 완료 | High | persist-layer | 60분 |
| `ui-books-shelf` | FR-1 서재 UI + 저장소 연동 | ✅ 완료 | High | persist-layer, router-shell | 90분 |
| `ui-grass-main` | FR-4~6 메인 잔디 캘린더·일 탭 시 목록 | ✅ 완료 | High | domain-grass, router-shell | 120분 |
| `ui-log-entry` | FR-2~3 기록 화면·저장·반영 | ✅ 완료 | High | ui-books-shelf | 90분 |
| `nl-search` | FR-7 책 검색 클라이언트 (`API_BASE_URL` / `book_search_api.dart`) | ✅ 완료 | Medium | ui-books-shelf | 60분 |
| `ui-finish-book` | FR-8 완독 감지·축하·선택 한줄 평 | ✅ 완료 | Medium | ui-log-entry | 60분 |
| `polish-qa` | 빈 상태·`flutter analyze`·`flutter test` | ✅ 완료 | Medium | ui-grass-main, ui-log-entry, ui-finish-book | 60분 |

**전체 진행률**: 100% (11/11 tasks 완료)  
**마지막 업데이트**: 2026-05-12

> `/code PLAN-000001 <task-id>` — 터미널에서는 **`cd flutter`** 후 `flutter run` / `flutter analyze` 등을 실행한다.

---

## Tasks 상세 목록

### Phase 1: 스캐폴딩·브랜딩·내비

#### Task flutter-init
- [x] **상태**: 완료
- **Task ID**: `flutter-init`
- **한 줄 요약**: **`flutter/`** 디렉터리에 Flutter 프로젝트·`lib/core`·`lib/features`·Android/iOS 번들 `com.studiowash.booklog`
- **설명**: 저장소 루트는 plan/spec/tracking 전용으로 두고, `flutter/`에 프로젝트 배치. `applicationId` / `namespace` = `com.studiowash.booklog`.
- **의존성**: 없음
- **우선순위**: High
- **예상 시간**: 45분
- **구현 위치**: `flutter/` (`pubspec.yaml`, `flutter/lib/`, `flutter/android/`, `flutter/ios/`)

#### Task wire-branding
- [x] **상태**: 완료
- **Task ID**: `wire-branding`
- **한 줄 요약**: 표시명·문구 단일 모듈 + 플랫폼 리소스 연결 (FR-9)
- **설명**: `flutter/lib/core/app_branding.dart`에서 `appDisplayName`. Android `android:label` → `@string/app_name`. iOS `CFBundleDisplayName`.
- **의존성**: `flutter-init`
- **우선순위**: High
- **예상 시간**: 30분
- **구현 위치**: `flutter/lib/core/`, `flutter/android/app/src/main/res/values/strings.xml`, `flutter/ios/`

#### Task persist-layer
- [x] **상태**: 완료
- **Task ID**: `persist-layer`
- **한 줄 요약**: 로컬 DB·Book / ReadingEntry 테이블
- **설명**: sqflite. 책·기록 테이블, FK, 인덱스. `AppDatabase.open`.
- **의존성**: `flutter-init`
- **우선순위**: High
- **예상 시간**: 90분
- **구현 위치**: `flutter/lib/data/app_database.dart`

#### Task router-shell
- [x] **상태**: 완료
- **Task ID**: `router-shell`
- **한 줄 요약**: 라우팅 + 앱 셸(메인·기록 진입)
- **설명**: `go_router`. `/` 잔디, `/books`, `/log`. `MaterialApp.router`.
- **의존성**: `flutter-init`
- **우선순위**: High
- **예상 시간**: 45분
- **구현 위치**: `flutter/lib/app.dart`, `flutter/lib/router/app_router.dart`

### Phase 2: 도메인·잔디

#### Task domain-grass
- [x] **상태**: 완료
- **Task ID**: `domain-grass`
- **한 줄 요약**: 월별 일→합산 페이지 맵 + 상대 농도 + 하한
- **설명**: `grass_intensity.dart`, `dayPageTotalsRolling12MonthsProvider` / `dayPageTotalsForSelectedMonthProvider`, `entriesBetween`.
- **의존성**: `persist-layer`
- **우선순위**: High
- **예상 시간**: 60분
- **구현 위치**: `flutter/lib/features/reading/domain/grass_intensity.dart`, `flutter/lib/providers.dart`, `flutter/lib/data/app_database.dart`

### Phase 3: 화면

#### Task ui-books-shelf
- [x] **상태**: 완료
- **Task ID**: `ui-books-shelf`
- **한 줄 요약**: FR-1 책 목록·추가·편집·삭제
- **설명**: `books_screen.dart`, 최근 읽은 책 정렬.
- **의존성**: `persist-layer`, `router-shell`
- **우선순위**: High
- **예상 시간**: 90분
- **구현 위치**: `flutter/lib/features/books/`

#### Task ui-grass-main
- [x] **상태**: 완료
- **Task ID**: `ui-grass-main`
- **한 줄 요약**: FR-4~6 메인 12개월 잔디·캘린더 시트·날짜 탭 바텀시트
- **설명**: 메인 `GithubContributionStrip`(12개 달·월 라벨, `entriesBetween`), 상단 캘린더 아이콘 → 월 `MonthGithubContributionStrip` 시트 + 단계 농도 + 일별 시트.
- **의존성**: `domain-grass`, `router-shell`
- **우선순위**: High
- **예상 시간**: 120분
- **구현 위치**: `flutter/lib/features/grass/grass_screen.dart`, `flutter/lib/features/grass/month_grass_grid.dart`

#### Task ui-log-entry
- [x] **상태**: 완료
- **Task ID**: `ui-log-entry`
- **한 줄 요약**: FR-2~3 기록 화면·저장 후 잔디 반영
- **설명**: 날짜·책·페이지·접힘 감상, SnackBar.
- **의존성**: `ui-books-shelf`
- **우선순위**: High
- **예상 시간**: 90분
- **구현 위치**: `flutter/lib/features/log_entry/log_entry_screen.dart`

#### Task nl-search
- [x] **상태**: 완료
- **Task ID**: `nl-search`
- **한 줄 요약**: FR-7 책 검색 API 클라이언트 (`API_BASE_URL`)
- **설명**: `book_search_api.dart`, 기본 API origin은 `api_config.dart`; `dart-define=API_BASE_URL=` 로 끄기 가능.
- **의존성**: `ui-books-shelf`
- **우선순위**: Medium
- **예상 시간**: 60분
- **구현 위치**: `flutter/lib/features/books/data/book_search_api.dart`, `flutter/lib/core/api_config.dart`

#### Task ui-finish-book
- [x] **상태**: 완료
- **Task ID**: `ui-finish-book`
- **한 줄 요약**: FR-8 완독 시 바텀시트·선택 평·DB 반영
- **설명**: 누적 페이지 vs `totalPages`, `completion_note`.
- **의존성**: `ui-log-entry`
- **우선순위**: Medium
- **예상 시간**: 60분
- **구현 위치**: `flutter/lib/features/log_entry/log_entry_screen.dart`

#### Task polish-qa
- [x] **상태**: 완료
- **Task ID**: `polish-qa`
- **한 줄 요약**: 빈 상태·분석·테스트
- **설명**: `flutter analyze` 0 이슈, `flutter test` 통과. 위젯 테스트는 `inMemoryDatabasePath` + `databaseFactoryFfiNoIsolate` (`test/flutter_test_config.dart`).
- **의존성**: `ui-grass-main`, `ui-log-entry`, `ui-finish-book`
- **우선순위**: Medium
- **예상 시간**: 60분
- **구현 위치**: `flutter/test/`

## 의존성 그래프

```
flutter-init ──┬──> wire-branding
               ├──> persist-layer ──> domain-grass
               └──> router-shell ──┬──> ui-books-shelf ──┬──> ui-log-entry ──> ui-finish-book
                                    │                     └──> nl-search
                                    └──> ui-grass-main (needs domain-grass)

ui-grass-main, ui-log-entry, ui-finish-book ──> polish-qa
```

## 변경 이력

- 2026-05-12: 잔디 **셀 크기** 확대(`GithubContributionStrip` 13→22 logical px, 간격·요일 열·모서리 비율 조정).
- 2026-05-12: **메인 잔디 = 최근 365일** 롤링 띠; **월 달력·월 이동**은 AppBar **캘린더 아이콘** 바텀시트로 이동. DB `entriesBetween`, 프로바이더 `dayPageTotalsRolling365Provider` / `dayPageTotalsForSelectedMonthProvider`.
- 2026-05-12 (revise): 메인 잔디 **12개 달** 창 + 스트립 상단 **월 약어**(달 1일이 있는 주 열); 프로바이더 `dayPageTotalsRolling12MonthsProvider` / `mainGrassWindowStart`.
- 2026-05-12: **잔디 레이아웃** — plan `260512_github_like_ref.png` 기준: **Sun-first 세로 행 + 주 단위 가로 열**, **오른쪽=최근 주**, 가로 스크롤 시 왼쪽으로 과거 주 탐색. (`MonthGithubContributionStrip`)
- 2026-05-12: **UX revise** — GitHub 기여도 그래프 색·격자·Less/More 범례(`grass_github_palette.dart`). 기록 날짜: **오늘 이전만** 선택(`showDatePicker` `lastDate`), 캘린더 시트에서 **해당 일 기록** → `/log?day=YYYY-MM-DD`. (기존 `/log?bookId=` 유지.)
- 2026-05-12: **`/code PLAN-000001 *` 완료** — 남은 태스크 전부 구현·`flutter analyze` / `flutter test` 통과, `tracking/SPEC_TRACKING.md`·feature·`data` README, spec 코드 매핑 반영. 위젯 테스트: 파일 DB + isolate FFI는 `pump`에서 교착 → `inMemoryDatabasePath` + `databaseFactoryFfiNoIsolate` (`test/flutter_test_config.dart`). 잔디: `TableCalendar` 높이/페이지 루프 방지(`sixWeekMonthsEnforced`, `pageAnimationEnabled: false`, 스와이프 끔).
- 2026-05-12 (tasks 재실행): **`flutter-init` 완료 처리** — 코드베이스 기준으로 스캐폴딩·번들 ID·`lib/core`·`lib/features` 존재 확인 후 Quick Reference·진행률 갱신.
- 2026-05-12: 저장소 레이아웃 정리 — Flutter 앱을 **`flutter/`** 하위로 두도록 `plan.md`·`tasks.md`·`spec` 반영.
