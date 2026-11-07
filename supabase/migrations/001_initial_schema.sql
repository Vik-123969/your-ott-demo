-- Your OTT Phase 2B: initial schema
-- Run once in the Supabase SQL Editor for the NEW Mumbai project.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'viewer' check (role in ('viewer','admin')),
  created_at timestamptz not null default now()
);

-- Automatically create a viewer profile whenever a user signs up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', new.email))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create table if not exists public.titles (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  synopsis text not null default '',
  content_type text not null check (content_type in ('movie','series')),
  original_language text not null,
  available_audio_languages text[] not null default '{}',
  available_subtitle_languages text[] not null default '{}',
  genres text[] not null default '{}',
  release_year integer,
  maturity_rating text,
  poster_path text,
  backdrop_path text,
  status text not null default 'draft' check (status in ('draft','published','archived')),
  duration_seconds integer,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint movie_duration_check check (content_type <> 'movie' or duration_seconds is null or duration_seconds > 0)
);

create table if not exists public.seasons (
  id uuid primary key default gen_random_uuid(),
  title_id uuid not null references public.titles(id) on delete cascade,
  season_number integer not null check (season_number > 0),
  title text,
  unique(title_id, season_number)
);

create table if not exists public.episodes (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons(id) on delete cascade,
  episode_number integer not null check (episode_number > 0),
  title text not null,
  synopsis text not null default '',
  duration_seconds integer,
  playback_asset_ref text,
  status text not null default 'draft' check (status in ('draft','published')),
  unique(season_id, episode_number)
);

create table if not exists public.watchlist (
  user_id uuid not null references auth.users(id) on delete cascade,
  title_id uuid not null references public.titles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id, title_id)
);

create table if not exists public.watch_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title_id uuid not null references public.titles(id) on delete cascade,
  episode_id uuid references public.episodes(id) on delete cascade,
  position_seconds integer not null default 0 check(position_seconds >= 0),
  duration_seconds integer check(duration_seconds is null or duration_seconds > 0),
  updated_at timestamptz not null default now()
);
create index if not exists watch_progress_user_updated_idx
on public.watch_progress(user_id, updated_at desc);

create or replace function public.is_admin()
returns boolean language sql stable security definer
set search_path = ''
as $$
  select exists(
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  );
$$;

alter table public.profiles enable row level security;
alter table public.titles enable row level security;
alter table public.seasons enable row level security;
alter table public.episodes enable row level security;
alter table public.watchlist enable row level security;
alter table public.watch_progress enable row level security;

drop policy if exists "Users read own profile" on public.profiles;
create policy "Users read own profile" on public.profiles for select to authenticated
using (id = (select auth.uid()) or public.is_admin());

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles for update to authenticated
using (id = (select auth.uid())) with check (id = (select auth.uid()) and role = 'viewer');

drop policy if exists "Admins manage profiles" on public.profiles;
create policy "Admins manage profiles" on public.profiles for all to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Anyone reads published titles" on public.titles;
create policy "Anyone reads published titles" on public.titles for select
using (status = 'published' or public.is_admin());

drop policy if exists "Admins manage titles" on public.titles;
create policy "Admins manage titles" on public.titles for all to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Published seasons readable" on public.seasons;
create policy "Published seasons readable" on public.seasons for select
using (public.is_admin() or exists(
  select 1 from public.titles t where t.id = title_id and t.status = 'published'
));

drop policy if exists "Admins manage seasons" on public.seasons;
create policy "Admins manage seasons" on public.seasons for all to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Published episodes readable" on public.episodes;
create policy "Published episodes readable" on public.episodes for select
using (public.is_admin() or (status = 'published' and exists(
  select 1 from public.seasons s join public.titles t on t.id = s.title_id
  where s.id = season_id and t.status = 'published'
)));

drop policy if exists "Admins manage episodes" on public.episodes;
create policy "Admins manage episodes" on public.episodes for all to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Users manage own watchlist" on public.watchlist;
create policy "Users manage own watchlist" on public.watchlist for all to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "Users manage own progress" on public.watch_progress;
create policy "Users manage own progress" on public.watch_progress for all to authenticated
using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- After signing up to the app, promote the first trusted owner account:
-- update public.profiles set role = 'admin' where id = '<AUTH_USER_UUID>';
-- Run that one statement manually as the project owner. Never expose service_role keys.
-- Explicit Data API grants. RLS policies above continue to restrict rows.
grant usage on schema public to anon, authenticated;
grant select on table public.profiles to authenticated;
grant select on table public.titles to anon, authenticated;
grant insert, update, delete on table public.titles to authenticated;
grant select, insert, update, delete on table public.seasons to authenticated;
grant select, insert, update, delete on table public.episodes to authenticated;
grant select, insert, update, delete on table public.watchlist to authenticated;
grant select, insert, update, delete on table public.watch_progress to authenticated;
grant execute on function public.is_admin() to authenticated;
