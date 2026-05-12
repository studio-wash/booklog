# Grass (잔디 캘린더)

**마지막 업데이트**: 2026-05-12

## Spec 정보

- **Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md`
- **Plan 파일**: `plan/PLAN-000001_haruhanjang-mvp/plan.md`, `plan/PLAN-000002_main-current-reading/plan.md`
- **구현 상태**: ✅ 완료

## 코드 위치

- **Flutter**: `flutter/lib/features/grass/grass_screen.dart`, `flutter/lib/features/grass/month_grass_grid.dart`, `flutter/lib/features/grass/current_reading_card.dart`

## Spec-Code 매핑

| Spec 요구사항 | 코드 파일 | 상태 | 마지막 업데이트 |
|--------------|-----------|------|----------------|
| FR-4 메인 12개월 잔디·월 라벨·캘린더 시트·가로 스크롤 | `grass_screen.dart`, `month_grass_grid.dart`, `providers.dart` | ✅ | 2026-05-12 |
| FR-5 GitHub형 초록 단계 | `grass_github_palette.dart` + `grass_screen.dart` | ✅ | 2026-05-12 |
| FR-6 날 탭·해당 일 기록 | `grass_screen.dart` — `_openGrassDaySheet` → `/log?day=` | ✅ | 2026-05-12 |
| FR-10 메인 현재 읽기 카드 | `grass_screen.dart`, `current_reading_card.dart`, `providers.dart` | ✅ | 2026-05-12 |

## 생성/수정 이력

- 2026-05-12: PLAN-000002 — FR-10 **Current book** 카드(잔디 아래, `/log?bookId=`).
- 2026-05-12: 메인 **최근 12개 달** 롤링 띠 + 주 열 위 **월 약어**; **월 달력**은 AppBar 캘린더 아이콘 시트. `GithubContributionStrip` + `entriesBetween`.
- 2026-05-12: GitHub 프로필형(`260512_github_like_ref.png`) — **열=주·행=Sun–Sat**, 가로 스크롤·**초기 위치 오른쪽(최근)**; 셀은 숫자 없이 색만.
- 2026-05-12: `TableCalendar` → 커스텀 월 격자 → 위 스트립으로 정리.
- 2026-05-12: GitHub 기여도형 색·격자·범례, 시트에서 해당 일 `/log?day=` 연결
