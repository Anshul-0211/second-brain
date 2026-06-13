# 🧠 Second Brain — Technical Explanation

## Project Overview

**Second Brain** is a **personal, zero-cost, AI-powered content management system** that helps users save, organize, and retrieve information from anywhere. It automatically classifies content (links, notes, files), extracts metadata, tags items, and enables natural-language search across their entire personal knowledge base.

**Stack**: Flutter (frontend) + Node.js/Hono (backend) + Supabase PostgreSQL (database) + Groq/HuggingFace (AI)

**Goal**: A single, searchable "brain dump" where everything gets organized automatically.

---

## What IS Currently Working ✅

### **Phase 1: Backend Scaffolding** ✅
- Hono.js REST API server at `localhost:3000`
- Supabase PostgreSQL database with pgvector extension
- Full database schema: `items`, `categories`, `tags`, `item_tags`, `item_categories`, `user_profile`
- Seeded 8 default categories (Tech, Finance, Study, Personal, Entertainment, News, Health, Other)

### **Phase 2: Processing Pipeline** ✅ (~95%)
1. **Type Detector** ✅ — Detects if content is a link, note, or file (regex-based)
2. **Metadata Extractor** ✅ — Extracts title, description, author from web links
3. **NLP Tagger** ✅ — Extracts entities and keywords using compromise.js
4. **Rule Classifier** ✅ — Keyword-based scoring to assign initial category
5. **AI Fallback** ✅ — Groq LLaMA classifier (when rule confidence < 0.7)
6. **Embedder** ⏳ **(PENDING)** — HuggingFace API has 403 permission issue (non-blocking)

### **Phase 3: Backend API** ✅
- **Items routes** (`/api/items`): Full CRUD with automatic pipeline processing
- **Search routes** (`/api/search`): Tag-based search fallback (semantic search pending)
- **Tags/Categories routes** (`/api/tags`, `/api/categories`, `/api/profile`): Metadata retrieval
- **API Key middleware**: Protects endpoints with `x-api-key: dev-key` header

### **Phase 4: Flutter Client** ✅
1. **Dump Screen** ✅ — Text input with type detection badge, submit button
2. **Feed Screen** ✅ — Grid/list of items, category filter chips, pull-to-refresh
3. **Search Screen** ✅ — Debounced search input, tag-based results with "time ago" timestamps
4. **Detail Screen** ✅ — Full item view, tags, category, clickable URL (url_launcher), delete button
5. **Providers** ✅ — ItemsProvider, SearchProvider (Provider state management)
6. **Theme** ✅ — Cognitive Nebula design system (dark mode, glassmorphism, gradients)
7. **Models** ✅ — Item, Tag, Category with full serialization

---

## Architecture Diagram

```
┌─────────────────────────────────────┐
│      Flutter Mobile App             │
│  Dump │ Feed │ Search │ Detail      │
│  (Bottom nav, Provider state mgmt)  │
└──────────────┬──────────────────────┘
               │
               │ HTTP REST API
               │ (API key auth)
               ▼
┌─────────────────────────────────────┐
│    Node.js + Hono API Server        │
│    http://localhost:3000            │
│                                     │
│  POST /api/items       ← Dump flow  │
│  GET  /api/items       ← Feed list  │
│  POST /api/search      ← Search     │
│  GET  /api/tags        ← Metadata   │
└──────────────┬──────────────────────┘
               │
    ┌──────────▼──────────┐
    │  Processing         │
    │  Pipeline           │
    │                     │
    │  1. Type Detect     │
    │  2. Metadata Extr.  │
    │  3. NLP Tagging     │
    │  4. Rule Classify   │
    │  5. AI Fallback     │
    │  6. Embedder        │
    └─────┬───────┬───────┘
          │       │
    ┌─────▼──┐  ┌─▼──────────────┐
    │Supabase│  │External APIs    │
    │        │  │                 │
    │items   │  │• Groq (AI)      │
    │tags    │  │• HuggingFace    │
    │categor │  │  (embeddings)   │
    │user    │  │                 │
    └────────┘  └─────────────────┘
```

