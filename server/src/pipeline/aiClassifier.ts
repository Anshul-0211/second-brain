/**
 * Step 5: AI Classification Fallback (Groq API)
 * Only called when rule-based confidence < threshold.
 * Uses llama-3.1-8b-instant for speed and free tier limits.
 */

import Groq from 'groq-sdk';
import { config } from '../lib/config.js';

const groq = new Groq({ apiKey: config.groqApiKey });

export interface AiClassificationResult {
  category: string;
  tags: string[];
  summary?: string;
}

export async function aiClassifyAndTag(text: string): Promise<AiClassificationResult> {
  try {
    const truncated = text.slice(0, 1000); // Limit input to save tokens

    const response = await groq.chat.completions.create({
      model: config.groqModel,
      messages: [
        {
          role: 'system',
          content: `You are a content classifier for a personal knowledge base. 
Return JSON only with this exact format:
{"category": "...", "tags": ["tag1", "tag2", "tag3"], "summary": "one sentence summary"}

Categories (pick exactly one): Tech, Finance, Study, Personal, Entertainment, News, Health, Other
Tags: 3-5 concise, lowercase, generalizable tags. No hashtags.
Summary: One clear sentence summarizing the content.`,
        },
        {
          role: 'user',
          content: `Classify and tag this content:\n\n${truncated}`,
        },
      ],
      temperature: 0,
      max_tokens: 150,
      response_format: { type: 'json_object' },
    });

    const content = response.choices[0]?.message?.content;
    if (!content) throw new Error('No response from AI');

    const parsed = JSON.parse(content);

    return {
      category: parsed.category || 'Other',
      tags: Array.isArray(parsed.tags) ? parsed.tags.slice(0, 5) : [],
      summary: parsed.summary || undefined,
    };
  } catch (err) {
    console.error('[aiClassifier] AI classification failed:', err);
    // Graceful fallback — don't break the pipeline
    return {
      category: 'Other',
      tags: [],
    };
  }
}
