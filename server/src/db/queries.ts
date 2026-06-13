import { supabase } from './client.js';

// ─── ITEMS ───────────────────────────────────────────

export interface FileAttachment {
  id: string;
  name: string;
  url: string;
  size: number;
  mime_type: string;
  storage_path: string;
  uploaded_at: string;
}

export interface CreateItemInput {
  type: 'link' | 'note' | 'file';
  content_raw: string;
  title?: string;
  description?: string;
  source_url?: string;
  ai_summary?: string;
  confidence_score?: number;
  embedding?: number[];
  files?: FileAttachment[];
  file_count?: number;
  has_attachment?: boolean;
}

export async function createItem(input: CreateItemInput) {
  const embeddingStr = input.embedding
    ? `[${input.embedding.join(',')}]`
    : null;

  const { data, error } = await supabase
    .from('items')
    .insert({
      ...input,
      embedding: embeddingStr,
    })
    .select()
    .single();

  if (error) throw new Error(`Failed to create item: ${error.message}`);
  return data;
}

export async function getItems(limit = 50, offset = 0, category?: string) {
  let query = supabase
    .from('items')
    .select('*')
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  const { data, error } = await query;
  if (error) throw new Error(`Failed to get items: ${error.message}`);
  return data;
}

export async function getItemById(id: string) {
  const { data, error } = await supabase
    .from('items')
    .select('*')
    .eq('id', id)
    .single();

  if (error) throw new Error(`Failed to get item: ${error.message}`);
  return data;
}

export async function deleteItem(id: string) {
  const { error } = await supabase
    .from('items')
    .delete()
    .eq('id', id);

  if (error) throw new Error(`Failed to delete item: ${error.message}`);
}

export async function updateItem(id: string, updates: Partial<CreateItemInput>) {
  const { data, error } = await supabase
    .from('items')
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq('id', id)
    .select()
    .single();

  if (error) throw new Error(`Failed to update item: ${error.message}`);
  return data;
}

// ─── TAGS ────────────────────────────────────────────

export async function getOrCreateTag(name: string) {
  const normalized = name.toLowerCase().trim().replace(/[^a-z0-9\s-]/g, '');
  if (!normalized) return null;

  // Try to find existing
  const { data: existing } = await supabase
    .from('tags')
    .select('*')
    .eq('name', normalized)
    .single();

  if (existing) return existing;

  // Create new
  const { data, error } = await supabase
    .from('tags')
    .insert({ name: normalized })
    .select()
    .single();

  if (error) throw new Error(`Failed to create tag: ${error.message}`);
  return data;
}

export async function linkTagToItem(itemId: string, tagId: string) {
  const { error } = await supabase
    .from('item_tags')
    .upsert({ item_id: itemId, tag_id: tagId });

  if (error) throw new Error(`Failed to link tag: ${error.message}`);
}

export async function getItemTags(itemId: string) {
  const { data, error } = await supabase
    .from('item_tags')
    .select('tag_id, tags(id, name)')
    .eq('item_id', itemId);

  if (error) throw new Error(`Failed to get item tags: ${error.message}`);
  return data?.map((d: any) => d.tags) || [];
}

export async function getAllTags() {
  const { data, error } = await supabase
    .from('tags')
    .select('*')
    .order('name');

  if (error) throw new Error(`Failed to get tags: ${error.message}`);
  return data;
}

// ─── CATEGORIES ──────────────────────────────────────

export async function getCategories() {
  const { data, error } = await supabase
    .from('categories')
    .select('*')
    .order('name');

  if (error) throw new Error(`Failed to get categories: ${error.message}`);
  return data;
}

export async function getCategoryByName(name: string) {
  const { data, error } = await supabase
    .from('categories')
    .select('*')
    .eq('name', name)
    .single();

  if (error) return null;
  return data;
}

export async function linkCategoryToItem(itemId: string, categoryId: string) {
  const { error } = await supabase
    .from('item_categories')
    .upsert({ item_id: itemId, category_id: categoryId });

  if (error) throw new Error(`Failed to link category: ${error.message}`);
}

export async function getItemCategories(itemId: string) {
  const { data, error } = await supabase
    .from('item_categories')
    .select('category_id, categories(id, name, color)')
    .eq('item_id', itemId);

  if (error) throw new Error(`Failed to get item categories: ${error.message}`);
  return data?.map((d: any) => d.categories) || [];
}

// ─── SEARCH ──────────────────────────────────────────

export async function searchByEmbedding(embedding: number[], threshold = 0.5, limit = 10) {
  const embeddingStr = `[${embedding.join(',')}]`;

  const { data, error } = await supabase
    .rpc('search_items', {
      query_embedding: embeddingStr,
      match_threshold: threshold,
      match_count: limit,
    });

  if (error) throw new Error(`Search failed: ${error.message}`);
  return data;
}

