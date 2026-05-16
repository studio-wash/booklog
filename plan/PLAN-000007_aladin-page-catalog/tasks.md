# Implementation Tasks — Aladin page catalog

**생성일**: 2026-05-15  
**Plan 파일**: `plan/PLAN-000007_aladin-page-catalog/plan.md`  
**Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md` (FR-7 확장, FR-1 `total_pages` pre-fill)

## 실행 가능한 Tasks (Quick Reference)

| Task ID | 한 줄 요약 | 상태 | 우선순위 | 의존성 | 예상 시간 |
|---------|-----------|------|----------|--------|-----------|
| `doc-aladin-api` | `knowledge/reference/api/aladin-openapi.md` 작성 | ✅ 완료 | High | - | 25분 |
| `isbn-normalize` | ISBN-13 정규화 유틸 (서버·Flutter 공통 규칙) | ✅ 완료 | High | - | 30분 |
| `env-aladin` | `ALADIN_TTB_KEY` 환경 변수·`.env.example` | ✅ 완료 | High | - | 10분 |
| `catalog-schema` | api-server 카탈로그 SQLite `book_catalog` 스키마 | ✅ 완료 | High | isbn-normalize | 35분 |
| `catalog-upsert` | 네이버 검색 item별 카탈로그 upsert (기존 `total_pages` 보존) | ✅ 완료 | High | catalog-schema | 40분 |
| `aladin-client` | Aladin ItemLookUp(ISBN) 클라이언트·`itemPage` 파싱 | ✅ 완료 | High | doc-aladin-api, env-aladin | 45분 |
| `aladin-daily-limit` | 일 5,000회 카운터·한도 시 스킵 | ✅ 완료 | High | catalog-schema | 30분 |
| `search-enrich` | 검색 시 lazy Aladin 보강 (요청당 상한) | ✅ 완료 | High | catalog-upsert, aladin-client, aladin-daily-limit | 55분 |
| `search-response` | `items[]`에 `total_pages` (nullable) 포함 응답 | ✅ 완료 | High | search-enrich | 20분 |
| `aladin-attribution` | 알라딘 출처·링크 표기 (약관 검토 반영) | ✅ 완료 | Medium | search-enrich | 20분 |
| `aladin-metrics` | 일일 호출·스킵 사유 로그/간단 카운터 | ✅ 완료 | Medium | aladin-daily-limit | 25분 |
| `hit-total-pages` | `BookSearchHit.totalPages` optional 필드·파싱 | ✅ 완료 | High | search-response | 20분 |
| `prefill-pages` | 검색 결과 선택 시 Total pages 입력란 pre-fill | ✅ 완료 | High | hit-total-pages | 25분 |
| `test-isbn-catalog` | ISBN 정규화·카탈로그 upsert·한도 단위 테스트 | ✅ 완료 | Medium | catalog-upsert, aladin-daily-limit | 40분 |
| `test-flutter-search` | 검색 JSON 파싱·pre-fill 위젯/파서 테스트 | ✅ 완료 | Medium | prefill-pages | 30분 |
| `sync-spec-fr7` | spec FR-7·FR-1·코드 매핑 갱신 | ✅ 완료 | Low | prefill-pages, search-response | 15분 |

**전체 진행률**: 100% (16/16 tasks 완료)  
**마지막 업데이트**: 2026-05-15

> **사용법**: `/code PLAN-000007 <task-id>` · 완료: `/code PLAN-000007 *`

---

## 변경 이력

- 2026-05-15: PLAN-000007 초기 `tasks.md` 생성
- 2026-05-15: `/knowledge` — `aladin-openapi.md` (`doc-aladin-api`)
- 2026-05-15: `/code PLAN-000007 *` — api-server catalog·Aladin enrich·Flutter pre-fill·tests·spec
