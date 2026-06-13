# Week 2: Daily Recommendations & Re-engagement

## Overview

Week 2 adds intelligent recommendation features to make the feed smarter. The system now:

1. **Scores items daily (8am)** based on deadline urgency, viewing status, and relevance
2. **Shows top 5 recommendations** in a special section at top of feed
3. **Detects re-engagement candidates** (7+ days unseen) and sends notifications
4. **Allows dismissal** of recommendations for personalization

## Architecture

### Phase 3: Daily Recommendations

```
Daily Schedule (8am UTC)
    ↓
Recommendation Engine (scoring algorithm)
    ├─ Urgency Score (deadline proximity): 0-100
    ├─ Freshness Score (unviewed items): 0-100
    └─ Reengagement Score (old items): 0-100
    ↓
Daily Recommendations Table (stores top 5)
    ↓
Feed Screen (displays "💡 RECOMMENDED FOR YOU")
```

### Phase 4: Re-engagement

```
Daily Schedule (8am UTC)
    ↓
Check for items not viewed 7+ days
    ↓
Mark as reengagement_notified_at
    ↓
Send notification (FCM ready)
    ↓
User receives: "You saved this a week ago. Still relevant?"
```

## Database Schema

### Daily Recommendations Table

```sql
daily_recommendations (
  id UUID PRIMARY KEY,
  item_id UUID -> items,
  score FLOAT (0-100),
  reason TEXT ('has_deadline', 'unviewed', 'not_viewed_recently'),
  metadata JSONB {
    urgencyScore: 0-100,
    freshnessScore: 0-100,
    reengagementScore: 0-100,
    totalFactors: count
  },
  dismissed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP DEFAULT NOW() + 1 day
)
```

### Recommendation Dismissals (Audit Log)

```sql
recommendation_dismissals (
  id UUID PRIMARY KEY,
  recommendation_id UUID -> daily_recommendations,
  item_id UUID -> items,
  reason TEXT ('not_relevant', 'already_done', 'not_interested', 'read_later'),
  dismissed_at TIMESTAMP DEFAULT NOW()
)
```

### Items Table Extensions

```sql
ALTER TABLE items ADD:
  - reengagement_notified_at: TIMESTAMP (when 7+ day notification sent)
  - reengagement_dismissed_at: TIMESTAMP (when user dismissed notification)
```

## Scoring Algorithm

### Urgency Score (Deadline-based)

**Input:** Pending reminders for the item with due dates

```typescript
if (daysUntilDue < 0) → 95 points (Overdue)
if (daysUntilDue === 0-1) → 100 points (Today/Tomorrow)
if (daysUntilDue <= 7) → 80 points (This week)
if (daysUntilDue <= 14) → 50 points (Next week)
else → 20 points (Later)

+ Priority Boost:
  Urgent: +15 → max 100
  High: +10
  Medium: +5
  Low: +0

Final Urgency Weight: 35% of total score
```

### Freshness Score (Viewing Status)

**Input:** Item's `opened` and `view_count` fields

```typescript
if (NOT opened or view_count === 0) → 90 points (Never viewed)

Else (was viewed):
  if (daysSinceViewed <= 2) → 40 points
  if (daysSinceViewed <= 7) → 30 points
  if (daysSinceViewed <= 14) → 20 points
  if (daysSinceViewed > 14) → 10 points

Final Freshness Weight: 40% of total score
```

### Reengagement Score (Old Items)

**Input:** `last_viewed_at` or creation date

```typescript
if (daysSinceViewed >= 7 OR (neverViewed AND daysOld >= 7)):
  → 60-70 points (Trigger re-engagement)

Final Reengagement Weight: 25% of total score
```

### Final Score Calculation

```
Total Score = (Urgency × 0.35) + (Freshness × 0.40) + (Reengagement × 0.25)
Final Score = Min(100, Total Score)

Only items with score > 30 are recommended
Top 5 items by score are stored daily
```

## Backend Implementation

### 1. Migration (004_add_recommendations.sql)

**What it does:**
- Creates `daily_recommendations` table
- Creates `recommendation_dismissals` table (audit log)
- Adds columns to `items` table for reengagement tracking

**Run:**
```bash
# Automatically applied via migration runner
# Or manually via Supabase UI: copy SQL from server/src/db/migrations/004_add_recommendations.sql
```

### 2. Recommendation Engine (recommendationEngine.ts)

**Functions:**

```typescript
scoreItem(item): RecommendationScoringResult
  - Scores a single item
  - Calculates urgency, freshness, reengagement scores
  - Returns score (0-100) and reason

generateDailyRecommendations(): string[]
  - Fetches all items
  - Scores each item
  - Sorts by score descending
  - Deletes yesterday's recommendations
  - Inserts top 5 new recommendations
  - Returns list of recommended item IDs

getTodayRecommendations(): RecommendationRecord[]
  - Fetches today's recommendations (excluding dismissed)
  - Returns with full item data

dismissRecommendation(recId, itemId, reason?): boolean
  - Marks recommendation as dismissed_at = NOW()
  - Logs dismissal reason (optional)
```

