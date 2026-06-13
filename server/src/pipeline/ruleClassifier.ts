/**
 * Step 4: Rule-Based Classification (No AI)
 * Classifies content into categories using keyword scoring.
 * Returns a confidence score — if below threshold, AI fallback is triggered.
 */

export interface ClassificationResult {
  category: string;
  confidence: number;
  scores: Record<string, number>;
}

const CATEGORY_KEYWORDS: Record<string, string[]> = {
  Tech: [
    'programming', 'software', 'ai', 'artificial intelligence', 'machine learning',
    'api', 'code', 'developer', 'github', 'react', 'node', 'python', 'javascript',
    'typescript', 'database', 'cloud', 'devops', 'frontend', 'backend', 'algorithm',
    'data science', 'neural network', 'deep learning', 'computer', 'server',
    'startup', 'saas', 'web', 'app', 'mobile', 'framework', 'library', 'open source',
    'linux', 'docker', 'kubernetes', 'terraform', 'aws', 'azure', 'gcp',
    'cybersecurity', 'encryption', 'blockchain', 'quantum', 'robotics',
  ],
  Finance: [
    'stock', 'invest', 'investment', 'money', 'crypto', 'bitcoin', 'ethereum',
    'market', 'economy', 'bank', 'trading', 'portfolio', 'dividend', 'bond',
    'financial', 'budget', 'savings', 'retirement', 'tax', 'revenue', 'profit',
    'fintech', 'defi', 'nft', 'forex', 'mutual fund', 'interest rate',
    'inflation', 'gdp', 'recession', 'bull', 'bear', 'ipo', 'valuation',
  ],
  Study: [
    'learn', 'course', 'tutorial', 'university', 'exam', 'research', 'paper',
    'academic', 'study', 'lecture', 'homework', 'assignment', 'thesis',
    'professor', 'student', 'education', 'school', 'college', 'degree',
    'certification', 'quiz', 'textbook', 'curriculum', 'syllabus', 'grade',
    'scholarship', 'phd', 'masters', 'bachelors', 'mathematics', 'physics',
    'chemistry', 'biology', 'history', 'literature', 'philosophy',
  ],
  Personal: [
    'journal', 'diary', 'todo', 'reminder', 'goal', 'habit', 'personal',
    'family', 'friend', 'birthday', 'anniversary', 'wedding', 'vacation',
    'travel', 'recipe', 'cooking', 'grocery', 'shopping', 'home', 'garden',
    'pet', 'relationship', 'self', 'reflection', 'gratitude', 'dream',
    'bucket list', 'resolution', 'milestone', 'memory', 'photo',
  ],
  Entertainment: [
    'movie', 'music', 'game', 'gaming', 'netflix', 'spotify', 'youtube',
    'tv', 'show', 'series', 'anime', 'manga', 'comic', 'book', 'novel',
    'podcast', 'stream', 'twitch', 'concert', 'festival', 'album',
    'artist', 'actor', 'film', 'cinema', 'theater', 'playlist', 'review',
    'meme', 'funny', 'humor', 'entertainment', 'celebrity',
  ],
  News: [
    'breaking', 'report', 'journalist', 'politics', 'election', 'government',
    'president', 'minister', 'congress', 'senate', 'parliament', 'policy',
    'law', 'regulation', 'protest', 'crisis', 'war', 'peace', 'treaty',
    'climate', 'environment', 'global', 'world', 'international', 'nation',
    'headline', 'press', 'media', 'bbc', 'cnn', 'reuters', 'associated press',
  ],
  Health: [
    'workout', 'exercise', 'diet', 'mental health', 'meditation', 'nutrition',
    'fitness', 'yoga', 'gym', 'running', 'weight', 'calories', 'protein',
    'sleep', 'stress', 'anxiety', 'depression', 'therapy', 'mindfulness',
    'vitamin', 'supplement', 'disease', 'vaccine', 'doctor', 'hospital',
    'medicine', 'prescription', 'wellness', 'immune', 'cardio', 'strength',
  ],
};

export function classifyContent(text: string): ClassificationResult {
  const lowerText = text.toLowerCase();
  const words = lowerText.split(/\s+/);
  const wordSet = new Set(words);
  
  const scores: Record<string, number> = {};
  let maxScore = 0;
  let bestCategory = 'Other';

  for (const [category, keywords] of Object.entries(CATEGORY_KEYWORDS)) {
    let score = 0;
    
    for (const keyword of keywords) {
      if (keyword.includes(' ')) {
        // Multi-word keyword: check substring
        if (lowerText.includes(keyword)) {
          score += 2; // Multi-word matches are worth more
        }
      } else {
        // Single word: check set membership
        if (wordSet.has(keyword)) {
          score += 1;
        }
      }
    }

    // Normalize by keyword list size
    const normalizedScore = score / Math.sqrt(keywords.length);
    scores[category] = normalizedScore;

    if (normalizedScore > maxScore) {
      maxScore = normalizedScore;
      bestCategory = category;
    }
  }

  // Convert to confidence (0-1)
  // We consider 3+ keyword matches in a category as high confidence
  const confidence = Math.min(maxScore / 3, 1);

  return {
    category: confidence > 0.3 ? bestCategory : 'Other',
    confidence,
    scores,
  };
}