---

## Full Data Flow: "Dump → Feed → Search"

### **Use Case: User dumps a YouTube link**

User: "Check out https://www.youtube.com/watch?v=AA24OlKrRfo"

#### **1. Dump Flow (POST /api/items)**

```
Input: { content: "Check out https://www.youtube.com/watch?v=AA24OlKrRfo" }
                                    │
                                    ▼
         🧠 PIPELINE ORCHESTRATOR (processor.ts)
                                    │
        ├─→ 📌 TYPE DETECTOR
        │   └─→ Regex: URL detected ✅
        │   └─→ Result: type = "link"
        │
        ├─→ 📄 METADATA EXTRACTOR (article-extractor)
        │   └─→ Fetches YouTube page
        │   └─→ Extracts: title="[Video Title]", description="[Description]"
        │   └─→ Stores: source_url, ai_summary
        │
        ├─→ 🏷️  NLP TAGGER (compromise.js)
        │   └─→ Tokenizes content
        │   └─→ Extracts: entities, nouns, keywords
        │   └─→ Tags: [youtube, video, link, ...]
        │
        ├─→ 📊 RULE CLASSIFIER
        │   └─→ Keyword scoring against categories
        │   └─→ Matches: Entertainment (80% confidence)
        │   └─→ If confidence ≥ 0.7 → done
        │   └─→ Else → next step
        │
        ├─→ 🤖 AI FALLBACK (Groq LLaMA)
        │   └─→ Prompt: "Classify this YouTube video"
        │   └─→ Response: category="Entertainment", extra_tags=[video, tutorial, entertainment]
        │   └─→ Combines: NLP tags + AI tags
        │
        ├─→ 🔢 EMBEDDER (HuggingFace)
        │   └─→ Text: title + description
        │   └─→ API: /models/all-MiniLM-L6-v2
        │   └─→ Response: embedding=[0.12, -0.45, ...] (384 dimensions)
        │   └─→ Status: ⚠️  Currently failing (403)
        │
        ├─→ 💾 STORE IN DATABASE
        │   └─→ items table: Create row with all above data
        │   └─→ categories table: Link item to "Entertainment"
        │   └─→ tags table: Create/link all extracted tags
        │   └─→ item_tags table: Many-to-many relationship
        │
                                    ▼
Output: { success: true, item: {...fullData...}, confidence: 0.85, aiUsed: true }
```

**Result in Database:**
```json
{
  "id": "f889787f-...",
  "type": "link",
  "title": "Video Title",
  "description": "...",
  "source_url": "https://www.youtube.com/...",
  "ai_summary": "A YouTube video about ...",
  "confidence_score": 0.85,
  "embedding": [0.12, -0.45, ...],  // ← For semantic search
  "created_at": "2026-04-09T10:23:00Z",
  "categories": [{ id: "...", name: "Entertainment", color: "#8B5CF6" }],
  "tags": [
    { id: "...", name: "youtube" },
    { id: "...", name: "video" },
    { id: "...", name: "entertainment" },
    ...
  ]
}
```

---

### **2. Feed Flow (GET /api/items)**

```
User navigates to Feed Screen
                    │
                    ▼
    Fetch: GET /api/items?limit=50&offset=0
                    │
                    ▼
         Supabase queries:
         - items table (newest first)
         - Join with categories
         - Join with tags
                    │
                    ▼
         Return: [{ item1 }, { item2 }, ...]
                    │
                    ▼
     Flutter UI renders:
     
     ┌──────────────────────────┐
     │ Item Card                │
     ├──────────────────────────┤
     │ 🎥 VIDEO | Saved 2h ago  │
     │                          │
     │ [Video Title]            │
     │ Video description...     │
     │                          │
     │ 🟣 Entertainment         │
     │ #youtube #video #link   │
     └──────────────────────────┘
```

