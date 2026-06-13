# Soft Mind - Second Brain App

## Product Overview

**The Pitch:** A zero-friction digital sanctuary that catches your scattered thoughts, links, and files. AI quietly organizes your chaotic inputs into a serene, highly readable feed for gentle review later.

**For:** Chronically online students, researchers, and information hoarders overwhelmed by their own bookmarks.

**Device:** mobile

**Design Direction:** Calm, organic minimalism. Deeply tactile with warm off-whites, sage greens, and generous pill-like radii. Zero sharp edges; feels like a digital pebble. 

**Inspired by:** Cosmos, Are.na, and Zen meditation timers.

---

## Screens

- **The Drop:** A hyper-minimal, single-purpose capture screen ready the instant the app opens.
- **The Stream:** A flowing, AI-curated feed of processed thoughts and saved artifacts.
- **The Focus:** A distraction-free reading/viewing environment for a single saved item.
- **Gentle Nudges:** A soft notification center reminding you of forgotten gems.

---

## Key Flows

**Quick Capture:** 
1. User opens app -> sees **The Drop** screen
2. User taps large text area -> keyboard opens automatically
3. User types "Read chapter 4 of Biology" and taps **Release** -> input dissolves into a soft animation
4. Screen resets instantly for the next thought

**Review Flow:**
1. User taps bottom tab -> opens **The Stream**
2. User taps a sage-colored card titled "Biology Notes" -> opens **The Focus**
3. User reads, taps **Archive** -> card shrinks and floats away

---

<details>
<summary>Design System</summary>

## Color Palette

- **Primary:** `#7C8B74` - Sage green, soft but actionable (Buttons, active icons)
- **Background:** `#F4F3ED` - Warm oat, absolute zero pure white (App background)
- **Surface:** `#FCFBF8` - Brighter oat, slight contrast against background (Cards, inputs)
- **Text:** `#2C332A` - Deep forest black, extremely readable but less harsh than pure black
- **Muted:** `#BDBBAF` - Warm grey/sand (Time stamps, borders, inactive tabs)
- **Accent:** `#E3D5CA` - Soft terracotta blush (Highlights, gentle warnings)

## Typography

- **Headings:** Fraunces, 500 (Soft, organic serif), 28-36px
- **Body:** Karla, 400 (Warm, slightly idiosyncratic sans-serif), 18px
- **Small text:** Karla, 500, 14px
- **Buttons:** Karla, 600, 16px, tracking 0.02em

**Style notes:** 
- `32px` border radius on all primary surfaces (cards, large buttons)
- No hard borders; use subtle background shifts and ultra-diffuse shadows (`0 8px 30px rgba(44, 51, 42, 0.04)`)
- Haptic feedback is crucial; every action should feel soft but grounded.

## Design Tokens

```css
:root {
  --color-primary: #7C8B74;
  --color-background: #F4F3ED;
  --color-surface: #FCFBF8;
  --color-text: #2C332A;
  --color-muted: #BDBBAF;
  --color-accent: #E3D5CA;
  
  --font-heading: 'Fraunces', serif;
  --font-body: 'Karla', sans-serif;
  
  --radius-sm: 12px;
  --radius-md: 20px;
  --radius-lg: 32px;
  --radius-pill: 999px;
  
  --shadow-soft: 0 8px 30px rgba(44, 51, 42, 0.04);
  --shadow-float: 0 16px 40px rgba(44, 51, 42, 0.08);
}
```

</details>

---

<details>
<summary>Screen Specifications</summary>

### The Drop (Capture)

**Purpose:** Instant, frictionless dumping of any format (text, URL, file, voice).

**Layout:** 90% of screen is an input area. Bottom tab bar is hidden during typing.

**Key Elements:**
- **Omni-Input Area:** Takes up upper 2/3rds of screen. `placeholder: "What's on your mind?"`, `color: var(--color-muted)`, 28px Fraunces.
- **Attachment Dock:** 56px height, pill-shaped, floating at bottom above keyboard. Contains icons for Voice, Photos, Files, Camera.
- **Release Button:** 64px circular FAB, `#7C8B74`, right-aligned. Contains a soft upward-pointing arrow.

**States:**
- **Empty:** Placeholder visible, attachments dock transparent.
- **Loading:** Input text shimmers softly with a linear gradient.
- **Dictating:** Voice icon pulses gently with a soft `#7C8B74` glow, input area fills with real-time transcribed text.
- **Error:** Soft terracotta shake, text "Couldn't save, try again."

**Components:**
- **Format Toggle:** 40px pill, `#FCFBF8`, `border: 1px solid #BDBBAF`, switches input mode manually if needed.

**Interactions:**
- **Tap input:** Keyboard springs up, attachment dock slides up to sit exactly on keyboard.
- **Tap Voice Icon:** Activates microphone, hides keyboard, and begins voice dictation with a gentle haptic pulse.
- **Tap Release:** Text scales down to 0, drifts upward, haptic "pop", screen clears.

### The Stream (Feed)

**Purpose:** Review AI-organized notes and artifacts.