**Logging:**
Every function has detailed console logs prefixed with `[Recommendation]`:
```
[Recommendation] Item abc123: urgency=80, days=3
[Recommendation] Item def456: freshness=90 (unviewed)
[Recommendation] Item ghi789: reengagement=70 (14d old)
[Recommendation] SCORED abc123 for reason="has_deadline_and_unviewed"
[Recommendation] Top recommendations: 5 items above threshold
```

### 3. Daily Scheduler (dailyScheduler.ts)

**Functions:**

```typescript
setupDailyScheduler()
  - Called once on server startup
  - Calculates time until 8am UTC
  - Sets up recurring daily job
  - Logs next run time

runDailyRecommendationJob(): {success, recommendationsGenerated, reengagementTriggered}
  - Calls generateDailyRecommendations()
  - Calls checkAndTriggerReengagement()
  - Returns summary stats

checkAndTriggerReengagement(): number
  - Finds items not viewed in 7+ days
  - Updates reengagement_notified_at
  - (Ready for FCM integration)
  - Returns count of triggered notifications
```

**Schedule:**
- Runs daily at 8am UTC
- Configurable via `RECOMMENDATION_HOUR` env var
- Recurring every 24 hours

### 4. Recommendation API Routes (recommendations.ts)

**Endpoints:**

```
GET /api/recommendations/today
  Returns: {success, recommendations: [], count}
  Excludes: dismissed recommendations
  Includes: item data, score, reason, metadata

POST /api/recommendations/:id/dismiss
  Body: {itemId, reason?: 'not_relevant'|'already_done'|'not_interested'|'read_later'}
  Returns: {success, dismissedAt}
  Side effect: Logs in recommendation_dismissals table

POST /api/admin/trigger (testing only)
  No params required
  Returns: {success, recommendationsGenerated, reengagementTriggered, triggeredAt}
  Use for manual testing without waiting for 8am
```

**Error Handling:**
All endpoints return proper HTTP status codes:
- 200: Success
- 400: Bad request
- 500: Internal server error
- All errors include `success: false` and `error` message

## Frontend Implementation

### 1. Updated Feed Screen (feed_screen.dart)

**New Features:**

1. **Recommendations Section** (at top of feed)
   - Header: "💡 RECOMMENDED FOR YOU" with count badge
   - Horizontal scrolling carousel of 3-5 items
   - Each card shows:
     - Reason badge (🔴 Urgent, ✨ Fresh, ⏰ Rediscover)
     - Text preview (truncated)
     - Score bar (visual 0-100)
     - Dismiss button (x)

2. **Recommendations Loading State**
   - Skeleton cards while loading
   - Smooth shimmer animation

3. **Dismissal**
   - Click X button to dismiss
   - Removed from view immediately (optimistic update)
   - Reason logged: "not_relevant"

4. **Tap to Navigate**
   - Click any recommendation card → goes to detail screen
   - Tap is tracked as item view (existing functionality)

### 2. API Integration (api_service.dart)

**New Methods:**

```dart
getTodayRecommendations(): Future<List<dynamic>>
  - Fetches today's recommendations
  - Returns: [{id, item, score, reason, metadata}, ...]

dismissRecommendation(recId, itemId, {reason}): Future<void>
  - Sends POST to /api/recommendations/:id/dismiss
  - Optional reason parameter

triggerRecommendationsGeneration(): Future<Map>
  - Triggers manual generation (for testing)
  - Returns: {recommendationsGenerated, reengagementTriggered}
```

## Server Setup

### 1. Environment Variables (Already Set)

```env
SUPABASE_URL=your_url
SUPABASE_SERVICE_KEY=your_key
RECOMMENDATION_HOUR=8  # UTC hour for daily job (optional)
```

### 2. Server Startup

The scheduler is initialized automatically:

```typescript
// In index.ts
import { setupDailyScheduler } from './services/dailyScheduler';

// After app.onError()
setupDailyScheduler();

// Output:
// [DailyScheduler] Setting up daily scheduler...
// [DailyScheduler] Next run in 4.3 hours at 2024-01-15T08:00:00.000Z
// [DailyScheduler] ✅ Scheduler initialized
```

### 3. Rebuild & Deploy

```bash
cd server && npm run build

# Restart server:
npm start

# Watch logs:
# Should see:
# [DailyScheduler] Setting up daily scheduler...
# [DailyScheduler] Next run in X hours
# 🎯 Daily recommendation scheduler running (8am UTC)
```

## Testing

### Test 1: Manual Trigger (Immediate Testing)

Without waiting for 8am:

```bash
curl -X POST http://localhost:3000/api/admin/trigger \
  -H "x-api-key: dev-key" \
  -H "Content-Type: application/json"
```

