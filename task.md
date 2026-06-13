# 🧠 Second Brain — Task Tracker

## Phase 0: UI Design (Stitch MCP)
- [x] Create Stitch project "Second Brain" (ID: 4116248251126465297)
- [x] Create design system — "Aether Intelligence / Cognitive Nebula"
- [x] Design Dump Screen (mobile)
- [x] Design Feed Screen (mobile)
- [x] Design Search Screen (mobile)
- [x] Design Item Detail Screen (mobile)

## Phase 1: Backend Scaffolding & Database
- [x] Initialize Node.js + Hono project (`server/`)
- [x] Create database migration SQL (`server/src/db/migrations/001_init.sql`)
- [x] Create server config and env setup
- [x] Create Supabase client module
- [x] Install npm dependencies (92 packages, 0 vulnerabilities)
- [ ] Set up Supabase project (USER action needed)
- [ ] Set up HuggingFace token (USER action needed)

## Phase 2: Processing Pipeline
- [x] Create type detector
- [x] Create metadata extractor
- [x] Create NLP tagger (compromise.js)
- [x] Create rule classifier
- [x] Create AI classifier (Groq fallback)
- [x] Create embedder (HuggingFace)
- [x] Create pipeline orchestrator

## Phase 3: Backend API
- [x] Create API key middleware
- [x] Create items routes (CRUD)
- [x] Create search routes
- [x] Create tags/categories/profile routes
- [x] Create server entry point (index.ts with @hono/node-server)

## Phase 4: Flutter Client
- [x] Update pubspec.yaml with dependencies (flutter pub get ✅)
- [x] Create app theme (Cognitive Nebula design tokens)
- [x] Create models (Item, Tag, Category)
- [x] Create API service
- [x] Create providers (ItemsProvider, SearchProvider)
- [x] Create dump screen (glassmorphism, type detection, gradient button)
- [x] Create feed screen (category chips, item cards, loading skeleton)
- [x] Create search screen (debounced search, similarity scores, suggestions)
- [x] Create detail screen (full content, categories, tags, AI summary)
- [x] Create ItemCard widget
- [x] Create main.dart with bottom navigation
- [x] Flutter analyze passes (0 errors)

## Phase 5: Integration & Deploy
- [ ] Set up Supabase + run migration
- [ ] Set up HuggingFace token
- [ ] Create server .env with real keys
- [ ] Test backend locally (`npm run dev`)
- [ ] Test Flutter app locally
- [ ] Test full dump flow end-to-end
- [ ] Deploy backend to Render
- [ ] Build APK
