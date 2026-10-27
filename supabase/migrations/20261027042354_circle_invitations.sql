-- Bearer invitations: only a SHA-256 hash is stored; the code is returned once.
create table public.circle_invitations (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null unique references public.circles(id) on delete cascade,
  token_hash text not null unique check (token_hash ~ '^[0-9a-f]{64}$'),
  created_by uuid not null references auth.users(id) on delete cascade,
  expires_at timestamptz not null
);
create index circle_invitations_created_by_idx on public.circle_invitations(created_by);
alter table public.circle_invitations enable row level security;
revoke all on public.circle_invitations from public, anon, authenticated;
create policy "Invitations are RPC only" on public.circle_invitations
  for all to authenticated using (false) with check (false);
create schema if not exists scout_private;
revoke all on schema scout_private from public, anon;
grant usage on schema scout_private to authenticated;

create function scout_private.circle_invite(
  p_action text, p_circle_id uuid, p_code text, p_invite_id uuid, p_initials text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  target uuid;
  invitation public.circle_invitations%rowtype;
  circle_name text;
  code text;
  active boolean;
begin
  if uid is null then raise exception 'Sign in to use circle invitations' using errcode='42501'; end if;
  if p_action is null or p_action not in ('status','create','revoke','preview','join') then
    raise exception 'Invalid invitation action' using errcode='22023';
  end if;
  if p_action in ('preview','join') then
    if p_code is null or p_code !~ '^[0-9a-fA-F]{32}$' then
      raise exception 'This invitation is invalid, expired, or no longer available.' using errcode='22023';
    end if;
    select circle_id into target from public.circle_invitations
      where token_hash=encode(extensions.digest(lower(p_code),'sha256'),'hex');
    if target is null or (p_circle_id is not null and p_circle_id <> target) then
      raise exception 'This invitation is invalid, expired, or no longer available.' using errcode='22023';
    end if;
  else
    target := p_circle_id;
  end if;
  -- The shared-pick RPC uses the same lock: joining cannot race a vote/membership snapshot.
  perform pg_advisory_xact_lock(hashtextextended(target::text,0));
  if p_action in ('status','create','revoke') and not public.is_circle_member(target) then
    raise exception 'Circle membership required' using errcode='42501';
  end if;
  select * into invitation from public.circle_invitations where circle_id=target for update;
  active := invitation.id is not null and invitation.expires_at > now() and exists (
    select 1 from public.circle_members where circle_id=target and user_id=invitation.created_by
  );
  select name into circle_name from public.circles where id=target;
  if p_action in ('preview','join') then
    -- Recheck after acquiring the lock: replacement/revocation may have invalidated the lookup.
    if not active or invitation.token_hash <> encode(extensions.digest(lower(p_code),'sha256'),'hex') then
      raise exception 'This invitation is invalid, expired, or no longer available.' using errcode='22023';
    end if;
    if p_action='join' then
      insert into public.circle_members(circle_id,user_id,initials)
        values (target,uid,left(upper(coalesce(nullif(btrim(p_initials),''),'?')),2))
        on conflict (circle_id,user_id) do nothing;
    end if;
    return jsonb_build_object('circle_id',target,'circle_name',circle_name,'expires_at',invitation.expires_at,
      'is_member',exists(select 1 from public.circle_members where circle_id=target and user_id=uid));
  elsif p_action='create' then
    if active and invitation.id is distinct from p_invite_id then
      raise exception 'The invitation changed. Refresh and try again.' using errcode='PT409';
    end if;
    code := encode(extensions.gen_random_bytes(16),'hex');
    insert into public.circle_invitations(circle_id,token_hash,created_by,expires_at)
      values (target,encode(extensions.digest(code,'sha256'),'hex'),uid,now()+interval '7 days')
      on conflict(circle_id) do update set id=gen_random_uuid(),token_hash=excluded.token_hash,
        created_by=excluded.created_by,expires_at=excluded.expires_at returning * into invitation;
    active := true;
  elsif p_action='revoke' then
    if invitation.id is not null and invitation.id is distinct from p_invite_id then
      raise exception 'The invitation changed. Refresh and try again.' using errcode='PT409';
    end if;
    delete from public.circle_invitations where circle_id=target;
    active := false;
  end if;
  return jsonb_build_object('id',case when active then invitation.id else null end,
    'circle_id',target,'circle_name',circle_name,'is_active',active,
    'expires_at',case when active then invitation.expires_at else null end,'code',code);
end;
$$;
revoke all on function scout_private.circle_invite(text,uuid,text,uuid,text) from public, anon;
grant execute on function scout_private.circle_invite(text,uuid,text,uuid,text) to authenticated;
create function public.scout_circle_invite(p_action text, p_circle_id uuid default null,
  p_code text default null, p_invite_id uuid default null, p_initials text default '?')
returns jsonb language sql security invoker set search_path='' as $$
  select scout_private.circle_invite(p_action,p_circle_id,p_code,p_invite_id,p_initials);
$$;
revoke all on function public.scout_circle_invite(text,uuid,text,uuid,text) from public, anon;
grant execute on function public.scout_circle_invite(text,uuid,text,uuid,text) to authenticated;

-- Load real membership avatars in the same request as circles. Keep the legacy RPC for old apps.
create function scout_private.my_circles() returns jsonb language sql stable security definer set search_path='' as $$
  select coalesce(jsonb_agg(to_jsonb(c) || jsonb_build_object('circle_members',(
    select coalesce(jsonb_agg(to_jsonb(m) order by m.user_id),'[]'::jsonb)
    from public.circle_members m where m.circle_id=c.id
  )) order by c.created_at desc,c.id),'[]'::jsonb)
  from public.circles c where auth.uid() is not null and public.is_circle_member(c.id);
$$;
revoke all on function scout_private.my_circles() from public, anon;
grant execute on function scout_private.my_circles() to authenticated;
create function public.scout_my_circles() returns jsonb language sql stable security invoker set search_path='' as $$
  select scout_private.my_circles();
$$;
revoke all on function public.scout_my_circles() from public, anon;
grant execute on function public.scout_my_circles() to authenticated;
