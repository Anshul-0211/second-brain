-- Phase 1: File Attachment Support
-- Adds file attachment capabilities to items

-- ═══════════════════════════════════════════════════════════════
-- Add file support columns to items table
-- ═══════════════════════════════════════════════════════════════

-- Add files column (stores array of file metadata)
ALTER TABLE items ADD COLUMN IF NOT EXISTS files JSONB DEFAULT '[]';

-- File object structure (stored in files array):
-- {
--   id: string (UUID),
--   name: string (original filename),
--   url: string (signed Supabase Storage URL),
--   size: number (bytes),
--   mime_type: string (e.g., 'image/png', 'application/pdf'),
--   storage_path: string (path in Supabase bucket),
--   uploaded_at: ISO8601 timestamp
-- }

-- Add file count for quick check
ALTER TABLE items ADD COLUMN IF NOT EXISTS file_count INTEGER DEFAULT 0;

-- Add flag for items with attachments (for filtering/display)
ALTER TABLE items ADD COLUMN IF NOT EXISTS has_attachment BOOLEAN DEFAULT false;

-- Create index for items with attachments
CREATE INDEX IF NOT EXISTS idx_items_has_attachment ON items(has_attachment);
CREATE INDEX IF NOT EXISTS idx_items_file_count ON items(file_count);

-- ═══════════════════════════════════════════════════════════════
-- Storage bucket information (manual setup via Supabase Dashboard)
-- ═══════════════════════════════════════════════════════════════
-- Bucket name: items-attachments
-- Visibility: Private (requires signed URLs)
-- Max file size: 50MB per file
-- Auto-delete: 7 days after expiry of signed URL
