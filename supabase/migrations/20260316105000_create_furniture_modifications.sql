-- Modification request thread (one per order item when customer asks for modifications).
create table if not exists public.furniture_modifications (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  order_item_id uuid not null references public.order_items (id) on delete cascade,
  requested_by uuid not null references auth.users (id) on delete cascade,
  assigned_carpenter_id uuid references auth.users (id) on delete set null,
  status text not null default 'open' check (status in ('open', 'in_progress', 'completed', 'cancelled')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (order_item_id)
);

-- Chat messages in a modification thread.
create table if not exists public.furniture_modification_messages (
  id uuid primary key default gen_random_uuid(),
  modification_id uuid not null references public.furniture_modifications (id) on delete cascade,
  sender_id uuid not null references auth.users (id) on delete cascade,
  content text not null,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_furniture_modifications_requested_by
  on public.furniture_modifications (requested_by);
create index if not exists idx_furniture_modifications_assigned_carpenter
  on public.furniture_modifications (assigned_carpenter_id);
create index if not exists idx_furniture_modifications_status
  on public.furniture_modifications (status);
create index if not exists idx_furniture_modification_messages_modification_id
  on public.furniture_modification_messages (modification_id);

create or replace function public.is_carpenter()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'carpenter'
  );
$$;

do $$
begin
  if not exists (
    select 1 from pg_trigger
    where tgname = 'set_furniture_modifications_updated_at'
      and tgrelid = 'public.furniture_modifications'::regclass
  ) then
    create trigger set_furniture_modifications_updated_at
      before update on public.furniture_modifications
      for each row
      execute function public.set_updated_at();
  end if;
end
$$;
