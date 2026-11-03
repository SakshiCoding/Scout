-- Legacy permissive bucket-wide policies are ORed with the app's member policies.
-- A restrictive guard keeps Scout private even when those dashboard policies exist,
-- while leaving every other bucket's existing access rules unchanged.
drop policy if exists "Scout media requires current circle membership" on storage.objects;
create policy "Scout media requires current circle membership"
on storage.objects as restrictive
for all to public
using (
  case
    when bucket_id is distinct from 'scout-media' then true
    when (storage.foldername(name))[1] = 'circles'
      and (storage.foldername(name))[2] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then public.is_circle_member(((storage.foldername(name))[2])::uuid)
    else false
  end
)
with check (
  case
    when bucket_id is distinct from 'scout-media' then true
    when (storage.foldername(name))[1] = 'circles'
      and (storage.foldername(name))[2] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then public.is_circle_member(((storage.foldername(name))[2])::uuid)
    else false
  end
);
