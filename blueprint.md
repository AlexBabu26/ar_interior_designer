# Blueprint: AR Commerce Platform

## Overview
A high-end, AR-enabled e-commerce platform for furniture, allowing users to visualize products in their real-world space before purchasing.

## Project Details
- **Tech Stack:** Flutter (Client), Dart Frog (Planned Backend), Material 3.
- **Design Philosophy:** Premium, tactile UI with deep shadows, custom typography (`Lexend`), and Material 3 `ColorScheme`.
- **Key Features:**
  - Product Catalog (Browsing & Filtering)
  - AR Scene Experience (Multi-node AR placement)
  - Cart Management (Guest & Auth)
  - Secure Checkout

## Current Implementation Plan
1. **Foundation & Theming:**
   - [x] Set up `pubspec.yaml` with dependencies (`google_fonts`, `provider`, `go_router`, `vector_math`).
   - [x] Implement `ThemeProvider` and `Material 3` theme in `main.dart`.
   - [x] Establish folder structure (Feature-first).
2. **Navigation & Skeleton:**
   - [x] Configure `GoRouter` for main screens (Catalog, Product Detail, AR View, Cart).
   - [x] Create basic screen placeholders.
3. **Product Discovery (Catalog):**
   - [x] Define `Product` model.
   - [x] Build the Catalog UI with a premium "lifted" card design.
4. **AR & Cart Integration:**
   - [ ] Implement a simulated AR view for development (interactive nodes).
   - [ ] Build the detailed Product Screen with "View in AR" buttons.
   - [ ] Set up the full `CartProvider` with item removal and quantity.
