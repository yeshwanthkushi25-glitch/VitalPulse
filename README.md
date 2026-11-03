# VitalPulse — AI health & nutrition companion

VitalPulse is a Flutter application for nutrition and daily wellness tracking, backed by Supabase Auth and a row-level-secured Postgres database. The earlier browser prototypes are preserved separately in `demos/`.

## Project layout

- `vitalpulse_app/` — Flutter app for Android, iOS, web, and Windows.
- `supabase/` — backend configuration and database migrations.
- `demos/` — three previous HTML prototypes, preserved for reference and demonstration.
- `docs/screenshots/` — screenshots of the app and demos.

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

The app supports email/password account creation and sign-in, daily nutrition logging, water, steps, and sleep tracking, and account sign-out. Camera food recognition and automatic HealthKit/Health Connect watch synchronization are future integrations; the existing demos show prototype concepts for those features.

## Supabase CLI

From the project root:

```powershell
npx supabase login
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase db push
```
