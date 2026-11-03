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
4. Copy `.env.example` to `.env.local`, put your project URL and publishable key in it, and keep `.env.local` untracked. Then run the app from this directory:

   ```powershell
   Copy-Item .env.example .env.local
   flutter run -d chrome --dart-define-from-file=.env.local
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

## Meal scanner provider keys

Configure `OPENROUTER_API_KEY`, `GEMINI_API_KEY_1`, and `GEMINI_API_KEY_2` as Supabase Edge Function secrets for `analyze-food`. The function tries OpenRouter first, then the two Gemini keys as fallbacks. Keep provider keys in Supabase secrets; never put them in Flutter, HTML, `.env.local`, or source control. Provider requests may incur charges under the corresponding provider accounts.
