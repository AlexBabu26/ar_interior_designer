create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  cart_id uuid not null references public.carts (id) on delete cascade,
  product_id uuid not null references public.products (id),
  quantity integer not null check (quantity > 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (cart_id, product_id)
);

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'set_cart_items_updated_at'
      and tgrelid = 'public.cart_items'::regclass
  ) then
    create trigger set_cart_items_updated_at
      before update on public.cart_items
      for each row
      execute function public.set_updated_at();
  end if;
end
$$;
