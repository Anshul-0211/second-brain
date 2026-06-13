# Second Brain – Flutter to Next.js Migration Guide

## Project Overview

**Project Name:** Second Brain (Soft Mind)  
**Purpose:** Zero-friction digital sanctuary for capturing scattered thoughts, links, and files with AI-powered organization  
**Current Stack:** Flutter (frontend) + Node.js/Hono (backend) + Supabase + Groq  
**Target Stack:** Next.js (frontend) + Node.js/Hono (backend) + Supabase + Groq  

---

## 📊 Codebase Index & What to Copy

### ✅ Backend (TAKE AS-IS – No Changes Needed)
The entire backend can be migrated without modification:

```
server/
├── src/
│   ├── index.ts                 # Hono app entry point
│   ├── db/
│   │   ├── client.ts            # Supabase client config
│   │   ├── queries.ts           # Database queries
│   │   └── migrations/          # SQL migrations
│   ├── routes/
│   │   ├── items.ts             # /api/items CRUD
│   │   ├── notes.ts             # /api/items/:id/notes CRUD
│   │   ├── search.ts            # /api/search (vector + semantic)
│   │   └── tags.ts              # /api/tags
│   ├── pipeline/                # Processing pipeline
│   │   ├── typeDetector.ts      # Link vs Note vs File
│   │   ├── metadataExtractor.ts # Title, description extraction
│   │   ├── nlpTagger.ts         # Entity & keyword extraction
│   │   ├── classifier.ts        # Rule-based categorization
│   │   ├── aiSummarizer.ts      # Groq fallback
│   │   └── embedder.ts          # HuggingFace embeddings
│   ├── middleware/
│   │   └── apiKey.ts            # API key authentication
│   └── lib/
│       └── config.ts            # Environment & config
├── package.json
├── tsconfig.json
└── .env (COPY ENTIRELY)
```

**Actions:**
1. Copy entire `server/` folder
2. Copy `.env` file (update endpoints if needed)
3. Run `npm install` in new Next.js project
4. Backend runs as separate service (Render/Railway/local)

---

### ✅ Database (USE EXISTING SUPABASE PROJECT)
No changes needed. Your Supabase database is language-agnostic.

**Database schema (already exists):**
- `items` – Core content storage
- `item_notes` – Thread of notes per item
- `item_tags` – Tagging system
- `item_categories` – Category classification
- `search_vectors` – pgvector embeddings for semantic search

**What Next.js will do:**
- Call the same backend API endpoints
- No database layer needed in Next.js (backend handles it)
- Database queries remain 100% identical

---

## 🎨 Frontend – Flutter to Next.js Conversion

### App Architecture Overview

```
Second Brain Frontend
├── Screens (Flutter) → Pages (Next.js)
│   ├── DumpScreen        → /dump (Create/Capture)
│   ├── FeedScreen        → / (Home/Feed)
│   ├── DetailScreen      → /item/[id] (Item Detail)
│   └── SearchScreen      → /search (Search Results)
├── Widgets (Flutter) → Components (Next.js)
│   ├── item_card         → ItemCard.tsx
│   ├── inline_note_input → InlineNoteInput.tsx
│   └── ...               → Other UI components
├── States (Provider) → React Hooks (Next.js)
│   ├── ItemsProvider  → useItems() hook
│   └── SearchProvider → useSearch() hook
└── Theme System
    └── AppTheme (Dart) → Tailwind + CSS Variables
```

---

## 📋 Data Models to Port

All data models from Flutter need equivalent TypeScript interfaces in Next.js:

### 1. **Item Model**
```dart
// Flutter (Dart)
class Item {
  final String id;
  final String type;           // 'link', 'note', 'file'
  final String contentRaw;     // Original input
  final String? title;         // Extracted or AI-generated
  final String? description;   // Summary/preview
  final String? sourceUrl;     // For links
  final String? aiSummary;     // AI-generated summary
  final double? confidenceScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Tag> tags;
  final List<Category> categories;
  final List<ItemNote> notes;
  final String? notePreview;
  final int noteCount;
  final String? noteUrgency;
}
```

**Convert to TypeScript:**
```typescript
// Next.js (TypeScript)
interface Item {
  id: string;
  type: 'link' | 'note' | 'file';
  content_raw: string;
  title?: string;
  description?: string;
  source_url?: string;
  ai_summary?: string;
  confidence_score?: number;
  created_at: string;  // ISO 8601
  updated_at: string;
  tags: Tag[];
  categories: Category[];
  notes: ItemNote[];
  note_preview?: string;
  note_count: number;
  note_urgency?: string;
}
```

