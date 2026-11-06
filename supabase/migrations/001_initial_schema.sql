-- Your OTT Phase 2B: initial schema
-- Run in Supabase SQL Editor. Enable RLS on every user-facing table.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'viewer' check (role in ('viewer','admin')),
  created_at timestamptz not null default now()
);

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
  user_id uuid not null references auth.users(id) on delete cascade,
  title_id uuid not null references public.titles(id) on delete cascade,
  episode_id uuid references public.episodes(id) on delete cascade,
  position_seconds integer not null default 0 check(position_seconds >= 0),
  duration_seconds integer check(duration_seconds is null or duration_seconds > 0),
  updated_at timestamptz not null default now(),
  primary key(user_id, title_id, episode_id)
);

create or replace function public.is_admin()
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists(select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin');
$$;

alter table public.profiles enable row level security;
alter table public.titles enable row level security;
alter table public.seasons enable row level security;
alter table public.episodes enable row level security;
alter table public.watchlist enable row level security;
alter table public.watch_progress enable row level security;

create policy "Users read own profile" on public.profiles for select to authenticated using (id = auth.uid() or public.is_admin());
create policy "Users update own profile" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid() and role = 'viewer');
create policy "Admins manage profiles" on public.profiles for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Anyone reads published titles" on public.titles for select using (status = 'published' or public.is_admin());
create policy "Admins manage titles" on public.titles for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Published seasons readable" on public.seasons for select using (
  public.is_admin() or exists(select 1 from public.titles t where t.id = title_id and t.status = 'published')
);
create policy "Admins manage seasons" on public.seasons for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Published episodes readable" on public.episodes for select using (
  public.is_admin() or (status = 'published' and exists(
    select 1 from public.seasons s join public.titles t on t.id = s.title_id
    where s.id = season_id and t.status = 'published'
  ))
);
create policy "Admins manage episodes" on public.episodes for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy "Users manage own watchlist" on public.watchlist for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users manage own progress" on public.watch_progress for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- IMPORTANT: Create the first admin securely after signing up:
-- update public.profiles set role = 'admin' where id = '<auth-user-uuid>';
-- Run that statement manually in the SQL editor as project owner. Never expose service_role keys in clients.