**Features:**
- Category filter chips (tap "Tech" → shows only Tech items)
- Pull-to-refresh (triggers GET /api/items again)
- Time-ago formatting (2h ago, 1d ago, etc.)
- Tap card → navigates to Detail screen

---

### **3. Search Flow (POST /api/search)**

#### **Current Implementation (Tag-based, working now):**

```
User types: "youtube"
        │
        ▼
POST /api/search { query: "youtube" }
        │
        ▼
Search Algorithm:
├─→ Search content (title, description, content_raw) for "youtube"
│   └─→ Matches: 1 item
│
├─→ Search categories for "youtube"
│   └─→ No category named "youtube"
│   └─→ Matches: 0 items
│
├─→ Search tags for "youtube"
│   └─→ Matches: 1 tag named "youtube"
│   └─→ Returns: All items with this tag
│   └─→ Matches: 1 item
│
├─→ Deduplicate & sort by created_at
│
        ▼
Return: [{item}, ...]
(searchMethod: "tag-based (fallback)")
```

**Current Flow:**
1. Try semantic search (embed query, find similar embeddings) ← Currently failing due to HF token issue
2. Fallback to tag-based search ← **Currently active**
3. Return results with tags/categories enriched

---

#### **Future Implementation (Semantic Search, pending HF fix):**

```
User types: "youtube videos I should watch later"
        │
        ▼
POST /api/search { query: "youtube videos I should watch later" }
        │
        ▼
Search Algorithm:
├─→ EMBED QUERY
│   └─→ Text: "youtube videos I should watch later"
│   └─→ API: HuggingFace all-MiniLM-L6-v2
│   └─→ Response: query_embedding = [0.15, -0.32, ...] (384 dims)
│
├─→ VECTOR SIMILARITY SEARCH
│   └─→ DB function: search_items(query_embedding, threshold=0.5, limit=10)
│   └─→ SQL: SELECT * FROM items WHERE 1 - (embedding <=> query_embedding) > 0.5
│   └─→ Cosine similarity: Compares all 384-dim embeddings
│   └─→ Returns ranked by similarity score (0-1)
│
├─→ ENRICH RESULTS
│   └─→ For each item: fetch tags, categories, calculate similarity %
│
        ▼
Return: [
  { item: {...}, similarity: 0.92 },  // ← "Great match!"
  { item: {...}, similarity: 0.78 },  // ← "Good match"
  { item: {...}, similarity: 0.61 },  // ← "Relevant"
]
(searchMethod: "semantic")
```

**Why embeddings are better:**
- "youtube videos to watch" would find:
  - YouTube video items ✅
  - Items about video recommendations ✅
  - Items tagged "entertainment" (semantically related) ✅
- Without embeddings, only matches exact words (limited)

---

## Database Schema

```sql
CREATE TABLE items (
  id UUID PRIMARY KEY,
  type TEXT ('link' | 'note' | 'file'),
  content_raw TEXT,               -- Original input
  title TEXT,                     -- Extracted/AI-generated
  description TEXT,               -- Extracted/AI-generated
  source_url TEXT,                -- For links
  ai_summary TEXT,                -- Groq-generated summary
  confidence_score REAL,          -- 0-1, from classifier
  embedding vector(384),          -- HuggingFace embedding (NULL if failed)
  created_at TIMESTAMPTZ
);

CREATE TABLE categories (
  id UUID PRIMARY KEY,
  name TEXT UNIQUE,               -- Tech, Finance, Study, Personal, ...
  color TEXT                      -- UI color (#6366F1, etc.)
);

CREATE TABLE tags (
  id UUID PRIMARY KEY,
  name TEXT UNIQUE                -- youtube, dsa, algorithm, etc.
);

CREATE TABLE item_tags (
  item_id UUID REFERENCES items.id,
  tag_id UUID REFERENCES tags.id,
  PRIMARY KEY (item_id, tag_id)
);

CREATE TABLE item_categories (
  item_id UUID REFERENCES items.id,
  category_id UUID REFERENCES categories.id,
  PRIMARY KEY (item_id, category_id)
);

-- Vector similarity function
CREATE FUNCTION search_items(
  query_embedding vector(384),
  match_threshold FLOAT = 0.5,
  match_count INT = 10
) RETURNS TABLE (
  id UUID, type TEXT, title TEXT, ..., similarity FLOAT
) AS $$
  SELECT i.id, i.type, i.title, ...,
         1 - (i.embedding <=> query_embedding) AS similarity
  FROM items i
  WHERE 1 - (i.embedding <=> query_embedding) > match_threshold
  ORDER BY i.embedding <=> query_embedding
  LIMIT match_count;
$$ LANGUAGE SQL;
```

