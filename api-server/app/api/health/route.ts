import { canCallAladin, getAladinCallCount } from '@/lib/aladin/daily-limit';

export const runtime = 'nodejs';

export async function GET() {
  const day = new Date().toISOString().slice(0, 10);
  return Response.json({
    ok: true,
    service: 'booklog-api',
    ts: new Date().toISOString(),
    aladin: {
      hasTtbKey: Boolean(process.env.ALADIN_TTB_KEY?.trim()),
      callCountToday: getAladinCallCount(day),
      canCallToday: canCallAladin(day),
    },
  });
}
