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
        (await pool.query('SELECT name FROM schema_migrations')).rows.map((r) => r.name),
    );

    const files = ( await fs.readdir(dir)).filter((f) => f.endsWith('.sql')).sort();

    for (const file of files ) {
        if(applied.has(file)) continue;

        const sql = await fs.readFile(path.join(dir, file), 'utf-8');
        const client = await pool.connect();

        try{
            await client.query('BEGIN');
            await client.query(sql);
            await client.query('INSERT INTO schema_migrations (name) VALUES ($1)', [file]);
            await client.query('COMMIT');
        }catch (err){
            await client.query('ROLLBACK');
            console.error(`Failed: ${file}`);
            throw err;
        } finally {
            client.release();
        }
    }

    console.log('Migration up to date.');
    await pool.end();
}

run().catch((err) => {
    console.error(err);
    process.exit(1);
});