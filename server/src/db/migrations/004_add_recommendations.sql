-- Week 2: Daily Recommendations & Re-engagement
-- Adds tables for tracking recommendations and dismissals

-- ═══════════════════════════════════════════════════════════════
-- Daily Recommendations Table
-- Stores top recommended items generated each day at 8am
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS daily_recommendations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  
  -- Link to item
  item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  
  -- Recommendation score (0-100)
  -- Combines: urgency (deadline), freshness (unviewed), relevance (similar tags)
  score FLOAT NOT NULL,
  
  -- Why this item was recommended
  reason TEXT NOT NULL, -- e.g., "has_deadline", "unviewed", "related_to_recent"
  
  -- Metadata for scoring breakdown
  metadata JSONB DEFAULT '{}', -- {urgency_score: 80, freshness_score: 90, relevance_score: 70}
  
  -- Track dismissals per user (for future multi-user support)
  dismissed_at TIMESTAMP,
  
  -- Timestamps
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '1 day', -- Recommendations expire after 1 day
  
  CONSTRAINT valid_score CHECK (score >= 0 AND score <= 100)
);

CREATE INDEX idx_daily_recommendations_created_at ON daily_recommendations(created_at DESC);
CREATE INDEX idx_daily_recommendations_item_id ON daily_recommendations(item_id);
CREATE INDEX idx_daily_recommendations_dismissed ON daily_recommendations(dismissed_at);


-- ═══════════════════════════════════════════════════════════════
-- Recommendation Dismissals Table
-- Track which recommendations user dismissed (for re-engagement)
-- ═══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS recommendation_dismissals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  
  -- Link to recommendation and item
  recommendation_id UUID NOT NULL REFERENCES daily_recommendations(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  
  -- Why dismissed (optional user feedback)
  reason TEXT, -- e.g., "not_relevant", "already_done", "not_interested"
  
  -- Timestamp
  dismissed_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  CONSTRAINT valid_dismissal_reason CHECK (
    reason IS NULL OR reason IN ('not_relevant', 'already_done', 'not_interested', 'read_later')
  )
);

CREATE INDEX idx_recommendation_dismissals_item_id ON recommendation_dismissals(item_id);
CREATE INDEX idx_recommendation_dismissals_dismissed_at ON recommendation_dismissals(dismissed_at DESC);


-- ═══════════════════════════════════════════════════════════════
-- Re-engagement Tracking
-- Adds columns to items table for re-engagement detection
-- ═══════════════════════════════════════════════════════════════
ALTER TABLE items 
ADD COLUMN IF NOT EXISTS reengagement_notified_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS reengagement_dismissed_at TIMESTAMP;

CREATE INDEX idx_items_reengagement_notified ON items(reengagement_notified_at);
CREATE INDEX idx_items_last_viewed_at ON items(last_viewed_at);

-- Comment for clarity
COMMENT ON COLUMN items.reengagement_notified_at IS 'When the 7+ day re-engagement notification was sent';
COMMENT ON COLUMN items.reengagement_dismissed_at IS 'When the user dismissed the re-engagement notification';
