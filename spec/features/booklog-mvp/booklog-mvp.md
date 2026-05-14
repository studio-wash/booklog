# Feature: booklog MVP

**Plan**: PLAN-000001, PLAN-000002 (메인 현재 읽기 카드)  
**구현 루트**: `flutter/lib/` (Flutter 앱은 저장소의 `flutter/` 디렉터리)

## FR 목록

| ID | 요구사항 |
|----|----------|
| FR-1 | 사용자는 **책**을 등록·수정·삭제할 수 있다. 필드: 제목(필수), 총 페이지(선택), 식별용 메타(최소). |
| FR-2 | 사용자는 **읽기 기록**을 **날짜**(당일 기본, **과거 날짜 선택·보정** 가능)·책·**마지막으로 읽은 쪽**(절대 쪽 번호)으로 저장한다. **과거 날짜**는 같은 책에 대해 **타임라인상 이전 로그의 쪽 ≤ 입력 ≤ 이후 로그의 쪽**이어야 하며, 저장 후 일별 델타(`pages`)는 책 단위로 재정렬된다. 같은 날 여러 기록 가능; 잔디 농도는 **해당 일 합산 `pages`** 기준. 진입: 기록 화면 날짜 선택, 또는 `/log?day=YYYY-MM-DD`. |
| FR-3 | 사용자는 기록 시 **느낀 점**을 선택적으로 입력한다(길이 제한 없음, 접힘 UI). |
| FR-4 | **메인 화면** 잔디는 **최근 12개 달**(오늘 포함, 해당 월 1일부터 역산) **GitHub 프로필형 띠**로 보여준다: **열=주**, **행=요일(Sun–Sat)**, **가로 스크롤**(초기는 **오른쪽=최근**). 각 **달 1일이 속한 주** 열 위에 **월 약어**(예: FEB, MAR)를 둔다. 농도는 **해당 12개월 창 안에서의 최대 일 합산 페이지** 대비 상대 비율. **월 단위 달력·월 이동**은 상단 **캘린더 아이콘**으로 연 바텀시트에서 제공한다. |
| FR-5 | 잔디 **GitHub contribution 그래프와 동일 계열 단색 초록 단계**(책별 색은 MVP 제외). |
| FR-6 | 날짜를 탭하면 해당 일의 기록 목록(책, 페이지, 감상 요약)을 볼 수 있다. |
| FR-7 | 외부 **도서 검색**(Naver 검색 API를 `api-server`에서 프록시)으로 책을 검색하고, **새 책 추가** 시 검색 결과(썸네일·제목·저자 등)에서 선택해 제목을 채운다. 검색이 꺼져 있거나 실패·미일치 시 **직접 입력**으로 제목을 넣을 수 있다. |
| FR-8 | 책에 총 페이지가 있고 기록으로 **완독**에 도달하면 축하 UI를 띄우고, **한줄 평**은 선택, **그냥 완료** 가능. |
| FR-9 | 앱 표시명·번들은 **변경 용이 구조**(`app_branding`, Gradle/Xcode 단일 진실, `@string/app_name`)를 따른다. |
| FR-10 | **메인**에서 **가장 최근에 저장한 읽기 기록**이 있는 책의 제목·**마지막으로 읽은 쪽**(해당 책 `MAX(last_page_read)`)·마지막 기록일(그 기록의 날짜)을 보여준다. 책에 총 페이지가 있으면 **진행 바**를 함께 표시한다. **메인 `+` FAB**으로 기록 화면에 들어가며, 최근 기록 책이 있으면 그 책이 **`/log?bookId=`**로 **미리 선택**된다. 기록이 없으면 안내 문구만 표시한다. |

## 구현 코드 매핑 (코드 기준)

| FR | 주요 Dart / 리소스 |
|----|-------------------|
| FR-1 | `flutter/lib/features/books/books_screen.dart`, `flutter/lib/data/app_database.dart` (`Book`, `books`) |
| FR-2 | `flutter/lib/features/log_entry/log_entry_screen.dart`, `flutter/lib/router/app_router.dart` (`day`, `bookId`), `flutter/lib/data/app_database.dart` (`insertEntry`, `lastPageBoundsForNewEntry`, per-book `pages` reconcile after insert, `ReadingEntry`, `reading_entries`), `flutter/lib/providers.dart` (`readingDataTickProvider`) |
| FR-3 | `flutter/lib/features/log_entry/log_entry_screen.dart` |
| FR-4 | `flutter/lib/features/grass/grass_screen.dart`, `month_grass_grid.dart` (`GithubContributionStrip` 월 라벨 행 + `MonthGithubContributionStrip`), `grass_intensity.dart`, `grass_github_palette.dart`, `app_database.dart` (`entriesBetween`), `providers.dart` (`dayPageTotalsRolling12MonthsProvider`, `mainGrassWindowStart`, `dayPageTotalsForSelectedMonthProvider`, `selectedMonthProvider`) |
| FR-5 | `flutter/lib/features/reading/domain/grass_github_palette.dart`, `grass_screen.dart` |
| FR-6 | `flutter/lib/features/grass/grass_screen.dart` — 날 탭 바텀시트 + 해당 일 기록 버튼 |
| FR-7 | `flutter/lib/features/books/data/book_search_hit.dart`, `book_search_api.dart` (`searchBookHits`), `core/api_config.dart`, `books_screen.dart` (검색 우선 추가 시트) |
| FR-8 | `flutter/lib/features/log_entry/log_entry_screen.dart`, `app_database.dart` (`totalPagesReadForBook`, `completion_note`) |
| FR-9 | `flutter/lib/core/app_branding.dart`, `flutter/android/.../strings.xml`, `flutter/ios/Runner/Info.plist` |
| FR-10 | `grass_screen.dart`(잔디 아래 현재 읽기 카드 + **`+` FAB** → 최근 책이 있으면 `/log?bookId=`·없으면 `/log`), `current_reading_card.dart`, `providers.dart` (`currentReadingProvider`, `CurrentReadingSnapshot`), `app_database.dart` (`latestReadingEntry`, `bookById`, `maxLastPageReadForBook`) |

## 비기능

- 로컬 우선 저장(MVP).  
- Android / iOS 빌드 가능.