**Indexes:**
- `items(created_at DESC)` — Fast feed queries
- `items(type)` — Filter by content type
- `tags(name)` — Tag lookups
- `items USING ivfflat (embedding vector_cosine_ops)` — Fast semantic search (pending)

---

## API Endpoints

### **Items CRUD**

```
POST /api/items
├─ Input: { content: string }
├─ Process: Full pipeline (detect → extract → tag → classify → embed → store)
└─ Output: { success: true, item: {...}, confidence, aiUsed, embeddingGenerated }

GET /api/items?limit=50&offset=0
├─ Input: Query params (pagination)
└─ Output: { items: [item, ...], count, limit, offset }

GET /api/items/:id
├─ Input: Item ID
└─ Output: { item: {..., tags: [...], categories: [...]} }

PATCH /api/items/:id
├─ Input: { title, description, category, tags } (partial updates)
└─ Output: Updated item

DELETE /api/items/:id
├─ Input: Item ID
└─ Output: { success: true }
```

### **Search**

```
POST /api/search
├─ Input: { query: string, threshold: 0.4, limit: 10 }
├─ Process:
│   1. Try semantic search (embed query + vector similarity)
│   2. Fallback to tag-based search (if embeddings fail)
└─ Output: {
     query: string,
     searchMethod: "semantic" | "tag-based (fallback)",
     results: [{ item, tags, categories, similarity }, ...],
     count: number
   }
```

### **Metadata**

```
GET /api/tags
└─ Output: { tags: [{ id, name }, ...] }

GET /api/categories
└─ Output: { categories: [{ id, name, color }, ...] }

GET /api/profile
└─ Output: { profile: { id, display_name, created_at } } or null

POST /api/profile
├─ Input: { displayName: string }
└─ Output: { success: true, profile: {...} }
```

---

## Implementation Status

### ✅ Fully Implemented (Ready for MVP)

| Component | Status | Notes |
|-----------|--------|-------|
| Dump Screen | ✅ | Type detection badge, paste → submit |
| Feed Screen | ✅ | Items display, category filters, pull-refresh |
| Search Screen | ✅ | Tag-based search working, UI responsive |
| Detail Screen | ✅ | Full metadata, clickable URL, delete button |
| Type Detector | ✅ | URL/link/note detection via regex |
| Metadata Extractor | ✅ | Title/desc extraction via article-extractor |
| NLP Tagger | ✅ | Entity extraction via compromise.js |
| Rule Classifier | ✅ | Keyword-based category scoring |
| AI Classifier | ✅ | Groq LLaMA fallback (groq-sdk) |
| Database Schema | ✅ | Full schema with pgvector extension |
| API Routes | ✅ | CRUD, search, metadata endpoints |
| API Key Auth | ✅ | x-api-key header validation |
| Theme System | ✅ | Cognitive Nebula (dark, glassmorphism) |
| State Management | ✅ | Provider (ItemsProvider, SearchProvider) |

### ⏳ Pending (Non-blocking)

| Component | Status | Blocker | Impact |
|-----------|--------|---------|--------|
| HuggingFace Embeddings | ⏳ | 403 permission error | Semantic search unavailable |
| Semantic Search | ⏳ | Embeddings failing | Search less accurate (fallback works) |
| Render Deployment | ⏳ | User action | MVP works locally, not yet prod-ready |
| Flutter APK Build | ⏳ | User action | App works on emulator/web, not APK yet |

