import { pool } from './pool.js';

const result = await pool.query('SELECT now() AS time');
console.log('Connected! Server time:', result.rows[0].time);
await pool.end();