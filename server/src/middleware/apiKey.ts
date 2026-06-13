import type { Context, Next } from 'hono';
import { config } from '../lib/config.js';

/**
 * Simple API key middleware for personal use.
 * Checks for x-api-key header or ?key= query param.
 */
export async function apiKeyAuth(c: Context, next: Next) {
  const headerKey = c.req.header('x-api-key');
  const queryKey = c.req.query('key');
  const providedKey = headerKey || queryKey;

  if (!providedKey || providedKey !== config.apiKey) {
    return c.json({ error: 'Unauthorized: Invalid API key' }, 401);
  }

  await next();
}
