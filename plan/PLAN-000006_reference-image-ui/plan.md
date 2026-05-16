# 피쳐 계획서
**Plan ID**: PLAN-000006  
**생성일**: 2026-05-15  
**레퍼런스**: `reference/reference.png` (Reading Tracker App 목업, 12화면 + 하단 네비 구조도)

## 피쳐 아이디어
`reference.png`에 맞춰 booklog 앱의 **색·타이포·카드·네비·화면별 레이아웃**을 정리된 Reading Tracker 스타일로 맞춘다. 데이터·비즈니스 로직(FR)은 유지하고 **UI/UX 표현**을 우선 갱신한다.

## 레퍼런스 자산
| 항목 | 값 |
|------|-----|
| 경로 | `plan/PLAN-000006_reference-image-ui/reference/reference.png` |
| 상태 | **등록 완료** (구현·태스크 분해 시 이 파일을 단일 진실로 사용) |
| 톤 | **배경 흰색**, **포인트·버튼·네비 검정/진회색**, 카드 **얇은 회색 테두리**. **초록은 잔디(히트맵)만** (`grass_github_palette.dart`) |

## 목적
- 디자인 요청 시 “PLAN-000006 `reference.png` 기준”으로 일관되게 구현한다.
- 현재 MVP(잔디·기록·책·완독·export)와 목업의 **갭**을 문서화해, 시각 작업과 신규 기능을 구분한다.

## 레퍼런스 화면 ↔ 현재 앱 매핑

| # | 목업 화면 | 현재 구현 | PLAN-000006 범위 |
|---|-----------|-----------|------------------|
| 1 | Home (데이터 있음) — 인사, Streak/연간 권수 칩, 히트맵, Currently Reading 카드, FAB | `grass_screen.dart`, `current_reading_card.dart`, 12개월 잔디 | **인사·요약 칩·카드·FAB 위치**를 목업에 가깝게. Streak/연간 권수는 **표시용 집계**(기존 DB로 계산 가능한 것만) |
| 2 | Record Entry — 책 선택, 큰 쪽 수, ±, 메모 | `log_entry_screen.dart` | **레이아웃·타이포·버튼** 정렬 |
| 3 | Book Search — 검색바, 탭, 최근 검색, 결과+추가 | `books_screen.dart` 검색 시트 | **검색 UI** 스타일 |
| 4 | Book Detail — 표지, 진행, Reading History, Record/Finished | 책 목록·기록은 분산, **전용 상세 화면 없음** | **1차**: 목록 행·시트 수준 스타일. **2차(별 태스크)**: 상세 라우트 `/books/:id` |
| 5 | Reading History (전체 월별) | 일 탭 시트·잔디만 | **2차**: `/history` 또는 Books 하위 목록 |
| 6 | Completion bottom sheet | `log_entry_screen` 완독 UI | **바텀시트·축하 문구·버튼** 스타일 |
| 7 | Review (별점+리뷰) | 완독 **한줄 평**만 (FR-8) | **별점 UI는 제외**. 한줄 평 입력을 목업 Review 시트 **톤**에 맞춤 |
| 8 | My Page / Profile | 없음 | **2차 이후** (통계·업적·Quotes는 신규 FR) |
| 9 | Settings | `/dev/data` 백업만 | **2차**: 설정 셸 + 기존 백업 항목 이전. Daily Goal 등은 신규 FR |
| 10 | Home (empty) | 기록 없을 때 카드 안내만 | **일러스트+카피** empty state 추가 |
| 11 | Day detail — 당일 합계·세션 타임라인 | 잔디 날 탭 **간단 ListTile** 시트 | **합계 헤더·세션 카드**로 시트 개선 |
| 12 | Bottom nav (Home / History / + / Books / Profile) | AppBar 아이콘 + FAB, **하단 탭 없음** | **1차 핵심**: `ShellRoute` + 5탭(가운데 +는 `/log`로). History·Profile은 1차에 **플레이스홀더** 또는 Books/Grass로 임시 연결 |

## 디자인 토큰 (reference.png에서 추출)

구현 시 `flutter/lib/core/app_theme.dart`(UI 크롬)와 `grass_github_palette.dart`(잔디 전용)를 **분리**한다.

