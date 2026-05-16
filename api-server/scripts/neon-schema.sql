-- Optional: run once in Neon SQL Editor (tables are also created on first API request).
CREATE TABLE IF NOT EXISTS book_catalog (
  isbn13 TEXT PRIMARY KEY,
  title TEXT,
  image_url TEXT,
  author TEXT,
  publisher TEXT,
  pubdate TEXT,
  link TEXT,
  total_pages INTEGER,
  page_source TEXT,
  naver_cached_at BIGINT,
  aladin_enriched_at BIGINT,
  updated_at BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS aladin_daily_usage (
  day TEXT PRIMARY KEY,
  call_count INTEGER NOT NULL DEFAULT 0
);
