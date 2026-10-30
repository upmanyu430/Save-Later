# Save Later 🔖

> **Save now. Find anytime.**
>
> A private, offline-first bookmark manager and read-later utility built with Flutter, designed to eliminate digital clutter and combat link rot—with zero cloud lock-in.

---

## ⚡ Overview

**Save Later** is a standalone, privacy-first personal knowledge vault and link archiver. Built from the ground up on a strict **local-first** paradigm, Save Later ensures that your personal web library remains completely stored on your physical device—free from telemetry, third-party analytics, ad networks, or mandatory user accounts.

Featuring a distinctive **soft neo-brutalist** interface with tactile drop shadows, crisp border geometries, pastel accents, and spring-loaded micro-interactions, Save Later treats every bookmark and note as a physical, collectible digital card.

---

## ✨ Core Pillars & Features

### 1. Frictionless Ingestion & Quick Save
* **Native OS Share Target:** Capture links, text snippets, and media directly from external apps via native platform share intents (`receive_sharing_intent`).
* **Quick-Save Bar:** Instant clipboard paste directly from the home dashboard with automatic URL extraction and sanitization.
* **Automated Enrichment:** Scrapes and parses Open Graph tags, Twitter Cards, and standard HTML metadata (`<title>`, `<meta name="description">`, canonical favicons, preview thumbnails) in background isolates.

### 2. Zero-Overhead Organization
* **Color-Coded Collections:** Group saves into custom folders with customizable flat pastel palettes, custom outline icons, and dynamic item counters.
* **Sub-Collections:** Organize deep research hierarchies into nested folder structures.
* **Canonical Tag System:** Tag bookmarks with autocomplete suggestions to prevent duplicate variations (e.g., `#design`, `#flutter`).
* **Pin & Unsorted Queues:** Pin critical links to the top of your workspace or triage new saves in the Unsorted inbox.

### 3. Review Mode (Flashcard Deck)
* **Distraction-Free Catch-Up:** Review unread links one by one in a focused flashcard deck.
* **Gesture Triage:** Fast-triage saves using intuitive swipe gestures.
* **Segmented Progress Trackers:** Dynamic brutalist progress bars tracking daily reading sessions with a satisfying *"You're all caught up!"* completion screen.

### 4. Anti-Link Rot & Offline Readiness
* **Local Asset Caching:** Downloads remote thumbnails and banner images directly to the device's local file system so visual context remains intact even if the original URL changes or disappears.
* **Unified Search:** High-speed querying across URLs, titles, user notes, domain sources, and tags.

### 5. Absolute Privacy & Portability
* **100% Local Storage:** Embedded database storage (Isar / SQLite WAL) ensures your data never leaves your device unless you explicitly export it.
* **Universal Import & Export:** Backup and restore your library via structured JSON or standard Netscape HTML bookmarks (compatible with all major web browsers).

---

## 🎨 Design System: Soft Neo-Brutalism

Save Later rejects transparent glassmorphism and blurs in favor of a bold, physical, and punchy design language:

* **Color Palette:**
  * Cream Canvas: `#F4F0EB`
  * Pastel Pink (Primary): `#FFFF9EAA`
  * Pastel Green (Secondary): `#FF3AC19F`
  * Pastel Yellow (Accent): `#FFFFD166`
  * Deep Charcoal / Outlines: `#FF1C1C1C`
* **Typography:** Heavyweight modern sans-serifs (Bricolage Grotesque) with bold headings (`FontWeight.w900`) and tight tracking.
* **Tactile Components (`NeoBox` & `NeoButton`):** Custom containers featuring 2.5px–3.0px solid borders, hard non-blurred drop shadows (`Offset(2.8, 2.8)`), and spring-loaded physics (`Curves.elasticOut` / `Curves.easeOutBack`).

---

## 🏗️ Architecture & Project Structure

The application is structured using a clean, feature-driven repository pattern powered by **Flutter Riverpod** and **GoRouter**:

```
lib/
├── config/
│   ├── app_constants.dart       # Sizing tokens, padding, durations, and layout bounds
│   └── app_theme.dart           # Neo-brutalist theme definitions, colors, typography
├── l10n/                        # Internationalization (.arb translation bundles)
├── models/
│   ├── bookmark.dart            # Bookmark data model (URL, metadata, tags, read states)
│   └── collection.dart          # Collection & folder hierarchy model
├── providers/
│   └── providers.dart           # Riverpod StateNotifiers (BookmarkNotifier, collection providers)
├── repositories/
│   ├── database_repository.dart # Abstract repository interface contract
│   └── isar_repository.dart     # Local database implementation
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart             # Main dashboard with Quick-Save bar & Collections grid
│   │   ├── bookmark_detail_screen.dart  # Detailed card view, notes editor, tag manager
│   │   ├── collection_detail_screen.dart# Filtered link feed, batch operations, folder actions
│   │   ├── review_mode_screen.dart      # Swiper card deck for unread links
│   │   ├── search_screen.dart           # Unified search bar, tag filtering & stats
│   │   ├── settings_screen.dart         # Data import/export, preferences & backups
│   │   └── welcome_screen.dart          # 3-slide animated onboarding walkthrough
│   └── widgets/
│       ├── bookmark_grid_item.dart      # Rich bookmark card with preview thumbnail
│       ├── bookmark_radial_menu.dart    # Long-press radial contextual actions
│       ├── collection_editor_modal.dart # Bottom sheet for creating & styling folders
│       ├── folder_box.dart              # Brutalist folder graphic with custom tab
│       ├── neo_box.dart                 # Core brutalist container with hard shadows
│       └── neo_button.dart              # Interactive button with spring press states
└── utils/
    ├── haptics_helper.dart      # Centralized haptic feedback controller
    ├── tag_helper.dart          # Tag sanitation and normalization
    └── url_helper.dart          # Link parsing, extraction, and validation logic
```

---

## 🚀 Getting Started

### Prerequisites

* [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.19.0 or later recommended)
* [Dart SDK](https://dart.dev/get-dart)
* Xcode (for iOS builds) or Android Studio / Android SDK (for Android builds)

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/save-later.git
   cd save-later
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Create an environment file at `assets/env`:
   ```env
   APP_NAME=Save Later
   SUPPORT_EMAIL=support@yourdomain.com
   HOW_TO_URL=https://yourusername.github.io/savelater-web/howto.html
   PRIVACY_POLICY_URL=https://yourusername.github.io/savelater-web/privacy.html
   TERMS_OF_SERVICE_URL=https://yourusername.github.io/savelater-web/terms.html
   ```

4. **Generate Code & Database Models:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Launch the Application:**
   ```bash
   flutter run
   ```

---

## 🔒 Privacy Philosophy

Save Later is built on the belief that personal bookmarks, notes, and reading habits should belong solely to the user:

* **Zero Cloud Dependency:** The app operates completely offline without forced accounts or server sync requirements.
* **No Telemetry:** No analytics SDKs, trackers, or behavioral profiling.
* **Local Processing:** All metadata extraction, text normalization, and thumbnail caching happen strictly on your hardware.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).