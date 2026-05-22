-- Allows authenticated users to create circles even when PostgREST evaluates
-- the insert policy before the created_by default is visible.

alter table public.circles
  alter column created_by set default auth.uid();

drop policy if exists "Authenticated users can create circles" on public.circles;

create policy "Authenticated users can create circles"
  on public.circles for insert
  with check (auth.uid() is not null);
