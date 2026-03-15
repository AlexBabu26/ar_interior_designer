alter table public.orders enable row level security;
alter table public.order_items enable row level security;

grant execute on function public.checkout_active_cart() to authenticated;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'orders'
      and policyname = 'Users read own orders'
  ) then
    create policy "Users read own orders"
      on public.orders
      for select
      to authenticated
      using (user_id = auth.uid() or public.is_admin());
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'orders'
      and policyname = 'Users create own orders'
  ) then
    create policy "Users create own orders"
      on public.orders
      for insert
      to authenticated
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
      and tablename = 'order_items'
      and policyname = 'Users read own order items'
  ) then
    create policy "Users read own order items"
      on public.order_items
      for select
      to authenticated
      using (
        exists (
          select 1
          from public.orders
          where orders.id = order_items.order_id
            and (orders.user_id = auth.uid() or public.is_admin())
        )
      );
  end if;
end
$$;