| 구분 | 토큰 | 값(목업 기준) |
|------|------|----------------|
| UI | 배경 | `#FFFFFF` |
| UI | 본문·아이콘 | `#1C1B1F` (검정에 가까운 잉크) |
| UI | 보조 텍스트 | `#5F6368` |
| UI | 카드·입력 fill | 흰 배경 + `#E0E0E0` 테두리, fill `#F5F5F5` |
| UI | Primary 버튼·FAB·진행 바 | **검정** 배경 + 흰 글자 (목업 6·7·12) |
| UI | 선택 탭·리스트 하이라이트 | 연회색 `#F0F0F0` — **초록 아님** |
| **잔디만** | 히트맵 셀 | GitHub형 초록 단계 `githubGrassCellFill` (FR-5) |
| **잔디만** | 빈 셀 | `#EBEDF0` |

**금지**: `ColorScheme.primary`를 초록으로 두고 앱 전체에 쓰는 것 — 레퍼런스와 불일치.

## 핵심 기능 (구현 단계)

### Phase A — 테마·셸 (필수)
- `buildBooklogLightTheme()` 및 공통 `BooklogCard`, `SectionHeader` 등 소규모 컴포넌트.
- **하단 네비게이션 셸**: Home=`/`, History(임시=`/` 또는 placeholder), Add=`/log`, Books=`/books`, Profile(임시=Books 또는 About placeholder).
- `go_router` `ShellRoute`로 기존 라우트를 탭 안에 유지.

### Phase B — 기존 화면 스킨 (필수)
- **Home**: 상단 인사(로컬 시간대), Streak·올해 읽은 권 수(집계), 잔디, Currently Reading 카드, FAB를 목업 1번 레이아웃에 맞춤.
- **Log entry**, **Books 검색/목록**, **완독 시트**, **일별 상세 시트** — Phase A 토큰 적용.

### Phase C — 갭 메우기 (선택·후속 plan 또는 동일 plan 확장)
- 책 상세 화면, 전역 Reading History, Profile/Settings, 별점 리뷰, 업적·Quotes — **신규 FR**로 `spec` 갱신 후 별 태스크.

## 사용자 시나리오
1. 사용자가 앱을 열면 목업과 같은 **하단 탭 + 홈 대시보드**를 본다.
2. 가운데 **+**로 기록 화면에 들어가 쪽 수를 입력한다(기존 FR-2).
3. 잔디 셀·날짜를 탭하면 **당일 요약이 있는** 시트를 본다(목업 11번).
4. 책·완독 흐름은 기존과 동일하되 **시각적으로** 목업 4·6·7번과 통일감이 있다.

## 제약·원칙
- **FR-1~FR-11 동작 변경 없이** UI만 바꾸는 것을 1차 목표로 한다. 네비·집계 표시는 UX 개선이며 DB 스키마 변경은 하지 않는다.
- 목업의 **소셜·계정·푸시·다크모드 토글** 등 미구현 항목은 화면에 넣지 않거나 비활성 placeholder로 두지 않는다(혼란 방지).
- 레퍼런스 PNG는 **런타임 에셋에 포함하지 않는다**(저장소 문서용). 색·간격은 코드·테마로 재현한다.
- 스펙 동기화는 `/code` 단계에서 변경된 화면·FR에 맞춰 `spec/features/booklog-mvp/`를 갱신한다.

## 기술적 고려사항
- 주요 파일: `app_theme.dart`, `app_router.dart`, `grass_screen.dart`, `current_reading_card.dart`, `log_entry_screen.dart`, `books_screen.dart`.
- Streak: 연속 읽기 일수 — `reading_entries` 날짜 집합으로 계산(신규 provider).
- “Books this year”: `books` + `reading_entries` 연도 필터 카운트.
- 테스트: 기존 widget/DB 테스트 유지; 네비 셸 추가 시 `router` 스모크 테스트 1건 권장.

## 완료 기준 (Definition of Done)
- [ ] `reference.png`와 나란히 볼 때 **홈·기록·책 목록·하단 네비**가 같은 제품군으로 보인다.
- [ ] Phase A·B 완료; Phase C 항목은 `tasks.md`에 “후속”으로 명시되어 있다.
- [ ] `flutter analyze` / `flutter test` 통과.
