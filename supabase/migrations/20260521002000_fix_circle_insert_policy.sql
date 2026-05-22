-- Makes circle creation policy explicit for existing databases.

drop policy if exists "Authenticated users can create circles" on public.circles;

create policy "Authenticated users can create circles"
  on public.circles for insert
  with check (
    auth.uid() is not null
    and created_by = auth.uid()
  );
