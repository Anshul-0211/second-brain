# 🧠 Second Brain — Implementation Plan (v2)

## Project Overview

Build a **personal, zero-cost, AI-powered "Second Brain"** — a single place to dump anything (links, notes, ideas) that auto-organizes, tags, and enables natural-language search. This is a continuation of the plan from previous conversations, now refined and ready for execution.

---

## What Changed from Previous Plan

> [!NOTE]
> The previous conversation produced a detailed implementation plan but **no code was written** — the Flutter project is still the default counter app scaffold. This plan refines that prior work and adds **Stitch MCP for UI design**.

Key changes:
- **Added Phase 0**: Use Stitch MCP to design all UI screens before coding
- **Simplified for personal use**: No multi-user auth needed (single user, API key protection)
- **Same zero-cost stack**: Supabase + Groq + HuggingFace + Render

---

## User Review Required

> [!NOTE]
> **Decisions Made:**
> - ✅ **Auth**: Skip full auth, but include a simple signup/profile setup on first launch. API protected with static API key.
> - ✅ **State Management**: Provider
> - ✅ **Target**: Mobile APK first, but works on web too
> - ✅ **Groq API**: Already have key
> - 🔧 **Supabase**: Will set up during implementation
> - 🔧 **HuggingFace**: Will set up during implementation

> [!WARNING]
> **Render cold start**: Free tier backend sleeps after 15 mins of inactivity (~30-60s cold start). Mitigate with UptimeRobot (free) for a keep-alive ping. Acceptable for personal use.

---

## Zero-Cost Tech Stack

| Layer | Technology | Cost | Notes |
|:---|:---|:---|:---|
| **Client** | Flutter (Mobile + Web) | Free | Already scaffolded |
| **UI Design** | Stitch MCP | Free | Design screens before coding |
| **API Server** | Node.js + Hono | Free | Lightweight, Render-compatible |
| **Database** | Supabase (PostgreSQL + pgvector) | Free | 500MB, built-in vector search |
| **NLP (local)** | compromise.js | Free | Runs in Node.js, no API calls |
| **AI Fallback** | Groq (`llama-3.1-8b-instant`) | Free | Only when rule-confidence < 0.7 |
| **Embeddings** | HuggingFace Inference API (`all-MiniLM-L6-v2`) | Free | 384-dim vectors |
| **API Hosting** | Render (free tier) | Free | Persistent Node.js server |
| **Client Hosting** | Firebase Hosting / Vercel | Free | Static Flutter web build |

---

## Architecture

```
┌─────────────────────────────────────┐
│         Flutter Client              │
│  Dump │ Feed │ Search │ Detail      │
│  (UI designed via Stitch MCP)       │
└──────────────┬──────────────────────┘
               │ REST API (API key auth)
┌──────────────▼──────────────────────┐
│     Node.js + Hono API Layer        │
│  /api/items  /api/search  /api/tags │
└──────────────┬──────────────────────┘
               │
    ┌──────────▼──────────────┐
    │   Processing Pipeline   │
    │                         │
    │ 1. Type Detector        │  ← Rule-based (URL regex)
    │ 2. Metadata Extractor   │  ← article-extractor (link → title/desc)
    │ 3. NLP Tagger           │  ← compromise.js (entities, keywords)
    │ 4. Rule Classifier      │  ← Keyword-map rules (confidence score)
    │ 5. AI Fallback          │  ← Groq (only if confidence < 0.7)
    │ 6. Embedder             │  ← HuggingFace API (all-MiniLM-L6-v2)
    └─────┬───────────┬───────┘
          │           │
┌─────────▼───┐ ┌────▼──────────────┐
│  Supabase   │ │  pgvector (same   │
│  PostgreSQL │ │  Supabase DB)     │
│  items,tags │ │  vector column    │
│  categories │ │  cosine search    │
└─────────────┘ └───────────────────┘
```

---

## Database Schema

```sql
-- Enable pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Items (core content)
CREATE TABLE items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL CHECK (type IN ('link', 'note', 'file')),
  content_raw TEXT NOT NULL,
  title TEXT,
  description TEXT,
  source_url TEXT,
  ai_summary TEXT,
  confidence_score REAL DEFAULT 0.0,
  embedding vector(384),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Categories
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  color TEXT
);

INSERT INTO categories (name, color) VALUES
  ('Tech', '#6366F1'), ('Finance', '#10B981'), ('Study', '#F59E0B'),
  ('Personal', '#EC4899'), ('Entertainment', '#8B5CF6'), ('News', '#3B82F6'),
  ('Health', '#14B8A6'), ('Other', '#6B7280');

-- Tags
CREATE TABLE tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL
);

-- Junctions
CREATE TABLE item_tags (
  item_id UUID REFERENCES items(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (item_id, tag_id)
);

CREATE TABLE item_categories (
  item_id UUID REFERENCES items(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  PRIMARY KEY (item_id, category_id)
);

-- Vector search index
CREATE INDEX ON items USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```

> [!NOTE]
> No `users` table — single-user personal app. The `user_id` column from the previous plan is removed.

---

## Proposed Changes

### Phase 0: UI Design with Stitch MCP

Create a new Stitch project and design all 4 core screens. This gives us:
- A visual reference to build from
- Exportable design tokens (colors, fonts, spacing)
- Consistent design language across screens

