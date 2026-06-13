/**
 * Recommendation API Routes
 * GET /api/recommendations/today - Get today's recommendations
 * POST /api/recommendations/:id/dismiss - Dismiss a recommendation
 * POST /api/admin/trigger-recommendations - Manual trigger (dev only)
 */

import { Hono } from 'hono';
import { supabase } from '../db/client.js';
import {
  getTodayRecommendations,
  dismissRecommendation,
} from '../services/recommendationEngine.js';
import { manualTriggerRecommendations } from '../services/dailyScheduler.js';

const recommendationRoutes = new Hono();

// ═══════════════════════════════════════════════════════════════
// GET /api/recommendations/today
// Retrieve today's top recommendations (excluding dismissed)
// ═══════════════════════════════════════════════════════════════
recommendationRoutes.get('/today', async (c) => {
  console.log('[RecommendationAPI] GET /api/recommendations/today');

  try {
    const recommendations = await getTodayRecommendations();

    if (!recommendations || recommendations.length === 0) {
      console.log('[RecommendationAPI] No recommendations for today');
      return c.json(
        {
          success: true,
          recommendations: [],
          count: 0,
          message: 'No recommendations available today',
        },
        200
      );
    }

    console.log(
      `[RecommendationAPI] Retrieved ${recommendations.length} recommendations`
    );

    // Get unique item IDs
    const itemIds = [...new Set(recommendations.map((r: any) => r.item_id))];
    console.log(`[RecommendationAPI] Fetching ${itemIds.length} items to enrich recommendations`);

    // Fetch full item data
    const { data: items, error: itemsError } = await supabase
      .from('items')
      .select('id, content_raw')
      .in('id', itemIds);

    if (itemsError) {
      console.error('[RecommendationAPI] Error fetching items:', itemsError);
    }

    // Create map for quick lookup
    const itemsMap: { [key: string]: any } = {};
    if (items && Array.isArray(items)) {
      items.forEach((item: any) => {
        itemsMap[item.id] = item;
      });
    }

    // Transform and enrich recommendations with full item data
    const transformed = recommendations.map((rec: any) => {
      const itemData = itemsMap[rec.item_id] || {
        id: rec.item_id,
        content_raw: `Item ${rec.item_id.substring(0, 8)}...`,
      };

      return {
        id: rec.id,
        item: itemData,
        score: rec.score,
        reason: rec.reason,
        metadata: rec.metadata,
      };
    });

    if (transformed.length > 0) {
      console.log('[RecommendationAPI] Sample item:', JSON.stringify(transformed[0]?.item).substring(0, 150));
    }

    return c.json(
      {
        success: true,
        recommendations: transformed,
        count: transformed.length,
      },
      200
    );
  } catch (error) {
    console.error('[RecommendationAPI] Error fetching recommendations:', error);
    return c.json(
      {
        success: false,
        error: 'Failed to fetch recommendations',
        details: error instanceof Error ? error.message : String(error),
      },
      500
    );
  }
});

// ═══════════════════════════════════════════════════════════════
// POST /api/recommendations/:id/dismiss
// User dismisses a recommendation
// ═══════════════════════════════════════════════════════════════
recommendationRoutes.post('/:id/dismiss', async (c) => {
  const recommendationId = c.req.param('id');
  console.log(`[RecommendationAPI] POST /api/recommendations/${recommendationId}/dismiss`);

  try {
    const body = (await c.req.json()) as {
      itemId: string;
      reason?: string;
    };

    const { itemId, reason } = body;

    if (!recommendationId || !itemId) {
      console.log('[RecommendationAPI] Missing required parameters');
      return c.json(
        {
          success: false,
          error: 'Missing recommendationId or itemId',
        },
        400
      );
    }

    const success = await dismissRecommendation(
      recommendationId,
      itemId,
      reason
    );

    if (!success) {
      console.log('[RecommendationAPI] Failed to dismiss recommendation');
      return c.json(
        {
          success: false,
          error: 'Failed to dismiss recommendation',
        },
        500
      );
    }

    console.log(
      `[RecommendationAPI] Successfully dismissed ${recommendationId} (reason: ${reason ?? 'none'})`
    );

    return c.json(
      {
        success: true,
        message: 'Recommendation dismissed',
        dismissedAt: new Date().toISOString(),
      },
      200
    );
  } catch (error) {
    console.error('[RecommendationAPI] Error dismissing recommendation:', error);
    return c.json(
      {
        success: false,
        error: 'Failed to dismiss recommendation',
        details: error instanceof Error ? error.message : String(error),
      },
      500
    );
  }
});

// ═══════════════════════════════════════════════════════════════
// POST /api/admin/trigger-recommendations
// Admin endpoint: manually trigger daily recommendation generation
// (Use for testing, would require auth in production)
// ═══════════════════════════════════════════════════════════════
recommendationRoutes.post('/admin/trigger', async (c) => {
  console.log('[RecommendationAPI] POST /api/admin/trigger-recommendations');

  // In production, verify admin token here
  // const token = c.req.header('Authorization');
  // if (!validateAdminToken(token)) {
  //   return c.json({ error: 'Unauthorized' }, 403);
  // }

  try {
    const result = await manualTriggerRecommendations();

    console.log('[RecommendationAPI] Manual trigger completed:', result);

    return c.json(
      {
        success: result.success,
        recommendationsGenerated: result.recommendationsGenerated,
        reengagementTriggered: result.reengagementTriggered,
        triggeredAt: new Date().toISOString(),
      },
      200
    );
  } catch (error) {
    console.error('[RecommendationAPI] Error triggering recommendations:', error);
    return c.json(
      {
        success: false,
        error: 'Failed to trigger recommendations',
        details: error instanceof Error ? error.message : String(error),
      },
      500
    );
  }
});

export default recommendationRoutes;
