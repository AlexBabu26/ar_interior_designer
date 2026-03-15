alter table public.furniture_modifications enable row level security;
alter table public.furniture_modification_messages enable row level security;

grant select, insert, update on public.furniture_modifications to authenticated;
grant select, insert on public.furniture_modification_messages to authenticated;

-- Customer: see and create modifications for their own orders; carpenters see assigned or open; admin sees all.
create policy "Users read own or assigned or admin all modifications"
  on public.furniture_modifications
  for select
  to authenticated
  using (
    requested_by = auth.uid()
    or assigned_carpenter_id = auth.uid()
    or (status = 'open' and public.is_carpenter())
    or public.is_admin()
  );

create policy "Customers create modifications for own orders"
  on public.furniture_modifications
  for insert
  to authenticated
  with check (
    requested_by = auth.uid()
    and exists (
      select 1 from public.orders
      where orders.id = order_id and orders.user_id = auth.uid()
    )
  );

create policy "Carpenter or admin update modification"
  on public.furniture_modifications
  for update
  to authenticated
  using (
    assigned_carpenter_id = auth.uid() or public.is_admin()
  )
  with check (
    assigned_carpenter_id = auth.uid() or public.is_admin()
  );

-- Messages: participants and admin can read; customer/carpenter in thread can insert.
create policy "Participants and admin read messages"
  on public.furniture_modification_messages
  for select
  to authenticated
  using (
    exists (
      select 1 from public.furniture_modifications fm
      where fm.id = modification_id
        and (fm.requested_by = auth.uid() or fm.assigned_carpenter_id = auth.uid() or public.is_admin())
    )
  );

create policy "Participant can send message"
  on public.furniture_modification_messages
  for insert
  to authenticated
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.furniture_modifications fm
      where fm.id = modification_id
        and (fm.requested_by = auth.uid() or fm.assigned_carpenter_id = auth.uid())
    )
  );
