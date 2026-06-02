-- Recreate journal-media permissions for databases whose initial schema was
-- applied manually before migration history was repaired.

grant execute on function public.is_circle_member(uuid) to authenticated;
grant select, insert, update, delete on public.media to authenticated;

drop policy if exists "Members can read media" on public.media;
create policy "Members can read media"
  on public.media for select
  to authenticated
  using (public.is_circle_member(media.circle_id));

drop policy if exists "Members can insert media" on public.media;
create policy "Members can insert media"
  on public.media for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and public.is_circle_member(media.circle_id)
  );

drop policy if exists "Members can update media" on public.media;
create policy "Members can update media"
  on public.media for update
  to authenticated
  using (public.is_circle_member(media.circle_id))
  with check (public.is_circle_member(media.circle_id));

drop policy if exists "Members can delete media" on public.media;
create policy "Members can delete media"
  on public.media for delete
  to authenticated
  using (public.is_circle_member(media.circle_id));

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
