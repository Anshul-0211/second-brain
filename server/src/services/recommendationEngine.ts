/**
 * Recommendation Engine
 * 
 * Generates intelligent recommendations for daily feed
 * Scores items based on:
 * 1. Deadline urgency (items due in < 7 days)
 * 2. Freshness (unviewed items)
 * 3. Re-engagement potential (items not viewed in 7+ days)
 * 4. Related items (vector similarity - Week 3 feature)
 */

import { supabase } from '../db/client.js';



interface RecommendationScoringResult {
  itemId: string;
  score: number;
  reason: string;
  metadata: {
    urgencyScore: number;
    freshnessScore: number;
    reengagementScore: number;
    totalFactors: number;
  };
}

interface ItemWithScoring {
  id: string;
  content_raw: string;
  created_at: string;
  opened: boolean;
  view_count: number;
  last_viewed_at?: string;
}

/**
 * Calculate recommendation score for a single item
 * Returns score 0-100 and reason for recommendation
 */
export async function scoreItem(
  item: ItemWithScoring
): Promise<RecommendationScoringResult | null> {
  let totalScore = 0;
  let scoreComponents = {
    urgencyScore: 0,
    freshnessScore: 0,
    reengagementScore: 0,
    totalFactors: 0,
  };

  try {
    // ═══════════════════════════════════════════════════════════
    // 1. URGENCY SCORING: Deadline proximity
    // ═══════════════════════════════════════════════════════════
    // Get reminders for this item to check deadline urgency
    const { data: reminders } = await supabase
      .from('reminders')
      .select('due_date, priority')
      .eq('item_id', item.id)
      .eq('status', 'pending')
      .is('completed_at', null);

    if (reminders && reminders.length > 0) {
      const now = new Date();
      let daysUntilDue = Infinity;
      let highestPriority = 'low';

      for (const reminder of reminders) {
        const dueDate = new Date(reminder.due_date);
        const days = Math.ceil(
          (dueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
        );

        if (days < daysUntilDue) {
          daysUntilDue = days;
          highestPriority = reminder.priority || 'low';
        }
      }

      // Score based on deadline proximity
      // Items due today/tomorrow: 100 points
      // Items due this week: 80 points
      // Items due next week: 50 points
      // Items due later: 20 points
      // Overdue items: 95 points
      if (daysUntilDue < 0) {
        scoreComponents.urgencyScore = 95; // Overdue
      } else if (daysUntilDue === 0 || daysUntilDue === 1) {
        scoreComponents.urgencyScore = 100; // Due today/tomorrow
      } else if (daysUntilDue <= 7) {
        scoreComponents.urgencyScore = 80; // This week
      } else if (daysUntilDue <= 14) {
        scoreComponents.urgencyScore = 50; // Next week
      } else {
        scoreComponents.urgencyScore = 20; // Later
      }

      // Priority boost
      const priorityBoost: { [key: string]: number } = {
        urgent: 15,
        high: 10,
        medium: 5,
        low: 0,
      };
      scoreComponents.urgencyScore += priorityBoost[highestPriority] ?? 0;
      scoreComponents.urgencyScore = Math.min(100, scoreComponents.urgencyScore);

      totalScore += scoreComponents.urgencyScore * 0.35; // 35% weight
      scoreComponents.totalFactors++;

      console.log(`[Recommendation] Item ${item.id}: urgency=${scoreComponents.urgencyScore}, days=${daysUntilDue}`);
    }

    // ═══════════════════════════════════════════════════════════
    // 2. FRESHNESS SCORING: Unviewed items
    // ═══════════════════════════════════════════════════════════
    if (!item.opened || item.view_count === 0) {
      scoreComponents.freshnessScore = 90; // High score for unviewed
      totalScore += scoreComponents.freshnessScore * 0.40; // 40% weight
      scoreComponents.totalFactors++;

      console.log(`[Recommendation] Item ${item.id}: freshness=${scoreComponents.freshnessScore} (unviewed)`);
    } else {
      // Item was viewed, but how long ago?
      if (item.last_viewed_at) {
        const lastViewed = new Date(item.last_viewed_at);
        const now = new Date();
        const daysSinceViewed = Math.ceil(
          (now.getTime() - lastViewed.getTime()) / (1000 * 60 * 60 * 24)
        );

        // Score based on recency: older items get lower freshness scores
        // Viewed 1-2 days ago: 40 points
        // Viewed 3-7 days ago: 30 points
        // Viewed 8-14 days ago: 20 points
        // Viewed 15+ days ago: 10 points
        if (daysSinceViewed <= 2) {
          scoreComponents.freshnessScore = 40;
        } else if (daysSinceViewed <= 7) {
          scoreComponents.freshnessScore = 30;
        } else if (daysSinceViewed <= 14) {
          scoreComponents.freshnessScore = 20;
        } else {
          scoreComponents.freshnessScore = 10;
        }

        totalScore += scoreComponents.freshnessScore * 0.30; // 30% weight
        scoreComponents.totalFactors++;

        console.log(
          `[Recommendation] Item ${item.id}: freshness=${scoreComponents.freshnessScore} (viewed ${daysSinceViewed}d ago)`
        );
      }
    }

    // ═══════════════════════════════════════════════════════════
    // 3. RE-ENGAGEMENT SCORING: Items not viewed in 7+ days
    // ═══════════════════════════════════════════════════════════
    if (item.last_viewed_at) {
      const lastViewed = new Date(item.last_viewed_at);
      const now = new Date();
      const daysSinceViewed = Math.ceil(
        (now.getTime() - lastViewed.getTime()) / (1000 * 60 * 60 * 24)
      );

      if (daysSinceViewed >= 7) {
        // Strong signal for re-engagement
        scoreComponents.reengagementScore = 70;
        totalScore += scoreComponents.reengagementScore * 0.25; // 25% weight
        scoreComponents.totalFactors++;

        console.log(
          `[Recommendation] Item ${item.id}: reengagement=${scoreComponents.reengagementScore} (${daysSinceViewed}d old)`
        );
      }
    } else if (item.created_at) {
      // Never viewed, check if old enough for re-engagement
      const created = new Date(item.created_at);
      const now = new Date();
      const daysOld = Math.ceil(
        (now.getTime() - created.getTime()) / (1000 * 60 * 60 * 24)
      );

      if (daysOld >= 7) {
        scoreComponents.reengagementScore = 60;
        totalScore += scoreComponents.reengagementScore * 0.25;
        scoreComponents.totalFactors++;

        console.log(
          `[Recommendation] Item ${item.id}: reengagement=${scoreComponents.reengagementScore} (${daysOld}d old, never viewed)`
        );
      }
    }

    // ═══════════════════════════════════════════════════════════
    // Determine primary reason for recommendation
    // ═══════════════════════════════════════════════════════════
    let reason = 'other';

    if (scoreComponents.urgencyScore > 80) {
      reason = scoreComponents.totalFactors > 1 ? 'has_deadline_and_unviewed' : 'has_deadline';
    } else if (scoreComponents.freshnessScore > 70) {
      reason = 'unviewed';
    } else if (scoreComponents.reengagementScore > 50) {
      reason = 'not_viewed_recently';
    }

    // Only return if score is meaningful (> 30)
    const finalScore = Math.round(Math.min(100, totalScore));

    if (finalScore <= 30) {
      console.log(`[Recommendation] Item ${item.id}: score too low (${finalScore}), skipping`);
      return null;
    }

    console.log(
      `[Recommendation] Item ${item.id}: SCORED ${finalScore} for reason="${reason}" (factors=${scoreComponents.totalFactors})`
    );

    return {
      itemId: item.id,
      score: finalScore,
      reason,
      metadata: scoreComponents,
    };
  } catch (error) {
    console.error(`[Recommendation] Error scoring item ${item.id}:`, error);
    return null;
  }
}

/**
 * Generate daily recommendations
 * Called at 8am each day
 * Returns top 5 recommended items
 */
export async function generateDailyRecommendations(): Promise<string[]> {
  console.log('[Recommendation] ═══════════════════════════════════════════');
  console.log('[Recommendation] Starting daily recommendation generation...');
  console.log('[Recommendation] ═══════════════════════════════════════════');

  try {
    // Fetch all items with relevantfields
    const { data: items, error } = await supabase
      .from('items')
      .select(
        `
        id,
        content_raw,
        created_at,
        opened,
        view_count,
        last_viewed_at
      `
      )
      .order('created_at', { ascending: false })
      .limit(100); // Score top 100 items, return top 5

    if (error || !items) {
      console.error('[Recommendation] Error fetching items:', error);
      return [];
    }

    console.log(`[Recommendation] Fetched ${items.length} items to score`);

    // Score each item
    const scoredItems: RecommendationScoringResult[] = [];

    for (const item of items) {
      const scored = await scoreItem(item as ItemWithScoring);
      if (scored) {
        scoredItems.push(scored);
      }
    }

    console.log(
      `[Recommendation] Scored items: ${scoredItems.length} items above threshold`
    );

    // Sort by score descending
    scoredItems.sort((a, b) => b.score - a.score);

    // Take top 5
    const topRecommendations = scoredItems.slice(0, 5);

    console.log(`[Recommendation] Top recommendations: ${topRecommendations.length}`);
    for (const rec of topRecommendations) {
      console.log(`[Recommendation]   - ${rec.itemId}: ${rec.score} (${rec.reason})`);
    }

    // Delete yesterday's recommendations
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    const { error: deleteError } = await supabase
      .from('daily_recommendations')
      .delete()
      .lt('created_at', yesterday.toISOString());

    if (deleteError) {
      console.error('[Recommendation] Error deleting old recommendations:', deleteError);
    }

    // Insert new recommendations
    const recommendationsToInsert = topRecommendations.map((rec) => ({
      item_id: rec.itemId,
      score: rec.score,
      reason: rec.reason,
      metadata: rec.metadata,
    }));

    const { data: inserted, error: insertError } = await supabase
      .from('daily_recommendations')
      .insert(recommendationsToInsert)
      .select('id, item_id');

    if (insertError) {
      console.error('[Recommendation] Error inserting recommendations:', insertError);
      return [];
    }

    console.log(
      `[Recommendation] Successfully inserted ${inserted?.length ?? 0} recommendations`
    );
    console.log('[Recommendation] ═══════════════════════════════════════════');

    return (inserted ?? []).map((r) => r.item_id);
  } catch (error) {
    console.error('[Recommendation] Unexpected error in generateDailyRecommendations:', error);
    return [];
  }
}

/**
 * Get today's recommendations (excluding dismissed ones)
 */
export async function getTodayRecommendations(): Promise<any[]> {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayISO = today.toISOString();

    console.log('[Recommendation] Fetching recommendations...');
    console.log('[Recommendation] Today start:', todayISO);

    // Fetch recommendations with just the basics (items will be fetched separately in the route)
    const { data, error } = await supabase
      .from('daily_recommendations')
      .select('id, item_id, score, reason, metadata, dismissed_at, created_at')
      .gte('created_at', todayISO)
      .is('dismissed_at', null)
      .order('score', { ascending: false });

    if (error) {
      console.error('[Recommendation] Error fetching today recommendations:', error);
      return [];
    }

    console.log(`[Recommendation] Found ${data?.length ?? 0} recommendations for today`);
    if (data && data.length > 0) {
      data.slice(0, 3).forEach((r: any, i: number) => {
        console.log(`[Recommendation]   ${i + 1}. Item: ${r.item_id.substring(0, 8)}, Score: ${r.score}, Reason: ${r.reason}`);
      });
    }

    return data ?? [];
  } catch (error) {
    console.error('[Recommendation] Error in getTodayRecommendations:', error);
    return [];
  }
}

/**
 * Dismiss a recommendation
 */
export async function dismissRecommendation(
  recommendationId: string,
  itemId: string,
  reason?: string
): Promise<boolean> {
  try {
    const { error: updateError } = await supabase
      .from('daily_recommendations')
      .update({ dismissed_at: new Date().toISOString() })
      .eq('id', recommendationId);

    if (updateError) {
      console.error('[Recommendation] Error dismissing recommendation:', updateError);
      return false;
    }

    // Log dismissal reason if provided
    if (reason) {
      const { error: logError } = await supabase
        .from('recommendation_dismissals')
        .insert({
          recommendation_id: recommendationId,
          item_id: itemId,
          reason,
        });

      if (logError) {
        console.error('[Recommendation] Error logging dismissal:', logError);
      }
    }

    console.log(
      `[Recommendation] Dismissed recommendation ${recommendationId} for item ${itemId}`
    );
    return true;
  } catch (error) {
    console.error('[Recommendation] Error in dismissRecommendation:', error);
    return false;
  }
}
