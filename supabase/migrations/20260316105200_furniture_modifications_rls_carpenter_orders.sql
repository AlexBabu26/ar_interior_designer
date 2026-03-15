-- Allow carpenters to UPDATE when status = 'open' (so they can assign themselves).
drop policy if exists "Carpenter or admin update modification" on public.furniture_modifications;

create policy "Carpenter or admin update modification"
  on public.furniture_modifications
  for update
  to authenticated
  using (
    assigned_carpenter_id = auth.uid()
    or (status = 'open' and public.is_carpenter())
    or public.is_admin()
  )
  with check (
    assigned_carpenter_id = auth.uid()
    or (status = 'open' and public.is_carpenter())
    or (status = 'cancelled' and public.is_carpenter())
    or public.is_admin()
  );

-- Let modification participants read order details for joined queries.
create policy "Modification participants read order"
  on public.orders
  for select
  to authenticated
  using (
    exists (
      select 1 from public.furniture_modifications fm
      where fm.order_id = orders.id
        and (fm.requested_by = auth.uid() or fm.assigned_carpenter_id = auth.uid() or public.is_admin())
    )
  );

create policy "Modification participants read order item"
  on public.order_items
  for select
  to authenticated
  using (
    exists (
      select 1 from public.furniture_modifications fm
      where fm.order_item_id = order_items.id
        and (fm.requested_by = auth.uid() or fm.assigned_carpenter_id = auth.uid() or public.is_admin())
    )
  );
