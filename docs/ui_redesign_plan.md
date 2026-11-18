# Mujeeb24 — Revised UI Redesign & Implementation Plan (Pre-Implementation Baseline)

> **Document Status:** Revised Master Plan (Pending Owner Approval)  
> **Target Application:** Mujeeb24 Mobile Client (Flutter / Dart)  
> **Scope:** Visual-only, incremental refactoring preserving 100% of existing functionality, APIs, providers, and test suites.  
> **Key Revisions:**  
> 1. Removed any claim of "zero risk" for shared code. Theme and token changes are formally recognized as global dependencies affecting 38 files.  
> 2. Established verified pre-change test and lint baselines.  
> 3. Adopted localized, incremental widget refactoring over broad rewrites.  
> 4. Froze all API clients, repositories, models, providers, auth, permissions, and submission handlers.  
> 5. Decoupled app icon design and release configurations into a separate future phase.

---

## 1. Verified Baseline Status (Pre-Implementation Audit)

The following baseline metrics were established by executing the test suite and static analysis directly on the repository before any source modifications:

* **Git Status:** Clean (`nothing to commit, working tree clean`) on branch `feature/design`.
* **Test Suite Baseline (`flutter test`):**
  * **Total Test Cases:** **269 tests** across 27 test files.
  * **Result:** **269 passed, 0 failed, 0 skipped** (Execution time: 28 seconds).
* **Static Analysis Baseline (`flutter analyze`):**
  * **Result:** **0 compile errors, 0 warnings, 13 info-level lint notices** (legacy string interpolations and parameter initializers in unrelated files).
* **Shared Theme Impact Audit:**
  * `AppColors` is imported and directly referenced across **38 Dart files** (37 distinct screens and shared widgets).
  * *Constraint:* Modifying existing constants in `lib/app/theme/app_theme.dart` carries global cascading risk. Therefore, Batch 1 will **not** modify shared global theme tokens.

---

## 2. Revised, Risk-Ranked Implementation Roadmap

The redesign sequence is ordered strictly from lowest risk (localized single-screen widgets) to higher risk (cross-cutting shared shells):

```
┌─────────────────────────────────────────────────────────────────┐
│ Batch 1 (Medium-Low Risk): Conversation Detail Screen           │
│ - Localized UI enhancement of conversation_detail_screen.dart   │
│ - Zero changes to global theme, API, models, or provider logic │
└───────────────────────────────┬─────────────────────────────────┘
                                │ (Passes all 269 tests)
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Batch 2 (Medium-Low Risk): Inbox List Tab                       │
│ - Localized styling of inbox_tab.dart list items and search bar │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Batch 3 (Medium Risk): Home Dashboard Tab                       │
│ - Refinement of dashboard_tab.dart metric cards & channel pills │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Batch 4 (Medium Risk): CRM Screens (Customers & Leads)          │
│ - Localized card and stage styling in customers_tab & leads_tab │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Batch 5 (Medium-High Risk): Commercial Transactions & Review    │
│ - Refined transaction cards, stepper, and review approval sheet │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Batch 6 (High Risk / Global): Additive Design System Tokens     │
│ - Consolidating validated local styles into app_theme.dart      │
│ - Purely additive; existing token names preserved               │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Batch 7 (Isolated Separate Phase): App Icon & Brand Assets      │
│ - App icon generation, mipmap densities, and release assets     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Scope of Batch 1: Conversation Detail Screen

### 3.1 Exact File Changing in Batch 1
* **`lib/features/merchant/presentation/conversation_detail_screen.dart`** (Only this single file).

### 3.2 Files Explicitly Excluded from Batch 1
* **Excluded Shared Theme:** `lib/app/theme/app_theme.dart` (Prevents side-effects across the other 37 dependent files).
* **Excluded API & Repositories:** `lib/core/api/api_client.dart`, `lib/core/merchant/merchant_repository.dart`, and all other repositories.
* **Excluded Models:** `lib/core/models/merchant_models.dart` and all other models.
* **Excluded Providers:** `lib/features/merchant/providers/merchant_provider.dart` and all other providers.
* **Excluded Application Shell:** `lib/app/app.dart`, `lib/main.dart`.
* **Excluded Platform Configs:** All files in `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`.
* **Excluded Dependencies & Assets:** `pubspec.yaml`, `pubspec.lock`, assets directories.

---

## 4. Component-Level Implementation Map (Conversation Detail)

All modifications to `ConversationDetailScreen` are strictly visual and localized within existing widget builder methods:

| Component | Target Method in `conversation_detail_screen.dart` | Visual Enhancement | Preserved Logic & Invariants |
|---|---|---|---|
| **Contextual Top Bar** | `Scaffold.appBar` | Customer avatar + WhatsApp green badge (`#25D366`), verified online presence dot (`#10B981`), assignee badge ("معيّن لك"). | Preserves `customer.displayName` fallback, labels modal trigger, agent assign dialog, and state toggle (`toggle_state`). |
| **Customer Mini-Dashboard** | New localized helper `_buildCustomerContextCard()` | Compact card above timeline with customer status pill, order count, assigned agent, and phone number wrapped in `Directionality(textDirection: TextDirection.ltr)`. | Renders only when `conv != null`. No new network requests; uses existing `conv.customer` and `conv.assignment`. |
| **Message Timeline** | `_buildMessagesList()` | Smooth reverse-scrolling `ListView.builder`, date stamps in soft capsule pills (`#EAEDFF`). | Preserves `_scrollController`, ascending chronological order, and listener hooks. |
| **Inbound Message Bubble** | `_buildMessageBubble()` (`!isOutbound`) | Start-aligned (RTL right) soft neutral bubble (`#F1F5F9`), subtle rounded geometry (`16px`, bottom-end `4px`). | Preserves timestamp display, direction checks, and message text finders. |
| **Outbound Message Bubble** | `_buildMessageBubble()` (`isOutbound && !isPrivate`) | End-aligned (RTL left) brand blue bubble (`AppColors.primary`), white text, delivery status checkmark. | Preserves status indicator, timestamp, and message text finders. |
| **Private Note Memo** | `_buildMessageBubble()` (`isPrivate`) | Warning container (`#FFFBEB`) with `#D97706` amber accents, lock icon, and author label. | **Must keep the text string `'ملاحظة خاصة'` intact** to preserve widget test finders. |
| **AI Draft Card** | `_buildMessageBubble()` / Timeline helper | Purple container (`#F5F3FF`) with auto_awesome icon, "اقتراح ذكي", and "استخدام الرد في المحرر" button. | Tapping button simply copies draft text into `_textController.text` without network side-effects. |
| **Quick Replies Shelf** | Localized helper `_buildQuickRepliesShelf()` | Horizontally scrollable row of pills with lightning prefix (`⚡ خيارات الدفع والشحن`). | Tapping appends/sets text in `_textController` for user review before sending. |
| **Composer Mode Toggle** | `_buildComposer()` | Segmented capsule with customer message (`#087FF5`) and private note (`#D97706`). | **Must preserve `FilterChip` widgets and exact labels `'رسالة للعميل'` and `'ملاحظة داخلية'`** for widget tests. |
| **Composer Input Box** | `_buildComposer()` | Rounded input container, multi-line support, attach & snippet icons. | **Must preserve `TextField` with `_textController` and hint texts `'type_message'` / `'type_private_note'`.** |
| **Send Action Button** | `_buildComposer()` | Styled `IconButton.filled` with directional arrow rotated for RTL (`transform rotate-180`). | **Preserves `isActionLoading ? null : _handleSend`**, in-flight spinner, double-tap lock, and `Idempotency-Key` headers. |
| **Error Banner** | `_buildErrorAlert()` | Amber/red error card showing error text and `req: xxxxxxxx` pill. | Preserves error string and request ID extraction from `merchantProvider.lastRequestId`. |