Response:
```json
{
  "success": true,
  "recommendationsGenerated": 5,
  "reengagementTriggered": 2,
  "triggeredAt": "2024-01-15T03:45:30.123Z"
}
```

### Test 2: View Recommendations in Feed

1. Open app → tap Feed tab
2. Should see "💡 RECOMMENDED FOR YOU" section at top
3. Shows cards with scores and reasons
4. Scroll horizontally to see all recommendations

### Test 3: Dismiss & Track

1. Click X on a recommendation card
2. Card disappears immediately
3. Dismissal logged in database
4. Refresh feed → recommendation stays dismissed

### Test 4: Re-engagement Detection

1. Dump an item today
2. Mark it as viewed (manually)
3. Wait 7 days (or manually update `last_viewed_at` in DB)
4. Trigger recommendations job manually
5. Check logs: should show "reengagement=70"
6. (Would send notification in production)

## Verification Checklist

- [ ] Migration 004 applied successfully
  ```bash
  # Check in Supabase: Tables → daily_recommendations exists
  # Tables → recommendation_dismissals exists
  # Items table → new columns visible
  ```

- [ ] Server starts without errors
  ```bash
  npm start
  # Should see: [DailyScheduler] ✅ Scheduler initialized
  ```

- [ ] Recommendations API working
  ```bash
  curl http://localhost:3000/api/recommendations/today -H "x-api-key: dev-key"
  # Should return: {success, recommendations, count}
  ```

- [ ] Feed screen renders recommendations
  ```
  Open app → Feed tab
  Should see: "💡 RECOMMENDED FOR YOU" section
  ```

- [ ] Scoring algorithm calculates scores
  ```bash
  # Check server logs:
  # [Recommendation] Item abc123: urgency=80, days=3
  # [Recommendation] Item def456: freshness=90 (unviewed)
  ```

- [ ] Dismissal works end-to-end
  ```
  Feed → Click X on recommendation
  Card disappears → refresh → stays dismissed
  ```

## Next Steps (Week 3)

1. **Related Items** (vector similarity)
   - Extract embeddings for all items
   - Run similarity search
   - Boost score for related items

2. **Smart Digest**
   - Weekly digest email/notification
   - Top items from the week
   - Format: Newsletter-style

3. **Advanced Scoring**
   - User engagement patterns
   - Time-of-day optimization
   - Tag-based personalization

## Troubleshooting

### No Recommendations Showing

**Check:**
1. Is database migration applied?
   ```sql
   SELECT COUNT(*) FROM daily_recommendations;
   ```

2. Are items being scored?
   ```bash
   # Check server logs for [Recommendation] messages
   npm start 2>&1 | grep "Recommendation"
   ```

3. Manual trigger working?
   ```bash
   curl -X POST http://localhost:3000/api/admin/trigger \
     -H "x-api-key: dev-key"
   ```

### Recommendations Always Dismissed

**Check:**
1. Are dismissals being saved?
   ```sql
   SELECT * FROM recommendation_dismissals LIMIT 5;
   ```

2. Try clearing dismissals:
   ```sql
   DELETE FROM recommendation_dismissals;
   -- Then refresh feed
   ```

### Scheduler Not Running

**Check:**
1. Server logs on startup:
   ```bash
   npm start 2>&1 | grep "DailyScheduler"
   ```

2. Is correct time passed since startup?
   ```typescript
   // Scheduler waits until next 8am UTC
   // If it's 3pm UTC and you started server,
   // next run is tomorrow 8am
   ```

3. For immediate testing:
   ```bash
   curl -X POST http://localhost:3000/api/admin/trigger \
     -H "x-api-key: dev-key"
   ```

## Key Files

- **Migration:** `server/src/db/migrations/004_add_recommendations.sql`
- **Engine:** `server/src/services/recommendationEngine.ts`
- **Scheduler:** `server/src/services/dailyScheduler.ts`
- **API Routes:** `server/src/routes/recommendations.ts`
- **Main Server:** `server/src/index.ts` (scheduler initialized here)
- **Feed UI:** `lib/screens/feed_screen.dart`
- **API Client:** `lib/services/api_service.dart`

## Success Metrics

✅ **Phase 3 (Recommendations):**
- Daily recommendations generated at 8am
- Top 5 items shown in feed
- Scores calculated correctly (urgency + freshness + reengagement)
- Dismissal works and prevents re-recommendation

✅ **Phase 4 (Re-engagement):**
- Items not viewed 7+ days detected
- Re-engagement notifications triggered
- Users can dismiss re-engagement prompts

These will be validated through:
1. Dumping 5-10 varied items (different deadlines, view counts)
2. Running manual trigger
3. Verifying recommendations appear correctly
4. Checking scores match algorithm logic
5. Dismissing and refreshing
6. Checking 7+ day old items show as "Rediscover"