### 2. **Tag Model**
```typescript
interface Tag {
  id: string;
  name: string;
  frequency?: number;  // How many items have this tag
}
```

### 3. **Category Model**
```typescript
interface Category {
  id: string;
  name: string;
  emoji?: string;
  color?: string;
}
```

### 4. **ItemNote Model**
```typescript
interface ItemNote {
  id: string;
  item_id: string;
  content: string;
  urgency: 'low-priority' | 'medium' | 'high-priority';
  created_at: string;
  updated_at: string;
}
```

---

## 🔄 API Endpoints (Backend → Frontend)

The Next.js frontend will call these exact same endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/items` | GET | Fetch all items (paginated) |
| `/api/items` | POST | Create new item (triggers pipeline) |
| `/api/items/:id` | GET | Get single enriched item |
| `/api/items/:id` | DELETE | Delete item |
| `/api/items/:id/notes` | GET | Get notes for an item |
| `/api/items/:id/notes` | POST | Add note to item |
| `/api/items/:id/notes/:noteId` | PUT | Update note |
| `/api/items/:id/notes/:noteId` | DELETE | Delete note |
| `/api/search` | POST | Semantic search (pgvector + keyword) |
| `/api/tags` | GET | Get all tags |

### API Key Authentication
All requests need header:
```typescript
headers: {
  'Content-Type': 'application/json',
  'x-api-key': process.env.NEXT_PUBLIC_API_KEY
}
```

---

## 🎨 UI/Design System – Flutter to Next.js

### Design Tokens (Already Defined in PRD)

**Flutter → Next.js conversion:**

```typescript
// lib/theme/design-tokens.ts or tailwind.config.ts
export const designTokens = {
  colors: {
    primary: '#7C8B74',      // Sage green
    background: '#F4F3ED',   // Warm oat
    surface: '#FCFBF8',      // Brighter oat
    text: '#2C332A',         // Deep forest black
    muted: '#BDBBAF',        // Warm grey/sand
    accent: '#E3D5CA',       // Soft terracotta blush
  },
  fonts: {
    heading: 'Fraunces',     // Font-family
    body: 'Karla',
  },
  radius: {
    sm: '12px',
    md: '20px',
    lg: '32px',
    pill: '999px',
  },
  shadows: {
    soft: '0 8px 30px rgba(44, 51, 42, 0.04)',
    float: '0 16px 40px rgba(44, 51, 42, 0.08)',
  },
};
```

### Screen-by-Screen Conversion

| Flutter Screen | Next.js Page | Purpose | Status |
|---|---|---|---|
| DumpScreen | `/dump` | Capture new items | ⚠️ In Progress |
| FeedScreen | `/` | View all items (stream) | ⚠️ In Progress |
| DetailScreen | `/item/[id]` | View detail + notes | ⚠️ To Do |
| SearchScreen | `/search` | Semantic search | ⚠️ To Do |
| MainShell (nav) | Layout/Navigation | Bottom nav conversion | ⚠️ To Do |

---

## 📦 Dependencies to Install (Next.js)

```bash
npm install next react react-dom
npm install @tanstack/react-query  # Data fetching (replaces provider pattern)
npm install zustand or jotai      # State management (alternative to Provider)
npm install axios                  # HTTP client (or use fetch)
npm install tailwindcss postcss autoprefixer  # Styling
npm install next-auth             # (Optional) If adding auth later
```

### Recommended Stack
- **Framework:** Next.js 14+ (App Router)
- **Styling:** Tailwind CSS + CSS Modules
- **State Management:** React Context + Hooks or Zustand
- **Data Fetching:** React Query (TanStack Query) or SWR
- **HTTP Client:** Axios or built-in fetch
- **Animation:** Framer Motion (equivalent to flutter_animate)
- **Fonts:** next/font (Google Fonts support built-in)

---

## 📂 Proposed Next.js Project Structure

```
nextjs-second-brain/
├── src/
│   ├── app/
│   │   ├── layout.tsx              # Root layout + navigation
│   │   ├── page.tsx                # Home (FeedScreen)
│   │   ├── dump/
│   │   │   └── page.tsx            # DumpScreen
│   │   ├── search/
│   │   │   └── page.tsx            # SearchScreen
│   │   ├── item/
│   │   │   └── [id]/
│   │   │       └── page.tsx        # DetailScreen
│   │   └── api/                    # (Optional) API routes if needed
│   ├── components/
│   │   ├── ItemCard.tsx            # From item_card.dart
│   │   ├── InlineNoteInput.tsx     # From inline_note_input.dart
│   │   ├── Navigation.tsx          # Bottom nav bar
│   │   └── ...
│   ├── hooks/
│   │   ├── useItems.ts             # ItemsProvider → custom hook
│   │   ├── useSearch.ts            # SearchProvider → custom hook
│   │   └── useApi.ts               # API service wrapper
│   ├── lib/
│   │   ├── api-client.ts           # Axios/fetch setup
│   │   ├── types.ts                # TypeScript interfaces
│   │   ├── theme.ts                # Design tokens
│   │   └── constants.ts            # App constants
│   ├── styles/
│   │   ├── globals.css
│   │   └── variables.css           # CSS variables for design tokens
│   └── context/
│       ├── ItemsContext.tsx        # React Context for items
│       └── SearchContext.tsx       # React Context for search
├── public/
├── tailwind.config.ts
├── tsconfig.json
├── next.config.ts
├── package.json
└── .env.local
```

---

## 🔌 State Management Conversion

### Flutter (Provider) → Next.js (React Hooks)

**Flutter:**
```dart
class ItemsProvider extends ChangeNotifier {
  List<Item> _items = [];
  bool _isLoading = false;
  
