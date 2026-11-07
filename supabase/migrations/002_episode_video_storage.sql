-- Your OTT Phase 2C: private episode video storage policies
--
-- FIRST create the bucket in Supabase Dashboard:
-- Storage -> New bucket
-- Name / bucket ID: ott-videos
-- Public bucket: OFF (private)
-- File size limit: 50 MB (Free plan maximum)
-- Allowed MIME types: video/mp4, video/webm
--
-- Then run this SQL once in the NEW Mumbai project.
-- These policies only allow signed-in admins to upload, preview/download,
-- replace, and delete episode video objects. Viewer playback access is not
-- granted by this migration; that needs a separate entitlement-aware server
-- or Edge Function before the consumer app can stream paid content.

drop policy if exists "OTT admins manage episode videos" on storage.objects;

create policy "OTT admins manage episode videos"
on storage.objects
for all
to authenticated
using (
  bucket_id = 'ott-videos'
  and public.is_admin()
)
with check (
  bucket_id = 'ott-videos'
  and public.is_admin()
);
