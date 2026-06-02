-- Keep journal photos private to members of the circle in their storage path.

insert into storage.buckets (id, name, public)
values ('scout-media', 'scout-media', false)
on conflict (id) do update set public = excluded.public;

drop policy if exists "Circle members can read scout media" on storage.objects;
create policy "Circle members can read scout media"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'scout-media'
    and (storage.foldername(name))[1] = 'circles'
    and public.is_circle_member(((storage.foldername(name))[2])::uuid)
  );

drop policy if exists "Circle members can upload scout media" on storage.objects;
create policy "Circle members can upload scout media"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'scout-media'
    and (storage.foldername(name))[1] = 'circles'
    and public.is_circle_member(((storage.foldername(name))[2])::uuid)
  );

drop policy if exists "Circle members can delete scout media" on storage.objects;
create policy "Circle members can delete scout media"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'scout-media'
    and (storage.foldername(name))[1] = 'circles'
    and public.is_circle_member(((storage.foldername(name))[2])::uuid)
  );
