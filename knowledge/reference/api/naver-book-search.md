# 네이버 검색 API — 책

문서 출처: https://developers.naver.com/docs/serviceapi/search/book/book.md

## booklog 저장소의 호출 구조 (코드 기준, 네이버 문서와 별개 층)

- Flutter 클라이언트는 네이버 `openapi.naver.com`에 직접 붙지 않고, 배포된 Next.js API(`api-server`)에 요청한다.
- 클라이언트 요청: `GET {API_BASE_URL}/api/books/search` — 쿼리 `q`(필수), 선택 `display`, `start`, `sort`. (`q`는 네이버 문서의 `query`와 동일 역할이며 서버에서 `query`로 넘긴다.)
- 서버가 네이버에 호출하는 URL: `https://openapi.naver.com/v1/search/book.json` — 위 표의 파라미터·헤더 규칙을 따른다.

## 개요 (문서 기준)

- 책 검색은 네이버 검색 API의 일부로, 네이버 검색의 책 검색 결과를 반환하는 RESTful API이다.
- 응답 형식: XML 또는 JSON.
- 호출 시 검색어·검색 조건은 쿼리 스트링으로 전달한다.
- 검색 API 일일 호출 한도: 25,000회 (문서 기준).
- 비로그인 오픈 API: HTTP 요청 헤더에 클라이언트 아이디·클라이언트 시크릿만 전송한다.
- API 사용량은 클라이언트 아이디별로 합산된다.

## 인증 헤더

| 헤더 이름 | 값 |
|-----------|-----|
| `X-Naver-Client-Id` | 애플리케이션 등록 시 발급받은 클라이언트 아이디 |
| `X-Naver-Client-Secret` | 애플리케이션 등록 시 발급받은 클라이언트 시크릿 |

## 책 검색 결과 조회

- 프로토콜: HTTPS
- HTTP 메서드: GET

### 요청 URL

| URL | 반환 형식 |
|-----|-----------|
| `https://openapi.naver.com/v1/search/book.xml` | XML |
| `https://openapi.naver.com/v1/search/book.json` | JSON |

### 쿼리 파라미터

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `query` | String | Y | 검색어. UTF-8 인코딩 |
| `display` | Integer | N | 한 번에 표시할 결과 수. 기본 10, 최대 100 |
| `start` | Integer | N | 검색 시작 위치. 기본 1, 최대 1000 |
| `sort` | String | N | `sim`: 정확도순 내림차순(기본값), `date`: 출간일순 내림차순 |

### 응답 (XML 요소와의 대응, JSON)

문서에 따르면 XML의 `rss/channel/item` 개별 결과는 JSON에서는 `items` 배열의 요소로 반환된다.

개별 아이템 필드 (문서 표 기준):

| 요소/필드 | 타입 | 설명 |
|-----------|------|------|
| `title` | String | 책 제목 |
| `link` | String | 네이버 도서 정보 URL |
| `image` | String | 썸네일 이미지 URL |
| `author` | String | 저자 이름 |
| `discount` | Integer | 판매 가격. 절판 등으로 가격이 없으면 값이 반환되지 않을 수 있음 |
| `publisher` | String | 출판사 |
| `isbn` | Integer (문서 표기) | ISBN |
| `description` | String | 네이버 도서 책 소개 |
| `pubdate` | dateTime | 출간일 |

채널 수준 메타 (XML `rss/channel` 하위, JSON에서의 필드명은 공식 JSON 예시를 문서에서 확인):

| 요소 | 타입 | 설명 |
|------|------|------|
| `lastBuildDate` | dateTime | 검색 결과 생성 시각 |
| `total` | Integer | 총 검색 결과 개수 |
| `start` | Integer | 검색 시작 위치 |
| `display` | Integer | 한 번에 표시한 검색 결과 개수 |

## 책 상세 검색 결과 조회

- 요청 URL: `https://openapi.naver.com/v1/search/book_adv.xml`
- 프로토콜: HTTPS, 메서드: GET
- 문서: 응답은 XML 형식으로 반환한다고 명시.
- `d_titl`(책 제목)과 `d_isbn`(ISBN) 중 **1개 이상** 필수. UTF-8 인코딩.
- 공통 쿼리 파라미터: `query`(N), `display`, `start`, `sort` — 의미는 책 검색 결과 조회와 동일 범주(문서 표 기준).

## 오류 코드 (문서 표 — 책 검색)

| 코드 | HTTP | 메시지(문서) |
|------|------|----------------|
| SE01 | 400 | Incorrect query request (잘못된 쿼리요청입니다.) |
| SE02 | 400 | Invalid display value (부적절한 display 값입니다.) |
| SE03 | 400 | Invalid start value (부적절한 start 값입니다.) |
| SE04 | 400 | Invalid sort value (부적절한 sort 값입니다.) |
| SE06 | 400 | Malformed encoding (잘못된 형식의 인코딩입니다.) |
| SE05 | 404 | Invalid search api (존재하지 않는 검색 api 입니다.) |
| SE99 | 500 | System Error (시스템 에러) |

문서 별도 안내:

- **403**: 개발자 센터 애플리케이션에서 검색 API를 사용하도록 설정하지 않은 경우 발생할 수 있다. Application > 내 애플리케이션 > API 설정에서 **검색** 사용 여부를 확인한다고 명시되어 있다.
- 공통 오류 코드는 네이버 오픈API **API 공통 가이드**의 오류 코드를 참고한다고 명시되어 있다.

## 구현 예제 (문서)

- 책 검색 결과 조회 구현 예는 블로그 검색 구현 예제와 유사하다고 하며, 블로그 검색 구현 예제 문서를 참고하라고 안내한다.
