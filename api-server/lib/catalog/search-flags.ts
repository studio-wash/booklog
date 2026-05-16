/** When true, search must not touch catalog DB or run background enrich. */
export function isCatalogEnrichDisabled(raw: string | null | undefined): boolean {
  if (raw == null || raw === '') return false;
  const v = raw.trim().toLowerCase();
  return v === '0' || v === 'false' || v === 'no' || v === 'off';
}
