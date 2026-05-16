# 피쳐 계획서

**Plan ID**: PLAN-000008  
**생성일**: 2026-05-15

## 피쳐 아이디어

책 추가를 **① Naver 검색·선택 전용 화면**과 **② 메타 입력·저장 화면**으로 분리한다. 검색 단계에서는 **우리 DB·알라딘 API를 전혀 호출하지 않고**, 선택 즉시 돌아온 뒤 **②에서만** 카탈로그 조회·(필요 시) 알라딘 보강으로 **총 페이지**를 채운다.

## 배경 (현재 불만)

- 한 바텀시트에 검색·결과·총 페이지·저장이 섞여 있어 로딩·인지 부하가 큼.
- 서버 검색 API가 Naver 이후 백그라운드 enrich를 걸어도, 사용자 체감은 “검색이 무겁다”로 남을 수 있음.
- 검색 목록에 쪽수·DB를 끼워 넣을 필요 없음 — **이미 읽는 책 찾기**가 목적.

## 목적

- 검색 UX를 **Naver 프록시 1회**에만 묶고, 로딩도 그때만 표시한다.
- 선택한 책은 **즉시** 추가 폼에 반영(제목·ISBN·표지·저자 등).
- **총 페이지**는 추가 폼에 들어온 **이후** 서버 카탈로그·알라딘으로 **비동기 pre-fill**(없으면 수동 입력 유지).

## 사용자 시나리오

1. **Books** 탭 AppBar `+` (또는 기록 화면에서 “책 추가”) → **책 검색** 전용 화면으로 이동.
2. 검색어 입력 → **Search** → 로딩(이때만) → Naver 결과 목록(표지·제목·저자·출판사, **쪽수·설명 없음**).
3. 행 탭 → **검색 화면 종료**, 선택한 `BookSearchHit`를 들고 **책 추가 폼**으로 이동(또는 pop 결과로 폼 시트 오픈).
4. 추가 폼: 선택 메타가 이미 채워짐. **총 페이지**·**이미 읽은 마지막 쪽**·저장.
5. 폼 진입 직후(백그라운드): `isbn`으로 서버에 “쪽수 있나?” 요청 → 있으면 **총 페이지 필드만** 자동 채움(사용자 수정 가능). 없으면 알라딘 1회 보강 시도 후 다시 반영(일 한도·키 없으면 스킵).

## 핵심 기능

### 1. Flutter — 책 검색 전용 화면 (`BookSearchPicker`)

- **라우트 예**: `/books/add/search` (`go_router` push, 결과는 `pop` + extra 또는 `BookSearchHit`).
- **API**: `GET {API}/api/books/search?q=...&display=10` 단, 서버는 **`catalog=0`**(이름 가칭)일 때 **백그라운드 enrich 완전 생략** — 응답 본문은 Naver `items[]` 그대로.
- UI: 검색창·Search 버튼·결과 리스트만. **저장 버튼 없음**.
- 로딩: `_searching` = 위 HTTP 호출 중만.
- 직접 ISBN/제목 입력은 **이 화면에 두지 않음** → 폼 화면 하단 보조(PLAN-000003 예외 경로 유지).

### 2. Flutter — 책 추가 폼 화면 (`AddBookForm`)

- **진입**: 검색 화면에서 선택 후만(필수 인자: `BookSearchHit`). 수동 추가는 “검색 없이 추가” 진입점 별도(빈 폼).
- 필드: 제목·ISBN·표지 URL(내부)·저자·출판사·출간일·링크(저장용), **총 페이지(선택)**, **기준선 페이지(선택)**, 저장.
- **선택 직후**: 쪽수 필드는 비어 있거나 로딩 힌트(“쪽수 불러오는 중…”, 필드 비활성화는 하지 않음).
- **폼 `initState` / `Future`**: `GET /api/books/catalog/pages?isbn13=...` (신규) 호출 → `total_pages` 오면 `_pagesCtrl` 채움.

### 3. api-server — 엔드포인트 분리

| 엔드포인트 | 용도 | DB / Aladin |
|-----------|------|-------------|
| `GET /api/books/search?...&catalog=0` | 검색 피커 전용 | **없음** (Naver만) |
| `GET /api/books/search?...` (기본) | 기존·기타 | Naver 응답 후 **백그라운드** upsert+Aladin (유지 가능) |
| `GET /api/books/catalog/pages?isbn13=` | 폼 진입 시 쪽수 | **읽기** + 없으면 **Aladin 1회** + upsert 후 반환 |

- `catalog/pages`: ISBN-13 정규화 → 카탈로그 `total_pages` 조회 → 없고 Aladin 가능하면 ItemLookUp 1회 → DB 저장 → JSON `{ total_pages: number \| null }`.
- 검색 피커가 `catalog=0`이면 `runCatalogEnrichInBackground` **호출하지 않음**.

### 4. 기록 화면(`/log`) 연동

- “책 없음 → 추가”도 동일: **검색 피커** → **추가 폼** → 저장 후 `bookId`로 기록 화면에 반영.

## 기술적 고려사항

- **PLAN-000003** 검색 우선·썸네일 리스트는 피커 화면으로 이전; 기존 `_AddBookSheetBody` 단일 시트는 **분리·축소** 또는 제거.
- **PLAN-000007** 카탈로그·Aladin은 **폼 진입 API**와 (선택) 기본 search 백그라운드에만 사용. 검색 피커와 분리해 한도·지연을 검색 UX에서 제거.
- **FR-7** 스펙: 검색 피커 = Naver only; 쪽수 pre-fill = 추가 폼 진입 후.
- **FR-1** ISBN 필수·메타 저장 정책 유지(description 미저장).
- 라우트 스택: `Books` → `SearchPicker` → `AddBookForm` → pop 시 서재. `go_router` `extra` 타입 안전(`BookSearchHit`).

## 범위 밖 (이번 plan)

- 검색 자동완성·최근 검색어(PLAN-000006 목업 수준은 후속).
- 폼에서 Aladin 출처 문구·별도 attribution UI(필요 시 소형 helperText만).
- 서버가 Naver `description` 필드를 JSON에서 제거하는 최적화(선택).

## 완료 기준

- [ ] 검색 전용 화면에서 Search 시 **Naver만** 호출되고, Neon/Aladin 로그·호출이 **0**.
- [ ] 결과 탭 시 **즉시** 추가 폼으로 넘어가고 제목·ISBN·표지 등이 채워짐.
- [ ] 추가 폼에서 **몇 초 내** 쪽수가 채워지거나(캐시/Aladin), 없으면 빈 채로 수동 입력 가능.
- [ ] 기록 화면에서도 동일 플로우.

## Plan 연동

- **대체·확장**: PLAN-000003 (검색 우선 UI), PLAN-000007 (카탈로그·쪽수) — UX만 2단계로 재배치.
- **Spec**: `booklog-mvp` FR-7·FR-1·FR-12 (Books `+` → 검색 피커) — `/code` 시 반영.
