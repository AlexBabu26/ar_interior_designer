# AR Commerce Platform – Product Requirements Document (PRD)

## 1. Product Overview

### 1.1 Product Name

AR Commerce Platform

### 1.2 Vision

Create a mobile-first e-commerce platform where users can place real products into their environment using augmented reality and purchase them instantly.

The platform will allow users to:
- Browse a curated catalog of 3D products
- Place multiple products in their real-world space using AR
- Build scenes with multiple items
- Add items directly from AR into the cart
- Checkout seamlessly

The initial catalog will be populated by licensed 3D models sourced from public repositories (Sketchfab, Free3D, PolyPizza, etc.) and converted into AR-ready assets.

---

## 2. Goals & Non-Goals

### 2.1 Goals

1. Deliver a mobile AR shopping experience
2. Support multi-product AR scenes
3. Provide a scalable e-commerce backend
4. Maintain clean architecture separation
5. Support 3D asset ingestion pipelines
6. Provide guest carts and authenticated carts
7. Maintain license attribution compliance

### 2.2 Non-Goals (v1)

The following are intentionally out of scope for MVP:
- Marketplace seller onboarding
- Product reviews
- User-generated uploads
- Social sharing
- Complex discount engines
- Real-time multiplayer AR scenes

---

## 3. User Personas

### 3.1 Shopper

A mobile user browsing products and visualizing them in their environment.

**Goals:**
- See how products look in real space
- Compare multiple items
- Purchase quickly

### 3.2 Catalog Curator (Admin)

Internal user responsible for adding AR products.

**Goals:**
- Import 3D models
- Ensure license compliance
- Optimize assets
- Publish products

---

## 4. Core User Experience

### 4.1 Product Discovery

**User flow:**
1. Open app
2. Browse catalog
3. Filter by category
4. Open product
5. Tap "View in AR"

**Supported filters:**
- Category
- Price range
- Availability

### 4.2 AR Scene Experience

**User flow:**
1. Camera opens
2. First product is placed
3. User can:
   - Move
   - Rotate
   - Scale
   - Add another product

Scene supports multiple nodes.

**Each AR node contains:**
```json
{
  "productId": "uuid",
  "assetId": "uuid",
  "position": { "x": 0, "y": 0, "z": 0 },
  "rotation": { "x": 0, "y": 0, "z": 0, "w": 1 },
  "scale": 1.0
}
```

Scene state is ephemeral and not persisted to the backend.

### 4.3 Add to Cart from AR

When a product node is selected, bottom sheet displays:
- Product name
- Price
- Add to cart button

Adds item to cart via API.

### 4.4 Checkout Flow

1. User opens cart
2. Reviews items
3. Confirms checkout
4. Order created
5. Payment processed
6. Order confirmation shown

---

## 5. System Architecture

### 5.1 High Level Architecture

```
Flutter Client
      |
      v
Dart Frog API
      |
      v
Application Layer (Use Cases)
      |
      v
Domain Layer
      |
      v
Infrastructure
  |        |
Postgres  Object Storage
(Neon)     (CDN)
```

---

## 6. Backend Architecture

### Clean Architecture Layers

```
presentation
   |
application
   |
domain
   |
infrastructure
```

Dependencies only point inward.

### 6.1 Domain Layer

**Contains:**
- Entities
- Value Objects
- Repository interfaces
- Domain services

**Entities:**
- Product
- Cart
- Order
- Asset

**Value Objects:**
- Money
- ProductId
- AssetUrl

**Domain Services:**
- PricingService
- CheckoutService
- CartMergeService
- InventoryService

### 6.2 Application Layer

Use cases orchestrate domain operations.

**Examples:**
- GetProducts
- GetProductDetail
- AddToCart
- UpdateCartItem
- RemoveCartItem
- Checkout
- MergeGuestCart

Use cases are pure business logic.

### 6.3 Infrastructure Layer

**Adapters:**
- Postgres repositories
- CDN adapter
- Payment provider adapter

### 6.4 Presentation Layer

Dart Frog routes. Routes call use cases and return DTOs.

---

## 7. Database Design

### 7.1 Users

```sql
create table users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  created_at timestamp default now()
);
```

### 7.2 Categories

```sql
create table categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null
);
```

### 7.3 Products

```sql
create table products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  description text,
  price_cents bigint not null,
  currency text default 'USD',
  stock_quantity integer default 0,
  is_active boolean default false,
  created_at timestamp default now()
);
```

### 7.4 Product Categories

Multi-category support.

```sql
create table product_categories (
  product_id uuid references products(id) on delete cascade,
  category_id uuid references categories(id) on delete cascade,
  primary key (product_id, category_id)
);
```

### 7.5 Product Images

```sql
create table product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id) on delete cascade,
  url text not null,
  is_primary boolean default false,
  sort_order integer default 0
);
```

### 7.6 3D Assets

Supports multiple runtimes.