**Layout:** Vertical scrolling list, no visible scrollbars. Floating bottom navigation.

**Key Elements:**
- **Greeting Header:** "Morning, mind.", Fraunces 28px, `#2C332A`.
- **Category Pills:** Horizontal scrolling row (e.g., "Articles", "Passing Thoughts", "To Watch").
- **Memory Cards:** 160px height, `#FCFBF8`, `32px` radius. Contains AI-generated summary of dumped content.

**States:**
- **Empty:** "Your mind is quiet today.", centered, Karla 18px, `#BDBBAF`.
- **Loading:** Ghost cards with slow `#F4F3ED` to `#FCFBF8` pulsing.

**Components:**
- **Memory Card:** `padding: 24px`, title Fraunces 20px, excerpt Karla 16px (`line-height: 1.5`), tiny source icon (URL vs Note) in top right.

**Interactions:**
- **Scroll down:** Header shrinks, category pills pin to top.
- **Tap Card:** Hero animation expands card to fill screen, enters **The Focus**.

### The Focus (Detail)

**Purpose:** Immersive reading/viewing of a saved item.

**Layout:** Full screen, distraction-free.

**Key Elements:**
- **Context Bar:** Top row, subtle "Back" arrow left, "Archive" icon right.
- **AI Summary Block:** Top of content, slightly darker background (`#E8E7E0`), rounded 20px, "AI Summary: ..." in Karla 16px.
- **Content Area:** 18px Karla, loose line height (1.6), generous side padding (24px).

**States:**
- **Empty:** N/A (cannot open empty item).
- **Loading:** Shimmering lines mimicking text width.

**Components:**
- **Action Footer:** Floating pill at bottom, `#FCFBF8`, actions: "Copy", "Share", "Delete".

**Interactions:**
- **Swipe Right:** Dismisses view, shrinks back to card in Stream.
- **Scroll:** Context bar fades out to maximize reading area.

### Gentle Nudges (Notifications)

**Purpose:** Soft reminders to revisit old notes.

**Layout:** Half-screen bottom sheet or full-screen overlay.

**Key Elements:**
- **Nudge Title:** "From 3 weeks ago", Karla 16px uppercase, `#BDBBAF`.
- **Artifact Preview:** Scaled down version of a Memory Card.
- **Action Buttons:** Two pills: "Review Now" (`#7C8B74`), "Let it go" (`#F4F3ED`).

**States:**
- **Empty:** "All caught up."

**Interactions:**
- **Tap 'Let it go':** Card dissolves into particles, haptic tick.
- **Tap 'Review Now':** Transitions directly into **The Focus** screen.

</details>

---

<details>
<summary>Build Guide</summary>



**Build Order:**
1. **Design System Configuration:** Add Fraunces/Karla via Google Fonts, setup Tailwind theme.
2. **The Drop:** Establish the core interaction paradigm and surface styles.
3. **The Stream:** Build the complex card layouts and scroll behaviors.
4. **The Focus:** Ensure typography and reading experience is pristine.
5. **Gentle Nudges:** Add bottom-sheet overlays and transition animations.

</details>

---

<details>
<summary>Issues and Fixes Implementation</summary>

### Robust Error Handling
- **Offline Mode:** If a user drops a thought while offline, it saves locally to device storage. The UI shows a subtle syncing icon in the Attachment Dock. Once reconnected, the queue silently syncs without interrupting the user.
- **AI Timeout Fallback:** If the AI summary generation exceeds 5 seconds or fails, **The Stream** displays the raw first sentence of the input with a muted "Organizing later..." label, ensuring no data blocking.
- **Large File Handling:** Dropping files over 50MB triggers an immediate inline warning in **The Drop** (`#E3D5CA` background pill) stating "File too heavy for quick capture", preventing long upload hangs.

### Accessibility Improvements
- **Screen Readers:** All icon-only buttons (Attachment Dock, Release Button, Archive icon) must have descriptive `aria-label` attributes. Memory cards must be announced as a single cohesive unit (Title, then Summary) rather than disjointed text fragments.
- **Dynamic Type Scaling:** Text containers must use flexible height (`min-height` rather than fixed `height`). When system font scales up, **The Drop** input area allows scrolling, and **Memory Cards** expand vertically to accommodate larger Fraunces/Karla text without clipping.
- **Contrast Ratios:** Ensure the muted text (`#BDBBAF`) against background (`#F4F3ED`) meets WCAG AA standards. If user enables high-contrast OS settings, dynamically darken the muted variable to `#8A887A`.

### UI Polish
- **Keyboard Transitions:** Implement `window.visualViewport` APIs to bind the Attachment Dock strictly to the top edge of the software keyboard, eliminating jarring layout jumps when the keyboard animates up or down.
- **Media Loading States:** Any image/video artifacts in **The Focus** must use a soft BlurHash placeholder derived from the image's dominant colors before fully popping in.
- **Haptic Hierarchy:**
  - *Light Tap:* Tapping bottom tabs or category pills.
  - *Medium Thud:* Successfully releasing a thought in **The Drop**.
  - *Heavy Double-Tick:* Error state (e.g., failed to save).

</details>