/**
 * Processing Pipeline Orchestrator
 * Runs all 6 steps sequentially. Individual step failures don't break the pipeline.
 * 
 * Flow:
 * 1. Detect type (rule-based)
 * 2. Extract metadata (article-extractor / text parse)
 * 3. NLP tagging (compromise.js)
 * 4. Rule-based classification (keyword scoring)
 * 5. AI fallback (Groq — only if confidence < threshold)
 * 6. Generate embedding (HuggingFace)
 * 7. Store everything in database
 */

import { detectType } from './typeDetector.js';
import { extractLinkMetadata, extractNoteMetadata } from './metadataExtractor.js';
import { extractTags } from './nlpTagger.js';
import { classifyContent } from './ruleClassifier.js';
import { aiClassifyAndTag } from './aiClassifier.js';
import { generateEmbedding } from './embedder.js';
import { extractEntities } from './entityExtractor.js';
import { storeEntities, createRemindersFromEntities } from './reminderCreator.js';
import { config } from '../lib/config.js';
import {
  createItem,
  getOrCreateTag,
  linkTagToItem,
  getCategoryByName,
  linkCategoryToItem,
  updateItem,
} from '../db/queries.js';

export interface PipelineResult {
  itemId: string;
  type: string;
  title: string;
  description: string;
  category: string;
  tags: string[];
  confidence: number;
  aiUsed: boolean;
  embeddingGenerated: boolean;
  summary?: string;
}

export async function processContent(rawContent: string): Promise<PipelineResult> {
  console.log('\n🧠 [Pipeline] Starting processing...');
  const startTime = Date.now();

  // ── Step 1: Type Detection ──
  console.log('  📌 Step 1: Type detection...');
  const typeResult = detectType(rawContent);
  console.log(`     → Type: ${typeResult.type}${typeResult.extractedUrl ? `, URL: ${typeResult.extractedUrl}` : ''}`);

  // ── Step 2: Metadata Extraction ──
  console.log('  📄 Step 2: Metadata extraction...');
  let metadata;
  if (typeResult.type === 'link' && typeResult.extractedUrl) {
    metadata = await extractLinkMetadata(typeResult.extractedUrl);
  } else {
    metadata = extractNoteMetadata(rawContent);
  }
  console.log(`     → Title: "${metadata.title}"`);

  // ── Step 3: NLP Tagging ──
  console.log('  🏷️  Step 3: NLP tagging...');
  const textForAnalysis = `${metadata.title} ${metadata.description} ${rawContent}`.slice(0, config.maxContentLength);
  const nlpResult = extractTags(textForAnalysis);
  console.log(`     → Tags: [${nlpResult.tags.join(', ')}]`);

  // ── Step 4: Rule-Based Classification ──
  console.log('  📊 Step 4: Rule-based classification...');
  const classification = classifyContent(textForAnalysis);
  console.log(`     → Category: ${classification.category} (confidence: ${classification.confidence.toFixed(2)})`);

  // ── Step 5: AI Fallback (if needed) ──
  let aiUsed = false;
  let finalCategory = classification.category;
  let finalTags = nlpResult.tags;
  let aiSummary: string | undefined;

  if (classification.confidence < config.classificationConfidenceThreshold) {
    console.log('  🤖 Step 5: AI fallback (low confidence)...');
    aiUsed = true;
    const aiResult = await aiClassifyAndTag(textForAnalysis);
    
    if (aiResult.category !== 'Other') {
      finalCategory = aiResult.category;
    }
    
    // Merge AI tags with NLP tags (deduplicated)
    if (aiResult.tags.length > 0) {
      finalTags = [...new Set([...nlpResult.tags, ...aiResult.tags])].slice(0, 7);
    }
    
    aiSummary = aiResult.summary;
    console.log(`     → AI Category: ${aiResult.category}, AI Tags: [${aiResult.tags.join(', ')}]`);
  } else {
    console.log('  ✅ Step 5: Skipped (high confidence)');
  }

  // ── Step 6: Embedding Generation ──
  console.log('  🔢 Step 6: Embedding generation...');
  const embedding = await generateEmbedding(textForAnalysis);
  const embeddingGenerated = embedding !== null;
  console.log(`     → Embedding: ${embeddingGenerated ? `${embedding!.length}-dim vector` : 'FAILED'}`);

  // ── Step 7: Store in Database ──
  console.log('  💾 Step 7: Storing in database...');
  const item = await createItem({
    type: typeResult.type,
    content_raw: rawContent,
    title: metadata.title,
    description: metadata.description,
    source_url: typeResult.extractedUrl || metadata.sourceUrl,
    ai_summary: aiSummary,
    confidence_score: classification.confidence,
    embedding: embedding || undefined,
  });

  // Link tags
  for (const tagName of finalTags) {
    try {
      const tag = await getOrCreateTag(tagName);
      if (tag) {
        await linkTagToItem(item.id, tag.id);
      }
    } catch (err) {
      console.warn(`     ⚠️ Failed to link tag "${tagName}":`, err);
    }
  }

  // Link category
  try {
    const category = await getCategoryByName(finalCategory);
    if (category) {
      await linkCategoryToItem(item.id, category.id);
    }
  } catch (err) {
    console.warn(`     ⚠️ Failed to link category "${finalCategory}":`, err);
  }

  // ── Step 8: Entity Extraction ──
  console.log('  🔍 Step 8: Entity extraction...');
  let entities = [];
  let remindersCreated = 0;
  try {
    entities = await extractEntities(textForAnalysis);
    
    // Store entities
    if (entities.length > 0) {
      await storeEntities(item.id, entities);
    }

    // ── Step 9: Reminder Creation (Option B: Liberal Pairing) ──
    console.log('  📋 Step 9: Reminder creation (with fallback to item title)...');
    const reminders = await createRemindersFromEntities(item.id, entities, metadata.title);
    remindersCreated = reminders.length;
    
    if (remindersCreated > 0) {
      console.log(`     → Created ${remindersCreated} reminder(s)`);
    }
  } catch (err) {
    console.warn(`     ⚠️ Entity extraction/reminder creation failed:`, err);
  }

  const elapsed = Date.now() - startTime;
  console.log(`\n✅ [Pipeline] Complete in ${elapsed}ms`);
  console.log(`   Item: ${item.id}`);
  console.log(`   Type: ${typeResult.type} | Category: ${finalCategory} | Tags: [${finalTags.join(', ')}]`);
  console.log(`   Entities: ${entities.length} | Reminders: ${remindersCreated}`);
  console.log(`   AI Used: ${aiUsed} | Embedding: ${embeddingGenerated}\n`);

  return {
    itemId: item.id,
    type: typeResult.type,
    title: metadata.title,
    description: metadata.description,
    category: finalCategory,
    tags: finalTags,
    confidence: classification.confidence,
    aiUsed,
    embeddingGenerated,
    summary: aiSummary,
  };
}
