-- Recreate visit permissions for databases whose initial schema stopped before
-- the journal policies were applied.

grant select, insert, update, delete on public.visits to authenticated;

drop policy if exists "Members can read visits" on public.visits;
create policy "Members can read visits"
  on public.visits for select
  to authenticated
  using (public.is_circle_member(visits.circle_id));

drop policy if exists "Members can insert visits" on public.visits;
create policy "Members can insert visits"
  on public.visits for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and public.is_circle_member(visits.circle_id)
  );

drop policy if exists "Members can update visits" on public.visits;
create policy "Members can update visits"
  on public.visits for update
  to authenticated
  using (public.is_circle_member(visits.circle_id))
  with check (public.is_circle_member(visits.circle_id));

drop policy if exists "Members can delete visits" on public.visits;
create policy "Members can delete visits"
  on public.visits for delete
  to authenticated
  using (public.is_circle_member(visits.circle_id));