// Fallback: Search by tags & content (when embeddings unavailable)
export async function searchByTags(queryText: string, limit = 10) {
  const query = queryText.toLowerCase().trim();
  
  // Step 1: Search items by title, description, or content
  const { data: contentMatches, error: contentError } = await supabase
    .from('items')
    .select('*')
    .or(`title.ilike.%${query}%,description.ilike.%${query}%,content_raw.ilike.%${query}%`)
    .order('created_at', { ascending: false });

  if (contentError) {
    console.error('[searchByTags] Content search error:', contentError);
  }

  // Step 2: Search categories by name
  const { data: categories, error: categoryError } = await supabase
    .from('categories')
    .select('id, name')
    .ilike('name', `%${query}%`);

  // Step 3: Get items by matching categories
  let categoryItems: any[] = [];
  if (categories && categories.length > 0) {
    const categoryIds = categories.map(c => c.id);
    const { data: catItems, error: catError } = await supabase
      .from('item_categories')
      .select('items(*)')
      .in('category_id', categoryIds);
    
    if (catError) {
      console.error('[searchByTags] Category items error:', catError);
    } else {
      categoryItems = (catItems || []).map(c => c.items).filter(Boolean);
    }
  }

  // Step 4: Search tags by name
  const { data: tags, error: tagError } = await supabase
    .from('tags')
    .select('id, name')
    .ilike('name', `%${query}%`);

  // Step 5: Get items by matching tags
  let tagItems: any[] = [];
  if (tags && tags.length > 0) {
    const tagIds = tags.map(t => t.id);
    const { data: tItems, error: tError } = await supabase
      .from('item_tags')
      .select('items(*)')
      .in('tag_id', tagIds);
    
    if (tError) {
      console.error('[searchByTags] Tag items error:', tError);
    } else {
      tagItems = (tItems || []).map(t => t.items).filter(Boolean);
    }
  }

  // Step 6: Combine and deduplicate results
  const allMatches = new Map();
  
  // Add content matches
  (contentMatches || []).forEach((item: any) => {
    allMatches.set(item.id, item);
  });

  // Add category matches
  categoryItems.forEach((item: any) => {
    allMatches.set(item.id, item);
  });

  // Add tag matches
  tagItems.forEach((item: any) => {
    allMatches.set(item.id, item);
  });

  const results = Array.from(allMatches.values())
    .sort((a: any, b: any) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    .slice(0, limit);

  console.log(`[searchByTags] Found ${results.length} items for query "${queryText}" (${contentMatches?.length || 0} content, ${categoryItems.length} category, ${tagItems.length} tag)`);
  return results;
}

// ─── USER PROFILE ────────────────────────────────────

export async function getProfile() {
  const { data, error } = await supabase
    .from('user_profile')
    .select('*')
    .limit(1)
    .single();

  if (error) return null;
  return data;
}

export async function createProfile(displayName: string) {
  const { data, error } = await supabase
    .from('user_profile')
    .insert({ display_name: displayName })
    .select()
    .single();

  if (error) throw new Error(`Failed to create profile: ${error.message}`);
  return data;
}

// ─── ENRICHED ITEM ───────────────────────────────────

export async function getEnrichedItem(id: string) {
  const item = await getItemById(id);
  const tags = await getItemTags(id);
  const categories = await getItemCategories(id);
  const notes = await getItemNotes(id);

  return { ...item, tags, categories, notes };
}

export async function getEnrichedItems(limit = 50, offset = 0) {
  const items = await getItems(limit, offset);
  
  // Enrich each item with tags, categories, and notes
  const enriched = await Promise.all(
    items.map(async (item: any) => {
      const [tags, categories, notes] = await Promise.all([
        getItemTags(item.id),
        getItemCategories(item.id),
        getItemNotes(item.id),
      ]);
      
      // For feed view, include only first 50 chars of first note as preview
      const notePreview = notes.length > 0 ? notes[0].content.slice(0, 50) + (notes[0].content.length > 50 ? '...' : '') : null;
      
      return { 
        ...item, 
        tags, 
        categories,
        // Include full notes for detail view, but add preview for list view
        notes,
        notePreview,
        noteCount: notes.length,
        noteUrgency: notes.length > 0 ? notes[0].urgency : null,
      };
    })
  );

  return enriched;
}

// ─── ITEM NOTES ──────────────────────────────────────

export interface CreateNoteInput {
  content: string;
  urgency?: 'urgent' | 'important' | 'low-priority';
}

export async function addNote(itemId: string, input: CreateNoteInput) {
  const { data, error } = await supabase
    .from('item_notes')
    .insert({
      item_id: itemId,
      content: input.content,
      urgency: input.urgency || 'low-priority',
    })
    .select()
    .single();

  if (error) throw new Error(`Failed to add note: ${error.message}`);
  return data;
}

export async function getItemNotes(itemId: string) {
  const { data, error } = await supabase
    .from('item_notes')
    .select('*')
    .eq('item_id', itemId)
    .order('created_at', { ascending: false });

  if (error) throw new Error(`Failed to get notes: ${error.message}`);
  return data || [];
}

export async function updateNote(noteId: string, input: Partial<CreateNoteInput>) {
  const { data, error } = await supabase
    .from('item_notes')
    .update({ ...input, updated_at: new Date().toISOString() })
    .eq('id', noteId)
    .select()
    .single();

  if (error) throw new Error(`Failed to update note: ${error.message}`);
  return data;
}

export async function deleteNote(noteId: string) {
  const { error } = await supabase
    .from('item_notes')
    .delete()
    .eq('id', noteId);

  if (error) throw new Error(`Failed to delete note: ${error.message}`);
}

// ─── ENTITIES ────────────────────────────────────────

export interface EntityInput {
  item_id: string;
  text: string;
  type: 'TASK' | 'DEADLINE' | 'PERSON' | 'PROJECT' | 'PRIORITY';
  value: string;
  confidence?: number;
  metadata?: Record<string, any>;
}

export async function getItemEntities(itemId: string) {
  const { data, error } = await supabase
    .from('entities')
    .select('*')
    .eq('item_id', itemId)
    .order('created_at', { ascending: false });

  if (error) throw new Error(`Failed to get entities: ${error.message}`);
  return data || [];
}

export async function getEntitiesByType(itemId: string, type: string) {
  const { data, error } = await supabase
    .from('entities')
    .select('*')
    .eq('item_id', itemId)
    .eq('type', type)
    .order('created_at', { ascending: false });

  if (error) throw new Error(`Failed to get entities by type: ${error.message}`);
  return data || [];
}

// ─── REMINDERS ───────────────────────────────────────

export interface ReminderInput {
  item_id: string;
  task_name: string;
  due_date: string;
  priority?: 'low' | 'medium' | 'high' | 'urgent';
  status?: 'pending' | 'completed' | 'snoozed' | 'dismissed';
}

export async function createReminderQuery(input: ReminderInput) {
  const { data, error } = await supabase
    .from('reminders')
    .insert({
      item_id: input.item_id,
      task_name: input.task_name,
      due_date: input.due_date,
      priority: input.priority || 'medium',
      status: input.status || 'pending',
    })
    .select()
    .single();

  if (error) throw new Error(`Failed to create reminder: ${error.message}`);
  return data;
}

export async function getItemReminders(itemId: string) {
  const { data, error } = await supabase
    .from('reminders')
    .select('*')
    .eq('item_id', itemId)
    .eq('status', 'pending')
    .order('due_date', { ascending: true });

  if (error) throw new Error(`Failed to get reminders: ${error.message}`);
  return data || [];
}

export async function getPendingReminders(limit = 100) {
  const { data, error } = await supabase
    .from('reminders')
    .select('*')
    .eq('status', 'pending')
    .order('due_date', { ascending: true })
    .limit(limit);

  if (error) throw new Error(`Failed to get pending reminders: ${error.message}`);
  return data || [];
}

export async function updateReminderStatus(
  reminderId: string,
  status: 'pending' | 'completed' | 'snoozed' | 'dismissed'
) {
  console.log(`[updateReminderStatus] Updating reminder ${reminderId} to status ${status}`);
  
  const updates: any = {
    status,
    updated_at: new Date().toISOString(),
  };

  if (status === 'completed') {
    updates.completed_at = new Date().toISOString();
  }

  console.log(`[updateReminderStatus] Update payload:`, updates);

  const { data, error } = await supabase
    .from('reminders')
    .update(updates)
    .eq('id', reminderId)
    .select()
    .single();

  if (error) {
    console.error(`[updateReminderStatus] ❌ Supabase error:`, error);
    throw new Error(`Failed to update reminder: ${error.message}`);
  }
  
  console.log(`[updateReminderStatus] ✅ Updated successfully:`, data);
  return data;
}

export async function markReminderNotificationSent(reminderId: string) {
  const { error } = await supabase
    .from('reminders')
    .update({
      notification_sent: true,
      notification_sent_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', reminderId);

  if (error) throw new Error(`Failed to mark notification sent: ${error.message}`);
}

export async function getRemindersNeedingNotification(hoursAhead = 24) {
  const now = new Date();
  const futureDate = new Date(now.getTime() + hoursAhead * 60 * 60 * 1000);

  const { data, error } = await supabase
    .from('reminders')
    .select('*')
    .eq('status', 'pending')
    .eq('notification_sent', false)
    .gte('due_date', now.toISOString())
    .lte('due_date', futureDate.toISOString())
    .order('due_date', { ascending: true });

  if (error) throw new Error(`Failed to get reminders needing notification: ${error.message}`);
  return data || [];
}

// ─── VIEWING TRACKER ─────────────────────────────────

export async function markItemAsOpened(itemId: string) {
  const now = new Date().toISOString();

  // Step 1: Get current view count
  const { data: item, error: fetchError } = await supabase
    .from('items')
    .select('view_count')
    .eq('id', itemId)
    .single();

  if (fetchError) {
    throw new Error(`Failed to fetch item: ${fetchError.message}`);
  }

  const newViewCount = (item.view_count || 0) + 1;

  // Step 2: Update with new view count
  const { data, error } = await supabase
    .from('items')
    .update({
      opened: true,
      opened_at: now,
      view_count: newViewCount,
      last_viewed_at: now,
      updated_at: now,
    })
    .eq('id', itemId)
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to mark as opened: ${error.message}`);
  }

  console.log(`[markItemAsOpened] Item ${itemId}: view_count=${newViewCount}, opened=${data.opened}`);
  return data;
}
