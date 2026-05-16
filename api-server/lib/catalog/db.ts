import Database from 'better-sqlite3';
import fs from 'node:fs';
import path from 'node:path';

const SCHEMA_SQL = `
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
  naver_cached_at INTEGER,
  aladin_enriched_at INTEGER,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS aladin_daily_usage (
  day TEXT PRIMARY KEY,
  call_count INTEGER NOT NULL DEFAULT 0
);
`;

let dbSingleton: Database.Database | null = null;

export function catalogDbPath(): string {
  const fromEnv = process.env.CATALOG_DB_PATH?.trim();
  if (fromEnv) return fromEnv;
  return path.join(process.cwd(), 'data', 'catalog.sqlite');
}

export function getCatalogDb(): Database.Database {
  if (dbSingleton) return dbSingleton;
  const file = catalogDbPath();
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const db = new Database(file);
  db.pragma('journal_mode = WAL');
  db.exec(SCHEMA_SQL);
  dbSingleton = db;
  return db;
}

/** Test-only: close and reset singleton. */
export function resetCatalogDbForTests(): void {
  if (dbSingleton) {
    dbSingleton.close();
    dbSingleton = null;
  }
}

export type CatalogRow = {
  isbn13: string;
  title: string | null;
  image_url: string | null;
  author: string | null;
  publisher: string | null;
  pubdate: string | null;
  link: string | null;
  total_pages: number | null;
  page_source: string | null;
  naver_cached_at: number | null;
  aladin_enriched_at: number | null;
  updated_at: number;
};
