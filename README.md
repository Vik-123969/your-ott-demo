# Your OTT

Your OTT is a Flutter Android streaming-catalogue app connected to Supabase.

## Current features
- Home, Movies, Series, search and language/genre filters
- Published catalogue loaded from Supabase
- Title details, seasons and episode metadata
- Private video upload and playback flow for configured licensed media
- Email/password account creation and sign-in
- Per-user My List / watchlist
- Dark theme and bottom navigation

## Build Android APK
GitHub Actions builds a release APK on every push to `main` and on manual dispatch.

1. Open the repository's Actions tab.
2. Open the latest successful **Build Your OTT Android Demo APK** run.
3. Download the `your-ott-android-demo-apk` artifact.
4. Extract the ZIP and install `app-release.apk` on Android.

## Authentication
The app currently uses Supabase email/password authentication only. Phone OTP is not enabled in the app. New users may need to confirm their email, depending on the Supabase Authentication email-confirmation setting.

## Important production requirements
This project is still under development and is not yet a complete commercial OTT service. Before public launch, configure licensed content rights, production video transcoding/HLS, CDN delivery, subscription/payment verification, security review, monitoring, customer support and applicable legal/privacy requirements. Never put a Supabase service-role key in the mobile app.


## Subscription access (manual admin activation)
- SQL migration: `supabase/migrations/003_subscriptions_access.sql`
- Run this migration in the Supabase SQL Editor for the Mumbai `your-ott` project.
- Admin Studio has a Subscriptions page to activate Monthly, Quarterly, Yearly or Lifetime access for an existing viewer, and cancel/reactivate records.
- The Android Profile page displays the signed-in customer's active plan and expiry.
- The `ott-videos` bucket is private; video reads require an admin account or an active subscription.
- This is manual activation only. No payment gateway or automatic renewal is connected yet.
