import Compromise from 'compromise';
import { parse } from 'chrono-node';

/**
 * Entity types that can be extracted from text
 */
export type EntityType = 'TASK' | 'DEADLINE' | 'PERSON' | 'PROJECT' | 'PRIORITY';

export interface ExtractedEntity {
  text: string;              // Original text: "assignment", "Thursday", "Sarah"
  type: EntityType;
  value: string;             // Normalized: "assignment", "2026-04-17", "sarah"
  confidence: number;        // 0-1
  metadata?: {
    date?: string;           // ISO string for DEADLINE
    action?: string;         // for TASK: "do", "complete", "finish"
    priority?: string;       // for PRIORITY: "urgent", "high", "medium", "low"
    source?: string;         // for TASK: "title-fallback" indicates title-derived
  };
}

/**
 * Extract all meaningful entities from text
 * Uses compromise.js for NLP + chrono for date parsing + regex for patterns
 */
export async function extractEntities(text: string): Promise<ExtractedEntity[]> {
  const entities: ExtractedEntity[] = [];

  // 1. Extract DEADLINE (dates) using chrono-node
  // Pass today as reference to prefer future dates (e.g., "Friday" = next Friday, not last)
  const now = new Date();
  const dateResults = parse(text, now);
  
  for (const dateResult of dateResults) {
    if (dateResult.start) {
      const dateText = dateResult.text.toLowerCase();
      const parsedDate = dateResult.start.date();
      
      // If parsed date is in the past, try to "shift" to the future equivalent
      // (e.g., if "Friday" parsed to last Friday, use next Friday)
      let finalDate = new Date(parsedDate);
      
      // Check if this is a day-of-week reference (monday-sunday, with optional "on" prefix)
      const dayOfWeekPattern = /(monday|tuesday|wednesday|thursday|friday|saturday|sunday)/i;
      const isDayOfWeek = dayOfWeekPattern.test(dateText);
      
      // If date is in the past AND it's a day-of-week reference, shift to next week
      if (parsedDate < now && isDayOfWeek) {
        console.log(
          `[entityExtractor] Past date detected for day-of-week "${dateText}" (${parsedDate.toISOString().split('T')[0]}), shifting to next week`
        );
        finalDate = new Date(parsedDate);
        finalDate.setDate(finalDate.getDate() + 7);
      }
      
      entities.push({
        text: dateResult.text, // Keep original text (not lowercased)
        type: 'DEADLINE',
        value: finalDate.toISOString().split('T')[0],
        confidence: 0.95,
        metadata: {
          date: finalDate.toISOString(),
        },
      });
    }
  }

  // 2. Extract TASK using keyword patterns
  const taskPatterns = [
    /(?:^|[.,!?\s])(?:do|finish|complete|submit|send|create|write|read|study|learn|research|implement|fix|refactor|test|deploy|review|make|build|design|plan|organize|update|modify|add|put|place|move|remove|delete|edit|check|verify|purchase|buy|call|email|message|respond|schedule|prepare|setup|install|configure|run|start|stop|restart|remember|get|bring|take|clean|arrange|meet|attend|watch|listen|watch)\s+([^.,!?]*?)(?=[.,!?]|$)/gi,
  ];

  for (const pattern of taskPatterns) {
    let match;
    while ((match = pattern.exec(text)) !== null) {
      const taskText = match[1].trim();
      if (taskText && taskText.length < 100) {
        const action = match[0].match(/\b(do|finish|complete|submit|send|create|write|read|study|learn|research|implement|fix|refactor|test|deploy|review|make|build|design|plan|organize|update|modify|add|put|place|move|remove|delete|edit|check|verify|purchase|buy|call|email|message|respond|schedule|prepare|setup|install|configure|run|start|stop|restart|remember|get|bring|take|clean|arrange|meet|attend|watch|listen)\b/i)?.[1] || 'do';
        entities.push({
          text: taskText,
          type: 'TASK',
          value: taskText.toLowerCase(),
          confidence: 0.88,
          metadata: {
            action: action.toLowerCase(),
          },
        });
      }
    }
  }

  // 3. Extract PRIORITY using keywords
  const priorityKeywords = [
    { text: 'urgent', value: 'urgent', confidence: 0.99 },
    { text: 'asap', value: 'urgent', confidence: 0.98 },
    { text: 'critical', value: 'high', confidence: 0.95 },
    { text: 'important', value: 'high', confidence: 0.93 },
    { text: 'high priority', value: 'high', confidence: 0.92 },
    { text: 'low priority', value: 'low', confidence: 0.92 },
  ];

  for (const keyword of priorityKeywords) {
    const regex = new RegExp(`\\b${keyword.text}\\b`, 'gi');
    if (regex.test(text)) {
      entities.push({
        text: keyword.text,
        type: 'PRIORITY',
        value: keyword.value,
        confidence: keyword.confidence,
        metadata: {
          priority: keyword.value,
        },
      });
      regex.lastIndex = 0;
    }
  }

  // 4. Extract PERSON names using compromise.js
  const doc = Compromise(text);
  const people = doc.people().out('array');
  for (const person of people) {
    if (person && person.length > 0) {
      entities.push({
        text: person,
        type: 'PERSON',
        value: person.toLowerCase(),
        confidence: 0.85,
      });
    }
  }

  // 5. Extract PROJECT using patterns (capitalized phrases)
  const projectPattern = /\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+|project\s+[a-zA-Z0-9\s]+)\b/g;
  let projectMatch;
  while ((projectMatch = projectPattern.exec(text)) !== null) {
    const projectText = projectMatch[1].trim();
    if (projectText && projectText.length < 50) {
      // Filter out common non-project names
      if (!['The', 'This', 'That', 'These', 'Those', 'For', 'And', 'Or'].includes(projectText.split(' ')[0])) {
        entities.push({
          text: projectText,
          type: 'PROJECT',
          value: projectText.toLowerCase(),
          confidence: 0.75,
        });
      }
    }
  }

  // Remove duplicates (same type + value)
  const seen = new Set<string>();
  const unique = entities.filter((entity) => {
    const key = `${entity.type}:${entity.value}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  console.log(`[entityExtractor] Extracted ${unique.length} entities:`, {
    tasks: unique.filter((e) => e.type === 'TASK').length,
    deadlines: unique.filter((e) => e.type === 'DEADLINE').length,
    people: unique.filter((e) => e.type === 'PERSON').length,
    projects: unique.filter((e) => e.type === 'PROJECT').length,
    priorities: unique.filter((e) => e.type === 'PRIORITY').length,
  });

  return unique;
}

/**
 * Find pairs of TASK and DEADLINE entities that form reminders
 */
export function findTaskDeadlinePairs(entities: ExtractedEntity[]): Array<{
  task: ExtractedEntity;
  deadline: ExtractedEntity;
  priority?: string;
}> {
  const tasks = entities.filter((e) => e.type === 'TASK');
  const deadlines = entities.filter((e) => e.type === 'DEADLINE');
  const priorities = entities.filter((e) => e.type === 'PRIORITY');

  const pairs: Array<{
    task: ExtractedEntity;
    deadline: ExtractedEntity;
    priority?: string;
  }> = [];

  // ─── Option A: Strict if we have both tasks and deadlines ───
  if (tasks.length === 1 && deadlines.length > 0) {
    for (const deadline of deadlines) {
      pairs.push({
        task: tasks[0],
        deadline,
        priority: priorities.length > 0 ? priorities[0].metadata?.priority : undefined,
      });
    }
  } else if (tasks.length > 0 && deadlines.length === 1) {
    // If one deadline and multiple tasks, link the first task
    pairs.push({
      task: tasks[0],
      deadline: deadlines[0],
      priority: priorities.length > 0 ? priorities[0].metadata?.priority : undefined,
    });
  } else if (tasks.length > 1 && deadlines.length > 1) {
    // Multiple tasks and deadlines: link each task with first deadline
    for (const task of tasks) {
      pairs.push({
        task,
        deadline: deadlines[0],
        priority: priorities.length > 0 ? priorities[0].metadata?.priority : undefined,
      });
    }
  }

  return pairs;
}

/**
 * Create fallback task entity from item title
 * Used for Option B: Liberal Pairing (create reminder from DEADLINE alone)
 */
export function createTaskFromTitle(title: string): ExtractedEntity {
  return {
    text: title,
    type: 'TASK',
    value: title.toLowerCase(),
    confidence: 0.75, // Lower confidence since it's fallback
    metadata: {
      action: 'complete',
      source: 'title-fallback', // indicates this was generated from title
    },
  };
}
