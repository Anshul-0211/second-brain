import { supabase } from '../db/client.js';
import { ExtractedEntity, EntityType, findTaskDeadlinePairs, createTaskFromTitle } from './entityExtractor.js';

/**
 * Helper: Check if a date is in the past (comparing only date portion, not time)
 */
function isDateInPast(date: Date): boolean {
  const now = new Date();
  const todayOnly = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const dateOnly = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  
  return dateOnly < todayOnly;
}

export interface CreateReminderInput {
  item_id: string;
  task_name: string;
  due_date: Date;
  priority?: 'low' | 'medium' | 'high' | 'urgent';
}

export interface ReminderTask {
  id: string;
  item_id: string;
  task_name: string;
  due_date: Date;
  priority: string;
  status: string;
  notification_sent: boolean;
  created_at: Date;
}

/**
 * Store extracted entities in database
 */
export async function storeEntities(itemId: string, entities: ExtractedEntity[]): Promise<void> {
  if (entities.length === 0) return;

  const records = entities.map((entity) => ({
    item_id: itemId,
    text: entity.text,
    type: entity.type,
    value: entity.value,
    confidence: entity.confidence,
    metadata: entity.metadata ? JSON.stringify(entity.metadata) : null,
  }));

  const { error } = await supabase.from('entities').insert(records);

  if (error) {
    console.error('[storeEntities] Error storing entities:', error.message);
    throw new Error(`Failed to store entities: ${error.message}`);
  }

  console.log(`[storeEntities] Stored ${records.length} entities for item ${itemId}`);
}

/**
 * Create reminders from extracted entities
 * Option B: Liberal Pairing
 * - If TASK + DEADLINE pairs exist, create reminders from pairs
 * - If only DEADLINE exists (no TASK), create reminder using itemTitle as task
 */
export async function createRemindersFromEntities(
  itemId: string,
  entities: ExtractedEntity[],
  itemTitle?: string
): Promise<ReminderTask[]> {
  const tasks = entities.filter((e) => e.type === 'TASK');
  const deadlines = entities.filter((e) => e.type === 'DEADLINE');
  const priorities = entities.filter((e) => e.type === 'PRIORITY');

  const created: ReminderTask[] = [];

  // ─── Option A: Use TASK + DEADLINE pairs if available ───
  if (tasks.length > 0 && deadlines.length > 0) {
    const pairs = findTaskDeadlinePairs(entities);

    for (const pair of pairs) {
      const dueDate = pair.deadline.metadata?.date
        ? new Date(pair.deadline.metadata.date)
        : new Date();

      // Skip if due date is in the past (comparing only date portion, not time)
      if (isDateInPast(dueDate)) {
        console.log(
          `[reminderCreator] Skipping reminder with past due date: ${pair.task.text} (due ${dueDate.toISOString().split('T')[0]})`
        );
        continue;
      }

      try {
        const reminder = await createReminder({
          item_id: itemId,
          task_name: pair.task.text,
          due_date: dueDate,
          priority: (pair.priority as any) || 'medium',
        });

        created.push(reminder);

        console.log(
          `[reminderCreator] Created reminder from TASK+DEADLINE: "${pair.task.text}" due ${dueDate.toISOString().split('T')[0]}`
        );
      } catch (error) {
        console.error('[reminderCreator] Error creating reminder:', error);
      }
    }
  }
  // ─── Option B: Liberal Pairing - Use DEADLINE alone with item title ───
  else if (deadlines.length > 0 && itemTitle) {
    console.log(
      `[reminderCreator] Option B: No TASK found, using item title as fallback: "${itemTitle}"`
    );

    for (const deadline of deadlines) {
      const dueDate = deadline.metadata?.date
        ? new Date(deadline.metadata.date)
        : new Date();

      // Skip if due date is in the past (comparing only date portion, not time)
      if (isDateInPast(dueDate)) {
        console.log(
          `[reminderCreator] Skipping reminder with past due date for title: ${itemTitle} (due ${dueDate.toISOString().split('T')[0]})`
        );
        continue;
      }

      try {
        const reminder = await createReminder({
          item_id: itemId,
          task_name: itemTitle, // Use item title as task
          due_date: dueDate,
          priority: priorities.length > 0 ? (priorities[0].metadata?.priority as any) : 'medium',
        });

        created.push(reminder);

        console.log(
          `[reminderCreator] Created reminder from DEADLINE+Title: "${itemTitle}" due ${dueDate.toISOString().split('T')[0]}`
        );
      } catch (error) {
        console.error('[reminderCreator] Error creating reminder from deadline:', error);
      }
    }
  } else if (deadlines.length > 0) {
    console.log(
      `[reminderCreator] ⚠️ Found ${deadlines.length} deadline(s) but no item title provided for Option B fallback`
    );
  }

  return created;
}

