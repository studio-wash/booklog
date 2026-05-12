# Feature: booklog MVP

**Plan**: PLAN-000001  
**구현 루트**: `flutter/lib/` (Flutter 앱은 저장소의 `flutter/` 디렉터리)

## FR 목록

| ID | 요구사항 |
|----|----------|
| FR-1 | 사용자는 **책**을 등록·수정·삭제할 수 있다. 필드: 제목(필수), 총 페이지(선택), 식별용 메타(최소). |
| FR-2 | 사용자는 **읽기 기록**을 **날짜**(당일 기본, **과거 날짜 선택·보정** 가능 — 깜빡함·자정 넘김 등)·책·읽은 페이지 수로 저장한다. 같은 날 여러 기록 가능; 잔디 농도는 **해당 일 합산 페이지** 기준. 진입: 기록 화면 날짜 선택, 또는 `/log?day=YYYY-MM-DD`(캘린더 시트). |
| FR-3 | 사용자는 기록 시 **느낀 점**을 선택적으로 입력한다(길이 제한 없음, 접힘 UI). |
| FR-4 | **메인 화면** 잔디는 **최근 365일**(오늘 포함) **GitHub 프로필형 띠**로 보여준다: **열=주**, **행=요일(Sun–Sat)**, **가로 스크롤**(초기는 **오른쪽=최근**). 농도는 **해당 365일 창 안에서의 최대 일 합산 페이지** 대비 상대 비율. **월 단위 달력·월 이동**은 상단 **캘린더 아이콘**으로 연 바텀시트에서 제공한다. |
| FR-5 | 잔디 **GitHub contribution 그래프와 동일 계열 단색 초록 단계**(책별 색은 MVP 제외). |
| FR-6 | 날짜를 탭하면 해당 일의 기록 목록(책, 페이지, 감상 요약)을 볼 수 있다. |
| FR-7 | **국립중앙도서관 검색 API**로 책 검색·선택 시 제목 등을 채울 수 있다(실패 시 수동 입력). 엔드포인트·키는 구현 시 확정. |
| FR-8 | 책에 총 페이지가 있고 기록으로 **완독**에 도달하면 축하 UI를 띄우고, **한줄 평**은 선택, **그냥 완료** 가능. |
| FR-9 | 앱 표시명·번들은 **변경 용이 구조**(`app_branding`, Gradle/Xcode 단일 진실, `@string/app_name`)를 따른다. |

## 구현 코드 매핑 (코드 기준)

| FR | 주요 Dart / 리소스 |
|----|-------------------|
| FR-1 | `flutter/lib/features/books/books_screen.dart`, `flutter/lib/data/app_database.dart` (`Book`, `books`) |
| FR-2 | `flutter/lib/features/log_entry/log_entry_screen.dart`, `flutter/lib/router/app_router.dart` (`day`, `bookId`), `flutter/lib/data/app_database.dart` (`ReadingEntry`, `reading_entries`), `flutter/lib/providers.dart` (`readingDataTickProvider`) |
| FR-3 | `flutter/lib/features/log_entry/log_entry_screen.dart` |
| FR-4 | `flutter/lib/features/grass/grass_screen.dart`, `month_grass_grid.dart` (`GithubContributionStrip`, `MonthGithubContributionStrip`), `grass_intensity.dart`, `grass_github_palette.dart`, `app_database.dart` (`entriesBetween`), `providers.dart` (`dayPageTotalsRolling365Provider`, `dayPageTotalsForSelectedMonthProvider`, `selectedMonthProvider`) |
| FR-5 | `flutter/lib/features/reading/domain/grass_github_palette.dart`, `grass_screen.dart` |
| FR-6 | `flutter/lib/features/grass/grass_screen.dart` — 날 탭 바텀시트 + 해당 일 기록 버튼 |
| FR-7 | `flutter/lib/features/books/data/nl_api.dart`, `books_screen.dart` (NL 버튼은 정의/키 있을 때) |
| FR-8 | `flutter/lib/features/log_entry/log_entry_screen.dart`, `app_database.dart` (`totalPagesReadForBook`, `completion_note`) |
| FR-9 | `flutter/lib/core/app_branding.dart`, `flutter/android/.../strings.xml`, `flutter/ios/Runner/Info.plist` |

## 비기능

- 로컬 우선 저장(MVP).  
- Android / iOS 빌드 가능.
