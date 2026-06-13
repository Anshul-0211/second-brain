/**
 * Daily Recommendation Scheduler
 * 
 * Runs every day at 8am (UTC or server timezone)
 * Generates and stores daily recommendations
 * Checks for items needing re-engagement notifications (7+ days unseen)
 */

import { generateDailyRecommendations } from './recommendationEngine.js';
import { supabase } from '../db/client.js';



/**
 * Check if it's time to run daily recommendations (8am UTC)
 * Use this for on-demand trigger checks
 */
export function isRecommendationTime(): boolean {
  const now = new Date();
  const hour = now.getUTCHours();
  const minute = now.getUTCMinutes();

  // Run at 8am UTC or use environment override
  const targetHour = parseInt(process.env.RECOMMENDATION_HOUR || '8', 10);
  return hour === targetHour && minute < 1; // Window: 8:00-8:01 UTC
}

/**
 * Run daily recommendation generation
 * Also checks for re-engagement triggers
 */
export async function runDailyRecommendationJob(): Promise<{
  success: boolean;
  recommendationsGenerated: number;
  reengagementTriggered: number;
}> {
  console.log('[DailyScheduler] ═══════════════════════════════════════════');
  console.log('[DailyScheduler] Running daily recommendation job...');
  console.log('[DailyScheduler] Time:', new Date().toISOString());

  try {
    // Step 1: Generate recommendations
    const recommendedItemIds = await generateDailyRecommendations();

    // Step 2: Check for re-engagement candidates (7+ days without viewing)
    const reengagementTriggered = await checkAndTriggerReengagement();

    // Step 3: Log summary
    const result = {
      success: true,
      recommendationsGenerated: recommendedItemIds.length,
      reengagementTriggered,
    };

    console.log('[DailyScheduler] ═══════════════════════════════════════════');
    console.log('[DailyScheduler] Job completed successfully!');
    console.log('[DailyScheduler] Summary:', result);
    console.log('[DailyScheduler] ═══════════════════════════════════════════');

    return result;
  } catch (error) {
    console.error('[DailyScheduler] Error running daily job:', error);
    return {
      success: false,
      recommendationsGenerated: 0,
      reengagementTriggered: 0,
    };
  }
}

/**
 * Check for items that haven't been viewed in 7+ days
 * Send re-engagement notifications for those items
 */
async function checkAndTriggerReengagement(): Promise<number> {
  console.log('[DailyScheduler] Checking for re-engagement candidates...');

  try {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    // Find items that:
    // 1. Haven't been viewed in 7+ days, OR
    // 2. Have never been viewed (last_viewed_at IS NULL) but were created 7+ days ago
    // 3. AND haven't already sent reengagement notification today
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const { data: candidates, error } = await supabase
      .from('items')
      .select('id, content_raw, created_at, last_viewed_at, reengagement_notified_at')
      .or(
        `last_viewed_at.lt.${sevenDaysAgo.toISOString()},` +
          `and(last_viewed_at.is.null,created_at.lt.${sevenDaysAgo.toISOString()})`
      )
      .or(
        `reengagement_notified_at.is.null,reengagement_notified_at.lt.${today.toISOString()}`
      );

    if (error) {
      console.error('[DailyScheduler] Error fetching reengagement candidates:', error);
      return 0;
    }

    console.log(`[DailyScheduler] Found ${candidates?.length ?? 0} reengagement candidates`);

    if (!candidates || candidates.length === 0) {
      return 0;
    }

    // Create re-engagement notifications for each candidate
    let notificationCount = 0;

    for (const item of candidates) {
      try {
        // Update reengage timing
        const { error: updateError } = await supabase
          .from('items')
          .update({
            reengagement_notified_at: new Date().toISOString(),
          })
          .eq('id', item.id);

        if (!updateError) {
          notificationCount++;
          console.log(
            `[DailyScheduler] Triggered re-engagement for item ${item.id}: "${(item.content_raw as string)?.substring(0, 50)}..."`
          );
        } else {
          console.error(`[DailyScheduler] Error updating item ${item.id}:`, updateError);
        }

        // In a production app, would send FCM notification here
        // Example:
        // await sendFCMNotification({
        //   title: '⏰ You saved this a while ago',
        //   body: item.text.substring(0, 80),
        //   link: `/item/${item.id}`,
        //   category: 'reengagement'
        // });
      } catch (itemError) {
        console.error(`[DailyScheduler] Error processing item ${item.id}:`, itemError);
      }
    }

    console.log(`[DailyScheduler] Re-engagement notifications: ${notificationCount}`);
    return notificationCount;
  } catch (error) {
    console.error('[DailyScheduler] Error in checkAndTriggerReengagement:', error);
    return 0;
  }
}

/**
 * Set up scheduled job to run at 8am daily
 * Call this once when server starts
 */
export function setupDailyScheduler(): void {
  console.log('[DailyScheduler] Setting up daily scheduler...');

  // Calculate time until next 8am UTC
  const now = new Date();
  const target = new Date();
  target.setUTCHours(8, 0, 0, 0); // 8am UTC

  // If already past 8am today, schedule for tomorrow
  if (target <= now) {
    target.setDate(target.getDate() + 1);
  }

  const msUntilNextRun = target.getTime() - now.getTime();
  const hoursUntil = (msUntilNextRun / (1000 * 60 * 60)).toFixed(1);

  console.log(
    `[DailyScheduler] Next run in ${hoursUntil} hours at ${target.toISOString()}`
  );

  // Schedule first run
  const firstTimeout = setTimeout(() => {
    console.log('[DailyScheduler] Running scheduled daily job...');
    runDailyRecommendationJob();

    // Then schedule recurring runs every 24 hours
    setInterval(() => {
      console.log('[DailyScheduler] Running scheduled daily job (recurring)...');
      runDailyRecommendationJob();
    }, 24 * 60 * 60 * 1000); // Every 24 hours
  }, msUntilNextRun);

  // Store timeout ID for cleanup if needed
  (global as any).dailySchedulerTimeout = firstTimeout;

  console.log('[DailyScheduler] ✅ Scheduler initialized');
}

/**
 * For testing: manually trigger recommendation job
 * Use query param: /api/admin/trigger-recommendations
 */
export async function manualTriggerRecommendations(): Promise<any> {
  console.log('[DailyScheduler] Manual trigger requested');
  return await runDailyRecommendationJob();
}
