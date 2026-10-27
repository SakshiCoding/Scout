-- Evaluate the caller identity once per statement instead of once per session row.
alter policy "Members read shared pick sessions" on public.pick_sessions
  using ((select auth.uid()) is not null and public.is_circle_member(circle_id));
