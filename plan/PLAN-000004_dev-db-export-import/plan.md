# 피쳐 계획서: 개발용 DB보내기·가져오기 (스키마 갱신 시 복구)

**Plan ID**: PLAN-000004  
**생성일**: 2026-05-15

## 피쳐 아이디어

프리릴리즈·개발 중에는 **마이그레이션 없이** 스키마를 바꾸면 로컬 DB가 비거나 재생성될 수 있다. 업데이트 전에 **export**해 두고, 스키마가 바뀐 뒤에는 (필요 시 **AI·스크립트로 JSON을 최신 포맷에 맞게 변환**한 뒤) 앱의 **import**로 다시 넣어 **복구**할 수 있게 한다. 테스트 반복 시마다 수동 DB 마이그레이션을 강요하지 않는다.

## 목적

- 스키마 버전업·`onUpgrade` 드롭 등으로 **데이터가 날아가도** 개발자가 **백업·복구 루프**를 짧게 유지한다.
- 수입 데이터는 **사람/AI가 편집 가능한 텍스트(JSON)** 로 두어, 컬럼 추가·이름 변경 시에도 **앱 밖에서** 변환한 뒤 다시 넣을 수 있다.
- **운영 사용자용 클라우드 백업**이나 서버 동기화는 범위 밖(로컬·개발 우선).

## 핵심 기능

### 1. Export (보내기)

- 앱에서 **단일 JSON 파일**로 덤프한다. (SQLite 바이너리 복사는 보조로 두지 않음: AI·diff에 불리함.)
- 루트 객체에 최소 다음 키를 둔다:
  - **`export_schema_version`**: 이 포맷 자체의 버전 (예: `1`). 향후 export 포맷이 바뀌면 숫자 올림.
  - **`app_schema_version`**: 보낼 당시 `AppDatabase`의 `userVersion` (sqflite 스키마 번호).
  - **`exported_at`**: ISO-8601 UTC 문자열.
  - **`books`**: `books` 테이블 행 배열. 컬럼은 **DB 스키마와 동일한 snake_case 키**로 직렬화 (`id`, `title`, `isbn`, `image_url`, `link`, `author`, `publisher`, `description`, `pubdate`, `total_pages`, `completion_note`, `created_at` 등 현행 기준).
  - **`reading_entries`**: `reading_entries` 행 배열 (`id`, `book_id`, `calendar_date`, `pages`, `last_page_read`, `note`, `created_at`).
- JSON은 UTF-8, 사람이 읽을 수 있게 **예쁘게 출력**(indent)하는 것을 기본으로 한다.
- **저장 위치**: 플랫폼에 맞게 사용자가 고를 수 있으면 좋고, MVP는 **공유 시트**(share) 또는 **문서 디렉터리에 파일 쓰기** 중 프로젝트에 이미 있는 패턴에 맞춘다.

### 2. Import (가져오기)

- 사용자가 **JSON 파일**을 고르면 파싱한다.
- **`export_schema_version`**이 앱이 지원하는 범위인지 검사한다. 너무 오래된 export는 “지원하지 않는 export 포맷”으로 거절하거나, 별도 변환 도구 안내.
- **`books`를 먼저 삽입**하고, 구 `book_id` → **새 `id`** 매핑 테이블을 만든다. (ISBN 등 자연키로 매칭할 수 있으면 보조 검증 가능하나, 기본은 **보낸 `id` 순서**로 매핑.)
- **`reading_entries`**는 `book_id`를 위 매핑으로 치환한 뒤 삽입한다.
- **트랜잭션**: import 전체가 성공하거나 전부 롤백한다.
- **충돌 정책 (MVP)**:
  - 기본: **빈 서재에서만 import** 허용 (`books`·`reading_entries` 둘 다 비어 있을 때만). 구현·검증 단순, 실수로 덮어쓰기 방지.
  - 옵션(후속): “기존 데이터 지우고 import” 확인 다이얼로그 — 필요 시 같은 플랜의 Phase 2로 적는다.

### 3. AI·수동 변환과의 역할 분리

- 스키마가 바뀌어 **옛 export가 신규 컬럼과 맞지 않을 때**:
  - 개발자가 export JSON을 **AI 또는 스크립트**에 넘기고, **신규 스키마에 맞는 JSON**을 받는다. (앱 안에 LLM을 넣지 않는다.)
- 앱은 **현재 `export_schema_version` + 현재 테이블 정의**에 맞는 JSON만 import한다.
- `knowledge/` 또는 `flutter/lib/data/README.md`에 **export JSON 예시 한 블록**과 “스키마 변경 시 이 키를 추가했다” 수준의 **체크리스트**를 두어, AI에게 줄 때 컨텍스트로 쓰기 쉽게 한다.

## 사용자 시나리오 (개발자)

1. 스키마 바꾸기 전: 설정(또는 개발자 메뉴)에서 **Export** → JSON 저장.
2. 브랜치 전환·DB 재생성 후 앱 실행 → 서재가 비어 있음.
3. (필요 시) AI가 예전 JSON을 최신 필드명·필수값 규칙에 맞게 수정해 준다.
4. **Import** → 파일 선택 → 검증 통과 시 책·기록 복구.

## 기술적 고려사항

- **직렬화**: `Book` / `ReadingEntry` 또는 `Map`을 `jsonEncode`하기 전에 DateTime·null 처리 규칙을 한곳에 모은다 (`export_import.dart` 등).
- **파일 피커**: `file_picker` 추가 여부 vs 기존 공유 API만 사용 — 구현 시 의존성 최소화 기준으로 선택.
- **보안**: import JSON은 **신뢰된 로컬 파일**만 가정; 임의 URL fetch는 하지 않는다.
- **테스트**: round-trip(export → import on empty DB) 단위 테스트로 스키마 v2 기준 스냅샷 고정.

## MVP에서 제외

- 서버 업로드·계정별 동기화.
- 증분 merge(같은 ISBN 책이 이미 있을 때 합치기) — MVP는 빈 DB 가정으로 단순화.
- 앱 내장 “AI로 변환” 버튼.

## 성공 기준

- 동일 스키마에서 export → clear DB → import 후 **책 권수·기록 건수·주요 필드**가 일치한다.
- 문서만으로 AI가 JSON을 변환할 때 참고할 **필드 목록**이 명확하다.

## 워크플로우에서의 위치

`/tasks PLAN-000004` → `/code PLAN-000004 …` 로 구현. spec은 `/code` 단계에서 FR 추가·매핑 반영.
