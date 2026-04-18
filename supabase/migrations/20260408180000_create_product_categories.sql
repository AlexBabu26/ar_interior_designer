-- Migration to create product_categories table
create table if not exists public.product_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default timezone('utc', now())
);

-- Enable RLS
alter table public.product_categories enable row level security;

-- Policies
create policy "Categories are viewable by everyone"
  on public.product_categories for select
  using (true);

create policy "Categories are manageable by admins"
  on public.product_categories for all
  using (
    exists (
      select 1 from public.profiles
      where profiles.id = auth.uid()
        and profiles.role = 'admin'
    )
  );

-- Seed some initial categories
insert into public.product_categories (name)
values 
  ('Sofas'),
  ('Chairs'),
  ('Tables'),
  ('Beds'),
  ('Storage'),
  ('Decor'),
  ('Office')
on conflict (name) do nothing;
