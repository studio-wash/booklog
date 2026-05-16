import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { catalogDbPath, isServerlessRuntime } from './db-sqlite';
import { usesPostgresCatalog } from './db';

describe('catalog db path', () => {
  it('prefers postgres when DATABASE_URL is set', () => {
    const prevDb = process.env.DATABASE_URL;
    process.env.DATABASE_URL = 'postgresql://user:pass@host/db';
    try {
      assert.equal(usesPostgresCatalog(), true);
    } finally {
      if (prevDb === undefined) delete process.env.DATABASE_URL;
      else process.env.DATABASE_URL = prevDb;
    }
  });

  it('uses /tmp on Vercel env', () => {
    const prevVercel = process.env.VERCEL;
    const prevEnv = process.env.CATALOG_DB_PATH;
    const prevDb = process.env.DATABASE_URL;
    process.env.VERCEL = '1';
    delete process.env.CATALOG_DB_PATH;
    delete process.env.DATABASE_URL;
    try {
      assert.equal(catalogDbPath(), '/tmp/booklog-catalog.sqlite');
    } finally {
      if (prevVercel === undefined) delete process.env.VERCEL;
      else process.env.VERCEL = prevVercel;
      if (prevEnv === undefined) delete process.env.CATALOG_DB_PATH;
      else process.env.CATALOG_DB_PATH = prevEnv;
      if (prevDb === undefined) delete process.env.DATABASE_URL;
      else process.env.DATABASE_URL = prevDb;
    }
  });

  it('rewrites CATALOG_DB_PATH under /var/task to /tmp', () => {
    const prev = process.env.CATALOG_DB_PATH;
    const prevVercel = process.env.VERCEL;
    const prevDb = process.env.DATABASE_URL;
    delete process.env.VERCEL;
    delete process.env.DATABASE_URL;
    process.env.CATALOG_DB_PATH = '/var/task/api-server/data/catalog.sqlite';
    try {
      assert.equal(catalogDbPath(), '/tmp/booklog-catalog.sqlite');
    } finally {
      if (prev === undefined) delete process.env.CATALOG_DB_PATH;
      else process.env.CATALOG_DB_PATH = prev;
      if (prevVercel === undefined) delete process.env.VERCEL;
      else process.env.VERCEL = prevVercel;
      if (prevDb === undefined) delete process.env.DATABASE_URL;
      else process.env.DATABASE_URL = prevDb;
    }
  });

  it('detects /var/task cwd as serverless', () => {
    assert.equal(isServerlessRuntime(), process.cwd().startsWith('/var/task'));
  });
});
