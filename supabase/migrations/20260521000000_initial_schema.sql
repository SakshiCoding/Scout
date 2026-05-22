-- Scout initial Supabase schema
-- Apply this in Supabase SQL editor or with the Supabase CLI.

create extension if not exists pgcrypto;

-- MARK: - Profiles

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  initials text not null,
  display_name text not null,
  created_at timestamptz not null default now()
);

-- MARK: - Circles

create table if not exists public.circles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  short_name text,
  accent_color text not null default '#CC5500',
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now()
);

create table if not exists public.circle_members (
  circle_id uuid not null references public.circles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  initials text not null,
  created_at timestamptz not null default now(),
  primary key (circle_id, user_id)
);

-- MARK: - Restaurants

create table if not exists public.restaurants (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles(id) on delete cascade,
  name text not null,
  cuisine text,
  price_tier text check (price_tier in ('$', '$$', '$$$', '$$$$')),
  address text,
  latitude double precision,
  longitude double precision,
  status text not null default 'want_to_try' check (status in ('want_to_try', 'visited')),
  notes text,
  vibe_tags text[] not null default '{}',
  rating double precision check (rating is null or (rating >= 0 and rating <= 5)),
  photo_url text,
  added_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- MARK: - Visits

create table if not exists public.visits (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid not null references public.restaurants(id) on delete cascade,
  circle_id uuid not null references public.circles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  visited_at timestamptz not null default now(),
  notes text,
  rating double precision check (rating is null or (rating >= 0 and rating <= 5)),
  created_at timestamptz not null default now()
);

-- MARK: - Media

create table if not exists public.media (
  id uuid primary key default gen_random_uuid(),
  restaurant_id uuid references public.restaurants(id) on delete cascade,
  visit_id uuid references public.visits(id) on delete cascade,
  circle_id uuid not null references public.circles(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null,
  media_type text not null check (media_type in ('photo', 'video')),
  created_at timestamptz not null default now(),
  check (restaurant_id is not null or visit_id is not null)
);

-- MARK: - Indexes

create index if not exists profiles_created_at_idx
  on public.profiles(created_at desc);

create index if not exists circle_members_user_id_idx
  on public.circle_members(user_id);

create index if not exists restaurants_circle_id_created_at_idx
  on public.restaurants(circle_id, created_at desc);

create index if not exists restaurants_circle_id_status_idx
  on public.restaurants(circle_id, status);

create index if not exists visits_circle_id_visited_at_idx
  on public.visits(circle_id, visited_at desc);

create index if not exists visits_restaurant_id_idx
  on public.visits(restaurant_id);

create index if not exists media_circle_id_created_at_idx
  on public.media(circle_id, created_at desc);

create index if not exists media_restaurant_id_idx
  on public.media(restaurant_id);

create index if not exists media_visit_id_idx
  on public.media(visit_id);

-- MARK: - RLS Helpers

create or replace function public.is_circle_member(check_circle_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.circle_members cm
    where cm.circle_id = check_circle_id
      and cm.user_id = auth.uid()
  );
$$;

-- MARK: - Row Level Security

alter table public.profiles enable row level security;
alter table public.circles enable row level security;
alter table public.circle_members enable row level security;
alter table public.restaurants enable row level security;
alter table public.visits enable row level security;
alter table public.media enable row level security;

create policy "Users can read their own profile"
  on public.profiles for select
  using (id = auth.uid());

create policy "Users can insert their own profile"
  on public.profiles for insert
  with check (id = auth.uid());

create policy "Users can update their own profile"
  on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "Members can read circles"
  on public.circles for select
  using (
    created_by = auth.uid()
    or public.is_circle_member(circles.id)
  );

create policy "Authenticated users can create circles"
  on public.circles for insert
  with check (auth.uid() is not null);

create policy "Members can update circles"
  on public.circles for update
  using (
    created_by = auth.uid()
    or public.is_circle_member(circles.id)
  )
  with check (
    created_by = auth.uid()
    or public.is_circle_member(circles.id)
  );

create policy "Members can read circle memberships"
  on public.circle_members for select
  using (
    user_id = auth.uid()
    or public.is_circle_member(circle_members.circle_id)
  );

create policy "Users can add themselves to circles"
  on public.circle_members for insert
  with check (user_id = auth.uid());

create policy "Users can update their own membership"
  on public.circle_members for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Members can read restaurants"
  on public.restaurants for select
  using (public.is_circle_member(restaurants.circle_id));

create policy "Members can insert restaurants"
  on public.restaurants for insert
  with check (public.is_circle_member(restaurants.circle_id));

create policy "Members can update restaurants"
  on public.restaurants for update
  using (public.is_circle_member(restaurants.circle_id))
  with check (public.is_circle_member(restaurants.circle_id));

create policy "Members can delete restaurants"
  on public.restaurants for delete
  using (public.is_circle_member(restaurants.circle_id));

create policy "Members can read visits"
  on public.visits for select
  using (public.is_circle_member(visits.circle_id));

create policy "Members can insert visits"
  on public.visits for insert
  with check (
    user_id = auth.uid()
    and public.is_circle_member(visits.circle_id)
  );

create policy "Members can update visits"
  on public.visits for update
  using (public.is_circle_member(visits.circle_id))
  with check (public.is_circle_member(visits.circle_id));

create policy "Members can delete visits"
  on public.visits for delete
  using (public.is_circle_member(visits.circle_id));

create policy "Members can read media"
  on public.media for select
  using (public.is_circle_member(media.circle_id));

create policy "Members can insert media"
  on public.media for insert
  with check (
    user_id = auth.uid()
    and public.is_circle_member(media.circle_id)
  );

create policy "Members can update media"
  on public.media for update
  using (public.is_circle_member(media.circle_id))
  with check (public.is_circle_member(media.circle_id));

create policy "Members can delete media"
  on public.media for delete
  using (public.is_circle_member(media.circle_id));
