/** Vercel+Neon often sets POSTGRES_URL; we also accept DATABASE_URL. */
export function getPostgresConnectionUrl(): string | undefined {
  for (const key of ['DATABASE_URL', 'POSTGRES_URL', 'POSTGRES_PRISMA_URL'] as const) {
    const value = process.env[key]?.trim();
    if (value) return value;
  }
  return undefined;
}
