# 피쳐 계획서
**Plan ID**: PLAN-000007  
**생성일**: 2026-05-15

## 피쳐 아이디어
네이버 검색 결과를 **서버 카탈로그 DB**에 쌓고, **총 페이지(`total_pages`)** 가 없을 때만 **알라딘 Open API**로 보강한다. 앱에서는 값이 있으면 **총 페이지 입력란을 기본값으로 채우고**, 카탈로그·알라딘 모두 없거나 **일 5,000회 한도 소진** 시에는 **지금처럼 사용자가 직접 입력**한다.

## 현황 (코드·API 기준)

| 항목 | 현재 |
|------|------|
| 검색 | Flutter → `GET {API_BASE_URL}/api/books/search` → `api-server`가 네이버 `book.json` 프록시 (PLAN-000003, FR-7) |
| 네이버 응답 | 제목·ISBN·표지·저자·출판사·출간일·링크·설명 등 — **쪽수 필드 없음** (`knowledge/reference/api/naver-book-search.md`) |
| 사용자 서재 `books` | `total_pages`는 **추가 시트에서 수동 입력** (선택). 완독·진행률·FR-8에 사용 |
| 알라딘 | 미연동. Open API **일 5,000회** 공통 한도(기본형) |

→ “네이버 API는 쓰지만 쪽수는 유저 입력”이라는 이해가 **맞다**.

## 목적

- 같은 ISBN을 여러 사용자·여러 번 검색해도 **알라딘 호출은 서버 카탈로그에 한 번만** (한도 절약).
- 검색·책 추가 UX에서 **총 페이지를 자동 채울 수 있는 경우**를 늘린다.
- 한도·미매칭 시 **기존 수동 입력 UX는 그대로** 유지한다.

## 아키텍처 (결정)

```
[Flutter] search q
    → [api-server] GET /api/books/search
         → Naver book.json (항상)
         → ISBN별 catalog upsert (네이버 메타)
         → JSON items[] 즉시 반환 (total_pages = 카탈로그 캐시만)
         → [백그라운드] catalog upsert + (없으면) Aladin ItemLookUp → Neon 저장 (요청당 ≤3)
    → [Flutter] 추가 시트: total_pages 필드 기본값 = 응답값 (수정 가능)
    → [Flutter] insertBook → 기존 books 테이블 (로컬 서재, 변경 없음)
```

- **카탈로그 DB**: `api-server` **공유 저장소** — Vercel/프로덕션은 **Neon Postgres** (`DATABASE_URL` / `POSTGRES_URL`), 로컬은 URL 없을 때 SQLite. 앱 로컬 DB와 **분리**.
- **사용자 서재 `books`**: 읽기 기록·완독·잔디용 로컬 DB 유지. 카탈로그는 “검색·메타 보강” 전용.
- **설명(description)**: PLAN-000006 정책 유지 — 카탈로그·서재·**검색 목록 UI** 모두 Naver 본문 설명 **미사용·미표시**. (네이버 JSON에 있어도 Flutter에서 파싱하지 않음.)

## 핵심 기능

### 1. ISBN 정규화·키

- 카탈로그 PK: **ISBN-13** (없으면 ISBN-10 → 13 변환 시도, 실패 시 raw trim 보조 키).
- 네이버 `isbn` 필드는 `10자리 13자리` 공백 구분 — 파싱 규칙을 `api-server`·Flutter 공통 유틸로 둔다.

### 2. 카탈로그 upsert (네이버 검색 시)

검색 결과 **각 item**마다:

- `upsert` by `isbn13`: title, image_url, author, publisher, pubdate, link, naver_updated_at 등.
- 기존 `total_pages`가 있으면 **덮어쓰지 않음** (알라딘·이전 보강값 보존).
- 검색 노출만 하고 사용자가 추가하지 않아도 **카탈로그에는 남음** (이후 같은 ISBN 검색 시 Aladin 생략 가능).

### 3. 알라딘 페이지 보강 (조건부)

#### MVP 기본: 검색 시 lazy enrich (선택 시만은 후속)

| 방식 | MVP | 후속(PLAN-000007+) |
|------|-----|-------------------|
| **검색 시 lazy** — `GET /api/books/search` 처리 중, 카탈로그에 `total_pages` 없는 ISBN만 Aladin 시도(요청당 상한) | **채택** | 유지 |
| **선택 시만** — 사용자가 검색 결과 행을 탭·책 추가 시트를 열 때만 Aladin | 미구현 | 한도 절약·정확도 우선 시 검토 |

MVP는 **lazy**로 구현한다. 검색 직후 목록에 쪽수가 보이면 UX가 단순하고, 서버가 한 요청 안에서 네이버·카탈로그·Aladin을 묶기 쉽다. lazy로 한도 소모가 커지면 **선택 시 enrich** 또는 **인기 ISBN 우선 큐**를 후속 태스크로 분리한다.

- 대상: 카탈로그 행에 `total_pages IS NULL` (또는 0).
- **한 검색 요청당** 보강 시도 상한: 예) 결과 10건 중 **최대 10건** (네이버 `display`와 동일). 무한 루프 방지.
- **일일 호출 카운터**: `api-server`에 `aladin_calls_YYYY-MM-DD` (파일·DB·Redis 중 MVP는 SQLite/JSON 카운터). `>= 5000`이면 **Aladin 호출 스킵**, 네이버-only 응답.
- 성공 시: `total_pages`, `page_source = 'aladin'`, `aladin_enriched_at` 저장.
- 실패·미매칭: 필드 유지 NULL → 클라이언트는 수동 입력.

