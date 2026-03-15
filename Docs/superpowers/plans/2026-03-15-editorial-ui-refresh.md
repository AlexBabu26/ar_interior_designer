# Editorial UI Refresh Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the app into a light-first, premium furniture shopping experience that aligns with the approved design direction across the whole app.

**Architecture:** Introduce a centralized visual system first, then apply it consistently across storefront, purchase flow, account/auth, and admin screens. Keep business logic intact where possible and focus changes on theme, layout structure, reusable UI sections, and clearer visual hierarchy.

**Tech Stack:** Flutter, Material 3, Provider, Go Router, Google Fonts, flutter_test

---

## Chunk 1: Shared Design System

### Task 1: Create app-wide visual foundations

**Files:**
- Create: `lib/app/app_theme.dart`
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

Add assertions to `test/widget_test.dart` for the new premium shell behavior:
- catalog screen renders new hero copy
- app uses the light-first navigation experience
- key CTA text from the refreshed storefront is visible

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the existing app still renders the old shell and copy.

- [ ] **Step 3: Write minimal implementation**

Create `lib/app/app_theme.dart` with:
- the approved parchment/charcoal/clay/umber/sienna palette
- serif display typography for headings and sans-serif body text
- shared component theme overrides for app bars, cards, buttons, chips, inputs, and dividers

Update `lib/main.dart` to:
- build themes through the new theme file
- make light mode the primary polished experience
- keep dark mode available but visually simpler

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS with the refreshed shell expectations satisfied.

- [ ] **Step 5: Commit**

```bash
git add lib/app/app_theme.dart lib/main.dart test/widget_test.dart
git commit -m "feat: add editorial app theme foundation"
```

### Task 2: Add reusable layout primitives for consistent pages

**Files:**
- Create: `lib/app/app_surfaces.dart`
- Modify: `lib/features/storefront/presentation/storefront_screens.dart`
- Modify: `lib/features/auth/presentation/auth_screens.dart`
- Modify: `lib/features/orders/presentation/purchase_history_screen.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

Extend `test/widget_test.dart` to assert:
- the catalog exposes the new hero section and filter treatment
- the new shell still renders inside the updated shared page scaffolding

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the shared surfaces do not exist yet.

- [ ] **Step 3: Write minimal implementation**

Create reusable widgets/helpers in `lib/app/app_surfaces.dart` for:
- page width and section padding
- elevated content cards
- section headers / eyebrow labels
- empty/error panels
- bottom action containers for cart/checkout-style flows

Adopt these primitives in one or two screens first to confirm the pattern.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS with the new shared scaffolding in place.

- [ ] **Step 5: Commit**

```bash
git add lib/app/app_surfaces.dart lib/features/storefront/presentation/storefront_screens.dart lib/features/auth/presentation/auth_screens.dart lib/features/orders/presentation/purchase_history_screen.dart test/widget_test.dart
git commit -m "feat: add reusable editorial layout surfaces"
```

## Chunk 2: Storefront And Purchase Flow

### Task 3: Redesign catalog and product presentation

**Files:**
- Modify: `lib/features/storefront/presentation/storefront_screens.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

Add expectations for:
- editorial hero copy and supporting text
- improved filter labels
- product card metadata visible in the new layout

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the catalog still uses the old compact layout.

- [ ] **Step 3: Write minimal implementation**

Update `CatalogScreen`, `ProductCard`, and `ProductDetailScreen` to provide:
- large editorial hero section
- refined filter chip row
- larger, softer product cards with curated metadata
- richer product detail layout with clearer CTA hierarchy and premium spacing

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS and no regressions in the catalog smoke test.

- [ ] **Step 5: Commit**

```bash
git add lib/features/storefront/presentation/storefront_screens.dart test/widget_test.dart
git commit -m "feat: redesign storefront presentation"
```

### Task 4: Redesign AR, cart, and checkout flow

**Files:**
- Modify: `lib/features/storefront/presentation/storefront_screens.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

Add or update tests for:
- cart summary content hierarchy
- checkout CTA and summary layout
- AR view support text or action labels used in the refreshed layout

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the flow still renders the old utilitarian layout.

- [ ] **Step 3: Write minimal implementation**

Refresh `ARViewScreen`, `CartScreen`, and `CheckoutScreen` to:
- use the shared bottom action surfaces
- improve spacing and typography
- present clearer summaries and price emphasis
- retain existing cart and checkout behavior

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS with purchase-flow expectations updated.

- [ ] **Step 5: Commit**

```bash
git add lib/features/storefront/presentation/storefront_screens.dart test/widget_test.dart
git commit -m "feat: refresh cart and checkout layouts"
```

## Chunk 3: Auth, Account, History, And Admin

### Task 5: Refresh auth and account areas

**Files:**
- Modify: `lib/features/auth/presentation/auth_screens.dart`
- Modify: `lib/features/orders/presentation/purchase_history_screen.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

Add expectations for:
- richer auth screen structure
- improved account page hierarchy
- purchase history rendered inside elevated editorial sections

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because these screens still use plain cards and default spacing.

- [ ] **Step 3: Write minimal implementation**

Update auth, account, and purchase history screens to:
- use stronger heading hierarchy
- apply premium cards and section grouping
- improve actions, empty states, and supporting copy

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS with the refreshed structure in place.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/auth_screens.dart lib/features/orders/presentation/purchase_history_screen.dart test/widget_test.dart
git commit -m "feat: refresh account and auth experience"
```

### Task 6: Align admin screens and verify the refreshed app

**Files:**
- Modify: `lib/features/auth/presentation/auth_screens.dart`
- Modify: `lib/features/admin/presentation/admin_product_screens.dart`
- Modify: `test/widget_test.dart`
- Modify: `test/app/app_router_test.dart`
- Test: `test/widget_test.dart`
- Test: `test/app/app_router_test.dart`

- [ ] **Step 1: Write the failing test**

Add assertions that:
- admin entry points remain accessible for admins
- refreshed navigation labels and app shell still route correctly

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart test/app/app_router_test.dart`
Expected: FAIL because the updated labels/layout are not wired into tests yet.

- [ ] **Step 3: Write minimal implementation**

Update admin-facing UI to:
- share the same palette and spacing system
- keep admin tasks readable and utilitarian
- preserve routing and auth gating behavior

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart test/app/app_router_test.dart`
Expected: PASS.

- [ ] **Step 5: Run broader verification**

Run: `flutter test`
Expected: project tests pass, or any pre-existing failures are clearly identified.

Run: `dart analyze lib test`
Expected: no new analyzer issues in edited files.

- [ ] **Step 6: Commit**

```bash
git add lib/features/auth/presentation/auth_screens.dart lib/features/admin/presentation/admin_product_screens.dart test/widget_test.dart test/app/app_router_test.dart
git commit -m "feat: align admin ui with editorial refresh"
```
