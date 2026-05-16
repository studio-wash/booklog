import { getCatalogDb } from '../catalog/db';

export const ALADIN_DAILY_LIMIT = 5000;

function todayKey(): string {
  return new Date().toISOString().slice(0, 10);
}

export function getAladinCallCount(day: string = todayKey()): number {
  const row = getCatalogDb()
    .prepare('SELECT call_count FROM aladin_daily_usage WHERE day = ?')
    .get(day) as { call_count: number } | undefined;
  return row?.call_count ?? 0;
}

export function canCallAladin(day: string = todayKey()): boolean {
  return getAladinCallCount(day) < ALADIN_DAILY_LIMIT;
}

/** Increment only after a successful ItemLookUp that returned itemPage. */
export function incrementAladinCallCount(day: string = todayKey()): number {
  const db = getCatalogDb();
  db.prepare(
    `
    INSERT INTO aladin_daily_usage (day, call_count) VALUES (@day, 1)
    ON CONFLICT(day) DO UPDATE SET call_count = call_count + 1
    `,
  ).run({ day });
  return getAladinCallCount(day);
}
