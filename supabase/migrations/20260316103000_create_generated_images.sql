create table if not exists public.generated_images (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  prompt text not null,
  image_path text not null,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.generated_images enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'generated_images'
      and policyname = 'Users read own generated images'
  ) then
    create policy "Users read own generated images"
      on public.generated_images
      for select
      to authenticated
      using (user_id = auth.uid());
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'generated_images'
      and policyname = 'Users insert own generated images'
  ) then
    create policy "Users insert own generated images"
      on public.generated_images
      for insert
      to authenticated
      with check (user_id = auth.uid());
  end if;
end
$$;
