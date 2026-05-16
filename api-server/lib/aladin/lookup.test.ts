import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { extractItemPageFromAladinJson } from './lookup';

describe('aladin lookup parse', () => {
  it('reads itemPage from subInfo', () => {
    const pages = extractItemPageFromAladinJson({
      item: [
        {
          title: 'Sample',
          subInfo: { itemPage: 368 },
        },
      ],
    });
    assert.equal(pages, 368);
  });

  it('returns null when missing', () => {
    assert.equal(extractItemPageFromAladinJson({ item: [{}] }), null);
  });
});
