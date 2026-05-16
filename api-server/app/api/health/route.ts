import { canCallAladin, getAladinCallCount } from '@/lib/aladin/daily-limit';
import { getPostgresConnectionUrl } from '@/lib/catalog/database-url';

export const runtime = 'nodejs';

export async function GET() {
  const day = new Date().toISOString().slice(0, 10);
  const callCountToday = await getAladinCallCount(day);
  return Response.json({
    ok: true,
    service: 'booklog-api',
    ts: new Date().toISOString(),
    catalog: {
      storage: getPostgresConnectionUrl() ? 'postgres' : 'sqlite',
    },
    aladin: {
      hasTtbKey: Boolean(process.env.ALADIN_TTB_KEY?.trim()),
      callCountToday,
      canCallToday: await canCallAladin(day),
    },
  });
}
