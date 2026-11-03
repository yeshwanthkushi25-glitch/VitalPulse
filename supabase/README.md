# VitalPulse test backend

This folder contains the Supabase CLI project and a multi-user schema. Nutrition and daily health rows are owned by authenticated Supabase users and protected by row-level security.

## After Docker Desktop is installed

From this folder's parent directory, run:

```powershell
npx supabase start
```

The local stack is for development and testing. It runs locally and is not a public website host.

## Connect to a Supabase cloud project

After signing in with `npx supabase login`, link this project using the project reference, then apply pending migrations with `npx supabase db push`. The production project has already received the migrations in this repository. The `profiles` table stores user-specific calorie, hydration, and sleep targets; profile rows remain owner-scoped by RLS.

The deployed `analyze-food` Edge Function requires a valid user session and uses server-side provider secrets. Configure `OPENROUTER_API_KEY`, `GEMINI_API_KEY_1`, `GEMINI_API_KEY_2`, and `ALLOWED_ORIGINS` in the Supabase Dashboard's Edge Function Secrets page. Never add provider keys to the app or GitHub. Image scans may use billable provider requests.

Do not put service-role keys or AI provider keys in HTML source. The Flutter client uses a publishable key with RLS; AI provider keys stay in server-side function secrets.
