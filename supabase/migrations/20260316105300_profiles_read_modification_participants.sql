-- Let modification participants read the other party's profile (display_name) for chat header.
create policy "Read profile when same modification thread"
  on public.profiles
  for select
  to authenticated
  using (
    id = auth.uid()
    or exists (
      select 1 from public.furniture_modifications fm
      where (fm.requested_by = profiles.id or fm.assigned_carpenter_id = profiles.id)
        and (fm.requested_by = auth.uid() or fm.assigned_carpenter_id = auth.uid() or public.is_admin())
    )
  );
