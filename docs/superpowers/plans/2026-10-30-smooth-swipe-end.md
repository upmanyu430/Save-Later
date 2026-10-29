# Smooth Swipe End (60fps Card Transition) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate the animation lag/hitch that occurs at the exact moment a bookmark swipe ends, achieving 60fps/90Hz fluid card transitions on physical Android hardware.

**Architecture:** 
1. **Decouple UI rebuilds from Paging**: Replace screen-level `setState()` on page changes with an isolated `ValueNotifier<int>` for the header counter, progress bar row, and bottom link button. The swiper and screen tree will never rebuild during card paging.
2. **Deferred Database & Provider Updates**: Defer `bookmarkNotifierProvider.markAsRead()` and Riverpod provider invalidations until the scroll physics is completely idle (`ScrollEndNotification`), preventing database I/O and provider re-evaluation during ballistic animation frames.
3. **Key Stabilization & Continuous Z-Indices**: Add `ValueKey<int>(data.index)` to `Stack` card items and unify the z-index hierarchy between active swipe and resting states to prevent RenderObject thrashing and visual snapping when `page` settles.

**Tech Stack:** Flutter 3.38+ (Dart 3.7+), Flutter Riverpod, Isar Database, Android OnePlus 7T (90Hz Fluid AMOLED).

**Spec:** User feedback on OnePlus 7T: *"The animation exactly lags where bookmarks swipe ends. I want smooth like 60fps."*

---

## Global Constraints

- **Solid Card Visuals**: Preserve solid white cards with dimming overlays (`DecoratedBox` with `Colors.black.withValues(alpha: dim)`); no card body see-through transparency.
- **Stack Geometry**: 28dp peek offset for background cards, exact card aspect ratio (0.736 screen width clamp [280, 420], 1.70 ratio).
- **Navigation Semantics**: Backward swipes and navigation back must never mark cards as read or inflate completion counts.
- **Data Integrity**: All reviewed bookmarks must be reliably marked as read in the database before the screen is disposed or when caught-up is reached.
- **Test Integrity**: All tests in `test/review_mode_count_test.dart` and `test/review_mode_stack_test.dart` must pass at 100%.

---

## Review Focus

1. **Ballistic Deceleration Phase**: When user releases finger and card decelerates towards destination page, zero DB calls, zero provider invalidations, and zero screen `setState()` calls must occur.
2. **Rapid Multi-Swipes**: Quickly swiping through multiple cards before the first settles must accumulate pending read actions and flush them without dropping frames.
3. **Screen Exit Safety**: If the user taps the close button (`X`) or system back while reviews are queued, pending read operations must flush immediately in `dispose()` without data loss.
4. **Final Card Transition**: Reaching the caught-up state after swiping the last card must complete smoothly without premature screen flash.
5. **Stack Element Identity**: Cards in the `Stack` must maintain stable `ValueKey<int>` identities so Flutter does not recreate or rebind RenderObjects when the layer order or item count shifts.

---

## Task Decomposition

### Task 1: Decouple Top Bar and Progress Bar with `ValueNotifier`

**Files:**
- Modify: `lib/ui/screens/review_mode_screen.dart:43-160, 484-571`
- Test: `test/review_mode_count_test.dart`

**Interfaces:**
- Consumes: `_ReviewModeScreenState.currentIndex`
- Produces: `ValueNotifier<int> _currentIndexNotifier`, `ValueListenableBuilder<int>` wrappers for top header counter, progress bar row, and bottom link button.

- [ ] **Step 1: Write widget test verifying top bar and progress bar update without rebuilding the swiper**
  Add a test in `test/review_mode_count_test.dart` checking that page transitions update the counter text from `'01 / 03'` to `'02 / 03'` while keeping the `PageView` controller attached and stable.

- [ ] **Step 2: Run test to verify baseline**
  Run: `flutter test test/review_mode_count_test.dart`
  Expected: PASS

- [ ] **Step 3: Implement `ValueNotifier<int> _currentIndexNotifier` in `lib/ui/screens/review_mode_screen.dart`**
  - Initialize `_currentIndexNotifier = ValueNotifier<int>(0)` in `initState()` and dispose in `dispose()`.
  - In `_onPageChanged`, update `_currentIndexNotifier.value = nextIndex` instead of calling `setState()`.
  - Wrap top bar counter `Row` with `ValueListenableBuilder<int>`.
  - Wrap progress bar `Row` with `ValueListenableBuilder<int>`.
  - Wrap bottom open link button with `ValueListenableBuilder<int>`.
  - Only call `setState()` when `nextIndex >= unreadBookmarks.length` to transition to caught-up screen.

- [ ] **Step 4: Run test to verify it passes**
  Run: `flutter test test/review_mode_count_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add lib/ui/screens/review_mode_screen.dart test/review_mode_count_test.dart
  git commit -m "perf(review): decouple top bar and progress updates using ValueNotifier"
  ```

---

### Task 2: Defer Database Operations and Provider Invalidation to Scroll Idle

**Files:**
- Modify: `lib/ui/screens/review_mode_screen.dart:100-198`
- Test: `test/review_mode_count_test.dart`

