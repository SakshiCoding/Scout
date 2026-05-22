-- Fetches restaurants for a circle through a database function so the app does
-- not depend on table-select RLS behavior for wishlist restore.

create or replace function public.get_circle_restaurants(target_circle_id uuid)
returns setof public.restaurants
language sql
stable
security definer
set search_path = public
as $$
  select r.*
  from public.restaurants r
  where r.circle_id = target_circle_id
    and public.is_circle_member(target_circle_id)
  order by r.created_at desc;
$$;

grant execute on function public.get_circle_restaurants(uuid) to authenticated;
