/**
 * Step 2: Metadata Extraction (No AI)
 * Extracts title, description, and other metadata from content.
 */

import { extract } from '@extractus/article-extractor';

export interface MetadataResult {
  title: string;
  description: string;
  sourceUrl?: string;
  author?: string;
  publishedDate?: string;
  image?: string;
}

/**
 * Extract metadata from a link by fetching and parsing the page.
 */
export async function extractLinkMetadata(url: string): Promise<MetadataResult> {
  try {
    const article = await extract(url);

    if (article) {
      return {
        title: article.title || extractDomain(url),
        description: article.description || (article.content ? article.content.slice(0, 300) : ''),
        sourceUrl: url,
        author: article.author || undefined,
        publishedDate: article.published || undefined,
        image: article.image || undefined,
      };
    }
  } catch (err) {
    console.warn(`[metadataExtractor] Failed to extract from ${url}:`, err);
  }

  // Fallback: just use the URL domain as title
  return {
    title: extractDomain(url),
    description: `Saved link from ${extractDomain(url)}`,
    sourceUrl: url,
  };
}

/**
 * Extract metadata from plain text / notes.
 */
export function extractNoteMetadata(content: string): MetadataResult {
  const lines = content.trim().split('\n').filter(l => l.trim());
  
  // Title = first line (capped at 100 chars)
  const title = (lines[0] || 'Untitled Note').slice(0, 100);
  
  // Description = first 300 chars of content (excluding title)
  const descContent = lines.slice(1).join(' ').trim();
  const description = descContent
    ? descContent.slice(0, 300)
    : content.slice(0, 300);

  return { title, description };
}

function extractDomain(url: string): string {
  try {
    const u = new URL(url);
    return u.hostname.replace('www.', '');
  } catch {
    return url.slice(0, 50);
  }
}