#### Screens to Design
1. **Dump Screen** — Large paste area, minimal chrome, "brain dump" feel
2. **Feed Screen** — Card grid/list, category chips, search bar at top
3. **Search Screen** — Full-screen search with results, "Search your memory..." 
4. **Item Detail** — Content, tags, category, related items, timestamps

#### Design System
- **Theme**: Dark mode, deep purple/indigo palette
- **Font**: Inter
- **Roundness**: 8px corners
- **Style**: Glassmorphism, subtle animations, premium feel
- **Device**: Mobile-first

---

### Phase 1: Backend Scaffolding

#### [NEW] `server/` — Node.js + Hono backend

```
server/
├── package.json
├── tsconfig.json
├── .env.example
├── src/
│   ├── index.ts                 # Hono entry, CORS, routes
│   ├── lib/
│   │   └── config.ts            # Env vars
│   ├── db/
│   │   ├── client.ts            # Supabase client
│   │   ├── queries.ts           # Typed DB helpers
│   │   └── migrations/
│   │       └── 001_init.sql     # Full schema
│   ├── middleware/
│   │   └── apiKey.ts            # Simple API key auth
│   ├── routes/
│   │   ├── items.ts             # CRUD
│   │   ├── search.ts            # Semantic search
│   │   └── tags.ts              # Tags/categories
│   └── pipeline/
│       ├── processor.ts         # Orchestrator
│       ├── typeDetector.ts      # URL/note/file detection
│       ├── metadataExtractor.ts # Title/desc extraction
│       ├── nlpTagger.ts         # compromise.js
│       ├── ruleClassifier.ts    # Keyword scoring
│       ├── aiClassifier.ts      # Groq fallback
│       └── embedder.ts          # HuggingFace API
```

Dependencies: `hono`, `@supabase/supabase-js`, `compromise`, `groq-sdk`, `article-extractor`, `dotenv`

---

### Phase 2: Processing Pipeline

Each step of the pipeline runs sequentially. Individual step failures don't break the pipeline.

| Step | Module | Technology | When AI Used? |
|:---|:---|:---|:---|
| 1. Type Detection | `typeDetector.ts` | Regex/rules | Never |
| 2. Metadata Extraction | `metadataExtractor.ts` | article-extractor | Never |
| 3. NLP Tagging | `nlpTagger.ts` | compromise.js | Never |
| 4. Rule Classification | `ruleClassifier.ts` | Keyword scoring | Never |
| 5. AI Fallback | `aiClassifier.ts` | Groq API | Only if confidence < 0.7 |
| 6. Embedding | `embedder.ts` | HuggingFace API | Always (but not "AI" per se) |

---

### Phase 3: Flutter Client

#### [MODIFY] `pubspec.yaml` — Add dependencies
- `http`, `provider`, `go_router`, `google_fonts`, `shimmer`, `flutter_animate`, `shared_preferences`

#### [MODIFY] `lib/main.dart` — Rewrite entry point

#### [NEW] Flutter app structure
```
lib/
├── main.dart
├── app/
│   ├── app.dart           # MaterialApp config
│   ├── routes.dart        # GoRouter setup
│   └── theme.dart         # Design system from Stitch
├── models/
│   ├── item.dart
│   ├── tag.dart
│   └── category.dart
├── services/
│   ├── api_service.dart   # HTTP client to backend
│   └── storage_service.dart
├── providers/
│   ├── items_provider.dart
│   └── search_provider.dart
├── screens/
│   ├── dump_screen.dart
│   ├── feed_screen.dart
│   ├── search_screen.dart
│   └── detail_screen.dart
└── widgets/
    ├── item_card.dart
    ├── tag_chip.dart
    ├── category_badge.dart
    ├── dump_input.dart
    └── search_bar.dart
```

---

### Phase 4: Search System

```
User types: "That startup article I saved last week"
                    │
                    ▼
        Embed query via HuggingFace API
                    │
                    ▼
        pgvector cosine similarity search
                    │
                    ▼
        Return top 10 matches ranked by similarity
```

---

### Phase 5: Deploy (All Free)

| Service | Platform | Cost |
|:---|:---|:---|
| Backend | Render (free) | $0 |
| Database | Supabase (free) | $0 |
| Flutter Web | Vercel / Firebase Hosting | $0 |
| Flutter Mobile | Direct APK | $0 |

---

## Execution Order

1. **Phase 0**: Design UI screens in Stitch MCP (get visual reference)
2. **Phase 1**: Scaffold backend, set up DB schema
3. **Phase 2**: Build processing pipeline (the core intelligence)
4. **Phase 3**: Build Flutter client (using Stitch designs as reference)
5. **Phase 4**: Wire up search system
6. **Phase 5**: Deploy & verify

---

## Decisions (Resolved)

- ✅ **Auth**: Simple signup on first launch, API key for backend protection
- ✅ **State management**: Provider
- ✅ **Accounts**: Groq ready, Supabase + HuggingFace to be set up during build
- ✅ **Platform**: Mobile APK first, responsive for web

---

## Verification Plan

### Automated Tests
- Unit tests for each pipeline step (type detection, NLP tagger, rule classifier)
- Integration test: raw content → stored item with tags + embedding
- Search test: store samples → verify semantic search returns correct results

### Manual Verification
- Run Flutter app locally (`flutter run -d chrome` or `flutter run`)
- Test dump flow: paste URL → verify auto-title/tags
- Test dump flow: paste text → verify classification
- Test search: natural language → verify relevant results
- Test feed: items display with correct tags/categories

### Browser Testing
- Flutter web responsive layout in Chrome
- Mobile viewport test
