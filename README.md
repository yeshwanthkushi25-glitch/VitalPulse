# VitalPulse — AI health & nutrition companion

VitalPulse is a Flutter application for nutrition and daily wellness tracking, backed by Supabase Auth and a row-level-secured Postgres database. The earlier browser prototypes are preserved separately in `demos/`.

**The HTML demos are local-only prototypes.** Their sample accounts and browser storage are not secure authentication or server-side storage. The demo pages remove previously entered Supabase key fields and scrub saved key values from their local storage. Use the Flutter app for real accounts and data.

## Project layout

- `vitalpulse_app/` — Flutter app for Android, iOS, web, and Windows.
- `supabase/` — backend configuration and database migrations.
- `supabase/functions/analyze-food/` — authenticated, rate-limited AI meal scanner. Provider secrets are stored server-side.
- `demos/` — three previous HTML prototypes, preserved for reference and demonstration.
- `docs/screenshots/` — screenshots of the app and demos.
- `docs/privacy-policy.md` — starter privacy policy for review before release.

## Demo screenshots

| Flutter sign-in | Food & drink scanner prototype |
| --- | --- |
| ![VitalPulse Flutter sign-in screen](docs/screenshots/flutter-app-login.png) | ![VitalPulse food and drink scanner demo](docs/screenshots/food-drink-scanner.png) |

| Personalized diet prototype | Supabase dashboard prototype |
| --- | --- |
| ![VitalPulse personalized diet demo](docs/screenshots/personalized-diet.png) | ![VitalPulse Supabase dashboard demo](docs/screenshots/supabase-dashboard.png) |

## Start the app

Read [`vitalpulse_app/README.md`](vitalpulse_app/README.md) to configure a Supabase project, apply migrations, and run the app from VS Code. The Flutter app needs a Supabase project URL and public anon/publishable key at launch. Never put a service-role key in the client.

Open `vitalpulse_app/` as the VS Code workspace. Install the Flutter and Dart extensions, then run the app from VS Code's Run and Debug panel or with `flutter run`.

## Backend security

The migration in `supabase/migrations/` enables and forces RLS on profiles, nutrition records, and daily health records. All rows are owner-scoped to the Supabase Auth user. It applies input range constraints and grants table access only to authenticated users. Apply the migration before using a cloud project.

## Current scope

The app supports email/password account creation and sign-in, meal and beverage logging, water tracking, optional Apple Health / Health Connect read sync for steps, heart rate, and sleep, photo-based nutrition estimates with user review, and account sign-out. A meal photo is sent to the configured AI provider only after the user chooses a scan. Photos are not retained by VitalPulse. Estimates are approximate and should be reviewed before saving.

## Supabase CLI

From the project root:

```powershell
npx supabase login
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase db push
npx supabase functions deploy analyze-food
```

For meal photo scans, copy `supabase/functions/.env.example` to `supabase/functions/.env`, add your OpenAI API key, and set the deployed web origin in `ALLOWED_ORIGINS`. The local Supabase CLI reads that file for local functions; upload the same secrets with `npx supabase secrets set --env-file supabase/functions/.env`. Never commit `.env`; the function verifies the user's Supabase session, applies a 20-scan daily account limit, validates image type and size, and calls the AI provider with a server-side key. On iOS, enable the HealthKit capability in the signing profile. On Android, install Health Connect and review the privacy policy before requesting permissions.
