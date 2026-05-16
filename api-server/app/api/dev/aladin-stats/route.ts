import { ALADIN_DAILY_LIMIT, canCallAladin, getAladinCallCount } from '@/lib/aladin/daily-limit';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET() {
  const day = new Date().toISOString().slice(0, 10);
  const callCount = await getAladinCallCount(day);
  const hasKey = Boolean(process.env.ALADIN_TTB_KEY?.trim());

  return Response.json({
    day,
    callCount,
    dailyLimit: ALADIN_DAILY_LIMIT,
    canCall: hasKey && (await canCallAladin(day)),
    hasTtbKey: hasKey,
  });
}
