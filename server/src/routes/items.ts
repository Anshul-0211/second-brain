/**
 * Items API Routes
 * CRUD operations for brain items.
 */

import { Hono } from 'hono';
import { processContent } from '../pipeline/processor.js';
import {
  getEnrichedItems,
  getEnrichedItem,
  deleteItem,
  updateItem,
  addNote,
  getItemNotes,
  updateNote,
  deleteNote,
  CreateNoteInput,
  markItemAsOpened,
  getItemEntities,
  getItemReminders,
} from '../db/queries.js';
import { uploadFileToStorage, UPLOAD_CONFIG } from '../services/fileUploadService.js';

const items = new Hono();

// POST /api/items — Create new item (triggers pipeline)
items.post('/', async (c) => {
  try {
    const body = await c.req.json();
    const { content } = body;

    if (!content || typeof content !== 'string' || content.trim().length === 0) {
      return c.json({ error: 'Content is required' }, 400);
    }

    if (content.length > 50000) {
      return c.json({ error: 'Content too long (max 50000 chars)' }, 400);
    }

    const result = await processContent(content.trim());

    return c.json({
      success: true,
      item: result,
    }, 201);
  } catch (err: any) {
    console.error('[items POST] Error:', err);
    return c.json({ error: err.message || 'Failed to process item' }, 500);
  }
});

// GET /api/items — List all items (paginated)
items.get('/', async (c) => {
  try {
    const limit = parseInt(c.req.query('limit') || '50');
    const offset = parseInt(c.req.query('offset') || '0');

    const data = await getEnrichedItems(limit, offset);

    return c.json({
      items: data,
      count: data.length,
      limit,
      offset,
    });
  } catch (err: any) {
    console.error('[items GET] Error:', err);
    return c.json({ error: err.message || 'Failed to fetch items' }, 500);
  }
});

// GET /api/items/:id — Get single item with tags + categories
items.get('/:id', async (c) => {
  try {
    const id = c.req.param('id');
    const item = await getEnrichedItem(id);

    return c.json({ item });
  } catch (err: any) {
    console.error('[items GET/:id] Error:', err);
    return c.json({ error: err.message || 'Item not found' }, 404);
  }
});

// DELETE /api/items/:id — Delete item
items.delete('/:id', async (c) => {
  try {
    const id = c.req.param('id');
    await deleteItem(id);

    return c.json({ success: true, deleted: id });
  } catch (err: any) {
    console.error('[items DELETE] Error:', err);
    return c.json({ error: err.message || 'Failed to delete item' }, 500);
  }
});

// PATCH /api/items/:id — Update item
items.patch('/:id', async (c) => {
  try {
    const id = c.req.param('id');
    const body = await c.req.json();

    const updated = await updateItem(id, body);

    return c.json({ success: true, item: updated });
  } catch (err: any) {
    console.error('[items PATCH] Error:', err);
    return c.json({ error: err.message || 'Failed to update item' }, 500);
  }
});

// ─── VIEWING TRACKER ──────────────────────────────────

// PUT /api/items/:id/view — Mark item as opened
items.put('/:id/view', async (c) => {
  try {
    const id = c.req.param('id');
    const item = await markItemAsOpened(id);

    return c.json({
      success: true,
      item: {
        id: item.id,
        opened: item.opened,
        opened_at: item.opened_at,
        view_count: item.view_count,
        last_viewed_at: item.last_viewed_at,
      },
    });
  } catch (err: any) {
    console.error('[items PUT /view] Error:', err);
    return c.json({ error: err.message || 'Failed to mark as opened' }, 500);
  }
});

// ─── ENTITIES ENDPOINTS ───────────────────────────────

