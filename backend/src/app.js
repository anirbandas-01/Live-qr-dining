import express from 'express';
import cors from 'cors';
import { env } from './config/env.js';
import { notFound } from './middleware/notFound.js';
import { errorHandler } from './middleware/errorHandler.js';


export const app = express();

app.use(cors ({
       origin: env.CORS_ORIGIN
    })
);

app.use(express.json({
     limit: '100kb'
 }));

app.get('/api/v1/health', (req, res) => {
    res.json({ status: 'ok' , uptime: process.uptime() });
});

app.use(notFound);
app.use(errorHandler);