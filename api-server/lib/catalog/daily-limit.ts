import { ensureCatalogReady, usesPostgresCatalog } from './db';
import { getCatalogDb } from './db-sqlite';
import { firstRow, getNeonSql } from './db-pg';

export const ALADIN_DAILY_LIMIT = 5000;

function todayKey(): string {
  return new Date().toISOString().slice(0, 10);
}

export async function getAladinCallCount(day: string = todayKey()): Promise<number> {
  await ensureCatalogReady();

  if (usesPostgresCatalog()) {
    const sql = getNeonSql();
    const rows = await sql`
      SELECT call_count FROM aladin_daily_usage WHERE day = ${day}
    `;
    const count = firstRow<{ call_count: number }>(rows)?.call_count;
    return count != null ? Number(count) : 0;
  }

  const row = getCatalogDb()
    .prepare('SELECT call_count FROM aladin_daily_usage WHERE day = ?')
    .get(day) as { call_count: number } | undefined;
  return row?.call_count ?? 0;
}

export async function canCallAladin(day: string = todayKey()): Promise<boolean> {
  return (await getAladinCallCount(day)) < ALADIN_DAILY_LIMIT;
}

/** Increment only after a successful ItemLookUp that returned itemPage. */
export async function incrementAladinCallCount(day: string = todayKey()): Promise<number> {
  await ensureCatalogReady();

  if (usesPostgresCatalog()) {
    const sql = getNeonSql();
    await sql`
      INSERT INTO aladin_daily_usage (day, call_count) VALUES (${day}, 1)
      ON CONFLICT (day) DO UPDATE SET
        call_count = aladin_daily_usage.call_count + 1
    `;
    return getAladinCallCount(day);
  }

  const db = getCatalogDb();
  db.prepare(
    `
    INSERT INTO aladin_daily_usage (day, call_count) VALUES (@day, 1)
    ON CONFLICT(day) DO UPDATE SET call_count = call_count + 1
    `,
  ).run({ day });
  return getAladinCallCount(day);
}