---

## How Embeddings Work (Conceptual)

### **What is an Embedding?**

An embedding is a numerical representation of text in a **384-dimensional vector space** (for HuggingFace's `all-MiniLM-L6-v2`).

```
Text: "YouTube video about Python"
       │
       ▼
HuggingFace API
       │
       ▼
Embedding: [0.12, -0.45, 0.89, ..., 0.33]  (384 numbers)
```

**Key property:** Similar texts have similar embeddings (close in vector space).

```
"YouTube video tutorial" ────┐
                              → Embeddings close together
"Video about Python coding"  ┘

"Grocery shopping list" ─────┐
                              → Far apart in vector space
"Quantum physics" ────────────┘
```

### **Semantic Search Process**

```
User query: "python video tutorial"
                    │
                    ▼
           Embed query text
           embedding_query = [0.14, -0.42, ...]
                    │
                    ▼
     Find similar embeddings in DB
     Using COSINE SIMILARITY:
     
     similarity = dot_product(embedding_query, embedding_item)
                  ───────────────────────────────────────
                  ||embedding_query|| × ||embedding_item||
                    │
                    ▼
     Returns items ranked by similarity (0-1)
     
     ["Python tutorial" (0.94),
      "Learn coding" (0.78),
      "Video guide" (0.65),
      "Grocery list" (0.02)]
```

### **Why This Matters**

- **Without embeddings** (current):
  - Query: "python video tutorial"
  - Search: title/description contains "python" OR "video" OR "tutorial"
  - May miss: "Learn to code with Python"

- **With embeddings** (future):
  - Query: "python video tutorial"
  - Find: All items semantically similar to this query
  - Includes: "Learn to code with Python", "Video programming guide", etc.

---

## Use Cases

### **1. Quick Bookmarking with Auto-Organization**

**User**: Saves 10 links in one day
**System**: Automatically classifies as Tech/News/Finance, extracts titles, tags

**Before**: Manual folders + naming
**After**: Dump links → System organizes → Search by keyword

### **2. Multi-format Storage**

**User**: Can dump:
- Links (YouTube, articles, docs)
- Notes (text, ideas, reminders)
- Files (PDFs, images)

**System**: Handles all uniformly with appropriate metadata

### **3. Context-aware Recall**

**User**: "Find that article about AI in medicine"

**System Finds**:
- Exact matches: "AI in medicine" (title)
- Tag matches: "AI" tag
- Semantic matches: Articles about medical AI, healthcare AI, etc.

### **4. Knowledge Graph Creation**

**System builds overtime**:
- Categories: Tech (50 items), Finance (30 items), Study (40 items)
- Tags: python (12), javascript (8), dsa (15), finance (10)
- Relationships: "Items tagged finance" + "Items about trading" = Finance corner

---

## Deployment Architecture (Phase 5)

```
┌─────────────────────────────────┐
│    Flutter App (Web/Mobile)     │
│   (firebase-hosting or vercel)  │
└──────────────┬──────────────────┘
               │ HTTPS
               ▼
┌─────────────────────────────────┐
│  Node.js Server (Render.com)    │
│  https://second-brain.render... │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│  Supabase PostgreSQL (cloud)    │
│  pgvector enabled, backups ✅   │
└─────────────────────────────────┘
```

**Free Tier Costs**:
- Render: Free (sleeps after 15min, ~1-2sec cold start)
- Supabase: Free (500MB, auto backups)
- HuggingFace: Free (rate-limited)
- Groq: Free (fast inference)
- Firebase: Free (static hosting)

---

## Next Steps

### **Immediate (MVP Complete)**
1. ✅ User can dump content
2. ✅ System auto-tags and categorizes
3. ✅ User can browse feed and filter
4. ✅ User can search by tags (fallback)
5. ✅ User can view details and delete

### **Short-term (Production Ready)**
1. Fix HuggingFace Inference API permissions → Enable semantic search
2. Deploy backend to Render
3. Update Flutter app URL to production
4. Build APK for Android distribution

### **Medium-term (Enhanced UX)**
1. Batch dump (multiple items at once)
2. Import from browser bookmarks
3. Export/backup to JSON
4. Sharing specific items/collections
5. Custom categories per user

### **Long-term (Advanced Features)**
1. Multi-user support with Auth0/Firebase
2. Collaboration (shared second brains)
3. Browser extension for one-click dumping
4. Mobile native apps (iOS, Android with Flutter)
5. AI-generated summaries on demand
6. Trending topics/most-searched insights

---

## Code Structure

```
scnd_brain/
├── server/                          # Node.js + Hono backend
│   ├── src/
│   │   ├── index.ts                 # Entry point, routes setup
│   │   ├── lib/config.ts            # Environment variables
│   │   ├── db/
│   │   │   ├── client.ts            # Supabase connection
│   │   │   ├── queries.ts           # Typed DB helpers
│   │   │   └── migrations/001_init.sql
│   │   ├── middleware/apiKey.ts     # Auth middleware
│   │   ├── routes/
│   │   │   ├── items.ts             # CRUD endpoints
│   │   │   ├── search.ts            # Search endpoint
│   │   │   └── tags.ts              # Metadata endpoints
│   │   └── pipeline/                # Processing pipeline
│   │       ├── processor.ts         # Orchestrator
│   │       ├── typeDetector.ts
│   │       ├── metadataExtractor.ts
│   │       ├── nlpTagger.ts
│   │       ├── ruleClassifier.ts
│   │       ├── aiClassifier.ts
│   │       └── embedder.ts
│   ├── .env                         # Credentials (secrets)
│   └── package.json
│
└── lib/                             # Flutter app
    ├── main.dart                    # Entry point
    ├── app/
    │   ├── theme.dart               # Cognitive Nebula
    │   └── routes.dart
    ├── models/
    │   └── item.dart                # Item, Tag, Category
    ├── services/
    │   └── api_service.dart         # HTTP client
    ├── providers/
    │   └── providers.dart           # ItemsProvider, SearchProvider
    ├── screens/
    │   ├── dump_screen.dart
    │   ├── feed_screen.dart
    │   ├── search_screen.dart
    │   └── detail_screen.dart
    └── widgets/
        ├── item_card.dart
        └── ...
```

---

## Key Design Decisions

### **Why Supabase?**
- Free PostgreSQL + vector search (pgvector)
- Built-in auth (future multi-user)
- Real-time subscriptions (optional)
- Generous free tier (500MB, 100k queries/month)

### **Why Groq?**
- Fastest open-source LLM inference
- Free tier with high rate limit
- LLaMA models (capable, lightweight)
- Much faster than OpenAI for real-time classification

### **Why HuggingFace Embedding?**
- Free Inference API
- Small, fast model (all-MiniLM-L6-v2)
- 384 dimensions (reasonable size/accuracy tradeoff)
- No authentication overhead

### **Why Provider (Flutter)?**
- Simple, lightweight state management
- Built-in, no external package needed (well, minimal)
- Scales well for this app's scope
- Easy to upgrade to Riverpod later

### **Why Render?**
- Free Node.js hosting (sleeps, but acceptable for personal app)
- Simple deploy from GitHub
- Environment variables management
- Auto-builds on push

---

## Conclusion

**Second Brain is a complete MVP** combining:
- ✅ Intelligent content classification (rules + AI)
- ✅ Automatic metadata extraction
- ✅ Flexible storage (links, notes, files)
- ✅ Quick search (tag-based now, semantic later)
- ✅ Beautiful UI (Cognitive Nebula theme)
- ✅ Zero-cost infrastructure

The architecture is **scalable and maintainable**, with clear separation between processing pipeline and UI. Embeddings will be enabled once HuggingFace permissions are fixed, unlocking semantic search capabilities for even more powerful knowledge retrieval.

This is the personal knowledge base every developer (and student) needs. 🧠✨