**Interfaces:**
- Consumes: `bookmarkNotifierProvider.notifier.markAsRead(bookmark)`
- Produces: `final Set<int> _pendingReadBookmarkIds = {}`, `void _flushPendingReadActions()`.

- [ ] **Step 1: Write test verifying backward swipe does not mark as read and forward swipe queues read action**
  Ensure tests in `test/review_mode_count_test.dart` verify that pending bookmarks are flushed and recorded in `_reviewedBookmarkIds`.

- [ ] **Step 2: Run test to verify baseline**
  Run: `flutter test test/review_mode_count_test.dart`
  Expected: PASS

- [ ] **Step 3: Implement deferred read flushing in `lib/ui/screens/review_mode_screen.dart`**
  - Add `final Set<int> _pendingReadBookmarkIds = {};`.
  - In `_applyAction(Bookmark bookmark)`:
    - Add to `_reviewedBookmarkIds.add(bookmark.id)`.
    - Add to `_pendingReadBookmarkIds.add(bookmark.id)`.
    - Do NOT call `notifier.markAsRead(bookmark)` synchronously during the scroll frame!
  - Add `void _flushPendingReadActions()`:
    - If `_pendingReadBookmarkIds.isEmpty` return.
    - Extract bookmark IDs to commit, copy to temporary list, and clear `_pendingReadBookmarkIds`.
    - Dispatch `notifier.markAsRead` asynchronously in a post-frame callback / background microtask.
  - In `_onScrollNotification(ScrollNotification notification)`:
    - When `notification is ScrollEndNotification`:
      - Call `_flushPendingReadActions()`.
  - In `dispose()` and when tapping back/home button:
    - Call `_flushPendingReadActions()`.

- [ ] **Step 4: Run test to verify it passes**
  Run: `flutter test test/review_mode_count_test.dart test/review_mode_stack_test.dart`
  Expected: PASS

- [ ] **Step 5: Commit**
  ```bash
  git add lib/ui/screens/review_mode_screen.dart
  git commit -m "perf(review): defer database writes and provider invalidation until scroll is idle"
  ```

---

### Task 3: Stabilize Stack Element Keys and Continuous Z-Indices

**Files:**
- Modify: `lib/ui/screens/review_mode_screen.dart:200-295, 600-650`
- Test: `test/review_mode_stack_test.dart`

**Interfaces:**
- Consumes: `_calculateCardTransforms(page, cardWidth, totalCards)`
- Produces: `Key: ValueKey<int>(data.index)` on `Stack` items, unified non-discontinuous z-indices.

- [ ] **Step 1: Write test verifying stable keys and transforms across page boundary (0.999 -> 1.000)**
  Verify in `test/review_mode_stack_test.dart` that card transforms transition smoothly without sudden z-index inversion.

- [ ] **Step 2: Run test to verify baseline**
  Run: `flutter test test/review_mode_stack_test.dart`
  Expected: PASS

- [ ] **Step 3: Implement key stabilization and unified z-indices in `lib/ui/screens/review_mode_screen.dart`**
  - In `_calculateCardTransforms`:
    - Ensure consistent zIndex allocation:
      - Active card `k`: zIndex 10
      - Entering / right card `k + 1`: zIndex 8
      - Right stack `k + 2`: zIndex 4
      - Left card `k - 1`: zIndex 7
      - Left stack `k - 2`: zIndex 3
    - Remove abrupt zIndex jumps when `isAtRest` is reached.
    - Ensure Card `k - 1` smoothly rests at `-28.0` without sudden position teleporting.
  - In `AnimatedBuilder` child mapping:
    - Add `key: ValueKey<int>(data.index)` to each transformed card widget inside `Stack(children: transforms.map(...))`.
    - Ensure `RepaintBoundary` inside `_getCardWidget` isolates card painting from transform changes.

- [ ] **Step 4: Run all tests to verify 100% pass**
  Run: `flutter test test/review_mode_count_test.dart test/review_mode_stack_test.dart`
  Expected: All 7 tests PASS

- [ ] **Step 5: Commit**
  ```bash
  git add lib/ui/screens/review_mode_screen.dart
  git commit -m "perf(review): stabilize card keys and unify z-order transitions in stack"
  ```

---

### Task 4: Hardware Verification & APK Deployment on OnePlus 7T

**Files:**
- Verify: OnePlus 7T (`e1f2e27c`)

**Interfaces:**
- Consumes: Built APK (`build/app/outputs/flutter-apk/app-debug.apk`)
- Produces: 60fps/90Hz smooth swipe execution on target physical device.

- [ ] **Step 1: Build debug APK**
  Run: `flutter build apk --debug`
  Expected: Build succeeds with 0 errors.

- [ ] **Step 2: Install APK to OnePlus 7T**
  Run: `flutter install -d e1f2e27c`
  Expected: App installs successfully.

- [ ] **Step 3: Launch Review Mode and verify swipe-end fluidity**
  Run app on device, perform forward and backward card swipes, and confirm that the card snaps smoothly with zero hitch or dropped frame at the end of the swipe.

- [ ] **Step 4: Create Walkthrough Artifact**
  Document the before-and-after performance metrics and architectural changes in `walkthrough.md`.

---
