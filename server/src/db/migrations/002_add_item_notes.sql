-----------------------------------------------------------
-- ITEM_NOTES: Inline contextual notes for items
-----------------------------------------------------------
CREATE TYPE note_urgency AS ENUM ('urgent', 'important', 'low-priority');

CREATE TABLE item_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  urgency note_urgency DEFAULT 'low-priority',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-----------------------------------------------------------
-- INDEXES
-----------------------------------------------------------
CREATE INDEX idx_item_notes_item_id ON item_notes(item_id);
CREATE INDEX idx_item_notes_created_at ON item_notes(created_at DESC);
