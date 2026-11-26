-- Journal supports photos and native iOS video. Preserve private access and every RLS policy.
-- Keep within the default project-wide 50 MiB Storage ceiling; client photos are capped at 10 MiB.
update storage.buckets
set file_size_limit = 52428800,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/heic', 'image/heif',
                               'video/mp4', 'video/quicktime', 'video/x-m4v']::text[]
where id = 'scout-media' and public = false;

-- Fail rather than silently succeeding against a missing or accidentally public bucket.
do $$
begin
    if not exists (select 1 from storage.buckets where id = 'scout-media' and public = false
                   and file_size_limit = 52428800) then
        raise exception 'Scout requires its existing private scout-media bucket';
    end if;
end $$;
