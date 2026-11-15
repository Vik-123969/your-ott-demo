-- Your OTT subscription access foundation
-- Run in Supabase SQL Editor on the Mumbai (your-ott) project.
-- Safe to re-run. This does not collect or verify payments.

create extension if not exists pgcrypto;

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  plan_name text not null check (plan_name in ('Monthly','Quarterly','Yearly','Lifetime')),
  status text not null default 'active' check (status in ('active','cancelled','expired')),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint subscriptions_valid_period check (ends_at is null or ends_at > starts_at)
);

create index if not exists subscriptions_user_status_period_idx
  on public.subscriptions(user_id, status, starts_at, ends_at);

alter table public.subscriptions enable row level security;

drop policy if exists "Users read own subscriptions" on public.subscriptions;
create policy "Users read own subscriptions"
  on public.subscriptions for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists "Admins manage subscriptions" on public.subscriptions;
create policy "Admins manage subscriptions"
  on public.subscriptions for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant select on table public.subscriptions to authenticated;
grant insert, update, delete on table public.subscriptions to authenticated;

create or replace function public.has_active_subscription()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    (select auth.uid()) is not null
    and exists (
      select 1
      from public.subscriptions s
      where s.user_id = (select auth.uid())
        and s.status = 'active'
        and s.starts_at <= now()
        and (s.ends_at is null or s.ends_at > now())
    );
$$;

grant execute on function public.has_active_subscription() to authenticated;

-- Ensure uploaded videos remain private.
update storage.buckets
set public = false
where id = 'ott-videos';

-- Only admins and customers with a currently active subscription may read
-- objects from the private OTT video bucket. Admin upload/manage permissions
-- are handled by the separate admin Storage policy.
drop policy if exists "Active subscribers read published videos" on storage.objects;
create policy "Active subscribers read published videos"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'ott-videos'
    and (public.is_admin() or public.has_active_subscription())
  );
