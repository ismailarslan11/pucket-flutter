const fs = require('fs');
const path = require('path');
const _ = require('lodash');

const DB_FILE = path.join(__dirname, 'db.json');

class Chain {
  constructor(store) {
    this.store = store;
  }

  get(path) {
    const store = this.store;
    return {
      value: () => _.get(store.state, path),
      push: (item) => {
        let arr = _.get(store.state, path);
        if (!Array.isArray(arr)) {
          arr = [];
          _.set(store.state, path, arr);
        }
        arr.push(item);
        return new Chain(store);
      },
    };
  }

  set(path, value) {
    _.set(this.store.state, path, value);
    return this;
  }

  unset(path) {
    _.unset(this.store.state, path);
    return this;
  }

  defaults(defaults) {
    this.store.state = _.defaultsDeep(this.store.state, defaults);
    return this;
  }

  write() {
    this.store.persist();
    return this;
  }
}

class DataStore {
  constructor() {
    this.state = {};
    this.pool = null;
    this.mode = 'file';
    this._writeQueue = Promise.resolve();
  }

  async init() {
    if (process.env.DATABASE_URL) {
      const { Pool } = require('pg');
      this.mode = 'postgres';
      this.pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: process.env.PGSSL === 'false' ? false : { rejectUnauthorized: false },
      });

      await this.pool.query(`
        CREATE TABLE IF NOT EXISTS pucket_data (
          id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
          data JSONB NOT NULL DEFAULT '{}'::jsonb,
          updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
      `);

      const res = await this.pool.query('SELECT data FROM pucket_data WHERE id = 1');
      if (res.rows.length === 0) {
        let initial = {};
        if (fs.existsSync(DB_FILE)) {
          try {
            initial = JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
            console.log('PostgreSQL: mevcut db.json içe aktarılıyor…');
          } catch (err) {
            console.warn('db.json okunamadı, boş veritabanı ile başlanıyor:', err.message);
          }
        }
        await this.pool.query(
          'INSERT INTO pucket_data (id, data) VALUES (1, $1::jsonb)',
          [JSON.stringify(initial)]
        );
        this.state = initial;
      } else {
        this.state = res.rows[0].data || {};
      }
      console.log(`Veritabanı: PostgreSQL (${Object.keys(this.state.players || {}).length} oyuncu)`);
      return;
    }

    if (fs.existsSync(DB_FILE)) {
      try {
        this.state = JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
      } catch {
        this.state = {};
      }
    }
    console.log(`Veritabanı: dosya (db.json, ${Object.keys(this.state.players || {}).length} oyuncu)`);
  }

  persist() {
    if (this.mode === 'postgres' && this.pool) {
      const snapshot = _.cloneDeep(this.state);
      this._writeQueue = this._writeQueue
        .then(() =>
          this.pool.query(
            `INSERT INTO pucket_data (id, data, updated_at)
             VALUES (1, $1::jsonb, NOW())
             ON CONFLICT (id) DO UPDATE
             SET data = EXCLUDED.data, updated_at = NOW()`,
            [JSON.stringify(snapshot)]
          )
        )
        .catch((err) => console.error('PostgreSQL yazma hatası:', err.message));
      return this;
    }

    fs.writeFileSync(DB_FILE, JSON.stringify(this.state, null, 2));
    return this;
  }

  async flush() {
    await this._writeQueue;
  }

  async close() {
    await this.flush();
    if (this.pool) await this.pool.end();
  }
}

function createStore() {
  const store = new DataStore();
  const db = {
    init: () => store.init(),
    flush: () => store.flush(),
    close: () => store.close(),
    defaults(defaults) {
      return new Chain(store).defaults(defaults);
    },
    get(path) {
      return new Chain(store).get(path);
    },
    set(path, value) {
      return new Chain(store).set(path, value);
    },
    unset(path) {
      return new Chain(store).unset(path);
    },
  };
  return db;
}

module.exports = { createStore };
