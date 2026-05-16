# Feature: booklog MVP

**Plan**: PLAN-000001, PLAN-000002 (메인 현재 읽기 카드), PLAN-000004 (개발용 JSON export/import), PLAN-000005 (앱 이전 읽던 쪽 기준선), PLAN-000006 (reference UI·하단 네비), PLAN-000007 (알라딘 카탈로그·총 페이지 pre-fill)  
**구현 루트**: `flutter/lib/` (Flutter 앱은 저장소의 `flutter/` 디렉터리)

## FR 목록

| ID | 요구사항 |
|----|----------|
| FR-1 | 사용자는 **책**을 등록·수정·삭제할 수 있다. 필드: 제목·**ISBN**(필수, DB에서 유일)·표지 URL(문자열, 빈 값 허용·UI는 플레이스홀더), 총 페이지(선택), 완독 한줄 평(선택), **앱 등록 전까지 읽은 마지막 쪽**(선택·`starting_last_page_read`, 읽기 로그가 없을 때만 수정). 네이버 검색으로 추가할 때 **저자·출판사·출간일·도서 링크** 등(가격·할인·**본문 설명** 제외)만 저장한다. API 설명은 FR-7과 같이 **검색 UI 전용**이며 DB `description` 컬럼은 **신규 저장하지 않음**(레거시·export 호환). 검색·카탈로그가 제안한 **총 페이지**는 추가 시트에 **기본값**으로만 채우며, 사용자가 **수정·비울 수 있다**. |
| FR-2 | 사용자는 **읽기 기록**을 **날짜**(당일 기본, **과거 날짜 선택·보정** 가능)·책·**마지막으로 읽은 쪽**(절대 쪽 번호)으로 저장한다. **과거 날짜**는 같은 책에 대해 **타임라인상 이전 슬롯의 마지막 쪽보다 커야** 하며(이전 슬롯이 없을 때는 책의 **기준선 페이지**가 있으면 그보다 커야 함), **이후 로그의 쪽 이하**여야 하며, 저장 후 일별 델타(`pages`)는 책 단위로 재정렬된다. 같은 날 여러 기록 가능; 잔디 농도는 **해당 일 합산 `pages`** 기준. 진입: 기록 화면 날짜 선택, 또는 `/log?day=YYYY-MM-DD`. |
| FR-3 | 사용자는 기록 시 **느낀 점**을 선택적으로 입력한다(길이 제한 없음, 접힘 UI). |
| FR-4 | **메인 화면** 잔디는 **최근 12개 달**(오늘 포함, 해당 월 1일부터 역산) **GitHub 프로필형 띠**로 보여준다: **열=주**, **행=요일(Sun–Sat)**, **가로 스크롤**(초기는 **오른쪽=최근**). 각 **달 1일이 속한 주** 열 위에 **월 약어**(예: FEB, MAR)를 둔다. 농도는 **해당 12개월 창 안에서의 최대 일 합산 페이지** 대비 상대 비율. **월 단위 달력·월 이동**은 상단 **캘린더 아이콘**으로 연 바텀시트에서 제공한다. |
| FR-5 | 잔디 **GitHub contribution 그래프와 동일 계열 단색 초록 단계**(책별 색은 MVP 제외). |
| FR-6 | 날짜를 탭하면 해당 일의 기록 목록(책, 페이지, 감상 요약)을 볼 수 있다. |
| FR-7 | 외부 **도서 검색**: `api-server`가 Naver `book.json`을 프록시하고, ISBN별 **서버 카탈로그**에 메타를 upsert한다. 카탈로그에 `total_pages`가 없으면 검색 처리 중 **알라딘 ItemLookUp**(서버·일 5,000회 한도)으로 보강할 수 있으며, 응답 `items[]`에 **`total_pages`**(nullable)를 포함한다. Flutter는 결과 목록에 **설명**을 최대 2줄까지 표시할 수 있으나 **저장하지 않는다**. 검색 결과 선택 시 **총 페이지** 입력란에 카탈로그 값을 **pre-fill**하고, **제목·ISBN·표지·저자·출판사·출간일·도서 링크** 등(가격·할인·설명 제외)만 로컬 DB에 저장한다. Aladin 키 없음·한도 소진·미매칭 시 **수동 입력**(기존과 동일). |
| FR-8 | **완독**은 기록한 **마지막 쪽**과 **총 페이지**를 분리한다. 기록 화면에서 **마지막으로 읽은 쪽**은 잔디·진행·타임라인에 그대로 반영된다(부록만 있는 꼬리 구간은 예: 280쪽에 멈춰도 됨). 책에 **총 페이지**가 있으면 **Listed length**로 표시한다. 사용자가 **「이 책 다 읽음」** 체크 시 `books.finished_at`을 저장하고 축하·한줄 평 시트를 띄운다(총 페이지에 도달하지 않아도 됨). 총 페이지까지 로그로 도달한 경우에도(체크 없이) 축하 시트를 띄울 수 있다. **한줄 평**은 선택. |
| FR-9 | 앱 표시명·번들은 **변경 용이 구조**(`app_branding`, Gradle/Xcode 단일 진실, `@string/app_name`)를 따른다. |
| FR-10 | **메인**에서 **가장 최근에 저장한 읽기 기록**이 있는 책의 제목·**마지막으로 읽은 쪽**(해당 책 `reading_entries`의 `MAX(last_page_read)`와 **기준선 페이지** 중 큰 값)·마지막 기록일(그 기록의 날짜)을 **Currently reading** 카드로 보여준다. 책에 총 페이지가 있으면 **진행 바·%**를 함께 표시한다. 카드 탭 또는 **하단 네비 중앙 `+`** 로 기록 화면(`/log`)에 들어가며, 최근 기록 책이 있으면 **`/log?bookId=`** 로 **미리 선택**된다. 기록이 없으면 **empty state** 안내를 표시한다. |
| FR-11 | **개발·백업**: 로컬 DB를 **JSON으로 export**하고, **서재·기록이 비어 있을 때만** 동일 포맷 **import**로 복원할 수 있다(스키마 변경 전 백업, 외부 편집·AI 보조용). 포맷 버전(`export_schema_version`) 검증·`book_id` 재매핑 포함. **Profile** 탭에서 진입한다. |
| FR-12 | **하단 네비 셸**: Home(`/`), History(`/history`, placeholder 가능), 중앙 **`+`** → `/log`, Books(`/books`), Profile(`/profile`). Home **인사·Streak·올해 권수** 표시. UI는 PLAN-000006 `reference.png` 톤: **흰 배경·검정/회색 포인트**(버튼·FAB·진행 바·네비), **초록은 잔디 히트맵만**(FR-5). |

