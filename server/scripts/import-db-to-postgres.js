#!/usr/bin/env node
/**
 * Yerel db.json içeriğini PostgreSQL'e aktarır.
 * Kullanım: DATABASE_URL=postgres://... node scripts/import-db-to-postgres.js
 */
const fs = require('fs');
const path = require('path');

async function main() {
  const url = process.env.DATABASE_URL;
  if (!url) {
    console.error('DATABASE_URL gerekli');
    process.exit(1);
  }

  const dbPath = path.join(__dirname, '..', 'db.json');
  if (!fs.existsSync(dbPath)) {
    console.error('db.json bulunamadı:', dbPath);
    process.exit(1);
  }

  const data = JSON.parse(fs.readFileSync(dbPath, 'utf8'));
  const { Pool } = require('pg');
  const pool = new Pool({
    connectionString: url,
    ssl: process.env.PGSSL === 'false' ? false : { rejectUnauthorized: false },
  });

  await pool.query(`
    CREATE TABLE IF NOT EXISTS pucket_data (
      id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
      data JSONB NOT NULL DEFAULT '{}'::jsonb,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  await pool.query(
    `INSERT INTO pucket_data (id, data, updated_at)
     VALUES (1, $1::jsonb, NOW())
     ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data, updated_at = NOW()`,
    [JSON.stringify(data)]
  );

  const players = Object.keys(data.players || {}).length;
  const matches = (data.matchHistory || []).length;
  console.log(`✓ İçe aktarıldı: ${players} oyuncu, ${matches} maç kaydı`);
  await pool.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
