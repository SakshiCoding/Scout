-- Deletes a restaurant through an RPC so the database performs the
-- circle-membership check in one place, consistent with add_restaurant
-- and get_circle_restaurants which use the same pattern to avoid
-- client-side RLS timing issues.

create or replace function public.delete_restaurant(
  restaurant_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_circle_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select circle_id into target_circle_id
  from public.restaurants
  where id = restaurant_id;

  if target_circle_id is null then
    raise exception 'Restaurant not found';
  end if;

  if not public.is_circle_member(target_circle_id) then
    raise exception 'User is not a member of this circle';
  end if;

  delete from public.restaurants where id = restaurant_id;
end;
$$;

grant execute on function public.delete_restaurant(uuid) to authenticated;
