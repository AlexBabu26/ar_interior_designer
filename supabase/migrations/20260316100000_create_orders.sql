create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  order_number text not null unique,
  status text not null default 'placed' check (status in ('placed', 'paid', 'cancelled')),
  subtotal numeric(12,2) not null check (subtotal >= 0),
  total numeric(12,2) not null check (total >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'set_orders_updated_at'
      and tgrelid = 'public.orders'::regclass
  ) then
    create trigger set_orders_updated_at
      before update on public.orders
      for each row
      execute function public.set_updated_at();
  end if;
end
$$;
