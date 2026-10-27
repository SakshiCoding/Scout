-- Stale rounds are an application conflict, not a retryable serialization failure.
-- SQLSTATE 40001 can make hosted PostgREST retry forever; PT409 returns immediately.
create or replace function scout_private.pick_action(
  p_circle_id uuid, p_action text, p_session_id uuid, p_restaurant_id uuid, p_yes boolean, p_window integer
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  s public.pick_sessions%rowtype;
  members uuid[];
  deck uuid[];
  new_id uuid := gen_random_uuid();
  today date := (now() at time zone 'UTC')::date;
  own_count integer;
  old_vote boolean;
  all_done boolean;
  winner uuid;
begin
  if auth.uid() is null or not public.is_circle_member(p_circle_id) then
    raise exception 'Circle membership required' using errcode = '42501';
  end if;
  if p_action not in ('sync', 'vote', 'undo', 'reset') or p_action is null
     or p_window is null or p_window not between 0 and 2 then
    raise exception 'Invalid pick action' using errcode = '22023';
  end if;
  -- Covers first-create races as well as all votes, undo, and rematches in this circle.
  perform pg_advisory_xact_lock(hashtextextended(p_circle_id::text, 0));
  select array_agg(user_id order by user_id) into members from public.circle_members where circle_id = p_circle_id;
  if members is null or not (auth.uid() = any(members)) then
    raise exception 'Circle membership required' using errcode = '42501';
  end if;
  select * into s from public.pick_sessions where circle_id = p_circle_id for update;
  all_done := s.id is not null and cardinality(s.restaurant_ids) > 0 and
    (select count(*) from public.pick_votes where session_id = s.id) = cardinality(s.member_ids) * cardinality(s.restaurant_ids);
  if p_action = 'reset' and s.id = p_session_id and s.matched_restaurant_id is null and not all_done then
    raise exception 'Wait for everyone to finish before starting a new round' using errcode = '22023';
  end if;
  if s.id is null or s.session_day <> today or s.member_ids <> members
     or (select count(*) from public.restaurants r where r.id = any(s.restaurant_ids)
         and r.circle_id = p_circle_id and r.status = 'want_to_try') <> cardinality(s.restaurant_ids)
     or (cardinality(s.restaurant_ids) = 0 and exists (select 1 from public.restaurants where circle_id = p_circle_id and status = 'want_to_try'))
     or (p_action = 'reset' and s.id = p_session_id) then
    select array_agg(id order by rank) into deck from (
      select id, row_number() over (order by md5(id::text || new_id::text)) as rank
      from public.restaurants where circle_id = p_circle_id and status = 'want_to_try'
        and (p_window = 1 or (p_window = 0 and establishment_type in ('restaurant','cafe','bakery','other'))
             or (p_window = 2 and establishment_type in ('restaurant','bar','brewery','winery','other')))
      order by rank limit 3
    ) candidates;
    if deck is null then
      select array_agg(id order by rank) into deck from (
        select id, row_number() over (order by md5(id::text || new_id::text)) as rank
        from public.restaurants where circle_id = p_circle_id and status = 'want_to_try' order by rank limit 3
      ) fallback;
    end if;
    if s.id is not null then delete from public.pick_votes where session_id = s.id; end if;
    insert into public.pick_sessions (id, circle_id, session_day, time_window, restaurant_ids, member_ids)
      values (new_id, p_circle_id, today, p_window, coalesce(deck, '{}'::uuid[]), members)
    on conflict (circle_id) do update set id = excluded.id, session_day = excluded.session_day,
      time_window = excluded.time_window, restaurant_ids = excluded.restaurant_ids, member_ids = excluded.member_ids,
      matched_restaurant_id = null, revision = public.pick_sessions.revision + 1
    returning * into s;
  end if;
  if p_action in ('vote','undo') then
    if p_session_id is distinct from s.id then
      raise exception 'This round changed. Refresh and try again.' using errcode = 'PT409';
    end if;
    if cardinality(s.member_ids) < 2 then
      raise exception 'At least two circle members are needed to match' using errcode = '22023';
    end if;
    select count(*) into own_count from public.pick_votes where session_id = s.id and user_id = auth.uid();
    select is_yes into old_vote from public.pick_votes where session_id = s.id and user_id = auth.uid() and restaurant_id = p_restaurant_id;
    -- Retried identical requests are safe, including a retry after the winning response was lost.
    if p_action = 'vote' and old_vote is not null and old_vote = p_yes then
      null;
    elsif s.matched_restaurant_id is not null then
      raise exception 'This round has matched. Start a new round to pick again.' using errcode = '22023';
    elsif p_action = 'vote' then
      if p_yes is null or p_restaurant_id is null or p_restaurant_id is distinct from s.restaurant_ids[own_count + 1] then
        raise exception 'Vote on the next card in this round' using errcode = '22023';
      end if;
      insert into public.pick_votes values (s.id, auth.uid(), p_restaurant_id, p_yes);
      update public.pick_sessions set revision = revision + 1 where id = s.id returning * into s;
    elsif p_action = 'undo' then
      if own_count = 0 or p_restaurant_id is distinct from s.restaurant_ids[own_count] then
        raise exception 'Only your most recent vote can be undone' using errcode = '22023';
      end if;
      delete from public.pick_votes where session_id = s.id and user_id = auth.uid() and restaurant_id = p_restaurant_id;
      update public.pick_sessions set revision = revision + 1 where id = s.id returning * into s;
    end if;
    select r.id into winner from unnest(s.restaurant_ids) with ordinality r(id, position)
    where (select count(*) from public.pick_votes v where v.session_id = s.id and v.restaurant_id = r.id
           and v.is_yes and v.user_id = any(s.member_ids)) = cardinality(s.member_ids)
    order by r.position limit 1;
    if winner is not null and s.matched_restaurant_id is null then
      update public.pick_sessions set matched_restaurant_id = winner, revision = revision + 1 where id = s.id returning * into s;
    end if;
  end if;
  return to_jsonb(s) || jsonb_build_object('restaurants', coalesce((
    select jsonb_agg(to_jsonb(r)) from public.restaurants r where r.id = any(s.restaurant_ids) and r.circle_id = s.circle_id
  ), '[]'::jsonb), 'votes', coalesce((
    select jsonb_agg(to_jsonb(v) order by v.user_id, v.restaurant_id) from public.pick_votes v where v.session_id = s.id
  ), '[]'::jsonb));
end;
$$;
