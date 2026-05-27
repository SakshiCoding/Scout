-- Add establishment_type to restaurants
ALTER TABLE public.restaurants
ADD COLUMN IF NOT EXISTS establishment_type TEXT NOT NULL DEFAULT 'restaurant';

-- Drop old 11-param overload so the new default-param version is the only one
DROP FUNCTION IF EXISTS public.add_restaurant(
  uuid, text, text, text, text,
  double precision, double precision,
  text, text[], double precision, text
);

-- Recreate with establishment_type parameter (default keeps old callers working)
CREATE OR REPLACE FUNCTION public.add_restaurant(
  restaurant_circle_id       uuid,
  restaurant_name            text,
  restaurant_cuisine         text             default null,
  restaurant_price_tier      text             default null,
  restaurant_address         text             default null,
  restaurant_latitude        double precision default null,
  restaurant_longitude       double precision default null,
  restaurant_notes           text             default null,
  restaurant_vibe_tags       text[]           default '{}',
  restaurant_rating          double precision default null,
  restaurant_photo_url       text             default null,
  restaurant_establishment_type text          default 'restaurant'
)
returns public.restaurants
language plpgsql
security definer
set search_path = public
as $$
declare
  new_restaurant public.restaurants;
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not public.is_circle_member(restaurant_circle_id) then
    raise exception 'User is not a member of this circle';
  end if;

  insert into public.restaurants (
    circle_id, name, cuisine, price_tier, address,
    latitude, longitude, notes, vibe_tags, rating,
    photo_url, added_by, establishment_type
  ) values (
    restaurant_circle_id, restaurant_name, restaurant_cuisine,
    restaurant_price_tier, restaurant_address, restaurant_latitude,
    restaurant_longitude, restaurant_notes,
    coalesce(restaurant_vibe_tags, '{}'), restaurant_rating,
    restaurant_photo_url, current_user_id,
    coalesce(restaurant_establishment_type, 'restaurant')
  )
  returning * into new_restaurant;

  return new_restaurant;
end;
$$;

grant execute on function public.add_restaurant(
  uuid, text, text, text, text,
  double precision, double precision,
  text, text[], double precision, text, text
) to authenticated;
