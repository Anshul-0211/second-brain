/**
 * Step 1: Type Detection (Pure rule-based, no AI)
 * Detects whether content is a link, note, or file.
 */

const URL_REGEX = /^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/[\w\-./?%&=]*)?$/i;
const LOOSE_URL_REGEX = /https?:\/\/[^\s]+/i;

export interface TypeDetectionResult {
  type: 'link' | 'note' | 'file';
  extractedUrl?: string;
}

export function detectType(content: string): TypeDetectionResult {
  const trimmed = content.trim();

  // Check if the entire content is a URL
  if (URL_REGEX.test(trimmed)) {
    return {
      type: 'link',
      extractedUrl: ensureProtocol(trimmed),
    };
  }

  // Check if content starts with a URL
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('www.')) {
    const firstLine = trimmed.split('\n')[0].trim();
    if (URL_REGEX.test(firstLine)) {
      return {
        type: 'link',
        extractedUrl: ensureProtocol(firstLine),
      };
    }
  }

  // Check if content contains a URL (mixed content — still treat as link if URL is prominent)
  const urlMatch = trimmed.match(LOOSE_URL_REGEX);
  if (urlMatch && trimmed.length < 500) {
    // Short content with a URL → likely a link share
    return {
      type: 'link',
      extractedUrl: urlMatch[0],
    };
  }

  // Default to note
  return { type: 'note' };
}

function ensureProtocol(url: string): string {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  return `https://${url}`;
}