/**
 * Create a single reminder
 */
export async function createReminder(input: CreateReminderInput): Promise<ReminderTask> {
  const { data, error } = await supabase
    .from('reminders')
    .insert({
      item_id: input.item_id,
      task_name: input.task_name,
      due_date: input.due_date.toISOString(),
      priority: input.priority || 'medium',
      status: 'pending',
    })
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to create reminder: ${error.message}`);
  }

  return {
    ...data,
    due_date: new Date(data.due_date),
    created_at: new Date(data.created_at),
  };
}

/**
 * Get all pending reminders
 */
export async function getPendingReminders(limit = 100): Promise<ReminderTask[]> {
  const { data, error } = await supabase
    .from('reminders')
    .select('*')
    .eq('status', 'pending')
    .order('due_date', { ascending: true })
    .limit(limit);

  if (error) {
    throw new Error(`Failed to get pending reminders: ${error.message}`);
  }

  return (data || []).map((r) => ({
    ...r,
    due_date: new Date(r.due_date),
    created_at: new Date(r.created_at),
  }));
}

/**
 * Get reminders for a specific item
 */
export async function getItemReminders(itemId: string): Promise<ReminderTask[]> {
  const { data, error } = await supabase
    .from('reminders')
    .select('*')
    .eq('item_id', itemId)
    .order('due_date', { ascending: true });

  if (error) {
    throw new Error(`Failed to get item reminders: ${error.message}`);
  }

  return (data || []).map((r) => ({
    ...r,
    due_date: new Date(r.due_date),
    created_at: new Date(r.created_at),
  }));
}

/**
 * Update reminder status
 */
export async function updateReminderStatus(
  reminderId: string,
  status: 'pending' | 'completed' | 'snoozed' | 'dismissed',
  snoozeUntil?: Date
): Promise<ReminderTask> {
  const updates: any = {
    status,
    updated_at: new Date().toISOString(),
  };

  if (status === 'completed') {
    updates.completed_at = new Date().toISOString();
  }

  if (status === 'snoozed' && snoozeUntil) {
    updates.snoozed_until = snoozeUntil.toISOString();
  }

  const { data, error } = await supabase
    .from('reminders')
    .update(updates)
    .eq('id', reminderId)
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to update reminder: ${error.message}`);
  }

  return {
    ...data,
    due_date: new Date(data.due_date),
    created_at: new Date(data.created_at),
  };
}

/**
 * Mark reminder notification as sent
 */
export async function markReminderNotificationSent(reminderId: string): Promise<void> {
  const { error } = await supabase
    .from('reminders')
    .update({
      notification_sent: true,
      notification_sent_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', reminderId);

  if (error) {
    throw new Error(`Failed to mark notification as sent: ${error.message}`);
  }
}

/**
 * Get reminders due within next N hours that need notification
 */
export async function getRemindersNeedingNotification(hoursAhead = 24): Promise<ReminderTask[]> {
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

  if (error) {
    throw new Error(`Failed to get reminders needing notification: ${error.message}`);
  }

  return (data || []).map((r) => ({
    ...r,
    due_date: new Date(r.due_date),
    created_at: new Date(r.created_at),
  }));
}
