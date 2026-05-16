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

const SERVERLESS_CATALOG_FILE = '/tmp/booklog-catalog.sqlite';

let dbSingleton: Database.Database | null = null;

export function isServerlessRuntime(): boolean {
  if (process.env.VERCEL === '1' || process.env.VERCEL_ENV) return true;
  if (process.env.AWS_LAMBDA_FUNCTION_NAME) return true;
  return process.cwd().startsWith('/var/task');
}

export function catalogDbPath(): string {
  const fromEnv = process.env.CATALOG_DB_PATH?.trim();
  if (fromEnv) {
    if (fromEnv.startsWith('/var/task')) {
      return SERVERLESS_CATALOG_FILE;
    }
    return fromEnv;
  }
  if (isServerlessRuntime()) {
    return SERVERLESS_CATALOG_FILE;
  }
  return path.join(process.cwd(), 'data', 'catalog.sqlite');
}

function ensureCatalogDirectory(file: string): void {
  const dir = path.dirname(file);
  if (dir === '/tmp') return;
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
}

export function getCatalogDb(): Database.Database {
  if (dbSingleton) return dbSingleton;
  const file = catalogDbPath();
  ensureCatalogDirectory(file);
  const db = new Database(file);
  db.pragma('journal_mode = WAL');
  db.exec(SCHEMA_SQL);
  dbSingleton = db;
  return db;
}

export function resetCatalogDbForTests(): void {
  if (dbSingleton) {
    dbSingleton.close();
    dbSingleton = null;
  }
}
