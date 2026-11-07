-- Your OTT Phase 3: customer streaming and subscription access
-- Run this once in the Supabase SQL Editor for the Mumbai "your-ott" project.
--
-- 1) Movies can now store the same private Storage object path as episodes.
alter table public.titles
  add column if not exists playback_asset_ref text;

create index if not exists titles_playback_asset_ref_idx
  on public.titles(playback_asset_ref)
  where playback_asset_ref is not null;

-- 2) Subscription records. Payments are not connected yet; an admin will
-- activate a test/customer subscription until a payment provider is added.
create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_name text not null default 'Monthly',
  status text not null default 'inactive'
    check (status in ('inactive','active','cancelled','expired')),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists subscriptions_user_status_idx
  on public.subscriptions(user_id, status, ends_at);

alter table public.subscriptions enable row level security;

grant select, insert, update, delete on public.subscriptions to authenticated;

drop policy if exists "Users read own subscriptions" on public.subscriptions;
create policy "Users read own subscriptions"
on public.subscriptions
for select
to authenticated
using (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists "Admins manage subscriptions" on public.subscriptions;
create policy "Admins manage subscriptions"
on public.subscriptions
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- 3) Admin accounts can preview uploaded content. Customers need an active
-- subscription before Storage will issue signed URLs for published videos.
create or replace function public.has_active_subscription()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_admin() or exists (
    select 1
    from public.subscriptions s
    where s.user_id = (select auth.uid())
      and s.status = 'active'
      and s.starts_at <= now()
      and (s.ends_at is null or s.ends_at > now())
  );
$$;

grant execute on function public.has_active_subscription() to authenticated;

drop policy if exists "Active subscribers read published videos" on storage.objects;
create policy "Active subscribers read published videos"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'ott-videos'
  and public.has_active_subscription()
  and (
    exists (
      select 1
      from public.episodes e
      join public.seasons s on s.id = e.season_id
      join public.titles t on t.id = s.title_id
      where e.playback_asset_ref = storage.objects.name
        and e.status = 'published'
        and t.status = 'published'
    )
    or exists (
      select 1
      from public.titles t
      where t.playback_asset_ref = storage.objects.name
        and t.status = 'published'
    )
  )
);

-- The app reads the public catalogue using the anon/publishable client key.
-- Published-title/season/episode RLS policies already exist in Phase 2B.
