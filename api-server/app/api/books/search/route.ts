import { NextRequest } from 'next/server';
import { enrichNaverSearchItems } from '@/lib/catalog/enrich';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const NAVER_BOOK = 'https://openapi.naver.com/v1/search/book.json';

function corsHeaders(): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };
}

function parseIntParam(
  raw: string | null,
  fallback: number,
  min: number,
  max: number,
): number | null {
  if (raw == null || raw === '') return fallback;
  const n = Number.parseInt(raw, 10);
  if (!Number.isFinite(n) || n < min || n > max) return null;
  return n;
}

export function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders() });
}

export async function GET(request: NextRequest) {
  const clientId = process.env.NAVER_CLIENT_ID?.trim();
  const clientSecret = process.env.NAVER_CLIENT_SECRET?.trim();
  if (!clientId || !clientSecret) {
    return Response.json(
      { error: 'NAVER_CLIENT_ID / NAVER_CLIENT_SECRET not configured' },
      { status: 503, headers: corsHeaders() },
    );
  }

  const q = request.nextUrl.searchParams.get('q')?.trim();
  if (!q) {
    return Response.json({ error: 'missing q' }, { status: 400, headers: corsHeaders() });
  }

  const display = parseIntParam(request.nextUrl.searchParams.get('display'), 10, 1, 100);
  const start = parseIntParam(request.nextUrl.searchParams.get('start'), 1, 1, 1000);
  if (display == null || start == null) {
    return Response.json(
      { error: 'display must be 1–100, start must be 1–1000' },
      { status: 400, headers: corsHeaders() },
    );
  }

  const sortRaw = request.nextUrl.searchParams.get('sort')?.trim() ?? 'sim';
  const sort = sortRaw === 'date' ? 'date' : 'sim';

  const url = new URL(NAVER_BOOK);
  url.searchParams.set('query', q);
  url.searchParams.set('display', String(display));
  url.searchParams.set('start', String(start));
  url.searchParams.set('sort', sort);

  const res = await fetch(url.toString(), {
    headers: {
      'X-Naver-Client-Id': clientId,
      'X-Naver-Client-Secret': clientSecret,
      Accept: 'application/json',
    },
    cache: 'no-store',
  });

  const text = await res.text();
  if (!res.ok) {
    const ct = res.headers.get('content-type') ?? 'application/json;charset=utf-8';
    return new Response(text, {
      status: res.status,
      headers: { 'Content-Type': ct, ...corsHeaders() },
    });
  }

  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(text) as Record<string, unknown>;
  } catch {
    return Response.json(
      { error: 'invalid naver json' },
      { status: 502, headers: corsHeaders() },
    );
  }

  const rawItems = payload.items;
  const naverItems = Array.isArray(rawItems)
    ? rawItems.filter((it): it is Record<string, unknown> => it != null && typeof it === 'object')
    : [];

  const { items, aladinMetrics, aladinCallCount } = await enrichNaverSearchItems(
    naverItems,
    display,
  );

  return Response.json(
    {
      ...payload,
      items,
      _booklog: {
        aladinCallCountToday: aladinCallCount,
        aladinEnrich: aladinMetrics,
      },
    },
    { headers: corsHeaders() },
  );
}
