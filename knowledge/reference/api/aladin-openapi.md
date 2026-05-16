# 알라딘 Open API (TTB)

문서 출처: [알라딘 Open API 매뉴얼 (Google Docs)](https://docs.google.com/document/d/1mX-WxuoGs8Hy-QalhHcvuV17n50uGI2Sg_GHofgiePE/edit?tab=t.0) — 매뉴얼 본문 기준 **최종 업데이트 2022-07-13**.

## booklog 저장소에서의 용도 (코드·plan 기준)

- `api-server`가 **서버 전용**으로 호출한다. 클라이언트에 `TTBKey`를 노출하지 않는다.
- PLAN-000007: 카탈로그에 `total_pages`가 없을 때 **상품 조회 API(ItemLookUp)** 로 ISBN 조회 후 응답의 **`itemPage`**(쪽수)를 저장·검색 응답에 포함한다.
- 네이버 책 검색 API에는 쪽수 필드가 없다 (`knowledge/reference/api/naver-book-search.md`).

## 공통

| 항목 | 내용 |
|------|------|
| 인증 | 쿼리 파라미터 **`TTBKey`** (발급받은 TTB 키 문자열) |
| 프로토콜 | HTTP GET (매뉴얼 샘플 URL은 `http://www.aladin.co.kr/ttb/api/...`) |
| API Version | 쿼리 **`Version`**, 정수형 날짜. 기본값 `20070901`, **최신 `20131101`** |
| 출력 | **`Output`**: `XML`(기본) 또는 `JS`(JSON). 매뉴얼 표기 **JS = JSON** |
| 인코딩 | **`InputEncoding`**: 검색어 인코딩 영문 이름 (기본 `utf-8`, 예: `euc-kr`) |

---

## 1. 요청 (Request)

### 1) 상품 검색 API — ItemSearch

| 항목 | 값 |
|------|-----|
| URL | `http://www.aladin.co.kr/ttb/api/ItemSearch.aspx` |
| 샘플 | `...?ttbkey=[TTBKey]&Query=aladdin&QueryType=Title&MaxResults=10&start=1&SearchTarget=Book&output=xml&Version=20131101` |
| 페이지 제한 | 한 페이지 최대 **50**건, **총 결과 최대 200**건까지 검색 가능 |

**요청 파라미터**

| 파라미터 | 필수 | 종류 | 설명 |
|----------|------|------|------|
| `TTBKey` | Y | 문자열 | TTB 키 |
| `Query` | Y | 문자열 | 검색어 |
| `QueryType` | N | 문자열 | `Keyword`(기본, 제목+저자), `Title`, `Author`, `Publisher` |
| `SearchTarget` | N | 문자열 | `Book`(기본), `Foreign`, `Music`, `DVD`, `Used`, `eBook`, `All` |
| `Start` | N | 양의 정수 | 시작 페이지 (기본 1, 1 이상) |
| `MaxResults` | N | 양의 정수 | 페이지당 최대 건수 (기본 10, **1~100**) |
| `Sort` | N | 문자열 | `Accuracy`(기본), `PublishTime`, `Title`, `SalesPoint`, `CustomerRating`, `MyReviewCount` |
| `Cover` | N | 문자열 | `Big`, `MidBig`, `Mid`(기본), `Small`, `Mini`, `None` |
| `CategoryId` | N | 양의 정수 | 분야 ID (기본 0 = 전체) |
| `Output` | N | 문자열 | `XML`(기본), `JS` |
| `Partner` | N | 문자 | 제휴 파트너 코드 |
| `includeKey` | N | 양의 정수 | `1`이면 상품 링크에 TTBKey 포함 (기본 0) |
| `InputEncoding` | N | 문자열 | 기본 `utf-8` |
| `Version` | N | 정수 날짜 | 기본 `20070901`, 최신 `20131101` |
| `outofStockfilter` | N | 양의 정수 | `1`이면 품절/절판 등 재고 없는 상품 제외 (기본 0) |
| `RecentPublishFilter` | N | 0~60 | `1`이면 최근 1개월 출간만 (기본 0 = 전체) |
| `OptResult` | N | 배열 형태 요청 | 예: `ebookList`, `usedList`, `reviewList`, `fileFormatList` |

**결과 샘플 (매뉴얼)**

- XML: `http://www.aladin.co.kr/ttb/api/test/ItemSearch_20131101.xml`
- JS: `http://www.aladin.co.kr/ttb/api/test/ItemSearch_20131101.js`

---

### 2) 상품 리스트 API — ItemList

| 항목 | 값 |
|------|-----|
| URL | `http://www.aladin.co.kr/ttb/api/ItemList.aspx` |
| 샘플 | `...?ttbkey=[TTBKey]&QueryType=ItemNewAll&MaxResults=10&start=1&SearchTarget=Book&output=xml&Version=20131101` |
| 페이지 제한 | 한 페이지 최대 **50**건, **총 결과 최대 200**건 |

**요청 파라미터 (ItemSearch와 공통·유사 항목)**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `TTBKey` | Y | TTB 키 |
| `QueryType` | Y | `ItemNewAll`, `ItemNewSpecial`, `ItemEditorChoice`, `Bestseller`, `BlogBest` 등 |
| `SearchTarget` | N | `Book`(기본), `Foreign`, `Music`, `DVD`, `Used`, `eBook`, `All` |
| `SubSearchTarget` | N | `SearchTarget=Used`일 때 `Book`, `Music`, `DVD` |
| `Start`, `MaxResults`, `Cover`, `CategoryId`, `Output`, `Partner`, `includeKey`, `InputEncoding`, `Version`, `outofStockfilter` | N | ItemSearch와 동일 의미 |
| `Year`, `Month`, `Week` | N | `QueryType=Bestseller`일 때 주간 지정 (예: `Year=2022&Month=5&Week=3`). 생략 시 현재 주간 |
| `OptResult` | N | `ebookList`, `usedList`, `reviewList`, `fileFormatList` 등 |

**결과 샘플**

- XML: `http://www.aladin.co.kr/ttb/api/test/ItemList_20131101.xml`
- JS: `http://www.aladin.co.kr/ttb/api/test/ItemList_20131101.js`

---

### 3) 상품 조회 API — ItemLookUp

| 항목 | 값 |
|------|-----|
| URL | `http://www.aladin.co.kr/ttb/api/ItemLookUp.aspx` |
| 샘플 | `...?ttbkey=[TTBKey]&itemIdType=ISBN&ItemId=[도서의ISBN]&output=xml&Version=20131101&OptResult=ebookList,usedList,reviewList` |
| 응답 | 상품 검색/리스트 API의 `item` 스펙과 동일 + **부가정보** 추가 (아래 §2-2) |

매뉴얼: **`ItemIdType`은 `ISBN13` 사용을 권장** (“가급적 13자리 ISBN을 이용해주세요”).

**요청 파라미터**

| 파라미터 | 필수 | 종류 | 설명 |
|----------|------|------|------|
| `TTBKey` | Y | 문자열 | TTB 키 |
| `ItemId` | Y | 문자열/숫자 | 상품 식별값 (`ItemIdType`에 따라 ISBN 또는 알라딘 ItemId) |
| `ItemIdType` | N | 문자열 | `ISBN`(기본, 10자리), `ISBN13`(13자리), 또는 알라딘 `ItemId` 정수 |
| `Cover` | N | 문자열 | `Big`, `MidBig`, `Mid`(기본), `Small`, `Mini`, `None` |
| `Output` | N | 문자열 | `XML`(기본), `JS` |
| `Partner` | N | 문자 | 제휴 파트너 코드 |
| `Version` | N | 정수 날짜 | 기본 `20070901`, 최신 `20131101` |
| `includeKey` | N | 양의 정수 | `1`이면 링크에 TTBKey 포함 |
| `offCode` | N | 문자열 | 중고 매장 검색 API에서 얻은 `offCode` |
| `OptResult` | N | 배열 | `ebookList`, `usedList`, `reviewList`, `fileFormatList`, `c2binfo`, `packing`, `b2bSupply`, `subbarcode`, `cardReviewImgList`, `ratingInfo`, `bestSellerRank`, `previewImgList`, `eventList`, `authors`, `reviewList`, `fulldescription`, `fulldescription2`, `Toc`, `Story`, `categoryIdList`, `mdrecommend`, `phraseList` 등 (매뉴얼 표 참고) |

**booklog 구현 시 최소 요청 예 (JSON)**

- `ItemIdType=ISBN13`, `ItemId={isbn13}`, `Output=JS`, `Version=20131101`, `TTBKey=...`
- 쪽수만 필요할 때: `OptResult` 없이도 `subInfo.itemPage`가 기본 ItemLookUp 부가정보에 포함됨 (매뉴얼 §2-2).

**결과 샘플**

- XML: `http://www.aladin.co.kr/ttb/api/test/ItemLookUp_20131101.xml`
- JS: `http://www.aladin.co.kr/ttb/api/test/ItemLookUp_20131101.js`

---

### 4) 중고상품 보유 매장 검색 API — ItemOffStoreList

| 항목 | 값 |
|------|-----|
| URL | `http://www.aladin.co.kr/ttb/api/ItemOffStoreList.aspx` |
| 샘플 | `...?ttbkey=[TTBKey]&itemIdType=ISBN&ItemId=[도서의ISBN]&output=xml` |

**요청 파라미터**

| 파라미터 | 필수 | 설명 |
|----------|------|------|
| `TTBKey` | Y | TTB 키 |
| `ItemId` | Y | 상품 식별값 |
| `ItemIdType` | N | `ISBN`(기본, 10자리), `ISBN13` |

**결과 샘플**

- XML: `http://www.aladin.co.kr/ttb/api/test/ItemOffStoreList_20131101.xml`
- JS: `http://www.aladin.co.kr/ttb/api/test/ItemOffStoreList_20131101.js`

---

## 2. 응답 (Response)

### 1) 상품 검색 / 상품 리스트 / 상품 조회 — 공통 래퍼

| 필드 | 설명 | 자료형 |
|------|------|--------|
| `version` | API Version | 정수형 날짜 |
| `title` | API 결과 제목 | 문자열 |
| `link` | 관련 알라딘 페이지 URL | URL 문자열 |
| `pubDate` | API 출력일 | 날짜 문자열 |
| `totalResults` | 총 결과 수 | 정수 |
| `startIndex` | 페이지 수 | 정수 |
| `itemsPerPage` | 한 페이지 상품 수 | 정수 |
| `query` | 조회 쿼리 | 문자열 |
| `searchCategoryId` | 분야 조회 시 분야 ID | 정수 |
| `searchCategoryName` | 분야 조회 시 분야명 | 문자열 |

### `item` (상품 1건)

| 필드 | 설명 | 자료형 |
|------|------|--------|
| `title` | 상품명 | 문자열 |
| `link` | 상품 링크 URL | URL |
| `author` | 저자/아티스트 | 문자열 |
| `pubDate` | 출간일 | 날짜 |
| `description` | 상품 설명(요약) | 문자열 |
| `isbn` | 10자리 ISBN | 문자열 |
| `isbn13` | 13자리 ISBN | 문자열 |
| `priceSales` | 판매가 | 정수 |
| `priceStandard` | 정가 | 정수 |
| `mallType` | 몰 타입 (`BOOK`, `MUSIC`, `DVD`, `FOREIGN`, `EBOOK`, `USED` 등) | 문자열 |
| `stockStatus` | 재고 상태 (정상 유통 시 비어 있을 수 있음) | 문자열 |
| `mileage` | 마일리지 | 정수 |
| `cover` | 표지 이미지 URL | URL |
| `publisher` | 출판사 | 문자열 |
| `salesPoint` | 판매지수 | 정수 |
| `adult` | 성인 등급 여부 | bool |
| `fixedPrice` | 정가제 여부 (종이책/전자책) | bool |
| `subBarcode` | 부가기호 | 문자열 |
| `customerReviewRank` | 회원 리뷰 평점 (0~10, 별 0.5당 1점) | 정수 |
| `bestDuration`, `bestRank` | 베스트셀러 시 순위 정보 | 문자열 / 정수 |
| `seriesInfo` | `seriesId`, `seriesLink`, `seriesName` | 객체 |
| `subInfo` | 부가정보 (하위 필드 다수) | 객체 |

### `subInfo` (검색·리스트·조회 공통에 등장 가능)

| 필드 | 설명 |
|------|------|
| `ebookList` | 종이책 대응 전자책 목록 (`itemId`, `isbn`, `isbn13`, `priceSales`, `link` 등) |
| `usedList` | 중고 상품 (`aladinUsed`, `userUsed`, `spaceUsed` 등) |
| `fileFormatList` | 전자책 포맷·용량 (`fileType`, `fileSize`) |

---

### 2) 상품 조회 API — 부가정보 (ItemLookUp 전용·추가)

매뉴얼: 주황색 표기 항목은 일반 스펙에 없고 **별도 협의 후 제공**될 수 있음.

**`item` 추가**

| 필드 | 설명 |
|------|------|
| `fullDescription` | 책 소개 |
| `fullDescription2` | 출판사 제공 책 소개 |
| `categoryIdList` | 전체 분야 (`categoryId`, `categoryName`) |

**`subInfo` 추가 (booklog 쪽수 연동)**

| 필드 | 설명 | 자료형 |
|------|------|--------|
| **`itemPage`** | **상품 쪽수(페이지 수)** | **숫자** |
| `subTitle` | 부제 | 문자열 |
| `originalTitle` | 원제 | 문자열 |
| `taxFree` | 비과세 여부 | bool |
| `toc` | 목차 | 문자열 |
| `previewImgList` | 미리보기 이미지 URL | URL |
| `ratingInfo` | 별점·100자평·마이리뷰 수 (`ratingScore`, `ratingCount`, …) | 객체 |
| `bestSellerRank` | 주간 베스트셀러 순위 | 문자열 |
| `authors` | 작가 정보 목록 | 배열 |
| `c2bSales`, `c2bSales_price` | 중고 C2B 매입 | 숫자 |
| `packing` | 판형·무게·크기 (`styleDesc`, `weight`, `sizeDepth`, …) | 객체 |
| `phraseList`, `mdRecommendList`, `eventList`, `reviewList`, `offStoreInfo`, `story`, … | 매뉴얼 §2-2 표 전체 | — |

---

### 3) 중고상품 보유 매장 검색 — `itemOffStoreList`

| 필드 | 설명 |
|------|------|
| `version`, `link`, `pubDate`, `query` | 래퍼 메타 |
| `offCode` | 매장 코드 |
| `offName` | 매장명 |
| `link` | 매장 상품 링크 URL |

---

## 참고 링크

- [알라딘 Open API 매뉴얼 (Google Docs)](https://docs.google.com/document/d/1mX-WxuoGs8Hy-QalhHcvuV17n50uGI2Sg_GHofgiePE/edit?tab=t.0)
- ItemSearch 샘플 XML: http://www.aladin.co.kr/ttb/api/test/ItemSearch_20131101.xml
- ItemLookUp 샘플 XML: http://www.aladin.co.kr/ttb/api/test/ItemLookUp_20131101.xml
