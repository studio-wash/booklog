import { neon } from '@neondatabase/serverless';

let sql: ReturnType<typeof neon> | null = null;
let schemaReady: Promise<void> | null = null;

export function getNeonSql(): ReturnType<typeof neon> {
  const url = process.env.DATABASE_URL?.trim();
  if (!url) {
    throw new Error('DATABASE_URL is required for Postgres catalog storage');
  }
  if (!sql) sql = neon(url);
  return sql;
}

/** Neon tagged-template results vary by driver version; normalize to row objects. */
export function firstRow<T extends Record<string, unknown>>(
  result: unknown,
): T | undefined {
  if (Array.isArray(result) && result.length > 0) {
    return result[0] as T;
  }
  return undefined;
}

async function ensurePgSchema(): Promise<void> {
  const s = getNeonSql();
  await s`
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
    )
  `;
  await s`
    CREATE TABLE IF NOT EXISTS aladin_daily_usage (
      day TEXT PRIMARY KEY,
      call_count INTEGER NOT NULL DEFAULT 0
    )
  `;
}

export function ensurePgReady(): Promise<void> {
  if (!schemaReady) schemaReady = ensurePgSchema();
  return schemaReady;
}

export function resetPgForTests(): void {
  sql = null;
  schemaReady = null;
}