  Future<void> loadItems() async { ... }
  Future<void> addItem(String content) async { ... }
}

// Usage
context.read<ItemsProvider>().loadItems()
```

**Next.js Option 1 (React Context + Hooks):**
```typescript
// hooks/useItems.ts
export function useItems() {
  const [items, setItems] = useState<Item[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  
  const loadItems = async () => {
    setIsLoading(true);
    const data = await apiClient.getItems();
    setItems(data);
    setIsLoading(false);
  };
  
  const addItem = async (content: string) => {
    const newItem = await apiClient.createItem(content);
    setItems([newItem, ...items]);
    return newItem;
  };
  
  return { items, isLoading, loadItems, addItem };
}

// Usage in components
const MyComponent = () => {
  const { items, isLoading, loadItems } = useItems();
  useEffect(() => { loadItems(); }, []);
};
```

**Next.js Option 2 (React Query - Recommended):**
```typescript
// hooks/useItems.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

export function useItems() {
  const queryClient = useQueryClient();
  
  const { data: items, isLoading } = useQuery({
    queryKey: ['items'],
    queryFn: () => apiClient.getItems(),
  });
  
  const addItemMutation = useMutation({
    mutationFn: (content: string) => apiClient.createItem(content),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['items'] }),
  });
  
  return {
    items: items || [],
    isLoading,
    addItem: addItemMutation.mutate,
  };
}
```

---

## 🎯 Migration Checklist

### Phase 1: Setup (Week 1)
- [ ] Create Next.js project with App Router
- [ ] Set up Tailwind CSS + design tokens from PRD
- [ ] Install dependencies (React Query, Axios, Framer Motion)
- [ ] Set up environment variables (.env.local)
- [ ] Create TypeScript interfaces for all data models
- [ ] Set up API client wrapper (lib/api-client.ts)

### Phase 2: Core Features (Week 2-3)
- [ ] Build Layout + Navigation component
- [ ] Implement `/` (Feed page) – ItemCard, category filter
- [ ] Implement `/dump` (Capture page) – input, type detection, save
- [ ] Implement `/item/[id]` (Detail page) – notes, archive, delete
- [ ] Implement `/search` (Search page) – query input, results display
- [ ] Set up React Query for data fetching

### Phase 3: Polish (Week 4)
- [ ] Add animations (Framer Motion)
- [ ] Add loading states & skeletons
- [ ] Add error boundaries & error states
- [ ] Mobile responsiveness
- [ ] Test all API integrations
- [ ] Deploy to Vercel

### Phase 4: Nice-to-Have (Future)
- [ ] Voice input (Web Audio API)
- [ ] File upload handling
- [ ] PWA features
- [ ] Dark mode toggle
- [ ] User authentication (if needed)

---

## 📍 API Service Implementation

**Flutter API Service:**
```dart
class ApiService {
  static const String _baseUrl = 'http://localhost:3000';
  
  static Future<List<Item>> getItems() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/items?limit=50&offset=0'),
      headers: _headers,
    );
    // ... decode response
  }
}
```

**Next.js API Service (Recommended):**
```typescript
// lib/api-client.ts
import axios from 'axios';

