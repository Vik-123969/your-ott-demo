# Your OTT Admin Panel (responsive)

Target: one responsive web app for desktop and mobile browsers.

## Selected backend
Supabase (Postgres + Auth + Storage + Row Level Security).

## Current repository deliverables
- `../supabase/migrations/001_initial_schema.sql`: initial schema and RLS policies.
- `../docs/PHASE_2B_ADMIN_PANEL_PLAN.md`: modules and acceptance criteria.

## Setup
1. Create a Supabase project.
2. Open SQL Editor and run `supabase/migrations/001_initial_schema.sql`.
3. Sign up the owner account through Supabase Auth.
4. In SQL Editor, promote only that account's profile to admin using its Auth user UUID:
   `update public.profiles set role = 'admin' where id = '<your-auth-user-uuid>';`
5. Configure Storage buckets and policies before enabling artwork uploads.
6. Build and deploy the responsive admin frontend with the Supabase project URL and public anon/publishable key as public client config.

Never put the Supabase service_role key or database password in Flutter, browser JavaScript, GitHub repository files, or chat.

## Not yet live
The schema is committed, but no Supabase project is connected, no admin account has been created, and no web admin URL is deployed yet.
