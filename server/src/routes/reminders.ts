/**
 * Reminders API Routes
 * Task reminder management endpoints
 */

import { Hono } from 'hono';
import {
  getPendingReminders,
  updateReminderStatus,
  createReminderQuery,
  ReminderInput,
} from '../db/queries.js';

const reminders = new Hono();

// GET /api/reminders — List all pending reminders
reminders.get('/', async (c) => {
  try {
    const limit = parseInt(c.req.query('limit') || '100');
    const status = c.req.query('status') || 'pending';

    let allReminders = await getPendingReminders(limit);

    // Filter by status if not pending (for future use)
    if (status !== 'pending') {
      allReminders = allReminders.filter((r: any) => r.status === status);
    }

    // Add calculated fields
    const enriched = allReminders.map((r: any) => {
      const dueDate = new Date(r.due_date);
      const now = new Date();
      const diffMs = dueDate.getTime() - now.getTime();
      const daysUntilDue = Math.ceil(diffMs / (1000 * 60 * 60 * 24));
      const hoursUntilDue = Math.ceil(diffMs / (1000 * 60 * 60));

      let urgency = 'normal';
      if (daysUntilDue === 0) urgency = 'today';
      else if (daysUntilDue === 1) urgency = 'tomorrow';
      else if (daysUntilDue <= 3) urgency = 'soon';
      else if (daysUntilDue <= 7) urgency = 'this-week';

      return {
        ...r,
        daysUntilDue,
        hoursUntilDue,
        urgency,
        isOverdue: diffMs < 0,
      };
    });

    return c.json({
      success: true,
      reminders: enriched,
      count: enriched.length,
      stats: {
        overdue: enriched.filter((r: any) => r.isOverdue).length,
        today: enriched.filter((r: any) => r.urgency === 'today').length,
        tomorrow: enriched.filter((r: any) => r.urgency === 'tomorrow').length,
        thisWeek: enriched.filter((r: any) => r.urgency === 'this-week').length,
      },
    });
  } catch (err: any) {
    console.error('[reminders GET] Error:', err);
    return c.json({ error: err.message || 'Failed to fetch reminders' }, 500);
  }
});

// POST /api/reminders — Create new reminder manually
reminders.post('/', async (c) => {
  try {
    const body = await c.req.json();
    const { taskName, dueDate, priority, itemId } = body;

    if (!taskName || typeof taskName !== 'string' || taskName.trim().length === 0) {
      return c.json({ error: 'Task name is required' }, 400);
    }

    if (!dueDate || isNaN(Date.parse(dueDate))) {
      return c.json({ error: 'Valid due date is required' }, 400);
    }

    if (!itemId) {
      return c.json({ error: 'Item ID is required' }, 400);
    }

    const reminder = await createReminderQuery({
      item_id: itemId,
      task_name: taskName.trim(),
      due_date: new Date(dueDate).toISOString(),
      priority: priority || 'medium',
    });

    return c.json({ success: true, reminder }, 201);
  } catch (err: any) {
    console.error('[reminders POST] Error:', err);
    return c.json({ error: err.message || 'Failed to create reminder' }, 500);
  }
});

// PUT /api/reminders/:id — Update reminder status
reminders.put('/:id', async (c) => {
  try {
    const reminderId = c.req.param('id');
    console.log(`[reminders PUT] Updating reminder ${reminderId}`);
    
    const body = await c.req.json();
    console.log(`[reminders PUT] Request body:`, body);
    
    const { status } = body;

    if (!status || !['pending', 'completed', 'snoozed', 'dismissed'].includes(status)) {
      console.warn(`[reminders PUT] Invalid status: ${status}`);
      return c.json(
        { error: "Status must be one of: pending, completed, snoozed, dismissed" },
        400
      );
    }

    console.log(`[reminders PUT] Calling updateReminderStatus with id=${reminderId}, status=${status}`);
    const reminder = await updateReminderStatus(reminderId, status);
    
    console.log(`[reminders PUT] ✅ Updated reminder:`, reminder);
    return c.json({ success: true, reminder });
  } catch (err: any) {
    console.error(`[reminders PUT] ❌ Error:`, err.message || err);
    return c.json({ error: err.message || 'Failed to update reminder', details: err.toString() }, 500);
  }
});

// DELETE /api/reminders/:id — Delete reminder (set to dismissed)
reminders.delete('/:id', async (c) => {
  try {
    const reminderId = c.req.param('id');

    const reminder = await updateReminderStatus(reminderId, 'dismissed');

    return c.json({ success: true, reminder, message: 'Reminder dismissed' });
  } catch (err: any) {
    console.error('[reminders DELETE] Error:', err);
    return c.json({ error: err.message || 'Failed to delete reminder' }, 500);
  }
});

export default reminders;
