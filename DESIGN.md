# Save Later — Design System & Philosophy

> **Design Dials:** **ENERGY 3** / **RHYTHM 2** / **MOTION 2**
>
> A physical, tactile, and playful neo-brutalist design language built for local-first bookmarking.

---

## 1. Design Philosophy

Save Later rejects the sterile, homogenized aesthetic of modern SaaS: no translucent frosted glassmorphism, no blurry diffused drop shadows, and no washed-out ultra-light gray text.

Instead, Save Later embraces **Playful Neo-Brutalism**:
- **Tangible & Collectible:** Every bookmark, collection, and note feels like a physical index card or sticker placed on a warm cream desk.
- **Physical Feedback:** Micro-interactions have weight. Buttons and cards depress into the canvas upon tap (`Curves.easeOutBack`), simulating tactile mechanical switches.
- **Approachable Geometry:** Chunky 2.0px–3.0px solid borders with softened corner radii (8.0px–16.0px) balance brutalist solidity with inviting warmth.
- **Intentional Rest:** Animations serve orientation and tactile feedback. The UI does not move unless the user commands it.

---

## 2. Design Dials

| Dial | Level | Definition in Save Later |
| :--- | :---: | :--- |
| **ENERGY** | **3** | Dynamic pastel accents (#FFD166 sunshine yellow, #3AC19F fresh mint, #FF9EAA candy pink) set against a warm neutral canvas (#F4F0EB) and bold ink borders (#1C1C1C). High visual contrast and punchy, cheerful confidence without visual chaos. |
| **RHYTHM** | **2** | Predictable, disciplined 8pt grid structure with strict card bounding boxes and aligned badges. Clean layout cadence with playful asymmetrical moments (offset shadows, collection folder tabs). |
| **MOTION** | **2** | Purposeful and responsive. Fast tactile spring micro-interactions (100ms–200ms) on touch down and up. Settle-on-mount entrances that immediately rest. **Strictly zero perpetual unprovoked idle loops.** |

---

## 3. Color Palette & Accessibility Tokens

### 3.1 Core Palette

```
#F4F0EB ── Cream Background Canvas
#FFFFFF ── Pure White Surface / Card
#1C1C1C ── Ink / Deep Charcoal (Borders, Primary Typography, Hard Shadows)
#FFD166 ── Pastel Sunshine Yellow (Primary Accent)
#3AC19F ── Pastel Fresh Mint (Secondary Accent)
#FF9EAA ── Pastel Candy Pink (Highlight Accent)
```

### 3.2 WCAG AA Compliant Text Tokens

To ensure accessibility across all display types and ambient lighting conditions, secondary and muted text colors must strictly satisfy **WCAG AA contrast requirements (>= 4.5:1 for normal text)** against the canvas background (`#F4F0EB`):

| Token | Hex Value | Contrast on `#F4F0EB` | Compliance Level | Purpose |
| :--- | :--- | :---: | :---: | :--- |
| `AppTheme.border` / Default Text | `#1C1C1C` | **17.5 : 1** | WCAG AAA | Headings, titles, primary body copy, icons, borders |
| `AppTheme.textSecondary` | `#595959` | **7.2 : 1** | WCAG AAA | Subheadings, dates, secondary metadata, counts |
| `AppTheme.textMuted` | `#6B6B6B` | **5.6 : 1** | WCAG AA | Domain URLs, timestamps, placeholder text, hints |

> [!IMPORTANT]
> **Anti-Slop Contrast Rule:** Never use light grays such as `#9E9E9E` (2.5:1) or `#BDBDBD` (1.7:1) for text on `#F4F0EB`. All body and auxiliary text must use `AppTheme.textSecondary` or `AppTheme.textMuted` to guarantee readability.

---

## 4. Typography: Gabarito Scale

The typographic voice is defined by **Gabarito**, an approachable geometric sans-serif with friendly curves and high legibility.

| Text Style | Size | Weight | Line Height | Usage |
| :--- | :---: | :---: | :---: | :--- |
| **Display Large** | 24sp – 32sp | `FontWeight.w900` | 1.15 | Main App Bar title, Welcome splash screens |
| **Headline Medium** | 18sp – 20sp | `FontWeight.w800` | 1.20 | Screen headers, modal dialog titles |
| **Title Medium** | 16sp – 18sp | `FontWeight.w700` | 1.25 | Bookmark card titles, Collection titles |
| **Body Large** | 15sp – 16sp | `FontWeight.w600` | 1.40 | Primary notes content, modal descriptions |
| **Body Medium** | 13sp – 14sp | `FontWeight.w500` | 1.40 | Metadata summaries, tag labels, search hints |
| **Caption / Small** | 11sp – 12sp | `FontWeight.w500` | 1.30 | Timestamps, domain badges, item counters |
| **Button / Action** | 14sp – 16sp | `FontWeight.w700` | 1.00 | Interactive buttons, action chips |

---

## 5. Motion, Elevation & Shadows

### 5.1 Zero Blur Radius Hard Shadows
Neo-brutalist elevation is rendered with **crisp, solid offset shadows** rather than gaussian blurs:
- **Shadow Color:** `Color(0xFF1C1C1C)` (Solid ink)
- **Blur Radius:** `0.0` (Always crisp, never blurred)
- **Offset Standard:**
  - `shadowOffsetSm`: `0.5px – 1.0px` (tags, small chips)
  - `shadowOffsetMd`: `1.0px – 1.5px` (standard buttons, list items)
  - `shadowOffsetLg`: `2.0px – 2.5px` (bookmark cards, collection boxes)
  - `shadowOffsetXl`: `3.0px – 3.5px` (modals, dialogs, quick-save bar)

### 5.2 Tactile Press Physics
Interactive components (`NeoButton`, `NeoPressable`, `BookmarkGridItem`) provide tangible feedback:
- **Default State:** Translated upward/leftward with full shadow offset (`Offset(2.5, 2.5)`).
- **Pressed State:** Component translates toward the canvas by decreasing translation to `Offset(0, 0)` or `Offset(0.5, 0.5)`. The shadow shrinks synchronously, simulating a mechanical key switch pressing down.
- **Physics Curve:** Spring recoil via `Curves.easeOutBack` or fast spring transitions (100ms duration).

### 5.3 Anti-Slop Motion Principles
- **No Idle Wobbles:** UI elements must never continuously bounce, float, or oscillate while waiting for input. Idle animations drain attention, look sloppy, and waste battery.
- **Single-Pass Entrances:** Entrance animations (such as empty state cards) execute a single settle-on-mount animation via `forward()` with a gentle ease-out curve, then come to a complete, stable rest.
- **User-Initiated Transitions:** Meaningful animation happens as direct consequence of user interaction (swipes in Review Mode, modal drawer slide-ups, card press states).

---

## 6. Accessibility & Inclusivity

- **Touch Target Integrity:** All interactive elements maintain a minimum hit-test boundary of **44x44 dp** (WCAG 2.5.5 / 2.5.8), even when their visual presentation is intentionally compact (e.g., 39.6dp circular header buttons).
- **Keyboard Navigation:** Full focus management with `FocusableActionDetector`. When focused via keyboard, components display high-contrast focus rings and handle `ActivateIntent` (`Enter` / `Space`).
- **Meaningful Feedback:** Loading states must always pair visual spinners with clear, descriptive text (e.g., "Loading collections..."). Error states must provide actionable messages and prominent 'Retry' controls.
