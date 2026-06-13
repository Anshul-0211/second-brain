/**
 * Step 3: NLP Tagging (compromise.js — Local, No API)
 * Extracts entities, keywords, and topics from text.
 */

import nlp from 'compromise';

export interface NlpTagResult {
  tags: string[];
  entities: {
    people: string[];
    places: string[];
    organizations: string[];
  };
  topics: string[];
}

export function extractTags(text: string): NlpTagResult {
  const doc = nlp(text);

  // Extract named entities
  const people = doc.people().out('array') as string[];
  const places = doc.places().out('array') as string[];
  const organizations = doc.organizations().out('array') as string[];

  // Extract topics (nouns that are likely topics)
  const topics = doc.topics().out('array') as string[];
  
  // Extract significant nouns (as potential tags)
  const nouns = doc.nouns().out('array') as string[];
  
  // Build tag list from all sources, deduplicated and cleaned
  const rawTags = [
    ...topics,
    ...organizations,
    ...nouns.slice(0, 8),
  ];

  // Clean, normalize, and deduplicate
  const tags = [...new Set(
    rawTags
      .map(t => t.toLowerCase().trim())
      .filter(t => t.length > 2 && t.length < 30)
      .filter(t => !STOP_WORDS.has(t))
  )].slice(0, 5); // Max 5 tags

  return {
    tags,
    entities: { people, places, organizations },
    topics,
  };
}

// Common words to exclude from tags
const STOP_WORDS = new Set([
  'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been',
  'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
  'would', 'could', 'should', 'may', 'might', 'can', 'shall',
  'this', 'that', 'these', 'those', 'it', 'its', 'they', 'them',
  'their', 'we', 'our', 'you', 'your', 'i', 'me', 'my', 'he',
  'him', 'his', 'she', 'her', 'way', 'thing', 'things', 'lot',
  'something', 'anything', 'everything', 'nothing', 'one', 'two',
  'time', 'year', 'people', 'part', 'place', 'case', 'week',
  'company', 'system', 'program', 'question', 'work', 'number',
]);
