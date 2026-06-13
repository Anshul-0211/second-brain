-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-----------------------------------------------------------
-- ITEMS: Core content table
-----------------------------------------------------------
CREATE TABLE items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL CHECK (type IN ('link', 'note', 'file')),
  content_raw TEXT NOT NULL,
  title TEXT,
  description TEXT,
  source_url TEXT,
  ai_summary TEXT,
  confidence_score REAL DEFAULT 0.0,
  embedding vector(384),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-----------------------------------------------------------
-- CATEGORIES: Predefined content categories
-----------------------------------------------------------
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  color TEXT
);

-- Seed default categories
INSERT INTO categories (name, color) VALUES
  ('Tech', '#6366F1'),
  ('Finance', '#10B981'),
  ('Study', '#F59E0B'),
  ('Personal', '#EC4899'),
  ('Entertainment', '#8B5CF6'),
  ('News', '#3B82F6'),
  ('Health', '#14B8A6'),
  ('Other', '#6B7280');

-----------------------------------------------------------
-- TAGS: Auto-generated content tags
-----------------------------------------------------------
CREATE TABLE tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL
);

-----------------------------------------------------------
-- ITEM_TAGS: Many-to-many relationship
-----------------------------------------------------------
CREATE TABLE item_tags (
  item_id UUID REFERENCES items(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (item_id, tag_id)
);

-----------------------------------------------------------
-- ITEM_CATEGORIES: Many-to-many relationship
-----------------------------------------------------------
CREATE TABLE item_categories (
  item_id UUID REFERENCES items(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  PRIMARY KEY (item_id, category_id)
);

-----------------------------------------------------------
-- USER PROFILE: Simple single-user profile
-----------------------------------------------------------
CREATE TABLE user_profile (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-----------------------------------------------------------
-- INDEXES
-----------------------------------------------------------
-- Vector similarity search index (requires at least 100 rows to be effective)
-- We'll create this after sufficient data exists:
-- CREATE INDEX ON items USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- For now, use exact search (fine for personal use with < 10k items)
CREATE INDEX idx_items_created_at ON items(created_at DESC);
CREATE INDEX idx_items_type ON items(type);
CREATE INDEX idx_tags_name ON tags(name);

-----------------------------------------------------------
-- FUNCTIONS
-----------------------------------------------------------

-- Function to search items by vector similarity
CREATE OR REPLACE FUNCTION search_items(
  query_embedding vector(384),
  match_threshold float DEFAULT 0.5,
  match_count int DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  type TEXT,
  title TEXT,
  description TEXT,
  source_url TEXT,
  content_raw TEXT,
  confidence_score REAL,
  created_at TIMESTAMPTZ,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    i.id,
    i.type,
    i.title,
    i.description,
    i.source_url,
    i.content_raw,
    i.confidence_score,
    i.created_at,
    1 - (i.embedding <=> query_embedding) AS similarity
  FROM items i
  WHERE i.embedding IS NOT NULL
    AND 1 - (i.embedding <=> query_embedding) > match_threshold
  ORDER BY i.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;
