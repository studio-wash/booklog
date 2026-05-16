import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { isCatalogEnrichDisabled } from './search-flags';

describe('isCatalogEnrichDisabled', () => {
  it('disables for catalog=0', () => {
    assert.equal(isCatalogEnrichDisabled('0'), true);
    assert.equal(isCatalogEnrichDisabled('false'), true);
  });

  it('enables by default', () => {
    assert.equal(isCatalogEnrichDisabled(null), false);
    assert.equal(isCatalogEnrichDisabled('1'), false);
  });
});