export const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000',
  headers: {
    'Content-Type': 'application/json',
    'x-api-key': process.env.NEXT_PUBLIC_API_KEY,
  },
});

export const itemsApi = {
  getItems: (limit = 50, offset = 0) =>
    apiClient.get<{ items: Item[] }>('/api/items', { params: { limit, offset } }),
  
  createItem: (content: string) =>
    apiClient.post<Item>('/api/items', { content }),
  
  getItem: (id: string) =>
    apiClient.get<Item>(`/api/items/${id}`),
  
  deleteItem: (id: string) =>
    apiClient.delete(`/api/items/${id}`),
  
  createNote: (itemId: string, content: string, urgency = 'low-priority') =>
    apiClient.post(`/api/items/${itemId}/notes`, { content, urgency }),
  
  search: (query: string, threshold = 0.4, limit = 10) =>
    apiClient.post<{ results: any[] }>('/api/search', {
      query,
      threshold,
      limit,
    }),
};
```

---

## 🚀 Deployment

### Backend (No Changes)
- Deployed independently on Render/Railway/Vercel
- Environment variables: `SUPABASE_URL`, `SUPABASE_KEY`, `GROQ_API_KEY`, `HF_TOKEN`

### Frontend (Next.js)
- **Hosting:** Vercel (zero-config), Netlify, or Railway
- **Environment Variables (.env.local):**
  ```
  NEXT_PUBLIC_API_URL=https://your-api.render.com
  NEXT_PUBLIC_API_KEY=your-api-key
  ```

---

## 📝 Implementation Notes

### Key Differences Between Flutter & Next.js

| Aspect | Flutter | Next.js |
|--------|---------|---------|
| **Navigation** | go_router | Next.js App Router |
| **State** | Provider pattern | React Context/Zustand/Jotai |
| **Styling** | Flutter theme + Material | Tailwind CSS + CSS Modules |
| **HTTP** | http package | axios / fetch |
| **Animations** | flutter_animate | Framer Motion / CSS |
| **Data Fetching** | async/await + notifyListeners | React Query / SWR |
| **Type Safety** | Dart types | TypeScript |

### Translation Tips

1. **Padding/Margin** → Use Tailwind spacing (px, py, p-12, etc.)
2. **Colors** → Define CSS variables, use with Tailwind
3. **BorderRadius** → Use Tailwind rounded utilities
4. **TextStyles** → Map Flutter GoogleFonts to @apply directives
5. **Icons** → Use lucide-react or react-feather
6. **Gestures** → Use onClick, onMouseEnter, etc. (web events)
7. **LocalStorage** → Use browser localStorage (similar to shared_preferences)

---

## ✨ Example: DumpScreen → /dump Page

### Flutter DumpScreen
```dart
class DumpScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextField(
        controller: _controller,
        placeholder: 'What\'s on your mind?',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveToBrain,
        child: Icon(Icons.arrow_upward),
      ),
    );
  }
}
```

### Next.js /dump Page
```typescript
// app/dump/page.tsx
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { itemsApi } from '@/lib/api-client';

export default function DumpPage() {
  const [content, setContent] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();

  const handleSave = async () => {
    setIsLoading(true);
    try {
      await itemsApi.createItem(content);
      setContent('');
      // Show success or redirect
    } catch (error) {
      console.error('Failed to save:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F4F3ED] p-6">
      <textarea
        value={content}
        onChange={(e) => setContent(e.target.value)}
        placeholder="What's on your mind?"
        className="w-full p-6 rounded-3xl text-2xl font-fraunces"
      />
      <button
        onClick={handleSave}
        disabled={isLoading}
        className="mt-4 bg-[#7C8B74] text-white rounded-full p-4"
      >
        {isLoading ? '...' : '↑'}
      </button>
    </div>
  );
}
```

---

## 🎓 Learning Resources

- **Next.js Documentation:** https://nextjs.org/docs
- **React Hooks:** https://react.dev/reference/react/hooks
- **React Query:** https://tanstack.com/query/latest
- **Tailwind CSS:** https://tailwindcss.com/docs
- **TypeScript:** https://www.typescriptlang.org/docs/

---

## 📞 Quick Checklist Before Starting

- [ ] Backend API is running and accessible
- [ ] Supabase project is set up with existing schema
- [ ] API key authentication is working
- [ ] Environment variables (.env) are ready
- [ ] Design tokens from PRD are documented
- [ ] Next.js project is scaffolded
- [ ] TypeScript is configured

---

**Last Updated:** April 10, 2026  
**Status:** Ready for Next.js Migration 🚀

