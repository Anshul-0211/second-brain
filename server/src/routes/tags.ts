/**
 * Tags & Categories API Routes
 */

import { Hono } from 'hono';
import { getAllTags, getCategories, getProfile, createProfile } from '../db/queries.js';

const tags = new Hono();

// GET /api/tags — List all tags
tags.get('/tags', async (c) => {
  try {
    const data = await getAllTags();
    return c.json({ tags: data });
  } catch (err: any) {
    console.error('[tags GET] Error:', err);
    return c.json({ error: err.message }, 500);
  }
});

// GET /api/categories — List all categories
tags.get('/categories', async (c) => {
  try {
    const data = await getCategories();
    return c.json({ categories: data });
  } catch (err: any) {
    console.error('[categories GET] Error:', err);
    return c.json({ error: err.message }, 500);
  }
});

// GET /api/profile — Get user profile
tags.get('/profile', async (c) => {
  try {
    const profile = await getProfile();
    return c.json({ profile });
  } catch (err: any) {
    console.error('[profile GET] Error:', err);
    return c.json({ error: err.message }, 500);
  }
});

// POST /api/profile — Create/signup user profile
tags.post('/profile', async (c) => {
  try {
    const body = await c.req.json();
    const { displayName } = body;

    if (!displayName || typeof displayName !== 'string') {
      return c.json({ error: 'displayName is required' }, 400);
    }

    const profile = await createProfile(displayName.trim());
    return c.json({ success: true, profile }, 201);
  } catch (err: any) {
    console.error('[profile POST] Error:', err);
    return c.json({ error: err.message }, 500);
  }
});

export default tags;
