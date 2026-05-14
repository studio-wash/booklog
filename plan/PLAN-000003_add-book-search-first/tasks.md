# Implementation Tasks — 새 책 추가 검색 우선 (PLAN-000003)

**생성일**: 2026-05-13 01:28  
**Plan 파일**: `plan/PLAN-000003_add-book-search-first/plan.md`  
**Spec 파일**: `spec/features/booklog-mvp/booklog-mvp.md` (FR-1, FR-7)

## 실행 가능한 Tasks (Quick Reference)

| Task ID | 한 줄 요약 | 상태 | 우선순위 | 의존성 | 예상 시간 |
|---------|-------------|------|----------|--------|-----------|
| `book-search-hit` | `BookSearchHit` 모델 + Naver `items[]` 필드 파싱 | ✅ 완료 | High | - | 25분 |
| `book-search-api` | 검색 API가 히트 리스트·에러 힌트 반환 | ✅ 완료 | High | book-search-hit | 35분 |
| `add-book-flow-ui` | 새 책 바텀시트: 검색 우선·썸네일 목록·선택·직접 입력 접기 | ✅ 완료 | High | book-search-api | 90분 |
| `books-doc` | `books` README 및 구현 메모 정리 | ✅ 완료 | Low | add-book-flow-ui | 15분 |

**전체 진행률**: 100% (4/4 tasks 완료)  
**마지막 업데이트**: 2026-05-13

> `/code PLAN-000003 <task-id>` 또는 `/code PLAN-000003 *`

---

## Tasks 상세 목록

### Phase 1: 데이터 계층

#### Task book-search-hit

- [x] **상태**: 완료
- **Task ID**: `book-search-hit`
- **한 줄 요약**: `BookSearchHit` 모델 + Naver `items[]` 필드 파싱
- **설명**: `title`(HTML 제거), `image`(URL 문자열), `author`, `publisher` 등을 담는 불변 모델(예: `BookSearchHit`)을 추가한다. 네이버 JSON 필드는 `knowledge/reference/api/naver-book-search.md` 및 실제 응답을 기준으로 하며, 필드 누락·타입이 String이 아닌 경우 안전하게 처리한다.
- **의존성**: 없음
- **우선순위**: High
- **예상 시간**: 25분
- **구현 위치**: `flutter/lib/features/books/data/book_search_hit.dart`

#### Task book-search-api

- [x] **상태**: 완료
- **Task ID**: `book-search-api`
- **한 줄 요약**: 검색 API가 히트 리스트·에러 힌트 반환
- **설명**: `searchBookTitles`를 대체하거나 `searchBookHits` 등으로 확장해 `Future<({List<BookSearchHit> hits, String? hint})>` 형태로 통일한다. HTTP 비정상·JSON 오류·빈 `items` 시 기존과 동일하게 `hint`에 사용자 메시지를 담는다. 호출부는 `books_screen` 한 곳이므로 API 시그니처 변경 후 함께 수정한다.
- **의존성**: `book-search-hit`
- **우선순위**: High
- **예상 시간**: 35분
- **구현 위치**: `flutter/lib/features/books/data/book_search_api.dart`

### Phase 2: UI — 새 책 추가

#### Task add-book-flow-ui

- [x] **상태**: 완료
- **Task ID**: `add-book-flow-ui`
- **한 줄 요약**: 새 책 바텀시트: 검색 우선·썸네일 목록·선택·직접 입력 접기
- **설명**:
  - 상단: 검색어 필드 + 검색 트리거(명시 버튼 권장; 디바운스는 선택).
  - `bookSearchEnabled == false`일 때: 검색 블록 대신 안내 + **직접 입력**을 기본 펼침 또는 상단에 제목 필드 노출(plan의 예외 경로).
  - 결과: `ListView`/`ListTile` 등으로 스크롤 가능한 목록. `leading`: 고정 크기(48~56) `Image.network` + `errorBuilder`/placeholder.
  - 각 행: 제목(말줄임), 부제/한 줄에 `author`·`publisher` 일부.
  - 탭 시: `titleCtrl`(또는 동일 역할 상태)에 정제된 제목 반영, 선택 표시(배경 또는 체크).
  - **총 페이지** 입력과 **저장**은 목록 아래에 유지. 저장 시 기존 `insertBook` 호출.
  - 하단: `ExpansionTile` 등으로 **직접 입력**(제목·총 페이지) 접기. 검색 결과 0건·오류 시 안내 문구와 함께 직접 입력 유도.
  - 시트 높이: `isScrollControlled` + `ConstrainedBox`/`SizedBox`로 화면 비율 제한 또는 `DraggableScrollableSheet`로 키보드·긴 목록 대응(plan 정합).
- **의존성**: `book-search-api`
- **우선순위**: High
- **예상 시간**: 90분
- **구현 위치**: `flutter/lib/features/books/books_screen.dart` (`_addBook` 및 필요 시 비공개 위젯 분리)

### Phase 3: 문서

#### Task books-doc

- [x] **상태**: 완료
- **Task ID**: `books-doc`
- **한 줄 요약**: `books` README 및 구현 메모 정리
- **설명**: `flutter/lib/features/books/README.md`에 PLAN-000003 플로우(검색 우선·직접 입력 보조)·`BookSearchHit`·관련 파일 경로를 반영한다.
- **의존성**: `add-book-flow-ui`
- **우선순위**: Low
- **예상 시간**: 15분
- **구현 위치**: `flutter/lib/features/books/README.md`

## 의존성 그래프

```
book-search-hit → book-search-api → add-book-flow-ui → books-doc
```

## 변경 이력

- 2026-05-13 01:28: `tasks.md` 초기 생성 (PLAN-000003)
- 2026-05-13: `/code PLAN-000003 *` — 전 태스크 구현·spec/README 동기화
- 2026-05-13: revise — 새 책 시트 `ConsumerStatefulWidget` 분리·`CustomScrollView`로 dispose/overflow 수정
