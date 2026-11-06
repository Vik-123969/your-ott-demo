# Your OTT Admin Panel

A responsive, premium-dark web admin panel for desktop and mobile browsers.

## Current implementation

- `index.html`: working static admin frontend.
- Supabase email/password sign-in.
- Checks `public.profiles.role = 'admin'` before showing the dashboard.
- Dashboard counts for titles, published items, drafts and series.
- Catalogue CRUD for movies and series: create, edit, delete, search, filter, draft/publish/archive.
- Metadata fields: title, slug, language, year, maturity rating, genres, duration, poster URL and synopsis.
- Responsive layout for desktop, tablet and mobile.

## Connect it to your Supabase project

1. Open `index.html` in a browser after hosting it (or use a local static server).
2. Enter the Supabase **Project URL** and **public anon/publishable key** in the connection form.
3. Sign in with the admin email/password you created in Supabase Auth.
4. The panel verifies the signed-in user's role in `public.profiles`. Only `admin` accounts can enter.

The public anon/publishable key is designed for browser use. Never put a Supabase `service_role` key, secret key, or database password in this page, GitHub, or chat.

## Supabase requirements

Run `../supabase/migrations/001_initial_schema.sql` in the Mumbai project's SQL Editor. The migration creates the tables, RLS policies and a trigger that creates a viewer profile on signup. The owner account was promoted separately to admin.

## Hosting

This is a static site and can be hosted on GitHub Pages, Netlify or another HTTPS static host. For GitHub Pages, configure the repository's Pages setting to deploy from GitHub Actions or a branch, with `admin/` as the site root (or copy this file to the chosen site root). Do not publish any secret keys.

## Not implemented yet

- Artwork file upload / private media storage.
- Season and episode CRUD screens.
- User administration / subscription management.
- Video ingest, transcoding, HLS playback and payment processing.
- Production-grade audit log and operational monitoring.

The admin frontend is committed but not yet deployed to a public admin URL. Catalogue CRUD becomes active after you enter the Supabase project URL/public key and sign in as the verified admin.
