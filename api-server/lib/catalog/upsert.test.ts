import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { after, before, describe, it } from 'node:test';
import { resetCatalogDbForTests, usesPostgresCatalog } from './db';
import {
  getCatalogTotalPages,
  markAladinLookupAttempted,
  setCatalogTotalPagesFromAladin,
  upsertFromNaver,
  wasAladinLookupAttempted,
} from './upsert';
import { ALADIN_DAILY_LIMIT, canCallAladin, incrementAladinCallCount } from './daily-limit';

const tmpDb = path.join(os.tmpdir(), `booklog-catalog-test-${process.pid}.sqlite`);

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

describe('catalog upsert', () => {
  it('uses sqlite when DATABASE_URL is unset', () => {
    assert.equal(usesPostgresCatalog(), false);
  });

  it('preserves total_pages on second upsert', async () => {
    const fields = {
      isbnRaw: '9788936434267',
      title: 'Test Book',
      imageUrl: '',
      author: 'Author',
      publisher: null,
      pubdate: null,
      link: null,
    };
    const isbn13 = await upsertFromNaver(fields);
    assert.ok(isbn13);
    await setCatalogTotalPagesFromAladin(isbn13!, 320);
    assert.equal(await getCatalogTotalPages(isbn13!), 320);

    await upsertFromNaver({ ...fields, title: 'Updated Title' });
    assert.equal(await getCatalogTotalPages(isbn13!), 320);
  });

  it('marks aladin miss so lookup is not retried', async () => {
    const isbn = '9791198809834';
    await upsertFromNaver({
      isbnRaw: isbn,
      title: '전쟁과 평화의 별',
      imageUrl: '',
      author: null,
      publisher: null,
      pubdate: null,
      link: null,
    });
    assert.equal(await wasAladinLookupAttempted(isbn), false);
    await markAladinLookupAttempted(isbn);
    assert.equal(await wasAladinLookupAttempted(isbn), true);
    assert.equal(await getCatalogTotalPages(isbn), null);
  });
});

describe('aladin daily limit', () => {
  it('increments and respects limit', async () => {
    const day = '2099-01-01';
    for (let i = 0; i < ALADIN_DAILY_LIMIT; i++) {
      await incrementAladinCallCount(day);
    }
    assert.equal(await canCallAladin(day), false);
  });
});
