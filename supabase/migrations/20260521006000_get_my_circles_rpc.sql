-- Fetches circles visible to the current user without relying on PostgREST
-- embedded joins or table-select RLS behavior in the app.

create or replace function public.get_my_circles()
returns setof public.circles
language sql
stable
security definer
set search_path = public
as $$
  select c.*
  from public.circles c
  where auth.uid() is not null
    and (
      c.created_by = auth.uid()
      or exists (
        select 1
        from public.circle_members cm
        where cm.circle_id = c.id
          and cm.user_id = auth.uid()
      )
    )
  order by c.created_at desc;
$$;

grant execute on function public.get_my_circles() to authenticated;
