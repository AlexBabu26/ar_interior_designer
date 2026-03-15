alter table public.carts enable row level security;
alter table public.cart_items enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'carts'
      and policyname = 'Users manage own carts'
  ) then
    create policy "Users manage own carts"
      on public.carts
      for all
      to authenticated
      using (user_id = auth.uid())
      with check (user_id = auth.uid());
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'cart_items'
      and policyname = 'Users manage own cart items'
  ) then
    create policy "Users manage own cart items"
      on public.cart_items
      for all
      to authenticated
      using (
        exists (
          select 1
          from public.carts
          where carts.id = cart_items.cart_id
            and carts.user_id = auth.uid()
        )
      )
      with check (
        exists (
          select 1
          from public.carts
          where carts.id = cart_items.cart_id
            and carts.user_id = auth.uid()
        )
      );
  end if;
end
$$;
