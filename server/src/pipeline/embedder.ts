/**
 * Step 6: Embedding Generation (Cloudflare Workers AI)
 * Generates 384-dimensional vectors using BGE-small embedding model.
 */

import { config } from '../lib/config.js';

const CF_API_BASE = `https://api.cloudflare.com/client/v4/accounts/${config.cfAccountId}/ai/run/@cf/baai/bge-small-en-v1.5`;

/**
 * Generate embedding vector for text content.
 * Returns 384-dimensional float array using Cloudflare Workers AI.
 */
export async function generateEmbedding(text: string): Promise<number[] | null> {
  try {
    // Truncate to reasonable length (~2000 chars ≈ ~512 tokens)
    const truncated = text.slice(0, 2000);

    const response = await fetch(CF_API_BASE, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${config.cfApiToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        text: truncated,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[embedder] Cloudflare API error (${response.status}):`, errorText);
      return null;
    }

    const result = await response.json();

    // Cloudflare returns: { result: { shape: [1, 384], data: [[...]] }, success: true }
    if (result.success && result.result?.data && Array.isArray(result.result.data[0])) {
      const embedding = result.result.data[0];
      
      // Validate we got 384 dimensions
      if (embedding.length === 384) {
        return embedding;
      } else {
        console.error(`[embedder] Unexpected embedding dimension: ${embedding.length} (expected 384)`);
        return null;
      }
    }

    console.error('[embedder] Unexpected response format from Cloudflare:', result);
    return null;
  } catch (err) {
    console.error('[embedder] Failed to generate embedding:', err);
    return null;
  }
}