알라딘 API 상세는 구현 전 `knowledge/reference/api/aladin-openapi.md` 신규 작성(ItemLookUp·ISBN·`itemPage` 필드·TTB 키·출처 표기 요구).

### 4. 검색 API 응답 확장

- 기존 `items[]`에 선택 필드 추가: `total_pages` (int, nullable).
- 선택: `page_source` (`aladin` | null) — 디버그·UI 배지용, MVP는 생략 가능.

### 5. Flutter 책 추가 UX

- `BookSearchHit`에 `totalPages` optional 추가.
- 검색 결과 선택 시 **Total pages** 입력란에 **기본값 pre-fill** (비어 있으면 현재와 동일).
- 사용자가 **언제든 수정·비움** 가능. 저장 시 `books.total_pages`에 반영 (FR-1).

### 6. 폴백 (명시)

| 조건 | 동작 |
|------|------|
| 카탈로그에 `total_pages` 있음 | 입력란 기본값 채움 |
| 없음 + Aladin 한도 여유 + 매칭 성공 | 검색 응답에 포함 → 기본값 채움 |
| 없음 + 한도 소진 | Aladin 미호출, **수동 입력** (현행) |
| 없음 + Aladin 미매칭 | **수동 입력** (현행) |

## 사용자 시나리오

1. 사용자가 “원자 Habits” 검색 → 네이버 10건 반환, 서버가 카탈로그에 저장.
2. 그중 3권은 예전에 Aladin으로 페이지가 채워져 있음 → 목록/추가 시트에 **총 페이지 320** 등이 이미 들어 있음.
3. 새 책 1권은 페이지 없음 → 서버가 Aladin 1회 호출 → 368쪽 저장 → 추가 시트에 **368** pre-fill.
4. 당일 Aladin 5,000회 초과 → 새 책은 페이지 빈칸 → 사용자가 280 입력 후 저장 (완독 체크 등 기존 FR-8과 동일).

## 기술적 고려사항

### api-server

- 환경 변수: `ALADIN_TTB_KEY` (기존 `NAVER_*`와 별도).
- 카탈로그 스키마 예시 (`book_catalog`):

| 컬럼 | 설명 |
|------|------|
| `isbn13` | PK |
| `title`, `image_url`, `author`, `publisher`, `pubdate`, `link` | 네이버 |
| `total_pages` | INTEGER NULL |
| `page_source` | TEXT NULL (`aladin`) |
| `naver_cached_at`, `aladin_enriched_at` | INTEGER epoch |
| `updated_at` | INTEGER |

- Aladin 호출은 **서버에서만** (키 노출 방지).
- **Vercel**: 카탈로그·Aladin 일일 카운터는 **Neon Postgres** (`DATABASE_URL`). 로컬·테스트는 `DATABASE_URL` 없을 때 SQLite fallback.
- 출처: 알라딘 이용약관에 따라 상품 페이지·앱 내 **알라딘 링크/출처 표기** 검토 (구현 태스크에 포함).

### 보안·비용

- 카탈로그는 PII 없음(ISBN·공개 메타). 백업·마이그레이션은 api-server 배포 단위.
- Aladin 5,000/일 = **전 사용자 합산**이므로 서버 캐시가 필수. 인기 ISBN은 빠르게 채워지고 한도 소모 감소.
- **관측**: 일별 `aladin_calls`·스킵 사유(한도/미매칭)를 로그 또는 간단 카운터 API로 남겨, “갑자기 수동만 된다”는 현상을 설명·튜닝할 수 있게 한다.

### Spec 연동 (구현 시 `/code`에서 반영)

- **FR-7** 확장: 검색 응답·카탈로그 보강·`total_pages` pre-fill.
- **FR-1**: `total_pages`는 여전히 사용자 서재 필드; **출처는 카탈로그 제안값 + 수정 가능**.

## 범위 밖 (후속)

- 알라딘 **프리미엄** API(일 10만 회) 신청·운영.
- 카탈로그 **전체 동기화**·배치 잡(검색 외 ISBN 벌크 enrich).
- 네이버 `book_adv` 상세 API(별도 한도·필드 조사).

## 완료 기준

- [ ] 검색 시 네이버 결과가 서버 카탈로그에 ISBN별 upsert 된다.
- [ ] `total_pages` 없는 행만 Aladin 호출하며, 일 5,000회 초과 시 호출하지 않는다.
- [ ] Flutter 추가 시트에 페이지 기본값이 채워지고, 없을 때는 수동 입력이 가능하다.
- [ ] 기존 읽기·잔디·완독(FR-2~8) 동작 회귀 없음.
- [ ] `knowledge/reference/api/aladin-openapi.md` 및 spec FR-7 갱신.
- [ ] Aladin 일일 호출·스킵 건수를 서버에서 확인 가능(로그/카운터).

## 의존 plan

- PLAN-000003 (검색 우선 추가), PLAN-000006 (description 미저장 정책)
