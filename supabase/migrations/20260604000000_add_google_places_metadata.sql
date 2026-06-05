-- Persist the Google Places identity used to enrich restaurant records.
alter table public.restaurants
add column if not exists google_place_id text;

create index if not exists restaurants_google_place_id_idx
  on public.restaurants(google_place_id)
  where google_place_id is not null;

drop function if exists public.add_restaurant(
  uuid, text, text, text, text,
  double precision, double precision,
  text, text[], double precision, text, text
);

create or replace function public.add_restaurant(
  restaurant_circle_id          uuid,
  restaurant_name               text,
  restaurant_cuisine            text             default null,
  restaurant_price_tier         text             default null,
  restaurant_address            text             default null,
  restaurant_latitude           double precision default null,
  restaurant_longitude          double precision default null,
  restaurant_notes              text             default null,
  restaurant_vibe_tags          text[]           default '{}',
  restaurant_rating             double precision default null,
  restaurant_photo_url          text             default null,
  restaurant_establishment_type text             default 'restaurant',
  restaurant_google_place_id    text             default null
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
    photo_url, added_by, establishment_type,
    google_place_id
  ) values (
    restaurant_circle_id, restaurant_name, restaurant_cuisine,
    restaurant_price_tier, restaurant_address, restaurant_latitude,
    restaurant_longitude, restaurant_notes,
    coalesce(restaurant_vibe_tags, '{}'), restaurant_rating,
    restaurant_photo_url, current_user_id,
    coalesce(restaurant_establishment_type, 'restaurant'),
    restaurant_google_place_id
  )
  returning * into new_restaurant;

  return new_restaurant;
end;
$$;

grant execute on function public.add_restaurant(
  uuid, text, text, text, text,
  double precision, double precision,
  text, text[], double precision, text, text, text
) to authenticated;
