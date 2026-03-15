create table if not exists public.carts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'active' check (status in ('active', 'checked_out', 'abandoned')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists carts_active_user_idx
  on public.carts (user_id)
  where status = 'active';

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'set_carts_updated_at'
      and tgrelid = 'public.carts'::regclass
  ) then
    create trigger set_carts_updated_at
      before update on public.carts
      for each row
      execute function public.set_updated_at();
  end if;
end
$$;
