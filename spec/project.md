# booklog — 프로젝트 스펙 (요약)

**클라이언트**: Flutter (Android / iOS) — 코드는 **`flutter/`** 디렉터리에서 관리한다.  
**번들 ID**: `com.studiowash.booklog`  
**표시명 (현재)**: `booklog`  

## 목표

독서 기록을 **페이지 중심**으로 남기고, **월 단위 잔디**로 읽은 양을 시각화한다. MVP는 단색 잔디 + 월 내 상대적 진하기. 감상은 선택 입력.

## 피처 맵

| 피처 | 문서 |
|------|------|
| MVP (잔디·기록·서재·완독) | `spec/features/booklog-mvp/booklog-mvp.md` |

## 플랜 연동

- **PLAN-000001**: `plan/PLAN-000001_haruhanjang-mvp/plan.md`
- **PLAN-000003**: `plan/PLAN-000003_add-book-search-first/plan.md` — 새 책 추가 검색 우선 UI
- **PLAN-000005**: `plan/PLAN-000005_resume-reading-from-page/plan.md` — 앱 등록 전 읽던 마지막 쪽 기준선
- **PLAN-000006**: `plan/PLAN-000006_reference-image-ui/plan.md` — reference.png UI·하단 네비·홈 집계
- **PLAN-000007**: `plan/PLAN-000007_aladin-page-catalog/plan.md` — 서버 카탈로그·알라딘 쪽수·검색 pre-fill
- **PLAN-000008**: `plan/PLAN-000008_add-book-search-picker/plan.md` — 책 추가: Naver 검색 피커 → 폼에서 쪽수 보강
