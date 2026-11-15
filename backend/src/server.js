import { app } from "./app.js";
import { env } from "./config/env.js";

const server = app.listen(env.PORT, () => {
    console.log(`API running on http://localhost:${env.PORT}`);
});

function shutdown() {
    console.log('shutting down...');
    server.close(()=> process.exit(0));
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);