```sql
create table product_3d_assets (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id) on delete cascade,
  runtime text not null,
  format text not null,
  cdn_key text not null,
  thumbnail_url text,
  file_size_bytes bigint,
  polygon_count integer,
  has_textures boolean default false,
  mobile_optimized boolean default false,
  width_meters numeric,
  height_meters numeric,
  depth_meters numeric,
  status text default 'pending',
  source_site text,
  source_url text,
  license_type text,
  attribution_text text,
  created_at timestamp default now()
);
```

**Runtime examples:**
- `android_sceneview`
- `ios_quicklook`
- `webxr`

---

## 8. Cart System

### 8.1 Carts

Supports both guest carts and user carts.

```sql
create table carts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete cascade,
  guest_token text,
  status text default 'active',
  created_at timestamp default now()
);

-- Partial Unique Index: Only one active cart per user
create unique index uniq_active_cart_user 
on carts(user_id) 
where status = 'active';
```

### 8.2 Cart Items

```sql
create table cart_items (
  id uuid primary key default gen_random_uuid(),
  cart_id uuid references carts(id) on delete cascade,
  product_id uuid references products(id) on delete cascade,
  quantity integer not null default 1,
  unit_price_cents bigint not null
);
```

Prices are snapshotted.

---

## 9. Orders

### 9.1 Orders

```sql
create table orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id),
  status text default 'pending',
  payment_status text default 'pending',
  payment_provider text,
  payment_reference text,
  subtotal_cents bigint not null,
  tax_cents bigint default 0,
  shipping_cents bigint default 0,
  discount_cents bigint default 0,
  total_cents bigint not null,
  currency text default 'USD',
  placed_at timestamp,
  created_at timestamp default now()
);
```

### 9.2 Order Items

```sql
create table order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade,
  product_id uuid references products(id),
  product_name text not null,
  product_image_url text,
  quantity integer not null,
  unit_price_cents bigint not null
);
```

All data snapshotted.

---

## 10. Inventory

Inventory handled transactionally during checkout.

**Algorithm:**
```sql
begin;

select stock_quantity 
from products 
where id = ? 
for update;

-- if sufficient stock:
update products 
set stock_quantity = stock_quantity - ? 
where id = ?;

-- create order
insert into orders ...;

commit;
```

Prevents overselling.

---

## 11. Storage Strategy

3D models are never served by API servers.

They live in:
- Cloudflare R2
- S3
- Supabase Storage

Database stores: `cdn_key`

API returns generated CDN URL.

---

## 12. API Specification

**Base URL:** `/api/v1`

### Products

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/products` | List products |
| GET | `/products/{id}` | Get product detail |
| GET | `/products/{id}/assets` | Get product 3D assets |

### Cart

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/cart` | Get current cart |
| POST | `/cart/items` | Add item to cart |
| PATCH | `/cart/items/{id}` | Update cart item |
| DELETE | `/cart/items/{id}` | Remove cart item |

**Add item request:**
```json
{
  "productId": "uuid",
  "quantity": 1
}
```

### Orders

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/checkout` | Create order and process payment |
| GET | `/orders` | List user orders |
| GET | `/orders/{id}` | Get order detail |

### Admin APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/admin/products` | Create product |
| POST | `/admin/products/{id}/images` | Add product image |
| POST | `/admin/products/{id}/assets` | Add 3D asset |
| POST | `/admin/assets/import` | Import external asset |
| POST | `/admin/assets/{id}/process` | Process asset |
| POST | `/admin/assets/{id}/publish` | Publish asset |

---

## 13. AR Asset Pipeline

**Workflow:**
```
Download model
    ↓
Validate license
    ↓
Optimize (Blender / gltf-transform)
    ↓
Generate formats
    ↓
Upload to CDN
    ↓
Insert metadata into DB
    ↓
Publish product
```

---

## 14. Flutter Client Architecture

Feature-first structure.

```
lib/
  core/
  features/
    catalog/
    product_detail/
    ar_view/
    cart/
    checkout/
```

Each feature contains:
- `data/`
- `domain/`
- `presentation/`

---

## 15. AR Scene Design

Scene objects are client-side only.

**Each node:**
```dart
class ARNode {
  final String productId;
  final String assetId;
  final Vector3 position;
  final Quaternion rotation;
  final double scale;
}
```

Cart state remains separate.

---

## 16. Security

**Authentication:**
- JWT tokens
- Guest token for anonymous carts

**Admin routes require:** `role=admin`

---

## 17. Analytics

Track:
- Product views
- AR launches
- Add to cart
- Checkout conversions

---

## 18. Success Metrics

**Primary metrics:**
- AR session rate
- AR → cart conversion
- Cart → checkout conversion
- Average order value

---

## 19. MVP Scope

**Includes:**
- Product catalog
- AR placement
- Multi-item scenes
- Cart
- Checkout
- Admin ingestion

---

## 20. Future Enhancements

- Saved AR scenes
- Room measurement
- AI furniture suggestions
- Marketplace sellers
- Real-time multi-user AR
- Subscription catalogs
