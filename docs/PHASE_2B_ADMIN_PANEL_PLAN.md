# Your OTT — Phase 2B Admin Panel Plan

## Confirmed product requirement
The admin panel must work on both:
- Desktop/laptop browsers
- Mobile browsers with responsive touch-friendly layouts

## Recommended delivery
Build a responsive web admin panel (not a desktop-only app), so one secure panel works on Windows/macOS/Linux and Android/iPhone browsers. The viewer-facing Flutter app remains a separate client.

## Admin modules
1. Secure admin sign-in and sign-out
2. Dashboard summary: published titles, drafts, movies, series
3. Catalogue manager: create, edit, preview, publish/unpublish, archive
4. Artwork manager: poster and backdrop uploads
5. Metadata: title, synopsis, content type, language, audio/subtitle languages, genres, year, maturity rating
6. Series manager: seasons and episodes
7. User management (minimal account status and support actions; no password viewing)
8. Audit log for admin publishing changes

## Responsive UX requirements
- Desktop: sidebar navigation, searchable data table, multi-column edit forms
- Mobile: compact top navigation, stacked cards, large touch targets, single-column forms
- Confirm before destructive actions
- Show loading, empty, validation and error states
- Accessible labels and keyboard navigation

## Security requirements
- Admin routes must require authenticated admin role.
- Never trust a role value supplied only by the client.
- Enforce permissions in backend row-level security / server rules.
- Never bundle service-role keys or private API secrets in Flutter or web builds.
- Upload media to private storage; publish only approved records.
- Keep playback asset references server-side; do not expose raw origin credentials.

## Suggested backend
Supabase is the recommended MVP backend because it provides Postgres, Auth, Storage and Row Level Security. The admin web panel and Flutter app can share the same backend.
Firebase is a valid alternative if the owner already uses it.

## Needed before connecting live backend
Create a Supabase project and provide only the project URL and public anon/publishable key. Never send service_role keys, database passwords or secret keys in chat. Admin user provisioning and policies must be performed securely.

## Acceptance criteria
- Admin can sign in from desktop and mobile browser.
- Non-admin users cannot access admin data or mutations.
- Admin can create/edit/publish a movie and a series with seasons/episodes.
- Poster/backdrop uploads work on desktop and mobile.
- Flutter app can read published catalogue records only.
- Watchlist and progress are scoped to the signed-in viewer.
