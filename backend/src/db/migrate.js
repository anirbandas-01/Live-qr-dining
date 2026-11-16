import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool } from './pool';

const dir = path.join(path.dirname(fileURLToPath(import.meta.url)), 'migrations');


async function run() {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS schema_migration (
        name TEXT PRIMARY KEY,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
        )
    `);

    const applied = new Set (
        (await pool.query)
    )
}