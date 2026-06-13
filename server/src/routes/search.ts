/**
 * Search API Routes
 * Semantic search using vector embeddings with fallback to tag-based search.
 */

import { Hono } from 'hono';
import { generateEmbedding } from '../pipeline/embedder.js';
import { searchByEmbedding, searchByTags, getItemTags, getItemCategories } from '../db/queries.js';

const search = new Hono();

// POST /api/search — Semantic search with tag-based fallback
search.post('/', async (c) => {
  try {
    const body = await c.req.json();
    const { query, threshold = 0.4, limit = 10 } = body;

    if (!query || typeof query !== 'string' || query.trim().length === 0) {
      return c.json({ error: 'Query is required' }, 400);
    }

    let results: any[] = [];
    let searchMethod = 'semantic';

    // Step 1: Try semantic search with embeddings
    try {
      const embedding = await generateEmbedding(query.trim());
      if (embedding) {
        results = await searchByEmbedding(embedding, threshold, limit);
      } else {
        // If embedding generation failed, use fallback
        searchMethod = 'tag-based (embedding unavailable)';
        results = await searchByTags(query.trim(), limit);
      }
    } catch (embedErr: any) {
      // Fallback: Use tag-based search if embeddings fail
      console.warn('[search] Embedding generation failed, using tag-based search:', embedErr.message);
      searchMethod = 'tag-based (fallback)';
      results = await searchByTags(query.trim(), limit);
    }

    // Step 2: Enrich results with tags and categories
    const enriched = await Promise.all(
      (results || []).map(async (item: any) => {
        const [tags, categories] = await Promise.all([
          getItemTags(item.id),
          getItemCategories(item.id),
        ]);
        return {
          ...item,
          tags,
          categories,
          // If similarity field exists (from semantic search), round it; otherwise use 1.0
          similarity: item.similarity ? Math.round(item.similarity * 100) / 100 : 1.0,
        };
      })
    );

    return c.json({
      query: query.trim(),
      searchMethod,
      results: enriched,
      count: enriched.length,
    });
  } catch (err: any) {
    console.error('[search POST] Error:', err);
    return c.json({ error: err.message || 'Search failed' }, 500);
  }
});

export default search;
