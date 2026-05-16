export type AladinSkipReason = 'limit' | 'no_key' | 'no_match' | 'no_isbn';

export type AladinSearchMetrics = {
  attempted: number;
  enriched: number;
  skipped: Partial<Record<AladinSkipReason, number>>;
};

export function createAladinMetrics(): AladinSearchMetrics {
  return { attempted: 0, enriched: 0, skipped: {} };
}

export function recordAladinSkip(
  metrics: AladinSearchMetrics,
  reason: AladinSkipReason,
): void {
  metrics.skipped[reason] = (metrics.skipped[reason] ?? 0) + 1;
}

export function logAladinMetrics(metrics: AladinSearchMetrics, day: string, callCount: number): void {
  console.info(
    JSON.stringify({
      event: 'aladin_search_enrich',
      day,
      aladinCallCount: callCount,
      ...metrics,
    }),
  );
}
