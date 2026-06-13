/**
 * Item Notes API Routes
 * CRUD operations for inline contextual notes on items.
 */

import { Hono } from 'hono';
import {
  addNote,
  getItemNotes,
  updateNote,
  deleteNote,
  CreateNoteInput,
} from '../db/queries.js';

const notes = new Hono();

// POST /api/items/:id/notes — Add note to item
notes.post('/:id/notes', async (c) => {
  try {
    const itemId = c.req.param('id');
    const body = await c.req.json();
    const { content, urgency } = body as CreateNoteInput;

    if (!content || typeof content !== 'string' || content.trim().length === 0) {
      return c.json({ error: 'Note content is required' }, 400);
    }

    if (content.length > 5000) {
      return c.json({ error: 'Note too long (max 5000 chars)' }, 400);
    }

    const note = await addNote(itemId, {
      content: content.trim(),
      urgency: urgency || 'low-priority',
    });

    return c.json({ success: true, note }, 201);
  } catch (err: any) {
    console.error('[notes POST] Error:', err);
    return c.json({ error: err.message || 'Failed to add note' }, 500);
  }
});

// GET /api/items/:id/notes — Get all notes for item
notes.get('/:id/notes', async (c) => {
  try {
    const itemId = c.req.param('id');
    const notesList = await getItemNotes(itemId);

    return c.json({
      success: true,
      itemId,
      notes: notesList,
      count: notesList.length,
    });
  } catch (err: any) {
    console.error('[notes GET] Error:', err);
    return c.json({ error: err.message || 'Failed to fetch notes' }, 500);
  }
});

// PUT /api/items/:id/notes/:noteId — Update note
notes.put('/:id/notes/:noteId', async (c) => {
  try {
    const itemId = c.req.param('id');
    const noteId = c.req.param('noteId');
    const body = await c.req.json();
    const { content, urgency } = body as Partial<CreateNoteInput>;

    if (content && content.length > 5000) {
      return c.json({ error: 'Note too long (max 5000 chars)' }, 400);
    }

    const note = await updateNote(noteId, {
      ...(content && { content: content.trim() }),
      ...(urgency && { urgency }),
    });

    return c.json({ success: true, note });
  } catch (err: any) {
    console.error('[notes PUT] Error:', err);
    return c.json({ error: err.message || 'Failed to update note' }, 500);
  }
});

// DELETE /api/items/:id/notes/:noteId — Delete note
notes.delete('/:id/notes/:noteId', async (c) => {
  try {
    const itemId = c.req.param('id');
    const noteId = c.req.param('noteId');

    await deleteNote(noteId);

    return c.json({ success: true, deleted: noteId });
  } catch (err: any) {
    console.error('[notes DELETE] Error:', err);
    return c.json({ error: err.message || 'Failed to delete note' }, 500);
  }
});

export default notes;
