export async function GET() {
  return Response.json({
    ok: true,
    service: "booklog-api",
    ts: new Date().toISOString(),
  });
}
