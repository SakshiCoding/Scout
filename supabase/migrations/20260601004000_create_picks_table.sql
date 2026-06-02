-- One pick per circle per day, shared across all circle members.
-- Upsert on (circle_id, picked_date) so re-confirming the same day is idempotent.

create table if not exists public.picks (
  id            uuid        primary key default gen_random_uuid(),
  circle_id     uuid        not null references public.circles(id) on delete cascade,
  restaurant_id uuid        not null references public.restaurants(id) on delete cascade,
  picked_date   date        not null default current_date,
  created_by    uuid        references auth.users(id) on delete set null,
  created_at    timestamptz not null default now(),
  constraint picks_circle_date_unique unique (circle_id, picked_date)
);

alter table public.picks enable row level security;

create policy "Circle members can view picks"
  on public.picks for select
  using (is_circle_member(circle_id));

create policy "Circle members can insert picks"
  on public.picks for insert
  with check (is_circle_member(circle_id));

create policy "Circle members can update picks"
  on public.picks for update
  using (is_circle_member(circle_id));
