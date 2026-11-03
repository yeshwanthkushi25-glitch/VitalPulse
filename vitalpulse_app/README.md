# VitalPulse

Flutter health and nutrition tracker with Supabase Auth and a user-isolated Postgres backend. The app targets Android, iOS, web, and Windows.

## Configure Supabase

1. Create a Supabase project and keep its service-role key private. The Flutter app uses only the project's public/anon key; row-level security is required for safety.
2. Apply the schema from the repository root:

   ```powershell
   npx supabase login
   npx supabase link --project-ref YOUR_PROJECT_REF
   npx supabase db push
   ```

3. In Supabase Auth settings, set the site's allowed redirect URLs for the platforms you deploy. Enable email confirmation and configure SMTP before inviting real users.
4. Run the app from this directory, supplying values locally (do not commit them):

   ```powershell
   flutter run -d chrome --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
   ```

   For production builds, provide the same two public configuration values through your deployment pipeline. Never pass a service-role or database password to a client build.

## Features

- Email/password registration and sign-in using Supabase Auth.
- Per-user profile, nutrition, and daily health records protected by row-level security.
- Food entry creation and deletion; steps, water, and sleep tracking.
- Photo meal scanning through an authenticated Supabase Edge Function; the user reviews each estimate before saving. Images are sent to the configured AI provider and aren't saved by VitalPulse.
- Optional, read-only Apple Health / Health Connect sync for steps, heart rate, and sleep. Device permissions are requested only when the user starts a sync.
- Responsive Material 3 dashboard and sign-out.
- Password fields are never prefilled. Auth sessions are managed by the Supabase SDK.

## Security and production notes

The migration creates owner-scoped RLS policies, enables and forces RLS, grants table access only to authenticated users, validates health/nutrition ranges, and creates profiles on signup. Apply migrations to a fresh project before launching. Configure email confirmation, SMTP, redirect allowlists, MFA/rate limits, backups, and monitoring in Supabase. The public anon key is designed for client use only when RLS is correctly configured. Do not add service keys, AI provider secrets, or device-provider credentials to Flutter defines or source control.

The health sync reads from HealthKit or Health Connect only after an explicit permission request. Configure the platform privacy permissions and HealthKit capability, then verify on a real device before store release. Nutrition results are estimates, not clinical guidance.
