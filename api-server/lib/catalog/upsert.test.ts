import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { after, before, describe, it } from 'node:test';
import { resetCatalogDbForTests } from './db';
import {
  getCatalogTotalPages,
  setCatalogTotalPagesFromAladin,
  upsertFromNaver,
} from './upsert';
import { ALADIN_DAILY_LIMIT, canCallAladin, incrementAladinCallCount } from '../aladin/daily-limit';

const tmpDb = path.join(os.tmpdir(), `booklog-catalog-test-${process.pid}.sqlite`);

before(() => {
  process.env.CATALOG_DB_PATH = tmpDb;
  if (fs.existsSync(tmpDb)) fs.unlinkSync(tmpDb);
});

after(() => {
  resetCatalogDbForTests();
  if (fs.existsSync(tmpDb)) fs.unlinkSync(tmpDb);
  delete process.env.CATALOG_DB_PATH;
});

describe('catalog upsert', () => {
  it('preserves total_pages on second upsert', () => {
    const fields = {
      isbnRaw: '9788936434267',
      title: 'Test Book',
      imageUrl: '',
      author: 'Author',
      publisher: null,
      pubdate: null,
      link: null,
    };
    const isbn13 = upsertFromNaver(fields);
    assert.ok(isbn13);
    setCatalogTotalPagesFromAladin(isbn13!, 320);
    assert.equal(getCatalogTotalPages(isbn13!), 320);

    upsertFromNaver({ ...fields, title: 'Updated Title' });
    assert.equal(getCatalogTotalPages(isbn13!), 320);
  });
});

describe('aladin daily limit', () => {
  it('increments and respects limit', () => {
    const day = '2099-01-01';
    for (let i = 0; i < ALADIN_DAILY_LIMIT; i++) {
      incrementAladinCallCount(day);
    }
    assert.equal(canCallAladin(day), false);
  });
});
