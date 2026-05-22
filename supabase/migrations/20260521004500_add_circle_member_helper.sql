-- Helper used by RLS policies and RPC functions to check circle membership.
-- Some existing databases may not have this function if the initial migration
-- was run after the tables already existed.

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

grant execute on function public.is_circle_member(uuid) to authenticated;
