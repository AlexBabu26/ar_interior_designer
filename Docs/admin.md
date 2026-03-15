# Admin Guide

## 1. How to log in / create an admin account

### Normal login
- Use **Register** to create an account (default role: **customer**).
- Use **Login** with that email and password to sign in.

### Making a user an admin
The app does not allow changing role from the UI. Role is stored in `public.profiles.role` and only `'customer'` or `'admin'` are allowed. Authenticated users can only update their own `display_name`, not `role`.

**To promote a user to admin:**

1. In **Supabase Dashboard**: go to **SQL Editor** and run (replace with the user’s email or id):

```sql
-- By email
update public.profiles
set role = 'admin'
where email = 'admin@example.com';

-- Or by user id (from Authentication → Users in Supabase)
update public.profiles
set role = 'admin'
where id = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
```

2. The user signs out and signs in again (or refreshes) so the app reloads their profile. The **Admin** option will then appear in the account menu and they can open the admin dashboard.

### Summary
| Step | Action |
|------|--------|
| 1 | Register or use an existing account. |
| 2 | In Supabase: `update public.profiles set role = 'admin' where email = '...'` (or `where id = '...'`). |
| 3 | Sign out and sign in again. Use **Account** menu → **Open admin dashboard** (or go to `/admin`). |

---

## 2. Admin pages and routes

| Route | Screen | Description |
|-------|--------|-------------|
| `/admin` | **Admin Dashboard** | Entry point: product management link, analytics link. |
| `/admin/products` | **Manage Products** | List all products (active and inactive); tap a row to edit. “Add product” opens the create form. |
| `/admin/products/new` | **Add Product** | Create a new product (name, description, price, image URL, 3D model URL, categories, active flag). |
| `/admin/products/:id/edit` | **Edit Product** | Same form as create, pre-filled; save updates the product. Option to delete. |
| `/admin/analytics` | **Analytics** | Dashboard with order count, revenue, product count, and recent orders. |

Access to `/admin` and any `/admin/*` route is restricted: non-admin users are redirected to `/`.

---

## 3. Admin product CRUD

| Action | How | Implementation |
|--------|-----|----------------|
| **Create** | Dashboard → “Product management” → “Add product”, or product list → “Add product”. | `POST` to `products` (upsert with no id). Primary 3D model stored in `product_models`. |
| **Read** | List: `/admin/products` loads all products via `getAdminProducts()`. Single: open edit form; `getProductById(id)` loads one product. | Supabase `products` + `product_models`; RLS allows admin to select all. |
| **Update** | Open a product from the list → edit fields → “Save Product”. | Upsert to `products`; primary model updated in `product_models`. |
| **Delete** | On the edit screen, use “Delete product” (with confirmation). | Repository `deleteProduct(id)`; deletes product (and related `product_models` via FK cascade). |

Form fields: **Name**, **Description**, **Price**, **Image URL**, **Primary 3D Model URL**, **Categories** (comma-separated), **Active** (toggle). Saving validates required fields and then creates or updates the product and its primary model.

---

## 4. Admin analytics dashboard

**Route:** `/admin/analytics`

The analytics screen shows:

- **Total orders** – count of all orders (admin sees all via RLS).
- **Total revenue** – sum of `orders.total`.
- **Total products** – count of all products (active and inactive).
- **Recent orders** – list of latest orders (e.g. order number, status, total, date) with optional link to more detail later.

Data is loaded from the same `OrderRepository` and `ProductRepository` used elsewhere; RLS ensures only admins see all orders when they are logged in.

---

## 5. Database and RLS (reference)

- **Profiles:** `public.profiles` – `id`, `email`, `display_name`, `role` (`'customer'` \| `'admin'`). New users get a profile with `role = 'customer'` via trigger.
- **Admin check:** `public.is_admin()` returns true when the current user’s profile has `role = 'admin'`. Used in RLS for `products`, `orders`, etc.
- **Products:** Admins can select/insert/update/delete all rows; customers see only active products.
- **Orders:** Admins can select all orders; customers see only their own.