## 구현 코드 매핑 (코드 기준)

| FR | 주요 Dart / 리소스 |
|----|-------------------|
| FR-1 | `flutter/lib/features/books/books_screen.dart`, `flutter/lib/data/app_database.dart` (`Book`, `books`, `starting_last_page_read`, `insertBook`, `updateBook`) |
| FR-2 | `flutter/lib/features/log_entry/log_entry_screen.dart`, `flutter/lib/router/app_router.dart` (`day`, `bookId`), `flutter/lib/data/app_database.dart` (`insertEntry`, `lastPageBoundsForNewEntry`, `_effectivePrevFloor`, per-book `pages` reconcile, `ReadingEntry`, `reading_entries`), `flutter/lib/providers.dart` (`readingDataTickProvider`) |
| FR-3 | `flutter/lib/features/log_entry/log_entry_screen.dart` |
| FR-4 | `flutter/lib/features/grass/grass_screen.dart`, `month_grass_grid.dart` (`GithubContributionStrip` 월 라벨 행 + `MonthGithubContributionStrip`), `grass_intensity.dart`, `grass_github_palette.dart`, `app_database.dart` (`entriesBetween`), `providers.dart` (`dayPageTotalsRolling12MonthsProvider`, `mainGrassWindowStart`, `dayPageTotalsForSelectedMonthProvider`, `selectedMonthProvider`) |
| FR-5 | `flutter/lib/features/reading/domain/grass_github_palette.dart`, `grass_screen.dart` |
| FR-6 | `flutter/lib/features/grass/grass_screen.dart` — 날 탭 바텀시트(당일 페이지·세션·책 수 요약 + 세션 카드) + 해당 일 기록 버튼 |
| FR-7 | Flutter: `book_search_hit.dart` (`totalPages`), `book_search_api.dart`, `books_screen.dart` (pre-fill·Aladin 출처 helper). Server: `api-server/app/api/books/search/route.ts`, `api-server/lib/catalog/*`, `api-server/lib/aladin/*` |
| FR-8 | `log_entry_screen.dart` (완독 체크·Listed length), `app_database.dart` (`finished_at`, `completion_note`, `Book.isMarkedFinished`) |
| FR-9 | `flutter/lib/core/app_branding.dart`, `flutter/android/.../strings.xml`, `flutter/ios/Runner/Info.plist` |
| FR-10 | `grass_screen.dart`, `current_reading_card.dart`, `booklog_shell_scaffold.dart` (중앙 **`+`**), `providers.dart` (`currentReadingProvider`), `app_database.dart` (`latestReadingEntry`, `maxLastPageReadForBook`) |
| FR-11 | `booklog_export_format.dart`, `app_database.dart`, `data_backup_screen.dart`, `app_router.dart` (`/dev/data`), `profile_screen.dart`, `export_import_roundtrip_test.dart`, `starting_last_page_baseline_test.dart` |
| FR-12 | `app_theme.dart`, `booklog_ui.dart`, `booklog_shell_scaffold.dart`, `app_router.dart` (`ShellRoute`), `history_placeholder_screen.dart`, `profile_screen.dart`, `providers.dart` (`readingStreakProvider`, `booksReadThisYearProvider`), `app_database.dart` (`readingStreakDays`, `distinctBooksWithLogsInYear`) |

## 비기능

- 로컬 우선 저장(MVP).  
- Android / iOS 빌드 가능.
