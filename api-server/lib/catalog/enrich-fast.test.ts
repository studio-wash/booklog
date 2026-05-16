import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { after, before, describe, it } from 'node:test';
import { resetCatalogDbForTests } from './db';
import { attachCachedTotalPagesOnly } from './enrich-fast';
import { setCatalogTotalPagesFromAladin, upsertFromNaver } from './upsert';

const tmpDb = path.join(os.tmpdir(), `booklog-enrich-fast-${process.pid}.sqlite`);

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

describe('attachCachedTotalPagesOnly', () => {
  it('returns null pages when catalog empty', async () => {
    const items = await attachCachedTotalPagesOnly([
      { title: 'T', isbn: '9788936434267', image: '' },
    ]);
    assert.equal(items[0]?.total_pages, null);
  });

  it('reads pages already in catalog without upsert', async () => {
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
    await setCatalogTotalPagesFromAladin(isbn, 412);

    const items = await attachCachedTotalPagesOnly([
      { title: 'T', isbn, image: '' },
    ]);
    assert.equal(items[0]?.total_pages, 412);
  });
});
