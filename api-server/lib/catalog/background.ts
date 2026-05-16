import { waitUntil } from '@vercel/functions';

/**
 * Catalog upsert + Aladin enrich after the search HTTP response (Vercel waitUntil).
 * Locally, still schedules the promise without blocking the handler return.
 */
export function runCatalogEnrichInBackground(task: () => Promise<void>): void {
  const work = task().catch((err) => {
    console.error(
      JSON.stringify({
        event: 'catalog_enrich_background_failed',
        message: err instanceof Error ? err.message : String(err),
      }),
    );
  });

  try {
    waitUntil(work);
  } catch {
    void work;
  }
}
