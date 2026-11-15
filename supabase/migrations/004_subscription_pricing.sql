-- Your OTT: editable subscription prices
-- Run once in Supabase SQL Editor for the Mumbai your-ott project.

create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);

alter table public.app_settings enable row level security;

drop policy if exists "Anyone can read public app settings" on public.app_settings;
create policy "Anyone can read public app settings"
  on public.app_settings for select
  to anon, authenticated
  using (key = 'subscription_prices');

drop policy if exists "Admins manage app settings" on public.app_settings;
create policy "Admins manage app settings"
  on public.app_settings for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

grant select on public.app_settings to anon, authenticated;
grant insert, update, delete on public.app_settings to authenticated;

insert into public.app_settings (key, value)
values (
  'subscription_prices',
  '{"Monthly":99,"Quarterly":249,"Half-Yearly":449,"Yearly":799}'::jsonb
)
on conflict (key) do nothing;
