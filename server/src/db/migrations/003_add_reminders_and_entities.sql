-----------------------------------------------------------
-- ENTITIES: Extracted entities (tasks, deadlines, people, projects, priorities)
-----------------------------------------------------------
CREATE TABLE entities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  text TEXT NOT NULL,  -- e.g., "assignment", "Sarah", "Thursday"
  type TEXT NOT NULL,  -- TASK, DEADLINE, PERSON, PROJECT, PRIORITY
  value TEXT,          -- normalized version, e.g., "assignment" or ISO date
  confidence REAL DEFAULT 0.8,
  metadata JSONB,      -- e.g., { date: "2026-04-17", action: "finish", priority: "high" }
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_entities_item_id ON entities(item_id);
CREATE INDEX idx_entities_type ON entities(type);
CREATE INDEX idx_entities_created_at ON entities(created_at DESC);

-----------------------------------------------------------
-- REMINDERS: Task reminders with due dates
-----------------------------------------------------------
CREATE TABLE reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  task_name TEXT NOT NULL,
  due_date TIMESTAMPTZ NOT NULL,
  priority TEXT DEFAULT 'medium',  -- low, medium, high, urgent
  status TEXT DEFAULT 'pending',   -- pending, completed, snoozed, dismissed
  notification_sent BOOLEAN DEFAULT false,
  notification_sent_at TIMESTAMPTZ,
  reminder_triggered_at TIMESTAMPTZ,  -- when reminder was triggered by scheduler
  completed_at TIMESTAMPTZ,
  snoozed_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_reminders_item_id ON reminders(item_id);
CREATE INDEX idx_reminders_due_date ON reminders(due_date);
CREATE INDEX idx_reminders_status ON reminders(status);
CREATE INDEX idx_reminders_notification_sent ON reminders(notification_sent);
CREATE INDEX idx_reminders_created_at ON reminders(created_at DESC);

-----------------------------------------------------------
-- Add viewing tracker columns to items
-----------------------------------------------------------
ALTER TABLE items ADD COLUMN opened BOOLEAN DEFAULT false;
ALTER TABLE items ADD COLUMN opened_at TIMESTAMPTZ;
ALTER TABLE items ADD COLUMN view_count INTEGER DEFAULT 0;
ALTER TABLE items ADD COLUMN last_viewed_at TIMESTAMPTZ;

CREATE INDEX idx_items_opened ON items(opened);
CREATE INDEX idx_items_view_count ON items(view_count DESC);
CREATE INDEX idx_items_last_viewed_at ON items(last_viewed_at DESC);
