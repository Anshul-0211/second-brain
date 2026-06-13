import 'dotenv/config';

export const config = {
  port: parseInt(process.env.PORT || '3000'),
  nodeEnv: process.env.NODE_ENV || 'development',
  
  // Supabase
  supabaseUrl: process.env.SUPABASE_URL || '',
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY || '',
  supabaseServiceKey: process.env.SUPABASE_SERVICE_KEY || '',
  
  // Groq AI (classification fallback)
  groqApiKey: process.env.GROQ_API_KEY || '',
  
  // Cloudflare Workers AI (embeddings)
  cfApiToken: process.env.CF_API_TOKEN || '',
  cfAccountId: process.env.CF_ACCOUNT_ID || '',
  
  // HuggingFace (embeddings) - DEPRECATED, use Cloudflare
  hfToken: process.env.HF_TOKEN || '',
  
  // API Key protection
  apiKey: process.env.API_KEY || 'dev-key',
  
  // Pipeline thresholds
  classificationConfidenceThreshold: 0.7,
  maxContentLength: 5000,
  embeddingModel: 'sentence-transformers/all-MiniLM-L6-v2',
  groqModel: 'llama-3.1-8b-instant',
} as const;

// Validate required config
export function validateConfig(): string[] {
  const errors: string[] = [];
  if (!config.supabaseUrl) errors.push('SUPABASE_URL is required');
  if (!config.supabaseServiceKey) errors.push('SUPABASE_SERVICE_KEY is required');
  if (!config.groqApiKey) errors.push('GROQ_API_KEY is required');
  if (!config.cfApiToken) errors.push('CF_API_TOKEN is required (Cloudflare Workers AI)');
  if (!config.cfAccountId) errors.push('CF_ACCOUNT_ID is required (Cloudflare Workers AI)');
  return errors;
}