// GET /api/items/:id/entities — Get all entities for item
items.get('/:id/entities', async (c) => {
  try {
    const itemId = c.req.param('id');
    const entities = await getItemEntities(itemId);

    return c.json({
      success: true,
      itemId,
      entities,
      count: entities.length,
      breakdown: {
        tasks: entities.filter((e: any) => e.type === 'TASK').length,
        deadlines: entities.filter((e: any) => e.type === 'DEADLINE').length,
        people: entities.filter((e: any) => e.type === 'PERSON').length,
        projects: entities.filter((e: any) => e.type === 'PROJECT').length,
        priorities: entities.filter((e: any) => e.type === 'PRIORITY').length,
      },
    });
  } catch (err: any) {
    console.error('[entities GET] Error:', err);
    return c.json({ error: err.message || 'Failed to fetch entities' }, 500);
  }
});

// ─── REMINDERS ENDPOINTS ──────────────────────────────

// GET /api/items/:id/reminders — Get all reminders for item
items.get('/:id/reminders', async (c) => {
  try {
    const itemId = c.req.param('id');
    const reminders = await getItemReminders(itemId);

    const enriched = reminders.map((r: any) => ({
      ...r,
      daysUntilDue: Math.ceil(
        (new Date(r.due_date).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
      ),
    }));

    return c.json({
      success: true,
      itemId,
      reminders: enriched,
      count: enriched.length,
    });
  } catch (err: any) {
    console.error('[reminders GET] Error:', err);
    return c.json({ error: err.message || 'Failed to fetch reminders' }, 500);
  }
});

// ─── NOTES ENDPOINTS ──────────────────────────────────

// POST /api/items/:id/notes — Add note to item
items.post('/:id/notes', async (c) => {
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
items.get('/:id/notes', async (c) => {
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
items.put('/:id/notes/:noteId', async (c) => {
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
items.delete('/:id/notes/:noteId', async (c) => {
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

// ─── FILE UPLOAD ──────────────────────────────────

// POST /api/items/upload — Create item with file attachments
items.post('/upload', async (c) => {
  try {
    // Get multipart form data
    const formData = await c.req.formData();
    const content = formData.get('content') as string;
    const title = formData.get('title') as string | null;
    const files = formData.getAll('files') as File[];

    // Validate content
    if (!content || typeof content !== 'string' || content.trim().length === 0) {
      return c.json({ error: 'Content is required' }, 400);
    }

    if (content.length > 50000) {
      return c.json({ error: 'Content too long (max 50000 chars)' }, 400);
    }

    // Validate files
    if (!files || files.length === 0) {
      return c.json({ error: 'At least one file is required' }, 400);
    }

    if (files.length > UPLOAD_CONFIG.MAX_FILES_PER_ITEM) {
      return c.json(
        { error: `Too many files. Max: ${UPLOAD_CONFIG.MAX_FILES_PER_ITEM}` },
        400
      );
    }

    // Process content through pipeline (creates item in DB)
    console.log('[items POST /upload] Processing content...');
    const pipelineResult = await processContent(content.trim());
    const itemId = pipelineResult.itemId;

    // Upload files to storage
    const uploadedFiles = [];
    let totalSize = 0;

    for (const file of files) {
      const buffer = await file.arrayBuffer();
      const fileContent = Buffer.from(buffer);

      console.log(`[items POST /upload] Uploading file: ${file.name} (${fileContent.length} bytes)`);

      const uploadResult = await uploadFileToStorage(
        {
          content: fileContent,
          filename: file.name,
          type: file.type,
        },
        itemId
      );

      if (!uploadResult.success) {
        console.error(`[items POST /upload] File upload failed: ${uploadResult.error}`);
        return c.json(
          { error: `File upload failed: ${uploadResult.error}` },
          400
        );
      }

      uploadedFiles.push(uploadResult.file!);
      totalSize += uploadResult.file!.size;
    }

    // Update item with file metadata
    console.log(`[items POST /upload] Updating item with ${uploadedFiles.length} files`);
    const updatedItem = await updateItem(itemId, {
      files: uploadedFiles,
      file_count: uploadedFiles.length,
      has_attachment: true,
    });

    return c.json(
      {
        success: true,
        item: updatedItem,
        filesUploaded: uploadedFiles.length,
        totalSize,
      },
      201
    );
  } catch (err: any) {
    console.error('[items POST /upload] Error:', err);
    return c.json({ error: err.message || 'Failed to upload file' }, 500);
  }
});

export default items;
