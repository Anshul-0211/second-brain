/**
 * Second Brain API — Entry Point
 * Hono server with CORS, API key auth, and all routes.
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { config, validateConfig } from './lib/config.js';
import { apiKeyAuth } from './middleware/apiKey.js';
import itemsRoutes from './routes/items.js';
import searchRoutes from './routes/search.js';
import tagsRoutes from './routes/tags.js';
import remindersRoutes from './routes/reminders.js';
import recommendationRoutes from './routes/recommendations.js';
import { scheduleReminderNotifications } from './services/notificationScheduler.js';
import { setupDailyScheduler } from './services/dailyScheduler.js';

const app = new Hono();

// ── Global Middleware ──
app.use('*', logger());
app.use('*', cors({
  origin: '*', // Allow all origins (personal app)
  allowMethods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'x-api-key'],
}));

// ── Health check (no auth required) ──
app.get('/', (c) => {
  return c.json({
    name: 'Second Brain API',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString(),
  });
});

app.get('/health', (c) => {
  return c.json({ status: 'ok' });
});

// ── Protected routes ──
app.use('/api/*', apiKeyAuth);

app.route('/api/items', itemsRoutes);
app.route('/api/search', searchRoutes);
app.route('/api/reminders', remindersRoutes);
app.route('/api/recommendations', recommendationRoutes);
app.route('/api', tagsRoutes);

// ── 404 handler ──
app.notFound((c) => {
  return c.json({ error: 'Not Found' }, 404);
});

// ── Error handler ──
app.onError((err, c) => {
  console.error('Unhandled error:', err);
  return c.json({ error: 'Internal Server Error' }, 500);
});

// ── Start Server ──
const configErrors = validateConfig();
if (configErrors.length > 0) {
  console.warn('⚠️  Configuration warnings:');
  configErrors.forEach(e => console.warn(`   - ${e}`));
  console.warn('   Server will start but some features may not work.\n');
}

import { serve } from '@hono/node-server';

console.log(`
🧠 Second Brain API
────────────────────
Port: ${config.port}
Env:  ${config.nodeEnv}
────────────────────
`);

// ── Setup Notification Scheduler ──
// Run notification scheduler every 30 minutes
const notificationSchedulerInterval = setInterval(() => {
  scheduleReminderNotifications().catch((err) => {
    console.error('[notificationScheduler] Error:', err);
  });
}, 30 * 60 * 1000); // 30 minutes

// Run once on startup
scheduleReminderNotifications().catch((err) => {
  console.error('[notificationScheduler] Initial run error:', err);
});

// ── Setup Daily Recommendation Scheduler ──
// Runs at 8am UTC each day
setupDailyScheduler();

serve({
  fetch: app.fetch,
  port: config.port,
}, (info) => {
  console.log(`🚀 Server running at http://localhost:${info.port}`);
  console.log(`📬 Notification scheduler running (every 30 minutes)`);
  console.log(`🎯 Daily recommendation scheduler running (8am UTC)\n`);
});
