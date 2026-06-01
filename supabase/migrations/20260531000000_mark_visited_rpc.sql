-- mark_visited RPC: updates restaurant status to 'visited'.
-- Uses SECURITY DEFINER to avoid RLS timing issues with is_circle_member.

create or replace function public.mark_visited(
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
    raise exception 'Not a member of this circle';
  end if;

  update public.restaurants
  set status = 'visited'
  where id = restaurant_id;
end;
$$;

grant execute on function public.mark_visited(uuid) to authenticated;
