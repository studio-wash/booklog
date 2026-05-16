// PLAN-000007 — ISBN normalization (Naver `isbn` field → catalog PK isbn13).

const ISBN10_LAST = /^[0-9]{9}[0-9X]$/i;

function digitsOnly(s: string): string {
  return s.replace(/[^0-9Xx]/gi, '').toUpperCase();
}

/** Split Naver-style `8960515523 9788960515529` into parts. */
export function parseIsbnCandidates(raw: string): {
  isbn10?: string;
  isbn13?: string;
} {
  const trimmed = raw.trim();
  if (!trimmed) return {};

  const tokens = trimmed.split(/\s+/).map((t) => digitsOnly(t)).filter(Boolean);
  let isbn10: string | undefined;
  let isbn13: string | undefined;

  for (const d of tokens) {
    if (d.length === 13) isbn13 = d;
    else if (d.length === 10 && ISBN10_LAST.test(d)) isbn10 = d;
  }

  if (!isbn10 && !isbn13) {
    const all = digitsOnly(trimmed);
    if (all.length === 13) isbn13 = all;
    else if (all.length === 10 && ISBN10_LAST.test(all)) isbn10 = all;
  }

  return { isbn10, isbn13 };
}

/** ISBN-10 (no hyphens) → ISBN-13 with 978 prefix. */
export function isbn10ToIsbn13(isbn10: string): string | null {
  const body = digitsOnly(isbn10);
  if (!ISBN10_LAST.test(body)) return null;
  const core = body.slice(0, 9);
  const withoutCheck = `978${core}`;
  let sum = 0;
  for (let i = 0; i < 12; i++) {
    const n = Number.parseInt(withoutCheck[i]!, 10);
    sum += n * (i % 2 === 0 ? 1 : 3);
  }
  const check = (10 - (sum % 10)) % 10;
  return `${withoutCheck}${check}`;
}

/** Catalog primary key; null when no usable ISBN. */
export function normalizeIsbn13(raw: string): string | null {
  const { isbn10, isbn13 } = parseIsbnCandidates(raw);
  if (isbn13 && isbn13.length === 13) return isbn13;
  if (isbn10) return isbn10ToIsbn13(isbn10);
  const all = digitsOnly(raw);
  if (all.length === 13) return all;
  if (all.length === 10) return isbn10ToIsbn13(all);
  return null;
}
