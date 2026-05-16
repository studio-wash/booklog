import { NextRequest } from 'next/server';
import {
  bodyToNaverFields,
  resolveCatalogTotalPages,
  type CatalogPagesBody,
} from '@/lib/catalog/resolve-pages';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';
export const maxDuration = 30;

function corsHeaders(): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };
}

export function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders() });
}

export async function POST(request: NextRequest) {
  try {
    let body: CatalogPagesBody;
    try {
      body = (await request.json()) as CatalogPagesBody;
    } catch {
      return Response.json(
        { error: 'invalid json body' },
        { status: 400, headers: corsHeaders() },
      );
    }

    if (!bodyToNaverFields(body)) {
      return Response.json(
        { error: 'isbn and title are required' },
        { status: 400, headers: corsHeaders() },
      );
    }

    const result = await resolveCatalogTotalPages(body);
    return Response.json(
      { total_pages: result.total_pages },
      { headers: corsHeaders() },
    );
  } catch (err) {
    console.error(
      JSON.stringify({
        event: 'catalog_pages_error',
        message: err instanceof Error ? err.message : String(err),
      }),
    );
    return Response.json(
      { error: 'catalog pages failed' },
      { status: 500, headers: corsHeaders() },
    );
  }
}
