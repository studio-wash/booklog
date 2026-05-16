import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { after, before, describe, it } from 'node:test';
import { resetCatalogDbForTests } from './db';
import { bodyToNaverFields, resolveCatalogTotalPages } from './resolve-pages';
import { setCatalogTotalPagesFromAladin, upsertFromNaver } from './upsert';

const tmpDb = path.join(os.tmpdir(), `booklog-resolve-pages-${process.pid}.sqlite`);

before(() => {
  delete process.env.DATABASE_URL;
  process.env.CATALOG_DB_PATH = tmpDb;
  if (fs.existsSync(tmpDb)) fs.unlinkSync(tmpDb);
});

after(() => {
  resetCatalogDbForTests();
  if (fs.existsSync(tmpDb)) fs.unlinkSync(tmpDb);
  delete process.env.CATALOG_DB_PATH;
});

describe('resolveCatalogTotalPages', () => {
  it('requires isbn and title in body', () => {
    assert.equal(bodyToNaverFields({ isbn: '9788936434267' }), null);
    assert.equal(bodyToNaverFields({ title: 'T' }), null);
  });

  it('returns cached pages without aladin key', async () => {
    const isbn = '9788936434267';
    await upsertFromNaver({
      isbnRaw: isbn,
      title: 'Cached',
      imageUrl: '',
      author: null,
      publisher: null,
      pubdate: null,
      link: null,
    });
    await setCatalogTotalPagesFromAladin(isbn, 288);

    const prev = process.env.ALADIN_TTB_KEY;
    delete process.env.ALADIN_TTB_KEY;
    try {
      const r = await resolveCatalogTotalPages({
        isbn,
        title: 'Cached',
      });
      assert.equal(r.total_pages, 288);
    } finally {
      if (prev === undefined) delete process.env.ALADIN_TTB_KEY;
      else process.env.ALADIN_TTB_KEY = prev;
    }
  });
});
