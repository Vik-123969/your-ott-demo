# Your OTT — Phase 2 Development Plan

## Product decision
Catalog scope: all-language Movies and Web Series.
- Languages: Hindi, English, Tamil, Telugu, Malayalam, Kannada, Bengali, Marathi, Punjabi, Bhojpuri and other regional languages.
- Browse dimensions: Movies / Series, language, genre, year, popularity and newly added.
- UI language and audio/subtitle language are separate metadata fields.
- Phase 2 uses clearly labelled sample/demo records until the owner supplies licensed catalogue metadata and artwork.

## Phase 2 goal
Move from a local UI demo to a data-driven OTT MVP foundation. Do not claim real streaming until a licensed video source, backend and playback integration are configured.

## Milestones

### 2A — Catalogue experience
1. Content types: movie and series.
2. Search by title, cast, director and genre.
3. Filters: language, genre, release year and content type.
4. Detail pages: synopsis, poster, backdrop, runtime/season count, maturity rating, audio languages and subtitle languages.
5. Series structure: seasons and episodes.
6. Continue Watching and My List persisted per user after backend is connected.
7. Empty/loading/error states and retry controls.

### 2B — Backend and identity
Recommended MVP pattern:
- Flutter Android/iOS client.
- Managed backend (Supabase or Firebase) for authentication, database and user-specific data.
- Admin web panel for catalogue metadata and publishing workflow.
- Object storage for poster/backdrop artwork.
- Keep secrets and privileged keys on the server; never embed admin/service-role keys in the mobile app.

Backend entities:
- profiles
- titles
- seasons
- episodes
- genres
- languages
- title_genres
- title_languages
- watchlist
- watch_progress
- playback_entitlements

### 2C — Licensed video playback
1. Only ingest videos the operator owns or has written streaming rights to distribute.
2. Store video assets with a managed video provider or secured origin/CDN.
3. Deliver adaptive HLS playback URLs via a backend playback endpoint.
4. Validate user entitlement before issuing playback access.
5. Add subtitles, audio tracks, resume position, playback error handling and analytics.
6. Add DRM only when required by content licensors and supported by the chosen provider.

### 2D — Payments and release readiness
- Decide subscription vs free/ad-supported model.
- Add Indian payment gateway and server-side payment verification only after pricing and business entity details are known.
- Add privacy policy, terms, content takedown contact, age ratings and support contact.
- Test on real Android devices, slow networks and different screen sizes.
- Prepare signed production release and Play Store listing.

## Suggested data contract
A title record should contain:
- id, slug, title, synopsis
- content_type: movie | series
- original_language
- available_audio_languages[]
- available_subtitle_languages[]
- genres[]
- release_year, maturity_rating
- poster_url, backdrop_url, trailer_url
- status: draft | published | archived
- for movies: duration_seconds
- for series: seasons[] with episode metadata

An episode record should contain:
- id, season_id, episode_number, title, synopsis, duration_seconds
- published status and licensed playback asset reference (not a public raw origin URL)

## Security and rights checklist
- Never scrape or rebroadcast another OTT platform's catalogue or streams.
- Obtain written rights for each title, territory, language, platform and term.
- Do not put private playback origins, signing secrets or admin keys in the APK.
- Playback URLs should be short-lived and issued by the backend after entitlement checks.
- Collect only necessary user data and provide account deletion/support routes.

## Out of scope for Phase 2
- Aggregating subscriptions or embedding Netflix/Prime/Hotstar content inside Your OTT without a distribution agreement.
- Unlicensed live TV or sports streams.
- Production payments before business, pricing and refund policy are confirmed.

## Acceptance criteria
- User can browse all supported languages and genres.
- Search and filters work on the catalogue API.
- Movie and series detail pages render the same content contract.
- Series seasons/episodes are represented correctly.
- Watchlist and playback progress are tied to a signed-in user.
- Playback is enabled only for test media or properly licensed content.
- No secret keys or unlicensed media are bundled in the APK.
