import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { isbn10ToIsbn13, normalizeIsbn13, parseIsbnCandidates } from './isbn';

describe('isbn', () => {
  it('parses Naver dual isbn field', () => {
    const c = parseIsbnCandidates('8960515523 9788960515529');
    assert.equal(c.isbn10, '8960515523');
    assert.equal(c.isbn13, '9788960515529');
  });

  it('converts ISBN-10 to ISBN-13', () => {
    assert.equal(isbn10ToIsbn13('8960515523'), '9788960515529');
  });

  it('normalize prefers isbn13', () => {
    assert.equal(normalizeIsbn13('8960515523 9788960515529'), '9788960515529');
  });
});