---

## 5. Verification & Regression Testing Protocol

### 5.1 Pre-Change Baseline (Recorded)
* `flutter test` -> 269 passed.
* `flutter analyze` -> 13 info issues, 0 errors.

### 5.2 Post-Change Execution Protocol
After editing `conversation_detail_screen.dart`, run the following commands sequentially:
1. **Targeted Unit & Widget Tests:**
   ```bash
   flutter test test/merchant_widgets_test.dart
   flutter test test/message_ordering_and_backlog_test.dart
   flutter test test/merchant_filters_test.dart
   flutter test test/merchant_models_and_repository_test.dart
   ```
2. **Full Regression Test Suite:**
   ```bash
   flutter test
   ```
   *Pass Criteria:* Exactly 269 tests (or more) must pass with 0 failures.
3. **Static Analysis & Lint Check:**
   ```bash
   flutter analyze
   ```
   *Pass Criteria:* Zero errors, zero warnings. No increase in info-level lint notices.
4. **Git Diff Verification:**
   ```bash
   git diff --stat
   ```
   *Pass Criteria:* Only `lib/features/merchant/presentation/conversation_detail_screen.dart` is modified. Zero changes in any other directory.

---

## 6. Visual Comparison Procedure (Matching Viewports)

To guarantee high-fidelity alignment with the reference without visual regressions:

1. **Standardized Viewport:**
   * Target Viewport: **390 × 844 logical pixels** (Device pixel ratio: 3.0, representing modern standard mobile devices).
2. **Comparison Matrix (4 Key States):**
   * **State A (Active Chat):** Inbound message, outbound message, customer context header, date stamps.
   * **State B (Private Note Mode):** Segmented toggle on "ملاحظة داخلية", amber composer tint, private note bubbles.
   * **State C (Canned Replies):** Modal sheet open with searchable list of pre-configured responses.
   * **State D (Error / Edge Case):** Error alert banner displayed with request ID; long Arabic text wrapping without overflow.
3. **Inspection Checklist:**
   * Touch targets >= 44 × 44 logical points.
   * Text contrast >= 4.5:1 (WCAG AA).
   * Directional icons correctly mirrored for RTL (back arrow points right, send arrow points left).
   * Phone numbers, IDs, and timestamps directionally isolated (`LTR`).

---

## 7. Rollback Procedure (Preserving Unrelated Work)

If any test fails, visual misalignment occurs, or unexpected behavior is detected:

```bash
# 1. Discard ONLY changes made to the single target screen:
git restore lib/features/merchant/presentation/conversation_detail_screen.dart

# 2. Verify working tree integrity:
git status

# 3. Re-verify the baseline:
flutter test test/merchant_widgets_test.dart
```

*Strict Rule:* Never run `git reset --hard` or `git clean -fd` to prevent accidental loss of untracked notes or documents.

---

## 8. Explicit Stop Conditions

Work must stop immediately and be escalated to the project owner if any of the following occur:
1. **Baseline Test Failure:** Any of the 269 baseline tests fail after a change.
2. **API Layer Diff:** Any git diff detected in `lib/core/api/`, `lib/core/*/*_repository.dart`, or `lib/core/models/`.
3. **Missing Idempotency Header:** Any message or conversation mutation request sent without `Idempotency-Key`.
4. **Altered User Interaction:** Any widget test finder (e.g., `find.text('ملاحظة خاصة')`, `find.text('رسالة للعميل')`, or `find.byType(TextField)`) breaks or requires renaming.
5. **Accidental Dependency Change:** Any modification to `pubspec.yaml`, `pubspec.lock`, or platform build files.
