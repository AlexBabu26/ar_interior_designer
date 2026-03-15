create table if not exists public.product_models (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products (id) on delete cascade,
  model_url text not null,
  model_type text not null default 'glb',
  is_primary boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists product_models_primary_model_idx
  on public.product_models (product_id)
  where is_primary = true;
