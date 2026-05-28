-- Adds a stable add_visit RPC shape for clients that omit null RPC arguments.
-- Optional visit fields live inside visit_payload, while the RPC signature stays fixed.

create or replace function public.add_visit(
  target_restaurant_id uuid,
  visit_circle_id uuid,
  visit_payload jsonb default '{}'::jsonb
)
returns public.visits
language plpgsql
security definer
set search_path = public
as $$
declare
  new_visit public.visits;
  target_circle_id uuid;
  current_user_id uuid := auth.uid();
  payload_visited_at timestamptz;
  payload_notes text;
  payload_rating double precision;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  select circle_id into target_circle_id
  from public.restaurants
  where id = target_restaurant_id;

  if target_circle_id is null then
    raise exception 'Restaurant not found';
  end if;

  if target_circle_id <> visit_circle_id then
    raise exception 'Restaurant is not in this circle';
  end if;

  if not public.is_circle_member(visit_circle_id) then
    raise exception 'User is not a member of this circle';
  end if;

  payload_visited_at := coalesce((visit_payload ->> 'visited_at')::timestamptz, now());
  payload_notes := nullif(visit_payload ->> 'notes', '');
  payload_rating := nullif(visit_payload ->> 'rating', '')::double precision;

  insert into public.visits (
    restaurant_id,
    circle_id,
    user_id,
    visited_at,
    notes,
    rating
  )
  values (
    target_restaurant_id,
    visit_circle_id,
    current_user_id,
    payload_visited_at,
    payload_notes,
    payload_rating
  )
  returning * into new_visit;

  return new_visit;
end;
$$;

grant execute on function public.add_visit(
  uuid,
  uuid,
  jsonb
) to authenticated;
