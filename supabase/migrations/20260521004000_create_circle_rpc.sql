-- Creates a circle and its first membership in one database operation.
-- This avoids the RLS timing problem where the app must create a circle before
-- the user is a member of that circle.

create or replace function public.create_circle(
  circle_name text,
  circle_short_name text default null,
  circle_accent_color text default '#CC5500',
  member_initials text default '?'
)
returns public.circles
language plpgsql
security definer
set search_path = public
as $$
declare
  new_circle public.circles;
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  insert into public.circles (name, short_name, accent_color, created_by)
  values (circle_name, circle_short_name, circle_accent_color, current_user_id)
  returning * into new_circle;

  insert into public.circle_members (circle_id, user_id, initials)
  values (new_circle.id, current_user_id, member_initials)
  on conflict (circle_id, user_id) do nothing;

  return new_circle;
end;
$$;

grant execute on function public.create_circle(text, text, text, text) to authenticated;
