import { createClient } from '@supabase/supabase-js';
import { config } from '../lib/config.js';

// Use service key for backend operations (bypasses RLS)
export const supabase = createClient(
  config.supabaseUrl,
  config.supabaseServiceKey
);
